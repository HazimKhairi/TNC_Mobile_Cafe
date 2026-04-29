import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/firestore_service.dart';
import '../sales/sales_report_screen.dart';
import 'admin_menu_screen.dart';
import 'payment_verification_screen.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Admin Panel',
                    style: GoogleFonts.spectral(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Payment Verification card with live pending count
              Consumer<OrderProvider>(
                builder: (context, provider, _) {
                  final pendingCount = provider.pendingVerificationCount;
                  return _AdminCard(
                    icon: Icons.verified_user_rounded,
                    iconColor: AppColors.error,
                    iconBgColor:
                        AppColors.error.withValues(alpha: 0.1),
                    title: 'Payment Verification',
                    subtitle: pendingCount == 0
                        ? 'No pending receipts'
                        : '$pendingCount receipt${pendingCount == 1 ? '' : 's'} awaiting review',
                    badgeCount: pendingCount,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PaymentVerificationScreen(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Admin Feature Cards
              _AdminCard(
                icon: Icons.bar_chart_rounded,
                iconColor: AppColors.accentBlue,
                iconBgColor: AppColors.accentBlue.withValues(alpha: 0.1),
                title: 'Sales Report',
                subtitle: 'View revenue, orders & analytics',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SalesReportScreen()),
                ),
              ),

              const SizedBox(height: 14),

              _AdminCard(
                icon: Icons.restaurant_menu_rounded,
                iconColor: AppColors.success,
                iconBgColor: AppColors.success.withValues(alpha: 0.1),
                title: 'Menu Management',
                subtitle: 'Add, edit & delete drinks and categories',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminMenuScreen()),
                ),
              ),

              const SizedBox(height: 14),

              _AdminCard(
                icon: Icons.campaign_rounded,
                iconColor: AppColors.warning,
                iconBgColor: AppColors.warning.withValues(alpha: 0.1),
                title: 'Send Promotion',
                subtitle: 'Send promotional notification to all users',
                onTap: () => _showPromoDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPromoDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Send Promotion',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: GoogleFonts.inter(fontSize: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: GoogleFonts.inter(fontSize: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final message = messageController.text.trim();
              if (title.isEmpty || message.isEmpty) return;

              Navigator.pop(ctx);
              try {
                await FirestoreService().createNotification(AppNotification(
                  id: '',
                  userId: 'all',
                  title: title,
                  body: message,
                  type: NotificationType.promo,
                  createdAt: DateTime.now(),
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Promotion sent!',
                          style: GoogleFonts.inter()),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send: $e',
                          style: GoogleFonts.inter()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Send',
              style: GoogleFonts.inter(
                  color: AppColors.accentBlue, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  const _AdminCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.surface, width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 20),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
