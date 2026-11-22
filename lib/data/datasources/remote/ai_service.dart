import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Service for AI operations (OpenAI-compatible API)
abstract class AIService {
  /// Send a message to the AI and get a response
  Future<String> chat(String message, {List<Map<String, String>>? history});
  
  /// Analyze emotion from text
  Future<String> analyzeEmotion(String text);
  
  /// Generate personalized tasks based on analysis
  Future<List<Map<String, dynamic>>> generateTasks(Map<String, dynamic> analysisData);

  /// Generate personalized daily tasks based on user notes
  Future<List<String>> generatePersonalizedTasks(List<String> notes);
  
  /// Perform weekly analysis
  Future<Map<String, dynamic>> weeklyAnalysis(Map<String, dynamic> userData);
}

/// Implementation of [AIService] using OpenAI-compatible API
class AIServiceImpl implements AIService {
  final http.Client _httpClient;

  AIServiceImpl({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// System prompt for Lisa (the AI assistant)
  static const String _lisaSystemPrompt = '''
You are Lisa, a warm and empathetic AI companion in the SafeRoom app—a gamified mental health space. Your role is to support users' emotional well-being through:

CORE PRINCIPLES:
- Be empathetic, non-judgmental, and supportive
- Never provide medical diagnoses or clinical advice
- Encourage emotional awareness and self-reflection
- Use reflective questions to help users explore their feelings
- Celebrate small wins and progress
- Remember user's emotional patterns and preferences

CONVERSATION STYLE:
- Warm and genuine tone
- Short, focused responses (2-3 sentences when possible)
- Ask one thoughtful question at a time
- Validate feelings before offering perspectives
- Use the user's name when appropriate

IMPORTANT: You are NOT a therapist. If users express serious mental health concerns, gently encourage them to seek professional support while remaining supportive.
''';

  @override
  Future<String> chat(String message, {List<Map<String, String>>? history}) async {
    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _lisaSystemPrompt},
      ];

      // Add history if provided
      if (history != null) {
        messages.addAll(history);
      }

      messages.add({'role': 'user', 'content': message});

      final response = await _makeRequest(messages);
      return response;
    } catch (e) {
      throw AIServiceException(message: 'Failed to get AI response: $e');
    }
  }

  @override
  Future<String> analyzeEmotion(String text) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': '''
Analyze the emotional content of the user's text and respond with ONLY one of these emotions: calm, happy, sad, angry, anxious.
Do not include any other text, just the single emotion word in lowercase.
'''
        },
        {'role': 'user', 'content': text},
      ];

      final response = await _makeRequest(messages);
      final emotion = response.toLowerCase().trim();
      
      // Validate the response
      final validEmotions = ['calm', 'happy', 'sad', 'angry', 'anxious'];
      if (validEmotions.contains(emotion)) {
        return emotion;
      }
      return 'calm'; // Default fallback
    } catch (e) {
      return 'calm'; // Default on error
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateTasks(
    Map<String, dynamic> analysisData,
  ) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': '''
You are a mental health task generator. Based on the user's emotional patterns and data, generate 3-5 personalized daily tasks.

Each task should:
- Be specific and actionable
- Take 5-15 minutes to complete
- Support emotional well-being
- Be non-punitive and encouraging

Respond with a JSON array of tasks in this format:
[
  {"title": "Task title", "description": "Brief description", "duration": 10},
  ...
]

Only output the JSON array, no other text.
'''
        },
        {
          'role': 'user',
          'content': 'Generate tasks based on this data: ${jsonEncode(analysisData)}'
        },
      ];

      final response = await _makeRequest(messages);
      final jsonResponse = jsonDecode(response) as List;
      return jsonResponse.cast<Map<String, dynamic>>();
    } catch (e) {
      // Return default tasks on error
      return [
        {
          'title': 'Take 5 deep breaths',
          'description': 'Pause and focus on your breathing for a moment',
          'duration': 2
        },
        {
          'title': 'Write one thing you\'re grateful for',
          'description': 'Reflect on something positive in your life',
          'duration': 5
        },
      ];
    }
  }

  @override
  Future<List<String>> generatePersonalizedTasks(List<String> notes) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': '''
You are an expert AI mental health companion. Read the user's recent notes carefully.
Understand what they wrote, how they feel, their emotional tone, concerns, stressors, and goals.

Based on what they wrote and how they feel, generate exactly 3 personalized, actionable daily tasks.

RULES:
- Tasks must be short, clear, and specific.
- Tasks must directly relate to the user's notes/feelings (e.g., stressed -> calming task; sad/lonely -> connection/self-compassion; low energy -> gentle movement; overwhelmed -> small organizing step).
- Avoid generic advice like "be happy".
- Be supportive and non-clinical; no medical diagnosis.
- If notes are empty or generic, generate 3 general well-being tasks.

OUTPUT FORMAT:
Strictly return a JSON object with a single key "daily_tasks" containing a list of 3 strings.
Example:
{
  "daily_tasks": [
    "Take a 5-minute walk to clear your head",
    "Write down 3 things that went well today",
    "Drink a glass of water and stretch"
  ]
}
'''
        },
        {
          'role': 'user',
          'content':
              'User notes (most recent first). Generate tasks based on what they wrote and how they feel:\n${jsonEncode(notes)}'
        },
      ];

      final response = await _makeRequest(messages);
      final clean = _extractJson(response);
      final data = jsonDecode(clean);

      List<dynamic> rawTasks;
      if (data is Map && data['daily_tasks'] is List) {
        rawTasks = data['daily_tasks'] as List;
      } else if (data is Map && data['tasks'] is List) {
        rawTasks = data['tasks'] as List;
      } else if (data is List) {
        rawTasks = data;
      } else {
        throw const FormatException('Unexpected AI task response format');
      }

      final tasks = rawTasks
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();
      if (tasks.isEmpty) throw const FormatException('No tasks returned');
      return tasks;
    } catch (e) {
      // Fallback if AI fails
      return [
        "Take 3 deep breaths to center yourself",
        "Step outside for fresh air",
        "Write down one positive thought"
      ];
    }
  }

  String _extractJson(String text) {
    final trimmed = text.trim();
    final fence = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    );
    final match = fence.firstMatch(trimmed);
    if (match != null) return match.group(1)!.trim();
    // Fallback: try to find first JSON object/array.
    final objStart = trimmed.indexOf('{');
    final arrStart = trimmed.indexOf('[');
    final startCandidates = [objStart, arrStart].where((i) => i >= 0).toList();
    if (startCandidates.isEmpty) return trimmed;
    final start = startCandidates.reduce((a, b) => a < b ? a : b);
    final endObj = trimmed.lastIndexOf('}');
    final endArr = trimmed.lastIndexOf(']');
    final end = endObj > endArr ? endObj : endArr;
    if (end > start) return trimmed.substring(start, end + 1).trim();
    return trimmed;
  }

  @override
  Future<Map<String, dynamic>> weeklyAnalysis(
    Map<String, dynamic> userData,
  ) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': '''
You are an emotional pattern analyst. Review the user's weekly data and provide insights.

Respond with a JSON object containing:
{
  "summary": "Brief overview of the week",
  "patterns": ["pattern 1", "pattern 2"],
  "recommendations": ["recommendation 1", "recommendation 2"],
  "overallMood": "calm|happy|sad|angry|anxious",
  "progressNotes": "Notes on progress"
}

Only output the JSON object, no other text.
'''
        },
        {
          'role': 'user',
          'content': 'Analyze this weekly data: ${jsonEncode(userData)}'
        },
      ];

      final response = await _makeRequest(messages);
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return {
        'summary': 'Unable to generate analysis at this time.',
        'patterns': [],
        'recommendations': ['Continue journaling regularly'],
        'overallMood': 'calm',
        'progressNotes': '',
      };
    }
  }

  Future<String> _makeRequest(List<Map<String, String>> messages) async {
    // 1. Separate System Prompt from Conversation
    String? systemInstruction;
    final contents = <Map<String, dynamic>>[];

    for (final msg in messages) {
      if (msg['role'] == 'system') {
        systemInstruction = msg['content'];
      } else {
        // Map roles: 'user' -> 'user', 'assistant' -> 'model'
        final role = msg['role'] == 'assistant' ? 'model' : 'user';
        contents.add({
          'role': role,
          'parts': [
            {'text': msg['content']}
          ]
        });
      }
    }

    // 2. Build Request Body
    final body = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1000,
      },
    };

    if (systemInstruction != null) {
      body['system_instruction'] = {
        'parts': [
          {'text': systemInstruction}
        ]
      };
    }

    // 3. Send Request with Query Parameter API Key
    // Note: Gemini Key is passed in URL query param 'key', not Header for generic endpoint usually,
    // but we can try strictly following the endpoint we defined.
    // The endpoint is `...:generateContent`. It usually needs `?key=...`.
    
    final uri = Uri.parse('${ApiConstants.aiApiUrl}?key=${ApiConstants.aiApiKey}');
    
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Response structure: candidates[0].content.parts[0].text
      if (data['candidates'] != null && 
          (data['candidates'] as List).isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null) {
            
        final parts = data['candidates'][0]['content']['parts'] as List;
        if (parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }
      return ''; // Empty if no content
    } else {
      throw AIServiceException(
        message: 'Gemini API request failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
