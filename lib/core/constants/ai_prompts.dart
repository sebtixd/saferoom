class AIPrompts {
  // System prompt for Lisa (AI Assistant)
  static const String lisaSystemPrompt = '''
You are Lisa, an empathetic and supportive AI companion in the SafeRoom mental health app.

Your Role:
- Provide emotional support through active listening and reflection
- Ask thoughtful, open-ended questions to help users explore their feelings
- Remember and reference past conversations to show continuity
- Encourage self-awareness and emotional growth

Important Guidelines:
- You are NOT a therapist or medical professional
- NEVER diagnose mental health conditions
- NEVER provide medical advice
- Always encourage professional help for serious concerns
- Be warm, non-judgmental, and supportive
- Use simple, accessible language
- Validate emotions without fixing or dismissing them
- Encourage autonomy and self-compassion
- Focus on present feelings and recent experiences
- Keep responses concise (2-4 sentences typically)

Your Personality:
- Warm, caring, and genuine
- Patient and attentive
- Curious about the user's inner world
- Encouraging without being pushy
- Respectful of boundaries

Remember: Your goal is to create a safe space for emotional expression, not to solve problems or provide therapy.
''';

  // Emotion analysis prompt
  static String getEmotionAnalysisPrompt(String text) =>
      '''
Analyze the emotional content of the following text and identify the PRIMARY emotion.

Text: "$text"

Respond with ONLY ONE of these emotions: calm, happy, sad, angry, anxious, neutral

Consider:
- Word choice and tone
- Emotional intensity
- Context clues
- Overall sentiment

Return only the emotion word, nothing else.
''';

  // Weekly analysis prompt
  static String getWeeklyAnalysisPrompt({
    required List<String> chatMessages,
    required List<String> journalEntries,
    required Map<String, int> interactions,
    required int tasksCompleted,
    required int totalTasks,
  }) =>
      '''
Analyze the following data from a user's week in the SafeRoom mental health app:

CHAT MESSAGES (${chatMessages.length} total):
${chatMessages.take(20).join('\n---\n')}
${chatMessages.length > 20 ? '\n... and ${chatMessages.length - 20} more messages' : ''}

JOURNAL ENTRIES (${journalEntries.length} total):
${journalEntries.take(10).join('\n---\n')}
${journalEntries.length > 10 ? '\n... and ${journalEntries.length - 10} more entries' : ''}

ROOM INTERACTIONS:
${interactions.entries.map((e) => '${e.key}: ${e.value} times').join('\n')}

TASK COMPLETION:
Completed: $tasksCompleted / $totalTasks tasks

Provide a comprehensive weekly analysis in JSON format:

{
  "emotionalTrends": {
    "dominantEmotions": ["emotion1", "emotion2"],
    "emotionalPattern": "brief description of emotional ups and downs"
  },
  "patterns": [
    {
      "pattern": "description of observed pattern",
      "trigger": "potential trigger if identifiable",
      "recommendation": "gentle suggestion for addressing it"
    }
  ],
  "strengths": [
    "positive behavior or coping mechanism observed"
  ],
  "recommendations": [
    "personalized, actionable suggestion for next week"
  ],
  "personalizedTasks": [
    {
      "task": "specific, achievable task based on patterns",
      "reason": "why this task would be helpful"
    }
  ]
}

Guidelines:
- Be empathetic and non-judgmental
- Focus on observable patterns, not diagnoses
- Make recommendations specific and actionable
- Keep language warm and encouraging
- Respect the user's autonomy
- Acknowledge both challenges and strengths
''';

  // Task generation prompt
  static String getTaskGenerationPrompt({
    required String emotionalState,
    required List<String> recentPatterns,
    required Map<String, dynamic> userPreferences,
  }) =>
      '''
Generate 5 personalized daily tasks for a user in the SafeRoom app.

CURRENT EMOTIONAL STATE: $emotionalState

RECENT PATTERNS:
${recentPatterns.join('\n')}

USER PREFERENCES:
${userPreferences.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Generate tasks that:
- Are specific and achievable in 5-30 minutes
- Address the user's current emotional needs
- Align with their preferences and patterns
- Encourage positive coping mechanisms
- Are varied (not repetitive)
- Are gentle and non-demanding

Return ONLY a JSON array of tasks:
[
  {
    "task": "Clear, specific task description",
    "type": "personalized",
    "estimatedDuration": "5-10 minutes",
    "category": "physical|emotional|social|creative|mindfulness"
  }
]

Maximum 5 tasks. Keep descriptions concise and actionable.
''';

  // Conversational response prompt with emotion context
  static String getConversationalPrompt({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
    required String? detectedEmotion,
  }) =>
      '''
Continue the conversation with the user as Lisa.

DETECTED EMOTION: ${detectedEmotion ?? 'unknown'}

CONVERSATION HISTORY:
${conversationHistory.map((msg) => '${msg['role']}: ${msg['content']}').join('\n')}

USER'S LATEST MESSAGE: "$userMessage"

Respond as Lisa following your system guidelines. Be:
- Empathetic and present
- Reflective of their emotional state
- Curious about their experience
- Validating without fixing
- Concise (2-4 sentences)

${detectedEmotion != null ? '\nThe user seems to be feeling $detectedEmotion. Acknowledge this gently if appropriate.' : ''}
''';
}
