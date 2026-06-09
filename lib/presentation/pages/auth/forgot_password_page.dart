import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

import '../../../core/constants/admin_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/logo_widget.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  Future<void> _launchCall() async {
    final uri = Uri(scheme: 'tel', path: AdminConstants.adminPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp() async {
    final phone = AdminConstants.adminPhone.replaceAll('+', '');
    final message = Uri.encodeComponent(
      'Hi, I have forgotten my password. Please help me reset it.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: context.getResponsiveSize(5),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: context.getResponsiveSize(5),
              vertical: context.getScreenHeight(1),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    SizedBox(height: context.getScreenHeight(3)),

                    // ── Logo ──
                    Center(
                      child: LogoWidget(
                        logoSize: context.getResponsiveSize(16),
                        nameFontSize: context.getResponsiveSize(4),
                        subtitleFontSize: context.getResponsiveSize(2),
                        iconColor: context.colorPalette.gold,
                        nameColor: context.colorPalette.goldDeep,
                        subtitleColor: context.colorPalette.goldDark,
                        nameLetterSpacing: 2.0,
                        iconNameSpacing: context.getScreenHeight(0.8),
                        nameSubtitleSpacing: context.getScreenHeight(0.2),
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(4)),

                    // ── Title ──
                    Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(5.5),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(1)),

                    // ── Subtitle ──
                    Text(
                      'Please contact us. We will verify your details and provide you with new password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3.3),
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: context.getScreenHeight(4)),

                    // ── Contact Card ──
                    _buildContactCard(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.getResponsiveSize(4)),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(context.getResponsiveSize(3)),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // ── Icon + Text ──
          Container(
            width: context.getResponsiveSize(14),
            height: context.getResponsiveSize(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGold.withValues(alpha: 0.15),
                  AppColors.primaryGold.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.headset_mic_rounded,
              color: AppColors.primaryGold,
              size: context.getResponsiveSize(6),
            ),
          ),

          SizedBox(height: context.getScreenHeight(2)),

          Text(
            'Contact Us',
            style: TextStyle(
              fontSize: context.getResponsiveSize(4.5),
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),

          SizedBox(height: context.getScreenHeight(0.5)),

          Text(
            AdminConstants.adminPhone,
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.5),
              color: AppColors.textMuted,
            ),
          ),

          SizedBox(height: context.getScreenHeight(2.5)),

          // ── Buttons ──
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icon(
                    Icons.phone_rounded,
                    color: AppColors.primaryGold,
                    size: context.getResponsiveSize(4.5),
                  ),
                  label: 'Call Us',
                  color: AppColors.primaryGold,
                  onTap: _launchCall,
                ),
              ),
              SizedBox(width: context.getResponsiveSize(3)),
              Expanded(
                child: _ContactButton(
                  icon: FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: const Color(0xFF25D366),
                    size: context.getResponsiveSize(4.5),
                  ),
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: _launchWhatsApp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable Contact Button ─────────────────────────────────────────────────

class _ContactButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          padding: EdgeInsets.symmetric(
            vertical: context.getScreenHeight(1.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(width: context.getResponsiveSize(2)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.getResponsiveSize(3.8),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
