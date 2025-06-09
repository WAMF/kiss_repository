import 'package:flutter/material.dart';
import '../repositories/repository_type.dart';

class RepositorySelector extends StatelessWidget {
  final RepositoryType selectedType;
  final Function(RepositoryType) onChanged;
  final bool isLoading;

  const RepositorySelector({super.key, required this.selectedType, required this.onChanged, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Repository:', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        if (isLoading)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        else
          DropdownButton<RepositoryType>(
            value: selectedType,
            underline: Container(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
            onChanged: (type) {
              if (type != null) {
                onChanged(type);
              }
            },
            items: RepositoryType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.displayName,
                      style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
