import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _formatJoinedDate(User user) {
    final joinedAt = user.metadata.creationTime;
    if (joinedAt == null) return '-';
    return DateFormat('dd MMM yyyy').format(joinedAt);
  }

  String _accountTypeLabel(User user) {
    final providerIds =
        user.providerData.map((provider) => provider.providerId).toSet();

    if (providerIds.contains('google.com')) return 'Google Account';
    if (providerIds.contains('password')) return 'Password Account';
    return 'SpendWise Account';
  }

  Future<void> _signOut() async {
    await AuthService.signOut();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0f172a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0f172a),
          elevation: 0,
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text(
            'No user signed in',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'SpendWise User';

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f172a),
        elevation: 0,
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.grey[800],
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white70,
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.email ?? 'No email',
                style: const TextStyle(
                  color: Color(0xFF94a3b8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _accountTypeLabel(user),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              StreamBuilder<int>(
                stream: DatabaseService.getEntryCount(),
                builder: (context, snapshot) {
                  final totalEntries = snapshot.data ?? 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Total Entries', totalEntries.toString()),
                      _buildStatCard('Joined', _formatJoinedDate(user)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                icon: Icons.badge_outlined,
                title: 'UID',
                subtitle: user.uid,
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Log out from this device',
                isDestructive: true,
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isDestructive
          ? null
          : const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
    );
  }
}
