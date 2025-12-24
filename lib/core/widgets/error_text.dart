import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ErrorText extends StatelessWidget {
  final String message;
  
  const ErrorText({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}