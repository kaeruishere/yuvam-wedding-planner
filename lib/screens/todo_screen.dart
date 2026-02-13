import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import '../models/task_model.dart';
import '../services/todo_service.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _todoService = TodoService();
  bool? _selectedFilter; // null = all, true = completed, false = pending

  final List<String> _categories = [
    'Venue',
    'Catering',
    'Photography',
    'Music',
    'Decoration',
    'Invitations',
    'Other',
  ];

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();

    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppTexts.addTask),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: AppTexts.taskNameHint,
                    prefixIcon: const Icon(Icons.task),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDueDate == null
                        ? AppTexts.dueDateHint
                        : '${selectedDueDate!.day}.${selectedDueDate!.month}.${selectedDueDate!.year}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDueDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: AppTexts.notesHint,
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppTexts.cancelBtn),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter task title')),
                  );
                  return;
                }

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  useRootNavigator: true,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final newTask = Task(
                  id: '',
                  title: titleController.text,
                  completed: false,
                  dueDate: selectedDueDate,
                  notes: notesController.text,
                  createdAt: DateTime.now(),
                );

                final error = await _todoService.addTask(newTask);

                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop(); // Close loading

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task added successfully!')),
                  );
                }
              },
              child: Text(AppTexts.addBtn),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTexts.todoTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == null,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = null);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == null ? Colors.white : null,
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(AppTexts.taskPending),
                  selected: _selectedFilter == false,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = false);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == false ? Colors.white : null,
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(AppTexts.taskCompleted),
                  selected: _selectedFilter == true,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = true);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == true ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),

          // Tasks list
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _selectedFilter == null
                  ? _todoService.getTasksStream()
                  : _todoService.getTasksByStatus(_selectedFilter!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_outlined,
                          size: 64,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppTexts.noTasks,
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final task = snapshot.data![index];
                    return _buildTaskCard(task, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isDark) {
    final completed = task.completed;
    final title = task.title;
    final dueDate = task.dueDate;
    final taskId = task.id;

    final isOverdue = dueDate != null &&
        dueDate.isBefore(DateTime.now()) &&
        !completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: completed,
        onChanged: (value) async {
          final error = await _todoService.toggleTaskCompletion(
            taskId: taskId,
            completed: value ?? false,
          );

          if (error != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
        },
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: completed ? TextDecoration.lineThrough : null,
            color: completed ? Colors.grey : null,
          ),
        ),
        subtitle: dueDate != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isOverdue ? Colors.red : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dueDate.day}.${dueDate.month}.${dueDate.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey.shade600,
                        fontWeight: isOverdue ? FontWeight.bold : null,
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '(Overdue)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : null,
        secondary: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppTexts.deleteBtn),
                content: Text(AppTexts.deleteTaskConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppTexts.cancelBtn),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text(AppTexts.deleteBtn),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              final error = await _todoService.deleteTask(taskId);

              if (error != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
