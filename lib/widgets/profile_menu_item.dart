import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isSpecial; // For export button to make it stand out

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSpecial
          ? const Color(0xFF2a2f4a).withOpacity(0.8) // Slightly different for special
          : const Color(0xFF2a2f4a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}