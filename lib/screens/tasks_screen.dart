import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import '../models/task_model.dart';
import '../services/todo_service.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _todoService = TodoService();

  // Filters: null = all, false = pending, true = completed
  bool? _selectedTaskFilter = false; // Default to pending 

  // --- ADD TASK DIALOG ---
  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppTexts.addTask, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Task Name
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: AppTexts.taskNameHint, 
                    prefixIcon: const Icon(Icons.check_circle_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: AppTexts.notesHint, 
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Date Picker
                InkWell(
                  onTap: () async {
                    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: languageProvider.currentLocale,
                    );
                    if (date != null) setDialogState(() => selectedDueDate = date);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Text(
                          selectedDueDate == null 
                              ? AppTexts.dueDateHint 
                              : DateFormat('dd.MM.yyyy').format(selectedDueDate!),
                          style: TextStyle(
                            color: selectedDueDate == null ? Colors.grey.shade600 : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const Spacer(),
                        if (selectedDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setDialogState(() => selectedDueDate = null),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text(AppTexts.cancelBtn, style: TextStyle(color: Colors.grey.shade600))
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen görev adı giriniz')));
                  return;
                }
                
                showDialog(context: context, barrierDismissible: false, useRootNavigator: true, builder: (c) => const Center(child: CircularProgressIndicator()));
                
                final newTask = Task(
                  id: '', // Firestore generates
                  title: titleController.text.trim(),
                  notes: notesController.text.trim(),
                  dueDate: selectedDueDate,
                  completed: false,
                  createdAt: DateTime.now(),
                );

                final error = await _todoService.addTask(newTask);

                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop(); // Close loading

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                } else {
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görev eklendi!')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
        title: Text(AppTexts.tasksTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // Full Width Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterButton('Tümü', null, isDark),
                const SizedBox(width: 8),
                _buildFilterButton(AppTexts.taskPending, false, isDark),
                const SizedBox(width: 8),
                _buildFilterButton(AppTexts.taskCompleted, true, isDark),
              ],
            ),
          ),
          
          // Tasks list
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _selectedTaskFilter == null ? _todoService.getTasksStream() : _todoService.getTasksByStatus(_selectedTaskFilter!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.withOpacity(0.3)), 
                        const SizedBox(height: 16), 
                        Text(AppTexts.noTasks, style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 16), textAlign: TextAlign.center)
                      ]
                    )
                  );
                }

                // Client-side sorting
                // Sort by Due Date ASC. Null dates last.
                final tasks = snapshot.data!;
                tasks.sort((a, b) {
                  final da = a.dueDate;
                  final db = b.dueDate;
                  
                  if (da == null && db == null) return 0;
                  if (da == null) return 1; // nulls last
                  if (db == null) return -1;
                  
                  return da.compareTo(db);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => _buildTaskCard(tasks[index], isDark),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: Text(AppTexts.addTask),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterButton(String label, bool? filterValue, bool isDark) {
    final isSelected = _selectedTaskFilter == filterValue;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTaskFilter = filterValue),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isDark) {
    final completed = task.completed;
    final title = task.title;
    final notes = task.notes;
    final dueDate = task.dueDate;

    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now()) && !completed;
    final isDueSoon = dueDate != null && !isOverdue && dueDate.difference(DateTime.now()).inDays <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: completed 
          ? (isDark ? Colors.green.withOpacity(0.05) : Colors.green.shade50) 
          : (isDark ? const Color(0xFF1E293B) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: completed 
              ? Colors.green.withOpacity(0.2) 
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
        ),
      ),
      child: InkWell(
        onDoubleTap: () async {
            // Delete confirmation
             final confirm = await showDialog<bool>(
               context: context, 
               builder: (context) => AlertDialog(
                 title: Text(AppTexts.deleteBtn), 
                 content: Text(AppTexts.deleteTaskConfirm), 
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppTexts.cancelBtn)), 
                   ElevatedButton(
                     onPressed: () => Navigator.pop(context, true), 
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), 
                     child: Text(AppTexts.deleteBtn)
                   )
                 ]
               )
             );
             if (confirm == true) {
               // Show loading
               showDialog(
                 context: context,
                 barrierDismissible: false,
                 builder: (c) => const Center(child: CircularProgressIndicator()),
               );

               final error = await _todoService.deleteTask(task.id);

               if (context.mounted) {
                 Navigator.pop(context); // Close loading
                 if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                 } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Görev silindi")));
                 }
               }
             }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
               Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: completed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  activeColor: Colors.green,
                  onChanged: (value) async {
                    await _todoService.toggleTaskCompletion(taskId: task.id, completed: value ?? false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        decoration: completed ? TextDecoration.lineThrough : null,
                        color: completed ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    
                    if (notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        notes ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],

                    if (dueDate != null) ...[
                       const SizedBox(height: 8),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: isOverdue 
                               ? Colors.red.withOpacity(0.1) 
                               : (isDueSoon ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Icon(
                               Icons.calendar_today, 
                               size: 12, 
                               color: isOverdue ? Colors.red : (isDueSoon ? Colors.orange : Colors.grey.shade600)
                             ),
                             const SizedBox(width: 4),
                             Text(
                               DateFormat('dd.MM.yyyy').format(dueDate),
                               style: TextStyle(
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold,
                                 color: isOverdue ? Colors.red : (isDueSoon ? Colors.orange : Colors.grey.shade600)
                               ),
                             ),
                             if (isOverdue) ...[
                               const SizedBox(width: 4),
                               const Text('!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                             ]
                           ],
                         ),
                       ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
