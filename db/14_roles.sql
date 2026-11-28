-- Lab 4: application roles.

\getenv reader_password APP_READER_PASSWORD
\getenv writer_password APP_WRITER_PASSWORD

CREATE ROLE app_reader LOGIN PASSWORD :'reader_password';
CREATE ROLE app_writer LOGIN PASSWORD :'writer_password';

-- Remove default access to functions.
REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public FROM PUBLIC;

-- Reader can read views only.
GRANT USAGE ON SCHEMA public TO app_reader;
GRANT SELECT ON v_meme_cards, v_meme_engagement TO app_reader;

-- Writer can use the business function.
GRANT USAGE ON SCHEMA public TO app_writer;

GRANT EXECUTE ON FUNCTION register_repost(integer, text) TO app_writer;