import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Mutlaka eklenmeli

void navigateToProfile(BuildContext context, String userId) {
  context.go('/home/profile/$userId');
}
