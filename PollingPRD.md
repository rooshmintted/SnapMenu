1. Data Model Updates

Create a MenuPoll model that includes:

Original menu photo
Analysis results table
Poll creator info
Voting options (dishes from analysis)
Expiration time
Vote tallies


Create a PollVote model for individual votes:

Poll ID reference
Voter ID
Selected dish(es)
Vote timestamp



2. Database Schema Changes

Add menu_polls table to Supabase
Add poll_votes table with foreign key relationships
Set up proper indexing for efficient vote counting

3. UI Flow Integration

In MenuAnalysisResultView, add a "Create Poll" button alongside existing options
This button appears after analysis is complete and results are displayed

4. Poll Creation Flow

Create PollCreationView that shows:

Preview of original menu photo
Analysis results summary
Poll customization options (duration, which dishes to include)
Friend selection (reuse existing FriendSelectionView pattern)
Poll question/caption input



5. Poll Manager

Create PollManager class similar to your existing managers
Handle poll creation, vote submission, and results fetching
Manage poll expiration logic

6. Poll Display Views

Create PollView for displaying active polls to voters
Show original menu photo, analysis results, and voting interface
Create PollResultsView for showing vote tallies and winner

7. Friends Tab Integration

Add polls section to friends tab
Show active polls from friends
Display poll results after voting or expiration

8. Notification System

Add poll notifications (new poll from friend, poll results ready)
Integrate with existing friend notification patterns

9. Poll Voting Logic

Single or multiple choice voting options
Prevent duplicate voting
Real-time vote count updates

10. Results & Analytics

Show poll results with visual charts
Highlight "winner" dish based on votes
Show how your vote compared to others