
-- Lab 1: Meme Registry database schema

-- 1. Authors
CREATE TABLE authors (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    display_name text NOT NULL,
    username text NOT NULL UNIQUE,
    bio text,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Meme templates
CREATE TABLE templates (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tags
CREATE TABLE tags (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text
);

-- 4. Memes
CREATE TABLE memes (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title text NOT NULL,
    description text,
    media_url text NOT NULL,
    author_id integer NOT NULL,
    template_id integer NOT NULL,
    viral_index integer NOT NULL DEFAULT 0,

    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT memes_author_fk
        FOREIGN KEY (author_id)
        REFERENCES authors (id)
        ON DELETE RESTRICT,

    CONSTRAINT memes_template_fk
        FOREIGN KEY (template_id)
        REFERENCES templates (id)
        ON DELETE RESTRICT,

    CONSTRAINT memes_viral_index_check
        CHECK (viral_index >= 0),

    CONSTRAINT memes_title_check
        CHECK (length(trim(title)) > 0)
);

-- 5. Meme-tag relationship (many-to-many)
CREATE TABLE meme_tags (
    meme_id integer NOT NULL,
    tag_id integer NOT NULL,

    PRIMARY KEY (meme_id, tag_id),

    CONSTRAINT meme_tags_meme_fk
        FOREIGN KEY (meme_id)
        REFERENCES memes (id)
        ON DELETE CASCADE,

    CONSTRAINT meme_tags_tag_fk
        FOREIGN KEY (tag_id)
        REFERENCES tags (id)
        ON DELETE CASCADE
);

-- 6. Reposts
CREATE TABLE reposts (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meme_id integer NOT NULL,
    platform text NOT NULL,
    reposted_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT reposts_meme_fk
        FOREIGN KEY (meme_id)
        REFERENCES memes (id)
        ON DELETE CASCADE,

    CONSTRAINT reposts_platform_check
        CHECK (platform IN (
            'instagram',
            'tiktok',
            'facebook',
            'reddit',
            'x',
            'other'
        ))
);

-- 7. Reactions
CREATE TABLE reactions (
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meme_id integer NOT NULL,
    reaction_type text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT reactions_meme_fk
        FOREIGN KEY (meme_id)
        REFERENCES memes (id)
        ON DELETE CASCADE,

    CONSTRAINT reactions_type_check
        CHECK (reaction_type IN (
            'like',
            'love',
            'laugh',
            'wow',
            'sad',
            'angry'
        ))
);
