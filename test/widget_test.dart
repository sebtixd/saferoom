import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safe_room/domain/entities/daily_task.dart';
import 'package:safe_room/presentation/widgets/task_list_widget.dart';

void main() {
  testWidgets('TaskListWidget renders the daily tasks and their state', (
    WidgetTester tester,
  ) async {
    const tasks = [
      TaskItem(text: 'Drink a glass of water', completed: true),
      TaskItem(text: 'Take a short walk'),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TaskListWidget(tasks: tasks, dailyTaskId: 'daily-1'),
        ),
      ),
    );

    expect(find.text("Today's Focus"), findsOneWidget);
    expect(find.text('Drink a glass of water'), findsOneWidget);
    expect(find.text('Take a short walk'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
