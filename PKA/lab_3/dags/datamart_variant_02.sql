CREATE OR REPLACE VIEW public.video_games_datamart AS
SELECT
    year_of_release,
    genre,
    platform,
    publisher,
    global_sales,
    game_name
FROM public.stg_video_games;
