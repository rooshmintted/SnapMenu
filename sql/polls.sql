
-- Create menu_polls table
CREATE TABLE menu_polls (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    creator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT,
    description TEXT,
    menu_image_url TEXT NOT NULL,
    analysis_data JSONB NOT NULL, -- Store the full MenuAnalysisResponse
    poll_options JSONB NOT NULL, -- Array of dishes available for voting
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    allow_multiple_votes BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create poll_votes table
CREATE TABLE poll_votes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    poll_id UUID NOT NULL REFERENCES menu_polls(id) ON DELETE CASCADE,
    voter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    selected_dishes JSONB NOT NULL, -- Array of dish names/IDs selected
    vote_comment TEXT, -- Optional comment from voter
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one vote per user per poll (unless multiple votes allowed)
    UNIQUE(poll_id, voter_id)
);

-- Create poll_recipients table (who can see/vote on the poll)
CREATE TABLE poll_recipients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    poll_id UUID NOT NULL REFERENCES menu_polls(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    has_voted BOOLEAN DEFAULT false,
    notified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique poll-recipient pairs
    UNIQUE(poll_id, recipient_id)
);

-- Create indexes for better performance
CREATE INDEX idx_menu_polls_creator_id ON menu_polls(creator_id);
CREATE INDEX idx_menu_polls_expires_at ON menu_polls(expires_at);
CREATE INDEX idx_menu_polls_is_active ON menu_polls(is_active);
CREATE INDEX idx_menu_polls_created_at ON menu_polls(created_at DESC);

CREATE INDEX idx_poll_votes_poll_id ON poll_votes(poll_id);
CREATE INDEX idx_poll_votes_voter_id ON poll_votes(voter_id);
CREATE INDEX idx_poll_votes_created_at ON poll_votes(created_at DESC);

CREATE INDEX idx_poll_recipients_poll_id ON poll_recipients(poll_id);
CREATE INDEX idx_poll_recipients_recipient_id ON poll_recipients(recipient_id);
CREATE INDEX idx_poll_recipients_has_voted ON poll_recipients(has_voted);

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_menu_polls_updated_at 
    BEFORE UPDATE ON menu_polls 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_poll_votes_updated_at 
    BEFORE UPDATE ON poll_votes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE menu_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_recipients ENABLE ROW LEVEL SECURITY;

-- RLS Policies for menu_polls
-- Users can view polls where they are recipients or creators
CREATE POLICY "Users can view polls they have access to" ON menu_polls
    FOR SELECT USING (
        auth.uid() = creator_id OR 
        EXISTS (
            SELECT 1 FROM poll_recipients 
            WHERE poll_id = menu_polls.id AND recipient_id = auth.uid()
        )
    );

-- Users can create their own polls
CREATE POLICY "Users can create polls" ON menu_polls
    FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- Users can update their own polls (before they expire)
CREATE POLICY "Users can update their own polls" ON menu_polls
    FOR UPDATE USING (
        auth.uid() = creator_id AND 
        expires_at > NOW() AND 
        is_active = true
    );

-- Users can delete their own polls
CREATE POLICY "Users can delete their own polls" ON menu_polls
    FOR DELETE USING (auth.uid() = creator_id);

-- RLS Policies for poll_votes
-- Users can view votes for polls they have access to
CREATE POLICY "Users can view votes for accessible polls" ON poll_votes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM menu_polls mp 
            WHERE mp.id = poll_votes.poll_id AND (
                mp.creator_id = auth.uid() OR 
                EXISTS (
                    SELECT 1 FROM poll_recipients pr 
                    WHERE pr.poll_id = mp.id AND pr.recipient_id = auth.uid()
                )
            )
        )
    );

-- Users can insert their own votes
CREATE POLICY "Users can vote on accessible polls" ON poll_votes
    FOR INSERT WITH CHECK (
        auth.uid() = voter_id AND
        EXISTS (
            SELECT 1 FROM poll_recipients pr 
            WHERE pr.poll_id = poll_votes.poll_id AND pr.recipient_id = auth.uid()
        ) AND
        EXISTS (
            SELECT 1 FROM menu_polls mp 
            WHERE mp.id = poll_votes.poll_id AND mp.expires_at > NOW() AND mp.is_active = true
        )
    );

-- Users can update their own votes (if poll allows)
CREATE POLICY "Users can update their own votes" ON poll_votes
    FOR UPDATE USING (
        auth.uid() = voter_id AND
        EXISTS (
            SELECT 1 FROM menu_polls mp 
            WHERE mp.id = poll_votes.poll_id AND mp.expires_at > NOW() AND mp.is_active = true
        )
    );

-- RLS Policies for poll_recipients
-- Poll creators can manage recipients
CREATE POLICY "Poll creators can manage recipients" ON poll_recipients
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM menu_polls mp 
            WHERE mp.id = poll_recipients.poll_id AND mp.creator_id = auth.uid()
        )
    );

-- Recipients can view their own recipient records
CREATE POLICY "Users can view their recipient status" ON poll_recipients
    FOR SELECT USING (auth.uid() = recipient_id);

-- Function to get vote counts for a poll
CREATE OR REPLACE FUNCTION get_poll_vote_counts(poll_uuid UUID)
RETURNS TABLE(dish_name TEXT, vote_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dish->>'dish_name' as dish_name,
        COUNT(*) as vote_count
    FROM poll_votes pv,
         jsonb_array_elements(pv.selected_dishes) as dish
    WHERE pv.poll_id = poll_uuid
    GROUP BY dish->>'dish_name'
    ORDER BY vote_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if poll has expired and update status
CREATE OR REPLACE FUNCTION update_expired_polls()
RETURNS void AS $$
BEGIN
    UPDATE menu_polls 
    SET is_active = false 
    WHERE expires_at <= NOW() AND is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a view for poll statistics
CREATE VIEW poll_stats AS
SELECT 
    mp.id,
    mp.title,
    mp.creator_id,
    mp.created_at,
    mp.expires_at,
    mp.is_active,
    COUNT(DISTINCT pr.recipient_id) as total_recipients,
    COUNT(DISTINCT pv.voter_id) as total_votes,
    CASE 
        WHEN COUNT(DISTINCT pr.recipient_id) > 0 
        THEN ROUND(COUNT(DISTINCT pv.voter_id)::numeric / COUNT(DISTINCT pr.recipient_id) * 100, 2)
        ELSE 0 
    END as participation_rate
FROM menu_polls mp
LEFT JOIN poll_recipients pr ON mp.id = pr.poll_id
LEFT JOIN poll_votes pv ON mp.id = pv.poll_id
GROUP BY mp.id, mp.title, mp.creator_id, mp.created_at, mp.expires_at, mp.is_active;