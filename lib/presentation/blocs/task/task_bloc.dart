import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/usecases/task/get_todays_tasks_usecase.dart';
import '../../../../domain/usecases/task/toggle_task_completion_usecase.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart';
import '../../../../domain/entities/daily_task.dart';
import 'task_event.dart';
import 'task_state.dart';

import 'dart:async'; // Add async import

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTodaysTasksUseCase getTodaysTasks;
  final ToggleTaskCompletionUseCase toggleTaskCompletion;
  final AuthBloc authBloc;
  late StreamSubscription _authSubscription;

  TaskBloc({
    required this.getTodaysTasks,
    required this.toggleTaskCompletion,
    required this.authBloc,
  }) : super(TaskInitial()) {
    on<LoadDailyTasks>(_onLoadDailyTasks);
    on<ToggleTaskCompletion>(_onToggleTaskCompletion);
    
    // Listen to AuthBloc stream to handle authentication changes
    _authSubscription = authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        add(const LoadDailyTasks());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }

  Future<void> _onLoadDailyTasks(
    LoadDailyTasks event,
    Emitter<TaskState> emit,
  ) async {
    final authState = authBloc.state;
    if (authState is AuthAuthenticated) {
      debugPrint('TaskBloc: User is authenticated: ${authState.user.id}. Loading tasks...');
      emit(TaskLoading());
      final result = await getTodaysTasks(authState.user.id);
      result.fold(
        (failure) {
          debugPrint('TaskBloc: Failed to load tasks: ${failure.message}');
          emit(TaskError(failure.message));
        },
        (dailyTask) {
          debugPrint('TaskBloc: Talk loaded successfully. Task count: ${dailyTask.tasks.length}');
          emit(TaskLoaded(dailyTask));
        },
      );
    } else {
      debugPrint('TaskBloc: User NOT authenticated. Current AuthState: $authState');
      emit(const TaskError('User not authenticated'));
    }
  }

  Future<void> _onToggleTaskCompletion(
    ToggleTaskCompletion event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;
    if (currentState is TaskLoaded) {
      // Optimistic update
      final currentTasks = List<TaskItem>.from(currentState.dailyTask.tasks);
      final task = currentTasks[event.taskIndex];
      final previousState = task.completed;
      
      // Update locally immediately
      currentTasks[event.taskIndex] = task.copyWith(completed: event.completed);
      final updatedDailyTask = currentState.dailyTask.copyWith(tasks: currentTasks);
      
      emit(TaskLoaded(updatedDailyTask));
      
      // Perform actual API call
      final result = await toggleTaskCompletion(
        taskId: event.taskId,
        taskIndex: event.taskIndex,
        completed: event.completed,
      );
      
      // Revert if failed
      result.fold(
        (failure) {
          // Revert changes
          currentTasks[event.taskIndex] = task.copyWith(completed: previousState);
          emit(TaskLoaded(currentState.dailyTask.copyWith(tasks: currentTasks)));
          emit(TaskError(failure.message)); // Show error (e.g. snackbar listener)
          // Re-emit loaded state to clear error? Ideally we use distinct error stream or
          // keep the loaded state but show error. Simplified here.
        },
        (_) {}, // Success, already optimistic
      );
    }
  }
}
