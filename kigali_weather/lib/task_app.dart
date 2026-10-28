import 'package:flutter/material.dart';

import 'core/services.dart';
import 'core/theme.dart';
import 'features/tasks/presentation/task_controller.dart';
import 'features/tasks/presentation/task_screen.dart';

class TaskApp extends StatefulWidget {
  const TaskApp({super.key});
  @override
  State<TaskApp> createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  final services = AppServices();
  late final tasks = TaskController(services.tasks);
  @override
  void initState() {
    super.initState();
    tasks.load();
    services.weather.start();
  }

  @override
  void dispose() {
    tasks.dispose();
    services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Daybook',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: TaskScreen(controller: tasks, weather: services.weather),
  );
}
