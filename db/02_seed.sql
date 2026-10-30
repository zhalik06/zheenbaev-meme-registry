
-- Lab 1: Meme Registry test data

-- 1. Authors
INSERT INTO authors (display_name, username, bio) VALUES
('Alex', 'alex_memes', 'Internet meme creator'),
('Sam', 'sam_funny', 'Funny content creator'),
('Jordan', 'jordan_posts', 'Daily memes'),
('Taylor', 'taylor_lol', 'Humor and entertainment'),
('Chris', 'chris_memes', 'Classic meme creator'),
('Morgan', 'morgan_fun', 'Gaming memes'),
('Jamie', 'jamie_daily', 'Everyday humor'),
('Casey', 'casey_laughs', 'Comedy creator'),
('Riley', 'riley_internet', 'Internet culture'),
('Drew', 'drew_memes', 'Technology memes');

-- 2. Templates
INSERT INTO templates (name, description) VALUES
('Drake Hotline Bling', 'Two choices comparison'),
('Distracted Boyfriend', 'A person looking at another option'),
('Two Buttons', 'Difficult decision between two options'),
('Woman Yelling at Cat', 'Argument and reaction'),
('Expanding Brain', 'Increasing levels of intelligence'),
('Change My Mind', 'An invitation to debate'),
('Surprised Pikachu', 'Unexpected reaction'),
('Success Kid', 'Small victory or achievement'),
('Galaxy Brain', 'Advanced or absurd idea'),
('This Is Fine', 'Staying calm in a difficult situation');

-- 3. Tags
INSERT INTO tags (name, description) VALUES
('humor', 'General funny content'),
('programming', 'Programming related memes'),
('school', 'Education and student life'),
('gaming', 'Video game memes'),
('work', 'Workplace humor'),
('cats', 'Cat related memes'),
('technology', 'Technology topics'),
('everyday', 'Daily life situations'),
('irony', 'Ironical content'),
('reaction', 'Reaction memes');

-- 4. Memes
INSERT INTO memes
    (title, description, media_url, author_id, template_id)
VALUES
('Monday Morning', 'When Monday arrives too early', 'https://example.com/memes/1.jpg', 1, 1),
('One More Episode', 'When you should go to sleep', 'https://example.com/memes/2.jpg', 2, 2),
('Debugging Choice', 'Choosing between two difficult fixes', 'https://example.com/memes/3.jpg', 3, 3),
('Cat Argument', 'Trying to explain a simple idea', 'https://example.com/memes/4.jpg', 4, 4),
('Programmer Brain', 'Different levels of coding knowledge', 'https://example.com/memes/5.jpg', 5, 5),
('Coffee Debate', 'Why coffee is necessary', 'https://example.com/memes/6.jpg', 6, 6),
('Unexpected Bug', 'When the code suddenly breaks', 'https://example.com/memes/7.jpg', 7, 7),
('First Commit', 'A small programming achievement', 'https://example.com/memes/8.jpg', 8, 8),
('Advanced Procrastination', 'Finding complicated ways to avoid work', 'https://example.com/memes/9.jpg', 9, 9),
('Everything Is Fine', 'When the project deadline is near', 'https://example.com/memes/10.jpg', 10, 10);

-- 5. Meme tags (many-to-many)
INSERT INTO meme_tags (meme_id, tag_id) VALUES
(1, 1), (1, 8),
(2, 1), (2, 8),
(3, 2), (3, 7),
(4, 6), (4, 10),
(5, 2), (5, 7),
(6, 1), (6, 5),
(7, 2), (7, 10),
(8, 2), (8, 1),
(9, 8), (9, 9),
(10, 5), (10, 9);

-- 6. Reposts
INSERT INTO reposts (meme_id, platform) VALUES
(1, 'instagram'),
(2, 'tiktok'),
(3, 'reddit'),
(4, 'facebook'),
(5, 'x'),
(6, 'instagram'),
(7, 'tiktok'),
(8, 'reddit'),
(9, 'other'),
(10, 'facebook');

-- 7. Reactions
INSERT INTO reactions (meme_id, reaction_type) VALUES
(1, 'like'),
(2, 'love'),
(3, 'laugh'),
(4, 'wow'),
(5, 'like'),
(6, 'laugh'),
(7, 'sad'),
(8, 'love'),
(9, 'angry'),
(10, 'like');
