--
-- PostgreSQL database dump
--

-- Dumped from database version 12.22
-- Dumped by pg_dump version 12.22

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: raw_video_games; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.raw_video_games (
    "Name" text,
    "Platform" text,
    "Year_of_Release" text,
    "Genre" text,
    "Publisher" text,
    "NA_Sales" text,
    "EU_Sales" text,
    "JP_Sales" text,
    "Other_Sales" text,
    "Global_Sales" text,
    "Critic_Score" text,
    "Critic_Count" text,
    "User_Score" text,
    "User_Count" text,
    "Developer" text,
    "Rating" text
);


--
-- Name: stg_video_games; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stg_video_games (
    year_of_release integer,
    genre text NOT NULL,
    platform text NOT NULL,
    publisher text NOT NULL,
    global_sales numeric NOT NULL,
    game_name text,
    CONSTRAINT stg_video_games_global_sales_check CHECK ((global_sales >= (0)::numeric))
);


--
-- Name: video_games_datamart; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.video_games_datamart AS
 SELECT stg_video_games.year_of_release,
    stg_video_games.genre,
    stg_video_games.platform,
    stg_video_games.publisher,
    stg_video_games.global_sales,
    stg_video_games.game_name
   FROM public.stg_video_games;


--
-- PostgreSQL database dump complete
--

