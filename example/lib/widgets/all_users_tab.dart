import 'package:flutter/material.dart';
import 'package:kiss_repository/kiss_repository.dart';

import '../widgets/add_user_form.dart';
import '../widgets/user_list_widget.dart';
import '../models/user.dart';

class AllUsersTab extends StatelessWidget {
  final Repository<User> userRepository;
  const AllUsersTab({super.key, required this.userRepository});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AddUserForm(userRepository: userRepository),
        Expanded(child: UserListWidget(userRepository: userRepository)),
      ],
    );
  }
}
