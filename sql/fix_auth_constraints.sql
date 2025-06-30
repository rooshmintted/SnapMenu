-- Fix authentication constraints that are preventing user signup
-- The issue is that display_name constraint fails when null during auto profile creation

-- First, drop the problematic constraints
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_username_key;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS username_length;

-- Add proper constraints that handle null values correctly
-- Make username the unique field instead of display_name since that's what we actually use
ALTER TABLE public.profiles ADD CONSTRAINT profiles_username_unique UNIQUE (username);

-- Add username length constraint that only applies when username is not null
ALTER TABLE public.profiles ADD CONSTRAINT username_min_length 
    CHECK (username IS NULL OR char_length(username) >= 3);

-- Add display_name constraint that only applies when display_name is not null  
ALTER TABLE public.profiles ADD CONSTRAINT display_name_min_length 
    CHECK (display_name IS NULL OR char_length(display_name) >= 3);

-- Optional: Create a function to auto-populate display_name from username if needed
-- This ensures backward compatibility if any system expects display_name
CREATE OR REPLACE FUNCTION update_display_name()
RETURNS TRIGGER AS $$
BEGIN
    -- If display_name is null but username is provided, copy username to display_name
    IF NEW.display_name IS NULL AND NEW.username IS NOT NULL THEN
        NEW.display_name := NEW.username;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-populate display_name
DROP TRIGGER IF EXISTS trigger_update_display_name ON public.profiles;
CREATE TRIGGER trigger_update_display_name
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_display_name();

-- Enable RLS if not already enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Add RLS policy for users to manage their own profiles
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
CREATE POLICY "Users can manage own profile" ON public.profiles
    FOR ALL USING (auth.uid() = id);
