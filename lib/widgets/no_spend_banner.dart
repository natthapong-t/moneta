import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../services/expense_storage_service.dart';
import 'living_creature_widget.dart';

class NoSpendBanner extends StatefulWidget {
  final VoidCallback onStreakUpdated;

  const NoSpendBanner({super.key, required this.onStreakUpdated});

  @override
  State<NoSpendBanner> createState() => _NoSpendBannerState();
}

class _NoSpendBannerState extends State<NoSpendBanner> {
  bool _isNoSpendChecked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final checked = await ExpenseStorageService.instance.isTodayNoSpendDay();
    if (mounted) {
      setState(() {
        _isNoSpendChecked = checked;
        _isLoading = false;
      });
    }
  }

  Future<void> _markNoSpend() async {
    HapticFeedback.mediumImpact();
    final success = await ExpenseStorageService.instance.markTodayNoSpendDay();
    if (success && mounted) {
      setState(() {
        _isNoSpendChecked = true;
      });
      widget.onStreakUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.mintioMint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'สุดยอดมาก! วันนี้ประหยัดเงินสำเร็จ +1 สตรีค 🔥',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isNoSpendChecked
            ? AppColors.mintioCardElevated
            : const Color(0xFF1E202E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isNoSpendChecked
              ? AppColors.mintioMint.withValues(alpha: 0.5)
              : AppColors.mintioIndigo.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Mascot Eyes
          BlinkingCreatureEyes(
            width: 44,
            height: 32,
            pupilColor: _isNoSpendChecked
                ? AppColors.mintioMint
                : AppColors.mintioIndigo,
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isNoSpendChecked
                      ? 'วันนี้ประหยัดเงินสำเร็จ! 🏆'
                      : 'วันนี้ไม่ได้ใช้เงินใช่ไหม?',
                  style: const TextStyle(
                    color: AppColors.mintioTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isNoSpendChecked
                      ? 'สตรีคของคุณได้รับการปกป้องแล้ว'
                      : 'แตะเพื่อบันทึก No-Spend Day และรักษา Streak',
                  style: const TextStyle(
                    color: AppColors.mintioTextSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Action Button
          if (_isNoSpendChecked)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.mintioMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            )
          else
            ElevatedButton(
              onPressed: _markNoSpend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mintioIndigo,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'แตะเช็คอิน',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

