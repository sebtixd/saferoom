# SafeRoom Setup Guide

## Quick Start

### 1. Environment Configuration

You need to configure your API keys. There are two ways to do this:

#### Option A: Update Constants File (Easiest for Development)

Edit `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';

  // AI Service Configuration
  static const String aiApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String aiApiKey = 'sk-your-openai-key-here';
  static const String aiModel = 'gpt-4o-mini';
}
```

#### Option B: Use Environment Variables (Recommended for Production)

Run with dart-define flags:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=AI_API_URL=https://api.openai.com/v1 \
  --dart-define=AI_API_KEY=sk-your-key
```

### 2. Supabase Setup

1. **Create a Supabase project** at https://supabase.com
2. **Copy your project URL and anon key** from Settings > API
3. **Run the database schema** (see SQL section below)
4. **Enable Email Authentication** in Authentication > Providers

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Create Assets Directories

```bash
mkdir -p assets/images assets/sprites assets/audio
```

### 5. Run the App

```bash
flutter run
```

## Detailed Supabase Database Setup

### Step 1: Run This SQL in Supabase SQL Editor

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT,
  is_anonymous BOOLEAN DEFAULT FALSE,
  display_name TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  last_login_at TIMESTAMP,
  onboarding_completed BOOLEAN DEFAULT FALSE
);

-- Emotional profiles
CREATE TABLE emotional_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  mood_baseline INT CHECK (mood_baseline BETWEEN 1 AND 10),
  stress_level INT CHECK (stress_level BETWEEN 1 AND 10),
  energy_level INT CHECK (energy_level BETWEEN 1 AND 10),
  happiness_triggers TEXT[],
  anger_triggers TEXT[],
  calming_factors TEXT[],
  preferred_colors TEXT[],
  spiritual_preferences TEXT,
  work_study_rhythm TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Chat messages
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  emotion_detected TEXT,
  topic TEXT,
  timestamp TIMESTAMP DEFAULT NOW(),
  metadata JSONB
);

-- Journal entries
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  mood TEXT,
  tags TEXT[] DEFAULT '{}',
  analyzed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tasks
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('generic', 'personalized')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'completed')),
  category TEXT,
  estimated_duration TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  due_date TIMESTAMP,
  impact JSONB
);

-- Game state
CREATE TABLE game_state (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_emotion TEXT DEFAULT 'neutral',
  pet_happiness INT DEFAULT 50 CHECK (pet_happiness BETWEEN 0 AND 100),
  object_states JSONB DEFAULT '{}'::jsonb,
  interaction_counts JSONB DEFAULT '{}'::jsonb,
  unlocked_items TEXT[] DEFAULT '{}',
  environment_effects JSONB DEFAULT '{}'::jsonb,
  last_updated TIMESTAMP DEFAULT NOW(),
  last_pet_interaction TIMESTAMP DEFAULT NOW()
);

-- Interactions tracking (optional, for analytics)
CREATE TABLE interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  object_id TEXT NOT NULL,
  interaction_type TEXT,
  timestamp TIMESTAMP DEFAULT NOW(),
  duration_seconds INT
);
```

### Step 2: Enable Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE emotional_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;

-- Policies for users table
CREATE POLICY "Users can view own record"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own record"
  ON users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own record"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Policies for emotional_profiles
CREATE POLICY "Users can manage own profile"
  ON emotional_profiles FOR ALL
  USING (auth.uid() = user_id);

-- Policies for chat_messages
CREATE POLICY "Users can manage own messages"
  ON chat_messages FOR ALL
  USING (auth.uid() = user_id);

-- Policies for journal_entries
CREATE POLICY "Users can manage own journal"
  ON journal_entries FOR ALL
  USING (auth.uid() = user_id);

-- Policies for tasks
CREATE POLICY "Users can manage own tasks"
  ON tasks FOR ALL
  USING (auth.uid() = user_id);

-- Policies for game_state
CREATE POLICY "Users can manage own game state"
  ON game_state FOR ALL
  USING (auth.uid() = user_id);

-- Policies for interactions
CREATE POLICY "Users can manage own interactions"
  ON interactions FOR ALL
  USING (auth.uid() = user_id);
```

### Step 3: Create Database Functions (Optional but Recommended)

```sql
-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to emotional_profiles
CREATE TRIGGER update_emotional_profiles_updated_at
    BEFORE UPDATE ON emotional_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to journal_entries
CREATE TRIGGER update_journal_entries_updated_at
    BEFORE UPDATE ON journal_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

## OpenAI API Setup

### Option 1: OpenAI (Recommended)

1. Create account at https://platform.openai.com
2. Go to API Keys section
3. Create a new API key
4. Copy the key (starts with `sk-`)
5. Use model: `gpt-4o-mini` (cost-effective) or `gpt-4-turbo-preview` (best quality)

### Option 2: Alternative Providers

The app uses OpenAI-compatible endpoints, so you can use:

- **Azure OpenAI**: https://azure.microsoft.com/en-us/products/ai-services/openai-service
- **Anthropic Claude**: Via proxy at https://www.anthropic.com
- **Local LLMs**: Use Ollama or LM Studio with OpenAI-compatible endpoint

Example for Ollama (local):

```dart
static const String aiApiUrl = 'http://localhost:11434/v1/chat/completions';
static const String aiApiKey = 'not-required';
static const String aiModel = 'llama2';
```

## Asset Requirements

### Images (`assets/images/`)

- `logo.png` - App logo (512x512 recommended)
- `splash_background.png` - Splash screen background (optional)

### Sprites (`assets/sprites/`)

For the game, you can:

1. **Use placeholder colored rectangles** (app works without images)
2. **Create simple sprites** using any image editor
3. **Use free assets** from:
   - https://opengameart.org
   - https://itch.io/game-assets/free
   - https://kenney.nl/assets

Recommended sizes:

- `player.png` - 48x48px
- `desk.png` - 64x64px
- `bed.png` - 96x64px
- `window.png` - 64x80px
- `pet.png` - 48x48px
- `prayer_mat.png` - 64x64px

### Audio (`assets/audio/`)

Optional audio files (MP3 format):

- `quran.mp3` - For prayer corner
- `breathing.mp3` - Breathing exercise guide
- `meditation.mp3` - Meditation background
- `rain.mp3` - Rain ambiance for sad mood

You can find free audio at:

- https://freesound.org
- https://incompetech.com

## Testing the App Without Full Setup

### Minimal Setup (No Backend)

1. **Skip Supabase** - Use anonymous auth (will throw errors but app runs)
2. **Mock AI responses** - Edit `AIServiceImpl` to return dummy data
3. **Use placeholder sprites** - The game will work with colored boxes

### Mock AI Service

Edit `lib/data/datasources/remote/ai_service.dart`:

```dart
@override
Future<String> chat(String message, {List<Map<String, String>>? history}) async {
  // Return mock response
  await Future.delayed(Duration(seconds: 1));
  return "I'm here to support you. How are you feeling today?";
}

@override
Future<String> analyzeEmotion(String text) async {
  await Future.delayed(Duration(milliseconds: 500));
  return 'calm'; // Always return calm
}
```

## Common Issues & Solutions

### Issue: "Supabase not initialized"

**Solution**: Check that `ApiConstants.supabaseUrl` and `ApiConstants.supabaseAnonKey` are set correctly.

### Issue: "AI API request failed"

**Solution**:

- Verify your OpenAI API key is valid
- Check you have credits in your OpenAI account
- Ensure `ApiConstants.aiApiUrl` is correct

### Issue: "No assets found"

**Solution**:

- Create the asset directories: `mkdir -p assets/images assets/sprites assets/audio`
- Add at least one file to each directory (can be empty placeholder)
- Run `flutter pub get` again

### Issue: "Build fails with game dependencies"

**Solution**:

```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "Database connection failed"

**Solution**:

- Verify Supabase project is active
- Check RLS policies are set correctly
- Ensure user is authenticated before making database calls

## Development Tips

### Hot Reload with Game

Flame games don't always hot reload properly. If changes don't appear:

1. Stop the app (Ctrl+C)
2. Run `flutter run` again

### Debugging AI Responses

Enable logging in `AIServiceImpl`:

```dart
print('AI Request: $messages');
print('AI Response: $response');
```

### Testing Without Internet

The app requires internet for:

- Authentication (Supabase)
- AI features (OpenAI)

For offline testing, you need to:

1. Mock the repositories
2. Use local storage only
3. Disable AI features

## Next Steps

Once setup is complete:

1. **Run the app**: `flutter run`
2. **Create an account** or use anonymous login
3. **Complete onboarding** (9 questions)
4. **Explore the safe room**
5. **Interact with objects**
6. **Chat with Lisa** (AI assistant)
7. **Write journal entries**
8. **Complete daily tasks**

## Production Checklist

Before deploying:

- [ ] Set up environment variables (don't commit API keys)
- [ ] Enable Supabase RLS policies
- [ ] Configure proper authentication flows
- [ ] Add app icons and splash screens
- [ ] Test on multiple devices
- [ ] Set up error tracking (e.g., Sentry)
- [ ] Configure analytics (optional)
- [ ] Review and accept AI API terms of service
- [ ] Set up database backups
- [ ] Create privacy policy
- [ ] Add terms of service

## Getting Help

If you're stuck:

1. Check error logs: `flutter logs`
2. Review Supabase dashboard for database errors
3. Test API keys manually using curl
4. Check the GitHub issues
5. Review Flutter and Flame documentation

---

**Important**: This app is for emotional wellness support, not medical treatment. Always include appropriate disclaimers and encourage users to seek professional help when needed.
