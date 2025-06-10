import 'package:flutter/material.dart';

class AuthDialog extends StatefulWidget {
  final String email;
  final String password;
  const AuthDialog({super.key, required this.email, required this.password});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    _passwordController.text = widget.password;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Authentication'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, {
          'email': _emailController.text,
          'password': _passwordController.text,
        }), child: const Text('Login')),
      ],
    );
  }
}