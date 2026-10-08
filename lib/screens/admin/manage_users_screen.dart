import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retro_vibes/model/user_model.dart';
import 'package:retro_vibes/provider/auth_provider.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLoggedInUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/icons/retro_vibes_icon.png',
              width: 26,
              height: 26,
              errorBuilder: (c, e, s) => Icon(Icons.people, color: AppTheme.primaryAccent, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'REGISTERED USERS & ROLES',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFC85A32)));
          }

          final docs = snapshot.data?.docs ?? [];
          final usersList = docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();

          if (usersList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, color: AppTheme.white38, size: 48),
                  const SizedBox(height: 12),
                  Text('No registered users found in Firestore', style: TextStyle(color: AppTheme.white38, fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: usersList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = usersList[index];
              final isSelf = user.uid == currentLoggedInUser?.uid || user.email == currentLoggedInUser?.email;

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelf ? AppTheme.primaryAccent : Colors.white12,
                    width: isSelf ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: user.isAdmin ? const Color(0xFFFFD700) : AppTheme.primaryAccent,
                    radius: 20,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name.isNotEmpty ? user.name : 'Retro Listener',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'YOU',
                            style: TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${user.email} • ID: ${user.uid}',
                      style: TextStyle(color: AppTheme.white38, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: user.isAdmin
                          ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                          : AppTheme.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: user.isAdmin ? const Color(0xFFFFD700) : AppTheme.primaryAccent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      user.isAdmin ? 'ADMIN' : 'USER',
                      style: TextStyle(
                        color: user.isAdmin ? const Color(0xFFFFD700) : AppTheme.primaryAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
