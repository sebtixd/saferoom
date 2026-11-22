import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/exceptions.dart' as app_exceptions;
import '../../core/errors/failures.dart';
import '../../core/utils/task_generator.dart';
import '../../domain/entities/daily_task.dart';
import '../../domain/repositories/journal_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/notes_storage.dart';
import '../datasources/remote/ai_service.dart';
import '../datasources/remote/task_api_service.dart';
import '../models/daily_task_model.dart';

/// Daily tasks are generated with AI but persisted in the local SQLite API,
/// not Cloud Firestore.
class TaskRepositoryImpl implements TaskRepository {
  final TaskApiService _api;
  final UserRepository _userRepository;
  final JournalRepository _journalRepository;
  final AIService _aiService;
  final NotesStorage _notesStorage;

  TaskRepositoryImpl(
    this._api,
    this._userRepository,
    this._journalRepository,
    this._aiService,
    this._notesStorage,
  );

  @override
  Future<Either<Failure, DailyTask>> getTodaysTasks(String userId) async {
    try {
      final existing = await _api.getDailyTasks(
        userId: userId,
        date: DateTime.now(),
      );
      if (existing != null) {
        return Right(existing);
      }
    } on app_exceptions.AppException catch (e) {
      return Left(_toFailure(e));
    }
    return generateDailyTasks(userId);
  }

  @override
  Future<Either<Failure, DailyTask>> generateDailyTasks(String userId) async {
    try {
      final notes = await _collectNotes(userId);
      debugPrint('TaskRepo: Generating tasks with context of ${notes.length} notes...');

      List<String> taskStrings;
      try {
        taskStrings = await _aiService.generatePersonalizedTasks(notes);
        if (taskStrings.isEmpty) throw Exception('Empty AI task list');
      } catch (e) {
        debugPrint('TaskRepo: AI task generation failed, using fallback: $e');
        taskStrings = _fallbackTasks(userId);
      }

      final tasks = taskStrings
          .where((t) => t.trim().isNotEmpty)
          .take(3)
          .map((text) => TaskItemModel(text: text.trim(), completed: false))
          .toList();
      while (tasks.length < 3) {
        final fallback = _fallbackTasks(userId);
        for (final text in fallback) {
          if (tasks.length >= 3) break;
          if (!tasks.any((t) => t.text == text)) {
            tasks.add(TaskItemModel(text: text, completed: false));
          }
        }
        if (tasks.length < 3) {
          tasks.add(const TaskItemModel(text: 'Take a mindful pause and breathe', completed: false));
        }
      }

      final now = DateTime.now();
      final todayStr = now.toIso8601String().substring(0, 10);
      final dailyTask = DailyTaskModel(
        id: const Uuid().v4(),
        userId: userId,
        date: DateTime.parse(todayStr),
        tasks: tasks,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await _api.saveDailyTasks(dailyTask);
      return Right(saved);
    } on app_exceptions.AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<List<String>> _collectNotes(String userId) async {
    final notes = <String>[];

    // Notebook pages are the primary "what user wrote / feels" source.
    try {
      final pages = await _notesStorage.loadPages(userId);
      for (final page in pages.reversed.take(10)) {
        final content = page.content.trim();
        if (content.isNotEmpty) notes.add(content);
      }
    } catch (e) {
      debugPrint('TaskRepo: Failed to read notebook pages: $e');
    }

    // Also include journal entries if available.
    try {
      final notesResult = await _journalRepository.getEntries(userId);
      notesResult.fold(
        (failure) => debugPrint('TaskRepo: Failed to fetch journal notes: ${failure.message}'),
        (entries) {
          for (final entry in entries.take(10)) {
            final content = entry.content.trim();
            if (content.isNotEmpty) notes.add(content);
          }
        },
      );
    } catch (e) {
      debugPrint('TaskRepo: Failed to read journal entries: $e');
    }

    // Deduplicate while preserving order.
    final seen = <String>{};
    return notes.where((n) => seen.add(n)).take(15).toList(growable: false);
  }

  List<String> _fallbackTasks(String userId) {
    // Best-effort profile-aware fallback; defaults if profile unavailable.
    // TaskGenerator handles null profile safely.
    try {
      // Avoid async in fallback; return general tasks synchronously.
      return TaskGenerator.generate(null).map((t) => t.text).toList();
    } catch (_) {
      return const [
        'Take 5 deep breaths and notice how you feel',
        'Write one sentence about what is on your mind',
        'Drink water and take a short stretch break',
      ];
    }
  }

  @override
  Future<Either<Failure, void>> toggleTaskCompletion(
    String taskId,
    int taskIndex,
    bool completed,
  ) async {
    try {
      final dailyTaskModel = await _api.getDailyTaskById(taskId);
      if (taskIndex < 0 || taskIndex >= dailyTaskModel.tasks.length) {
        return const Left(ServerFailure(message: 'Invalid task index'));
      }

      final updatedTasks = List<TaskItem>.from(dailyTaskModel.tasks);
      updatedTasks[taskIndex] = updatedTasks[taskIndex].copyWith(completed: completed);
      final updated = dailyTaskModel.copyWith(
        tasks: updatedTasks,
        updatedAt: DateTime.now(),
      );

      final saveResult = await updateDailyTask(updated);
      return await saveResult.fold(
        (failure) async => Left(failure),
        (_) async {
          if (completed) {
            await _awardPoints(dailyTaskModel.userId);
          }
          return const Right(null);
        },
      );
    } on app_exceptions.AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyTask>> updateDailyTask(DailyTask dailyTask) async {
    try {
      return Right(await _api.updateDailyTasks(dailyTask));
    } on app_exceptions.AppException catch (e) {
      return Left(_toFailure(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<void> _awardPoints(String userId) async {
    try {
      final userResult = await _userRepository.getUserById(userId);
      await userResult.fold(
        (_) async => null,
        (user) async {
          final updatedUser = user.copyWith(points: user.points + 10);
          await _userRepository.updateUser(updatedUser);
          debugPrint('TaskRepo: Added 10 points to user ${user.id}.');
        },
      );
    } catch (e) {
      debugPrint('TaskRepo: Failed to update points: $e');
    }
  }

  Failure _toFailure(app_exceptions.AppException exception) {
    if (exception is app_exceptions.NetworkException) {
      return NetworkFailure(message: exception.message, code: exception.code);
    }
    if (exception is app_exceptions.ValidationException) {
      return ValidationFailure(message: exception.message, code: exception.code);
    }
    if (exception is app_exceptions.AuthException) {
      return AuthFailure(message: exception.message, code: exception.code);
    }
    return ServerFailure(message: exception.message, code: exception.code);
  }
}
