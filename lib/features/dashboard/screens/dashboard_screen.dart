import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../authentication/repositories/auth_repositories.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AuthRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),

      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await repository.logout();
          },
          child: const Text(
            "Logout",
          ),
        ),
      ),
    );
  }
}