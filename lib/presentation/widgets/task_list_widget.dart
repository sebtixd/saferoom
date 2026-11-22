import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/daily_task.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/task/task_event.dart';

class TaskListWidget extends StatelessWidget {
  final List<TaskItem> tasks;
  final String dailyTaskId;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.dailyTaskId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: Colors.orange[300], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Today\'s Focus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  context.read<TaskBloc>().add(
                    ToggleTaskCompletion(
                      taskId: dailyTaskId,
                      taskIndex: index,
                      completed: !task.completed,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: task.completed 
                            ? const Color(0xFF6B5CE7) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: task.completed 
                              ? const Color(0xFF6B5CE7) 
                              : Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: task.completed
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.text,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: task.completed ? 0.5 : 0.9),
                          fontSize: 14,
                          decoration: task.completed 
                              ? TextDecoration.lineThrough 
                              : null,
                          decorationColor: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
