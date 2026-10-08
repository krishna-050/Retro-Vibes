import 'package:flutter/material.dart';
import 'package:retro_vibes/theme/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlanIndex = 1; // 0 = Monthly, 1 = Annual (Recommended)

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double mediaHeight = size.height;
    double mediaWidth = size.width;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.white, size: mediaWidth * 0.065),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mediaWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Badge & Crown
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD700), width: 2),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Color(0xFFFFD700),
                        size: 42,
                      ),
                    ),
                    SizedBox(height: mediaHeight * 0.015),
                    Text(
                      'RETRO VIBES PREMIUM',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: mediaWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: mediaHeight * 0.005),
                    Text(
                      'Experience classic music without limits.',
                      style: TextStyle(
                        color: AppTheme.white38,
                        fontSize: mediaWidth * 0.035,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: mediaHeight * 0.035),

              // Benefits Checklist
              _buildBenefitRow(Icons.high_quality, 'Ultra High Quality Streaming', 'Stream tracks at up to 320kbps lossless audio', mediaWidth),
              _buildBenefitRow(Icons.block, '100% Ad-Free Experience', 'Zero interruptions between your favorite classic songs', mediaWidth),
              _buildBenefitRow(Icons.skip_next, 'Unlimited Skips', 'Skip as many tracks as you want, anytime', mediaWidth),
              _buildBenefitRow(Icons.download_for_offline, 'Offline Listening', 'Save retro hits to your device for offline playback', mediaWidth),
              _buildBenefitRow(Icons.tune, 'Vintage Equalizer & Custom Themes', 'Unlock cassette player visuals & custom Spidey theme', mediaWidth),

              SizedBox(height: mediaHeight * 0.035),

              // Plan Cards Section
              Text(
                'CHOOSE YOUR PLAN',
                style: TextStyle(
                  color: AppTheme.white38,
                  fontSize: mediaWidth * 0.032,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: mediaHeight * 0.015),

              // Monthly Plan
              _buildPlanCard(
                index: 0,
                title: 'Monthly Pass',
                price: '₹99 / month',
                subtitle: 'Cancel anytime. 7 days free trial included.',
                badge: null,
                mediaWidth: mediaWidth,
              ),

              SizedBox(height: mediaHeight * 0.015),

              // Annual Plan (Featured)
              _buildPlanCard(
                index: 1,
                title: 'Annual Retro Pass',
                price: '₹899 / year',
                subtitle: 'Equivalent to ₹74/mo. Save 25% + Gold Badge.',
                badge: 'BEST VALUE • SAVE 25%',
                mediaWidth: mediaWidth,
              ),

              SizedBox(height: mediaHeight * 0.035),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: mediaHeight * 0.065,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    _showSubscriptionDialog(context);
                  },
                  child: Text(
                    _selectedPlanIndex == 1 ? 'START 7-DAY FREE TRIAL (ANNUAL)' : 'GET MONTHLY PREMIUM',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: mediaWidth * 0.04,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              SizedBox(height: mediaHeight * 0.015),

              Center(
                child: Text(
                  'Recurring billing • Cancel anytime in Account Settings',
                  style: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.03),
                ),
              ),

              SizedBox(height: mediaHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle, double mediaWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryAccent, size: mediaWidth * 0.055),
          ),
          SizedBox(width: mediaWidth * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: mediaWidth * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.white38,
                    fontSize: mediaWidth * 0.032,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String subtitle,
    required String? badge,
    required double mediaWidth,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.cardBackground : AppTheme.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? const Color(0xFFFFD700) : AppTheme.white38,
                  size: mediaWidth * 0.06,
                ),
                SizedBox(width: mediaWidth * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: mediaWidth * 0.042,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppTheme.white38, fontSize: mediaWidth * 0.032),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFFD700) : AppTheme.white,
                    fontSize: mediaWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Color(0xFFFFD700)),
            const SizedBox(width: 10),
            Text('Premium Pass', style: TextStyle(color: AppTheme.white)),
          ],
        ),
        content: Text(
          'Payment Gateway integration is prepared. Subscriptions will be billed securely via Google Play Billing.',
          style: TextStyle(color: AppTheme.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );
  }
}
