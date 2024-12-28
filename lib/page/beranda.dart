import 'package:flutter/material.dart';
import 'package:rental_app/page/admin.dart';
import 'package:rental_app/page/user.dart';

class HomePage extends StatelessWidget {
  final String role;
  final String name;

  const HomePage({
    super.key,
    required this.role,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminPage(name: name, role: role),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserPage(name: name),
          ),
        );
      }
    });

    // Placeholder UI while navigation happens
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $name'),
      ),
      body: const Center(
        child: CircularProgressIndicator(), // Loading indicator
      ),
    );
  }
}
