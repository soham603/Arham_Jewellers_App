import 'package:flutter/material.dart';

class ApproveUsersScreen extends StatelessWidget {
  const ApproveUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Approve Users")),
      body: const Center(
        child: Text("Approve Users Screen"),
      ),
    );
  }
}