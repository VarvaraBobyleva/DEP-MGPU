import csv
import logging
from contextlib import closing
from pathlib import Path

import kagglehub
import pendulum
from airflow.decorators import dag, task
from airflow.providers.postgres.hooks.postgres import PostgresHook
from psycopg2 import sql
from psycopg2.extras import execute_values

DATASET = "sidtwr/videogames-sales-dataset"
CONNECTION = "analytics_postgres"
FIELDS = ("year_of_release", "genre", "platform", "publisher", "global_sales", "name")
LOGGER = logging.getLogger(__name__)


def find_sales_csv(directory):
    matches = []
    for path in sorted(directory.rglob("*.csv")):
        with path.open(encoding="utf-8-sig", newline="") as source:
            header = next(csv.reader(source), [])
        names = {column.strip().lower() for column in header}
        if set(FIELDS).issubset(names):
            matches.append(path)

    if len(matches) != 1:
        raise ValueError(
            f"Expected one CSV with {FIELDS}. Found: {matches}. "
            f"Available CSV files: {list(directory.rglob('*.csv'))}"
        )
    return matches[0]


@dag(
    dag_id="video_games_variant_02",
    start_date=pendulum.datetime(2024, 1, 1, tz="UTC"),
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
)
def video_games_variant_02():
    @task
    def download():
        path = find_sales_csv(Path(kagglehub.dataset_download(DATASET)))
        LOGGER.info("Selected CSV: %s", path.name)
        return str(path)

    @task
    def load_raw(file_path):
        hook = PostgresHook(postgres_conn_id=CONNECTION)
        with Path(file_path).open(encoding="utf-8-sig", newline="") as source:
            reader = csv.reader(source)
            header = next(reader)
            columns = {column.strip().lower(): column for column in header}
            if len(columns) != len(header) or "" in columns:
                raise ValueError("CSV contains duplicate or empty column names")

            rows = []
            for row in reader:
                if not row:
                    continue
                if len(row) != len(header):
                    raise ValueError(f"Unexpected number of fields on line {reader.line_num}")
                rows.append(tuple(row))

        if not rows:
            raise ValueError("CSV contains no records")

        definitions = sql.SQL(", ").join(
            sql.SQL("{} text").format(sql.Identifier(column)) for column in header
        )
        with closing(hook.get_conn()) as connection, connection, connection.cursor() as cursor:
            cursor.execute("DROP TABLE IF EXISTS public.raw_video_games")
            cursor.execute(
                sql.SQL("CREATE TABLE public.raw_video_games ({})").format(definitions)
            )
            execute_values(cursor, "INSERT INTO public.raw_video_games VALUES %s", rows)
        LOGGER.info("RAW records: %d", len(rows))
        return {field: columns[field] for field in FIELDS}

    @task
    def transform(columns):
        hook = PostgresHook(postgres_conn_id=CONNECTION)
        raw_fields = sql.SQL(", ").join(
            sql.SQL("{} AS {}").format(sql.Identifier(columns[field]), sql.Identifier(field))
            for field in FIELDS
        )
        query = sql.SQL("""
            WITH source AS (
                SELECT {raw_fields} FROM public.raw_video_games
            ), typed AS (
                SELECT
                    CASE WHEN btrim(year_of_release) ~ '^[1-9][0-9]{{3}}([.]0+)?$'
                         THEN split_part(btrim(year_of_release), '.', 1)::integer
                    END AS year_of_release,
                    NULLIF(btrim(regexp_replace(genre, '[[:space:]]+', ' ', 'g')), '') AS genre,
                    NULLIF(btrim(regexp_replace(platform, '[[:space:]]+', ' ', 'g')), '') AS platform,
                    NULLIF(btrim(regexp_replace(publisher, '[[:space:]]+', ' ', 'g')), '') AS publisher,
                    CASE WHEN btrim(global_sales) ~ '^[0-9]+([.][0-9]+)?$'
                         THEN btrim(global_sales)::numeric
                    END AS global_sales,
                    NULLIF(btrim(regexp_replace(name, '[[:space:]]+', ' ', 'g')), '') AS game_name
                FROM source
            )
            INSERT INTO public.stg_video_games
            SELECT year_of_release,
                   CASE WHEN genre IS NULL OR lower(genre) IN ('n/a', 'na', 'unknown') THEN 'Не указано' ELSE genre END,
                   CASE WHEN platform IS NULL OR lower(platform) IN ('n/a', 'unknown') THEN 'Не указано' ELSE platform END,
                   CASE WHEN publisher IS NULL OR lower(publisher) IN ('n/a', 'na', 'unknown') THEN 'Не указано' ELSE publisher END,
                   global_sales,
                   CASE WHEN game_name IS NULL OR lower(game_name) IN ('n/a', 'unknown') THEN NULL ELSE game_name END
            FROM typed
            WHERE global_sales IS NOT NULL
        """).format(raw_fields=raw_fields)

        with closing(hook.get_conn()) as connection, connection, connection.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS public.stg_video_games (
                    year_of_release integer,
                    genre text NOT NULL,
                    platform text NOT NULL,
                    publisher text NOT NULL,
                    global_sales numeric NOT NULL CHECK (global_sales >= 0),
                    game_name text
                )
            """)
            cursor.execute("TRUNCATE public.stg_video_games")
            cursor.execute(query)
            stage_count = cursor.rowcount
            if not stage_count:
                raise ValueError("No records have a valid Global_Sales value")
            cursor.execute("SELECT count(*) FROM public.raw_video_games")
            raw_count = cursor.fetchone()[0]
            cursor.execute("""
                SELECT count(*) FILTER (WHERE year_of_release IS NULL),
                       count(*) FILTER (WHERE game_name IS NULL)
                FROM public.stg_video_games
            """)
            missing_year, missing_name = cursor.fetchone()
        LOGGER.info(
            "RAW=%d STG=%d excluded_invalid_sales=%d missing_year=%d missing_name=%d",
            raw_count, stage_count, raw_count - stage_count, missing_year, missing_name,
        )

    @task
    def create_datamart():
        script = Path(__file__).with_name("datamart_variant_02.sql")
        hook = PostgresHook(postgres_conn_id=CONNECTION)
        hook.run(script.read_text(encoding="utf-8"))

    transform(load_raw(download())) >> create_datamart()


video_games_variant_02()
