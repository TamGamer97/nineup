-- MLB Trivia Database - Simplified Structure
-- Run this in your Supabase SQL editor to create the database from scratch

-- Step 1: Create the daily_questions table (text-only format)
CREATE TABLE daily_questions (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    question_order INTEGER NOT NULL CHECK (question_order BETWEEN 1 AND 9),
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL DEFAULT 'text' CHECK (question_type = 'text'),
    correct_answer TEXT NOT NULL,
    explanation TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(date, question_order)
);

-- Step 2: Create the MLB players table for pack system
CREATE TABLE mlb_players (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    position TEXT NOT NULL,
    team TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 50 AND 99),
    rarity TEXT NOT NULL CHECK (rarity IN ('Common', 'Rare', 'Epic', 'Legendary')),
    image_url TEXT,
    stats JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create simplified user lineups table with daily lineups as JSON
CREATE TABLE user_lineups (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_lineups JSONB NOT NULL DEFAULT '{}',
    -- Structure: {"2025-01-01": [{"player_id": 1, "order": 1, "acquired_at": "2025-01-01T10:30:00Z"}, ...]}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Step 4: Enable Row Level Security (RLS)
ALTER TABLE daily_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE mlb_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_lineups ENABLE ROW LEVEL SECURITY;

-- Step 5: Create policies for daily_questions (read-only for all authenticated users)
CREATE POLICY "Allow read access to daily questions" ON daily_questions
    FOR SELECT USING (true);

-- Step 6: Create policies for mlb_players (read-only for all authenticated users)
CREATE POLICY "Allow read access to mlb players" ON mlb_players
    FOR SELECT USING (true);

-- Step 7: Create policies for user_lineups
CREATE POLICY "Users can view their own lineups" ON user_lineups
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own lineups" ON user_lineups
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own lineups" ON user_lineups
    FOR UPDATE USING (auth.uid() = user_id);

-- Step 8: Create indexes for better performance
CREATE INDEX idx_daily_questions_date ON daily_questions(date);
CREATE INDEX idx_mlb_players_rating ON mlb_players(rating);
CREATE INDEX idx_mlb_players_rarity ON mlb_players(rarity);
CREATE INDEX idx_user_lineups_user_id ON user_lineups(user_id);

-- Step 9: Create function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Step 10: Create trigger to automatically update updated_at
CREATE TRIGGER update_user_lineups_updated_at 
    BEFORE UPDATE ON user_lineups 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Step 11: Insert sample questions for today (2025-01-01)
INSERT INTO daily_questions (date, question_order, question_text, correct_answer, explanation) VALUES
('2025-01-01', 1, 'Who holds the MLB record for most career home runs?', 'Barry Bonds', 'Barry Bonds hit 762 home runs during his career.'),
('2025-01-01', 2, 'In what year did Jackie Robinson break the color barrier in MLB?', '1947', 'Jackie Robinson made his MLB debut on April 15, 1947, for the Brooklyn Dodgers.'),
('2025-01-01', 3, 'Which team has won the most World Series championships?', 'New York Yankees', 'The Yankees have won 27 World Series championships.'),
('2025-01-01', 4, 'What is the name of the stadium where the Boston Red Sox play their home games?', 'Fenway Park', 'Fenway Park has been the home of the Red Sox since 1912.'),
('2025-01-01', 5, 'Who was the first player to hit 60 home runs in a single season?', 'Babe Ruth', 'Babe Ruth hit 60 home runs in 1927.'),
('2025-01-01', 6, 'What year did the designated hitter rule first come into effect in the American League?', '1973', 'The DH rule was introduced in the American League in 1973.'),
('2025-01-01', 7, 'Which pitcher holds the record for most career strikeouts?', 'Nolan Ryan', 'Nolan Ryan struck out 5,714 batters in his career.'),
('2025-01-01', 8, 'What is the name of the award given to the best pitcher in each league?', 'Cy Young Award', 'The Cy Young Award is named after Hall of Fame pitcher Cy Young.'),
('2025-01-01', 9, 'Which team was the first to win three consecutive World Series championships?', 'New York Yankees', 'The Yankees won three straight World Series from 1998-2000.');

-- Step 12: Insert sample questions for tomorrow (2025-01-02)
INSERT INTO daily_questions (date, question_order, question_text, correct_answer, explanation) VALUES
('2025-01-02', 1, 'Who is known as "The Iron Horse"?', 'Lou Gehrig', 'Lou Gehrig was nicknamed "The Iron Horse" for his durability.'),
('2025-01-02', 2, 'What is the distance from home plate to the pitcher''s mound?', '60 feet 6 inches', 'The distance from home plate to the pitcher''s mound is 60 feet 6 inches.'),
('2025-01-02', 3, 'Which player has the most career hits in MLB history?', 'Pete Rose', 'Pete Rose collected 4,256 hits in his career.'),
('2025-01-02', 4, 'What is the name of the trophy awarded to the World Series champion?', 'Commissioner''s Trophy', 'The Commissioner''s Trophy is awarded to the World Series champion.'),
('2025-01-02', 5, 'In what year did the first MLB All-Star Game take place?', '1933', 'The first MLB All-Star Game was played in 1933 at Comiskey Park.'),
('2025-01-02', 6, 'Who holds the record for most consecutive games played?', 'Cal Ripken Jr.', 'Cal Ripken Jr. played in 2,632 consecutive games.'),
('2025-01-02', 7, 'What is the name of the award given to the best rookie in each league?', 'Rookie of the Year', 'The Rookie of the Year Award is given to the best first-year player.'),
('2025-01-02', 8, 'Which team plays their home games at Wrigley Field?', 'Chicago Cubs', 'Wrigley Field has been the home of the Chicago Cubs since 1916.'),
('2025-01-02', 9, 'What year did the National League first begin play?', '1876', 'The National League was founded in 1876.');

-- Step 13: Insert MLB players for pack system
INSERT INTO mlb_players (name, position, team, rating, rarity, stats) VALUES
-- Legendary Players (95-99)
('Babe Ruth', 'RF', 'New York Yankees', 99, 'Legendary', '{"career_hr": 714, "career_avg": 0.342, "era": "1920s-1930s"}'),
('Willie Mays', 'CF', 'San Francisco Giants', 98, 'Legendary', '{"career_hr": 660, "career_avg": 0.302, "gold_gloves": 12}'),
('Ted Williams', 'LF', 'Boston Red Sox', 97, 'Legendary', '{"career_avg": 0.344, "career_hr": 521, "last_400_season": 1941}'),
('Hank Aaron', 'RF', 'Atlanta Braves', 96, 'Legendary', '{"career_hr": 755, "career_avg": 0.305, "all_star_games": 25}'),
('Lou Gehrig', '1B', 'New York Yankees', 95, 'Legendary', '{"career_avg": 0.340, "consecutive_games": 2130, "era": "1920s-1930s"}'),

-- Epic Players (85-94)
('Mickey Mantle', 'CF', 'New York Yankees', 94, 'Epic', '{"career_hr": 536, "career_avg": 0.298, "mvp_awards": 3}'),
('Joe DiMaggio', 'CF', 'New York Yankees', 93, 'Epic', '{"career_avg": 0.325, "hitting_streak": 56, "era": "1930s-1950s"}'),
('Stan Musial', 'LF', 'St. Louis Cardinals', 92, 'Epic', '{"career_avg": 0.331, "career_hr": 475, "mvp_awards": 3}'),
('Ty Cobb', 'CF', 'Detroit Tigers', 91, 'Epic', '{"career_avg": 0.366, "career_hits": 4189, "era": "1900s-1920s"}'),
('Cy Young', 'P', 'Boston Red Sox', 90, 'Epic', '{"career_wins": 511, "career_era": 2.63, "era": "1890s-1910s"}'),
('Walter Johnson', 'P', 'Washington Senators', 89, 'Epic', '{"career_wins": 417, "career_era": 2.17, "era": "1900s-1920s"}'),
('Christy Mathewson', 'P', 'New York Giants', 88, 'Epic', '{"career_wins": 373, "career_era": 2.13, "era": "1900s-1910s"}'),
('Honus Wagner', 'SS', 'Pittsburgh Pirates', 87, 'Epic', '{"career_avg": 0.328, "career_hits": 3420, "era": "1890s-1910s"}'),
('Rogers Hornsby', '2B', 'St. Louis Cardinals', 86, 'Epic', '{"career_avg": 0.358, "career_hr": 301, "era": "1910s-1930s"}'),
('Tris Speaker', 'CF', 'Boston Red Sox', 85, 'Epic', '{"career_avg": 0.345, "career_hits": 3514, "era": "1900s-1920s"}'),

-- Rare Players (75-84)
('Mel Ott', 'RF', 'New York Giants', 84, 'Rare', '{"career_hr": 511, "career_avg": 0.304, "era": "1920s-1940s"}'),
('Jimmie Foxx', '1B', 'Philadelphia Athletics', 83, 'Rare', '{"career_hr": 534, "career_avg": 0.325, "era": "1920s-1940s"}'),
('Al Simmons', 'LF', 'Philadelphia Athletics', 82, 'Rare', '{"career_avg": 0.334, "career_hr": 307, "era": "1920s-1940s"}'),
('Charlie Gehringer', '2B', 'Detroit Tigers', 81, 'Rare', '{"career_avg": 0.320, "career_hits": 2839, "era": "1920s-1940s"}'),
('Lefty Grove', 'P', 'Philadelphia Athletics', 80, 'Rare', '{"career_wins": 300, "career_era": 3.06, "era": "1920s-1940s"}'),
('Carl Hubbell', 'P', 'New York Giants', 79, 'Rare', '{"career_wins": 253, "career_era": 2.98, "era": "1920s-1940s"}'),
('Dizzy Dean', 'P', 'St. Louis Cardinals', 78, 'Rare', '{"career_wins": 150, "career_era": 3.02, "era": "1930s-1940s"}'),
('Bill Dickey', 'C', 'New York Yankees', 77, 'Rare', '{"career_avg": 0.313, "career_hr": 202, "era": "1920s-1940s"}'),
('Gabby Hartnett', 'C', 'Chicago Cubs', 76, 'Rare', '{"career_avg": 0.297, "career_hr": 236, "era": "1920s-1940s"}'),
('Red Ruffing', 'P', 'New York Yankees', 75, 'Rare', '{"career_wins": 273, "career_era": 3.80, "era": "1920s-1940s"}'),

-- Common Players (50-74)
('Earl Averill', 'CF', 'Cleveland Indians', 74, 'Common', '{"career_avg": 0.318, "career_hr": 238, "era": "1920s-1940s"}'),
('Chuck Klein', 'RF', 'Philadelphia Phillies', 73, 'Common', '{"career_avg": 0.320, "career_hr": 300, "era": "1920s-1940s"}'),
('Paul Waner', 'RF', 'Pittsburgh Pirates', 72, 'Common', '{"career_avg": 0.333, "career_hits": 3152, "era": "1920s-1940s"}'),
('Lloyd Waner', 'CF', 'Pittsburgh Pirates', 71, 'Common', '{"career_avg": 0.316, "career_hits": 2459, "era": "1920s-1940s"}'),
('Kiki Cuyler', 'RF', 'Chicago Cubs', 70, 'Common', '{"career_avg": 0.321, "career_hits": 2299, "era": "1920s-1930s"}'),
('Sam Rice', 'RF', 'Washington Senators', 69, 'Common', '{"career_avg": 0.322, "career_hits": 2987, "era": "1910s-1930s"}'),
('Heinie Manush', 'LF', 'Detroit Tigers', 68, 'Common', '{"career_avg": 0.330, "career_hits": 2524, "era": "1920s-1940s"}'),
('Goose Goslin', 'LF', 'Washington Senators', 67, 'Common', '{"career_avg": 0.316, "career_hr": 248, "era": "1920s-1940s"}'),
('Babe Herman', 'RF', 'Brooklyn Dodgers', 66, 'Common', '{"career_avg": 0.324, "career_hr": 181, "era": "1920s-1940s"}'),
('Riggs Stephenson', 'LF', 'Chicago Cubs', 65, 'Common', '{"career_avg": 0.336, "career_hr": 63, "era": "1920s-1930s"}'),
('Hack Wilson', 'CF', 'Chicago Cubs', 64, 'Common', '{"career_hr": 244, "career_avg": 0.307, "era": "1920s-1930s"}'),
('Chick Hafey', 'LF', 'St. Louis Cardinals', 63, 'Common', '{"career_avg": 0.317, "career_hr": 164, "era": "1920s-1930s"}'),
('Freddie Lindstrom', '3B', 'New York Giants', 62, 'Common', '{"career_avg": 0.311, "career_hits": 1747, "era": "1920s-1930s"}'),
('Travis Jackson', 'SS', 'New York Giants', 61, 'Common', '{"career_avg": 0.291, "career_hr": 135, "era": "1920s-1930s"}'),
('Pie Traynor', '3B', 'Pittsburgh Pirates', 60, 'Common', '{"career_avg": 0.320, "career_hits": 2416, "era": "1920s-1930s"}'),
('Frankie Frisch', '2B', 'St. Louis Cardinals', 59, 'Common', '{"career_avg": 0.316, "career_hits": 2880, "era": "1910s-1930s"}'),
('Rabbit Maranville', 'SS', 'Boston Braves', 58, 'Common', '{"career_avg": 0.258, "career_hits": 2855, "era": "1910s-1930s"}'),
('Dave Bancroft', 'SS', 'New York Giants', 57, 'Common', '{"career_avg": 0.279, "career_hits": 2004, "era": "1910s-1930s"}'),
('Joe Sewell', 'SS', 'Cleveland Indians', 56, 'Common', '{"career_avg": 0.312, "career_hits": 2226, "era": "1920s-1930s"}'),
('Luke Appling', 'SS', 'Chicago White Sox', 55, 'Common', '{"career_avg": 0.310, "career_hits": 2749, "era": "1930s-1950s"}'),
('Arky Vaughan', 'SS', 'Pittsburgh Pirates', 54, 'Common', '{"career_avg": 0.318, "career_hr": 96, "era": "1930s-1940s"}'),
('Billy Herman', '2B', 'Chicago Cubs', 53, 'Common', '{"career_avg": 0.304, "career_hits": 2345, "era": "1930s-1940s"}'),
('Tony Lazzeri', '2B', 'New York Yankees', 52, 'Common', '{"career_avg": 0.292, "career_hr": 178, "era": "1920s-1930s"}'),
('Red Rolfe', '3B', 'New York Yankees', 51, 'Common', '{"career_avg": 0.289, "career_hits": 1391, "era": "1930s-1940s"}'),
('Joe Gordon', '2B', 'New York Yankees', 50, 'Common', '{"career_avg": 0.268, "career_hr": 253, "era": "1930s-1940s"}');

-- Step 14: Verify the setup
-- Check table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'user_lineups' 
ORDER BY ordinal_position;

-- Check sample data
SELECT date, question_order, question_text, correct_answer 
FROM daily_questions 
WHERE date IN ('2025-01-01', '2025-01-02') 
ORDER BY date, question_order;

-- Check that RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('daily_questions', 'mlb_players', 'user_lineups');

-- Check player distribution by rarity
SELECT rarity, COUNT(*) as count, AVG(rating) as avg_rating
FROM mlb_players 
GROUP BY rarity 
ORDER BY avg_rating DESC; 