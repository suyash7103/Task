import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _filterPriority = 'all';
  bool? _filterCompleted;
  DateTimeRange? _dateRange;

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _auth.currentUser!.uid);
    
    if (_filterPriority != 'all') {
      query = query.where('priority', isEqualTo: _filterPriority);
    }
    
    if (_filterCompleted != null) {
      query = query.where('isCompleted', isEqualTo: _filterCompleted);
    }
    
    return query;
  }

  List<Task> _filterTasks(List<Task> tasks) {
    return tasks.where((task) {
      if (_dateRange != null) {
        final taskDate = task.dueDate.toDate();
        if (taskDate.isBefore(_dateRange!.start) || 
            taskDate.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Widget _buildTaskCard(Task task) {
    final Color priorityColor = switch(task.priority) {
      'low' => Colors.green,
      'medium' => Colors.orange,
      'high' => Colors.red,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 1.2,
                    child: Switch.adaptive(
                      value: task.isCompleted,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        _firestore.collection('tasks').doc(task.id).update({
                          'isCompleted': value
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(task.dueDate.toDate()),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.flag, size: 16, color: priorityColor),
                  const SizedBox(width: 4),
                  Text(
                    task.priority.substring(0, 1).toUpperCase() + task.priority.substring(1),
                    style: TextStyle(color: priorityColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No tasks available",
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TaskDetailScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Add New Task"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => StatefulBuilder(
                  builder: (context, setModalState) {
                    return Container(
                      padding: EdgeInsets.fromLTRB(
                        16, 16, 16,
                        MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Filters',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                            value: _filterPriority,
                            items: ['all', 'low', 'medium', 'high']
                                .map((priority) => DropdownMenuItem(
                                      value: priority,
                                      child: Text(priority.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setModalState(() => _filterPriority = value!);
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<bool?>(
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.check_circle_outline),
                            ),
                            value: _filterCompleted,
                            items: [
                              const DropdownMenuItem(value: null, child: Text("All")),
                              const DropdownMenuItem(value: true, child: Text("Completed")),
                              const DropdownMenuItem(value: false, child: Text("Incomplete")),
                            ],
                            onChanged: (value) {
                              setModalState(() => _filterCompleted = value);
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.date_range),
                            title: Text(
                              _dateRange == null 
                                ? 'Select Date Range'
                                : '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}',
                            ),
                            trailing: _dateRange != null 
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setModalState(() => _dateRange = null);
                                    setState(() {});
                                  },
                                )
                              : null,
                            onTap: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                currentDate: DateTime.now(),
                              );
                              if (range != null) {
                                setModalState(() => _dateRange = range);
                                setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    _filterPriority = 'all';
                                    _filterCompleted = null;
                                    _dateRange = null;
                                  });
                                  setState(() {});
                                },
                                child: const Text('Reset'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var tasks = snapshot.data!.docs
              .map((doc) => Task.fromFirestore(doc))
              .toList();
          
          tasks = _filterTasks(tasks);

          if (tasks.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tasks.length,
            itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}