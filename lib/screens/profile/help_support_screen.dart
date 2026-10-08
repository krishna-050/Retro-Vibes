import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _submitSupportTicket(BuildContext context, String issue) async {
    if (issue.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your problem before submitting.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final ticketId = 'ticket_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await FirebaseFirestore.instance.collection('support_tickets').doc(ticketId).set({
        'ticketId': ticketId,
        'userId': user?.uid ?? 'guest_user',
        'userEmail': user?.email ?? 'anonymous@retrovibes.com',
        'issueDescription': issue.trim(),
        'status': 'open',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                const SizedBox(width: 8),
                Text('Ticket Submitted', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Your support request ($ticketId) has been recorded in Cloud Firestore. Our team will review your report shortly!',
              style: TextStyle(color: AppTheme.white70, fontSize: 13),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showReportProblemDialog(BuildContext context) {
    final TextEditingController problemController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Report a Problem', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Describe the issue you encountered in Retro Vibes:', style: TextStyle(color: AppTheme.white38, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: problemController,
                    maxLines: 4,
                    style: TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      hintText: 'e.g., Audio buffering, playlist issue...',
                      hintStyle: TextStyle(color: AppTheme.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.white38)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final text = problemController.text.trim();
                          if (text.isEmpty) return;

                          setDialogState(() => isSubmitting = true);
                          Navigator.pop(ctx);
                          await _submitSupportTicket(context, text);
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    const supportEmail = 'support@retrovibes.com';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: AppTheme.primaryAccent, size: 24),
            const SizedBox(width: 8),
            Text('Contact Support', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need direct help with your Retro Vibes account?', style: TextStyle(color: AppTheme.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(supportEmail, style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  IconButton(
                    icon: Icon(Icons.copy, color: AppTheme.primaryAccent, size: 18),
                    tooltip: 'Copy Email',
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: supportEmail));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support email copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double mediaWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.white, size: mediaWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help & Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),

          _buildFaqItem(
            question: 'How do I download songs for offline listening?',
            answer: 'With Retro Vibes Premium, you can tap the download icon next to any song or playlist to listen offline without internet.',
          ),
          _buildFaqItem(
            question: 'How do I unlock the Spider-Man theme?',
            answer: 'Go to Profile > Appearance > Theme Selection and tap "Spider-Man Dark Red". You can also tap the Retro Vibes logo twice on the Home screen for the Snake game Easter egg!',
          ),
          _buildFaqItem(
            question: 'How does background playback work?',
            answer: 'Retro Vibes uses Android AudioService to maintain seamless background playback and lock-screen notification controls when you minimize the app.',
          ),
          _buildFaqItem(
            question: 'Can I link my Google account to my Guest profile?',
            answer: 'Yes! Go to Profile > Connected Accounts and tap "Connect" next to Google Sign-In to secure your guest data.',
          ),

          const SizedBox(height: 24),
          Text('CONTACT & FEEDBACK', style: TextStyle(color: AppTheme.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: ListTile(
              leading: Icon(Icons.report_problem_outlined, color: AppTheme.primaryAccent),
              title: Text('Report a Problem', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Send bug reports or technical feedback', style: TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.white38, size: 16),
              onTap: () => _showReportProblemDialog(context),
            ),
          ),

          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: ListTile(
              leading: Icon(Icons.email_outlined, color: AppTheme.primaryAccent),
              title: Text('Contact Support Team', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Get in touch with our support team', style: TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.white38, size: 16),
              onTap: () => _showContactSupportDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        iconColor: AppTheme.primaryAccent,
        collapsedIconColor: AppTheme.white38,
        title: Text(question, style: TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: TextStyle(color: AppTheme.white70, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
