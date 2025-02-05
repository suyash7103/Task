import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../widgets/priority_dropdown.dart';

class TaskDetailScreen extends StatefulWidget {
  final String? taskId;
  TaskDetailScreen({this.taskId});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedPriority = 'low';
  bool _isLoading = false;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      _loadTaskDetails();
    } else {
      _selectedDate = DateTime.now();
      _dueDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }
  }

  Future<void> _loadTaskDetails() async {
    setState(() => _isLoading = true);
    try {
      final taskSnapshot = await _firestore.collection('tasks').doc(widget.taskId).get();
      if (taskSnapshot.exists) {
        final task = Task.fromFirestore(taskSnapshot);
        _titleController.text = task.title;
        _descriptionController.text = task.description;
        _selectedDate = task.dueDate.toDate();
        _dueDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        _selectedPriority = task.priority;
      }
    } catch (e) {
      _showErrorSnackBar('Error loading task details');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final taskData = {
        'userId': _auth.currentUser!.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isCompleted': false,
        'dueDate': Timestamp.fromDate(_selectedDate!),
        'priority': _selectedPriority,
        'createdAt': widget.taskId == null ? Timestamp.now() : FieldValue.serverTimestamp(),
      };

      if (widget.taskId == null) {
        await _firestore.collection('tasks').add(taskData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
        }
      } else {
        await _firestore.collection('tasks').doc(widget.taskId).update(taskData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error saving task');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask() async {
    if (widget.taskId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('tasks').doc(widget.taskId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting task');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.taskId == null ? 'New Task' : 'Edit Task'),
        actions: [
          if (widget.taskId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteTask,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter task title',
                          prefixIcon: Icon(Icons.title),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter task description',
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                        ),
                        maxLines: 3,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dueDateController,
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                              _dueDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a due date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      PriorityDropdown(
                        value: _selectedPriority,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPriority = value);
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveTask,
                        icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.save),
                        label: Text(widget.taskId == null ? 'Create Task' : 'Update Task'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }
}