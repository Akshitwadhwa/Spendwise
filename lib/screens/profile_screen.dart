import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'carpool_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _maskUid(String uid) {
    if (uid.length <= 8) {
      return '*' * uid.length;
    }
    final start = uid.substring(0, 4);
    final end = uid.substring(uid.length - 4);
    final middle = '*' * (uid.length - 8);
    return '$start$middle$end';
  }

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

  Future<void> _showUidDialog({
    required String title,
    required String hintText,
    required String initialValue,
    required Future<void> Function(String? value) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showDialog<void>(
      context: context,
      builder: (context) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1e293b),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
              content: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Color(0xFF64748b)),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF10b981)),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF94a3b8)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() {
                            isSaving = true;
                          });
                          final value = controller.text.trim();
                          await onSave(value.isEmpty ? null : value);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
              StreamBuilder<Map<String, dynamic>>(
                stream: DatabaseService.getCurrentUserSettings(),
                builder: (context, snapshot) {
                  final settings = snapshot.data ?? const <String, dynamic>{};
                  final hideCarpool = settings['hideCarpoolSection'] != false;
                  final carpoolSourceUid =
                      (settings['carpoolSourceUid'] as String?)?.trim() ?? '';
                  final carpoolSharedWithUid =
                      (settings['carpoolSharedWithUid'] as String?)?.trim() ??
                          '';

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeThumbColor: const Color(0xFF10b981),
                          title: const Text(
                            'Hide Carpool Section',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Removes Carpool from Wallet categories',
                            style: TextStyle(color: Colors.grey),
                          ),
                          value: hideCarpool,
                          onChanged: (value) async {
                            await DatabaseService.setCarpoolSectionHidden(
                                value);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF334155)),
                        ListTile(
                          leading: const Icon(
                            Icons.directions_car_outlined,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Open Carpool',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'View your linked carpool ledger',
                            style: TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CarpoolScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFF334155)),
                        ListTile(
                          leading: const Icon(
                            Icons.link_outlined,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Carpool Source UID',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            carpoolSourceUid.isEmpty
                                ? 'Using this account'
                                : carpoolSourceUid,
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _showUidDialog(
                            title: 'Set Carpool Source UID',
                            hintText: 'Paste source account UID',
                            initialValue: carpoolSourceUid,
                            onSave: DatabaseService.setCarpoolSourceUid,
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFF334155)),
                        ListTile(
                          leading: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Share Carpool With UID',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            carpoolSharedWithUid.isEmpty
                                ? 'No account linked'
                                : carpoolSharedWithUid,
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _showUidDialog(
                            title: 'Set Share With UID',
                            hintText: 'Paste allowed reader UID',
                            initialValue: carpoolSharedWithUid,
                            onSave: DatabaseService.setCarpoolSharedWithUid,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.badge_outlined,
                title: 'UID',
                subtitle: _maskUid(user.uid),
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
