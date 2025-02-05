import 'package:flutter/material.dart';

class PriorityDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool showAllOption;

  const PriorityDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    this.showAllOption = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = ['low', 'medium', 'high'];
    if (showAllOption) {
      items.insert(0, 'all');
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Priority',
        prefixIcon: Icon(Icons.flag_outlined),
      ),
      value: value,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a priority';
        }
        return null;
      },
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: value == 'all'
                    ? Colors.grey
                    : value == 'low'
                        ? Colors.green
                        : value == 'medium'
                            ? Colors.orange
                            : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                value.substring(0, 1).toUpperCase() + value.substring(1),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}