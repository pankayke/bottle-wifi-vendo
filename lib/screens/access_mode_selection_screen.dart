import 'package:flutter/material.dart';

class AccessModeSelectionScreen extends StatelessWidget {
  const AccessModeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Campus Logo - Matching login screen style
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/school_logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.school,
                        size: 80,
                        color: Color(0xFF1565C0),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Bottle-Wifi',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Recycle bottles, get WiFi',
                style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
              ),

              const SizedBox(height: 60),

              // Access Mode Cards
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Guest Mode - Insert Bottle
                  _AccessModeCard(
                    icon: Icons.recycling,
                    title: 'Insert Bottle',
                    subtitle: 'Get free WiFi instantly',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                    ),
                    onTap: () => _navigateToGuestFlow(context),
                  ),

                  const SizedBox(height: 16),

                  // Voucher Mode
                  _AccessModeCard(
                    icon: Icons.confirmation_number,
                    title: 'Redeem Voucher',
                    subtitle: 'Enter your voucher code',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    ),
                    onTap: () => _navigateToVoucherFlow(context),
                  ),

                  const SizedBox(height: 16),

                  // Account Mode (Optional)
                  _AccessModeCard(
                    icon: Icons.person,
                    title: 'Login',
                    subtitle: 'Access your account (optional)',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    ),
                    isOutlined: true,
                    onTap: () => _navigateToLogin(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Info text
              const Text(
                'No account needed! Just insert a bottle or use a voucher.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGuestFlow(BuildContext context) {
    Navigator.pushNamed(context, '/guest-scan');
  }

  void _navigateToVoucherFlow(BuildContext context) {
    Navigator.pushNamed(context, '/voucher-entry');
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, '/login');
  }
}

class _AccessModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final bool isOutlined;
  final VoidCallback onTap;

  const _AccessModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.isOutlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isOutlined ? null : gradient,
          color: isOutlined ? Colors.white : null,
          border: isOutlined
              ? Border.all(color: const Color(0xFF1565C0), width: 2)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOutlined
                    ? const Color(0xFF1565C0).withOpacity(0.1)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isOutlined ? const Color(0xFF1565C0) : Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOutlined
                          ? const Color(0xFF1565C0)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isOutlined
                          ? const Color(0xFF757575)
                          : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isOutlined
                  ? const Color(0xFF1565C0).withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
