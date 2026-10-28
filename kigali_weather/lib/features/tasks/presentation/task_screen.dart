import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../weather/domain/weather.dart';
import '../../weather/presentation/weather_controller.dart';
import '../../weather/presentation/weather_screen.dart';
import '../domain/task.dart';
import 'task_controller.dart';
import 'task_editor.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({
    super.key,
    required this.controller,
    required this.weather,
  });
  final TaskController controller;
  final WeatherController weather;
  void _edit(BuildContext context, [Task? task]) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => TaskEditor(controller: controller, task: task),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final done = controller.tasks.where((t) => t.done).length;
      final total = controller.tasks.length;
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(CupertinoIcons.square_pencil, size: 22),
              SizedBox(width: 9),
              Text(
                'daybook',
                style: TextStyle(
                  fontSize: 20,
                  letterSpacing: -.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'About Daybook',
              icon: const Icon(CupertinoIcons.info_circle, size: 22),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Your space to get things done.'),
                  content: const Text(
                    'Tasks, notes, priorities and dates are saved on this device using SQLite. Your most recent deletion can be undone, even after reopening.\n\nWeather is provided by Open-Meteo under CC BY 4.0. This app does not sync across devices.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: controller.loading || controller.busy
              ? null
              : () => _edit(context),
          backgroundColor: ink,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(CupertinoIcons.plus, size: 20),
          label: const Text('New task'),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await controller.load();
              await weather.load();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                Text(
                  '${const ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'][DateTime.now().weekday - 1]}  /  ${shortDate(DateTime.now()).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: muted,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A clearer day.',
                  style: TextStyle(
                    fontSize: 36,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A little focus. A little room to think.',
                  style: TextStyle(fontSize: 15, color: muted),
                ),
                const SizedBox(height: 26),
                _WeatherBrief(weather: weather),
                const SizedBox(height: 20),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: SectionLabel(
                              'Your progress',
                              CupertinoIcons.chart_bar,
                            ),
                          ),
                          Text(
                            '$done / $total',
                            style: const TextStyle(fontSize: 13, color: muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        total == 0
                            ? 'A fresh page.'
                            : done == total
                            ? 'Everything, taken care of.'
                            : '${total - done} ${total - done == 1 ? 'thing' : 'things'} to make space for.',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 5,
                          backgroundColor: blueWash,
                          color: accent,
                          semanticsLabel: '$done of $total tasks completed',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                TextField(
                  onChanged: controller.search,
                  decoration: const InputDecoration(
                    hintText: 'Find a task or note',
                    prefixIcon: Icon(CupertinoIcons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TaskFilter.values
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(switch (filter) {
                                TaskFilter.all => 'All tasks',
                                TaskFilter.today => 'Today',
                                TaskFilter.upcoming => 'Upcoming',
                                TaskFilter.completed => 'Done',
                              }),
                              selected: controller.filter == filter,
                              showCheckmark: false,
                              selectedColor: ink,
                              labelStyle: TextStyle(
                                color: controller.filter == filter
                                    ? Colors.white
                                    : muted,
                              ),
                              side: BorderSide(
                                color: controller.filter == filter ? ink : line,
                              ),
                              shape: const StadiumBorder(),
                              onSelected: (_) => controller.setFilter(filter),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (controller.filter == TaskFilter.today)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Due today, including anything overdue.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                if (controller.error != null)
                  Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(controller.error!),
                        TextButton(
                          onPressed: controller.load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                if (controller.loading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: CupertinoActivityIndicator(),
                  ),
                if (!controller.loading && controller.visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.tray,
                          size: 36,
                          color: accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.query.isNotEmpty
                              ? 'No matching tasks.'
                              : 'A little breathing room.',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.query.isNotEmpty
                              ? 'Try another word.'
                              : 'Add a task, or explore another view.',
                          style: const TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                if (!controller.loading)
                  ...controller.visible.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TaskTile(
                        task: task,
                        busy: controller.busy,
                        onEdit: () => _edit(context, task),
                        onToggle: () =>
                            controller.save(task.copyWith(done: !task.done)),
                        onDelete: () async {
                          final saved = await controller.delete(task);
                          if (!context.mounted || !saved) return;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Task deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: controller.undo,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (controller.canUndo)
                  TextButton.icon(
                    onPressed: controller.busy ? null : controller.undo,
                    icon: const Icon(CupertinoIcons.arrow_uturn_left, size: 16),
                    label: const Text('Undo last deletion'),
                  ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'YOURS, ONE TASK AT A TIME',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.busy,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  final Task task;
  final bool busy;
  final VoidCallback onEdit, onToggle, onDelete;
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: task.done ? 'Mark incomplete' : 'Complete task',
          onPressed: busy ? null : onToggle,
          icon: Icon(
            task.done
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.circle,
            color: task.done ? accent : muted,
            size: 24,
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: busy ? null : onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      decoration: task.done ? TextDecoration.lineThrough : null,
                      color: task.done ? muted : ink,
                    ),
                  ),
                  if (task.notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        task.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: muted,
                        ),
                      ),
                    ),
                  if (task.due != null || task.priority > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (task.due != null)
                            Text(
                              shortDate(task.due!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: accent,
                              ),
                            ),
                          if (task.priority > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.flag_fill,
                                  size: 11,
                                  color: accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.priority == 2
                                      ? 'High priority'
                                      : 'Important',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Task actions',
          enabled: !busy,
          icon: const Icon(CupertinoIcons.ellipsis, size: 19),
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit task')),
            const PopupMenuItem(value: 'delete', child: Text('Delete task')),
          ],
        ),
      ],
    ),
  );
}

class _WeatherBrief extends StatelessWidget {
  const _WeatherBrief({required this.weather});
  final WeatherController weather;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: weather,
    builder: (context, _) => Surface(
      color: blueWash,
      child: weather.loading
          ? const Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 14),
                Text('A look outside…'),
              ],
            )
          : weather.weather == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather is unavailable.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check your connection and try again.',
                  style: TextStyle(fontSize: 13, color: muted),
                ),
                TextButton(
                  onPressed: weather.load,
                  child: const Text('Retry weather'),
                ),
              ],
            )
          : InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      WeatherScreen(controller: weather, canPop: true),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    weatherIcon(weather.weather!.code),
                    color: accent,
                    size: 34,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.city.name} · ${weather.weather!.temperature.round()}°',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weather.offline
                              ? 'Offline · saved ${weather.weather!.observedDate} ${weather.weather!.clock}'
                              : describe(weather.weather!.code),
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: accent,
                  ),
                ],
              ),
            ),
    ),
  );
}
