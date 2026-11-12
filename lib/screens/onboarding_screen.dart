import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../services/expense_storage_service.dart';
import '../widgets/moneta_goddess_widget.dart';
import 'main_navigation_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0 = Lang, 1 = Currency, 2 = Salary, 3 = Budget, 4 = Scan Scope, 5 = Notification
  String _selectedLanguage = 'ไทย';
  String _selectedCurrency = '฿ บาท (THB)';
  String _selectedSalary = '฿10,000 – 50,000';
  double _monthlyBudget = 15000;
  int _selectedScanHistoryDays = 7; // Default: Sweet Spot 7 days

  final List<String> _languages = ['English', '中文', 'ไทย'];
  final List<String> _salaryRanges = [
    '฿10,000 – 50,000',
    '฿50,000 – 100,000',
    '฿100,000 – 200,000',
    '> ฿200,000',
  ];

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_step < 5) {
      setState(() {
        _step++;
      });
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    if (_step > 0) {
      setState(() {
        _step--;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    final storage = ExpenseStorageService.instance;
    await storage.setUserLanguage(_selectedLanguage);
    await storage.setUserCurrency(_selectedCurrency);
    await storage.setUserSalaryRange(_selectedSalary);
    await storage.setMonthlyBudget(_monthlyBudget);
    await storage.setScanHistoryDays(_selectedScanHistoryDays);
    await storage.setCompletedOnboarding(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, anim, secAnim) => const MainNavigationShell(),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.mintioCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💲 เลือกสกุลเงิน',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.mintioCardElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาสกุลเงิน',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: Colors.white38),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'แนะนำ',
                style: TextStyle(
                  color: AppColors.mintioTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildCurrencyTile('฿', 'บาท', 'THB'),
              _buildCurrencyTile('\$', 'ดอลลาร์สหรัฐ', 'USD'),
              _buildCurrencyTile('¥', 'เยนญี่ปุ่น', 'JPY'),
              _buildCurrencyTile('€', 'ยูโร', 'EUR'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyTile(String symbol, String name, String code) {
    final isSelected = _selectedCurrency.contains(code);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCurrency = '$symbol $name ($code)';
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintioCardElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              code,
              style: const TextStyle(
                color: AppColors.mintioTextSecondary,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check_rounded, color: AppColors.mintioIndigo, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintioMidnight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildStepLanguage();
      case 1:
        return _buildStepCurrency();
      case 2:
        return _buildStepSalary();
      case 3:
        return _buildStepBudget();
      case 4:
        return _buildStepScanScope();
      case 5:
        return _buildStepNotifications();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 0: เลือกภาษา (IMG_3468.PNG)
  Widget _buildStepLanguage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          const Text(
            'เลือกภาษา',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          ..._languages.map((lang) {
            final isSelected = _selectedLanguage == lang;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedLanguage = lang);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.mintioCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lang,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.mintioMint,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          _buildPrimaryButton('ไปต่อ', _nextStep),
          const Spacer(),
          // Moneta Goddess + Sacred Goose at bottom peering up
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                SacredGoosePixelWidget(size: 54),
                SizedBox(width: 14),
                MonetaGoddessPixelWidget(size: 105, mood: GoddessMood.idle),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Step 1: เลือกสกุลเงิน (IMG_3469.PNG)
  Widget _buildStepCurrency() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _prevStep,
              child: const Text(
                'กลับ',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'เลือกสกุลเงิน',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _showCurrencyPicker,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.mintioCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCurrency,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 28),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildPrimaryButton('ยืนยัน', _nextStep),
          const Spacer(),
          const Center(
            child: MonetaGoddessPixelWidget(
              size: 115,
              mood: GoddessMood.happy,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Step 2: เงินเดือน (IMG_3471.PNG & IMG_3472.PNG)
  Widget _buildStepSalary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                MonetaGoddessPixelWidget(size: 110, mood: GoddessMood.streakFlame),
                SizedBox(width: 12),
                SacredGoosePixelWidget(size: 50),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ตอนนี้คุณเงินเดือนประมาณเท่าไหร่',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          ..._salaryRanges.map((range) {
            final isSelected = _selectedSalary == range;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSalary = range);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.mintioCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        range,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.mintioMint,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          _buildPrimaryButton('ไปต่อ', _nextStep),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Step 3: งบประมาณรายเดือน (IMG_3473.PNG)
  Widget _buildStepBudget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _prevStep,
              child: const Text('กลับ', style: TextStyle(color: Colors.white70)),
            ),
          ),
          const Center(
            child: MonetaGoddessPixelWidget(
              size: 115,
              mood: GoddessMood.idle,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ใช้เดือนละเท่าไหร่?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.mintioCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '฿${_monthlyBudget.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: AppTheme.tabularFigures(
                  base: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.mintioIndigo,
              inactiveTrackColor: AppColors.mintioCard,
              thumbColor: Colors.white,
              trackHeight: 6,
            ),
            child: Slider(
              value: _monthlyBudget,
              min: 5000,
              max: 100000,
              divisions: 19,
              onChanged: (val) {
                setState(() => _monthlyBudget = val);
              },
            ),
          ),
          const Spacer(),
          _buildPrimaryButton('ไปต่อ', _nextStep),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Step 4: เลือกขอบเขตการกวาดสลิปย้อนหลัง (Strategy B + C)
  Widget _buildStepScanScope() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: _prevStep,
              ),
              const Spacer(),
            ],
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                SacredGoosePixelWidget(size: 46),
                SizedBox(width: 10),
                MonetaGoddessPixelWidget(size: 88, mood: GoddessMood.happy),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'กวาดสลิปย้อนหลังนานแค่ไหนดี?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Moneta จะดึงเฉพาะสลิปธนาคารมาให้คุณปัดแยกหมวดหมู่ ไม่ปะปนกับรูปถ่ายหรือภาพหน้าจอ',
            style: TextStyle(
              color: AppColors.mintioTextSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _buildScanScopeOption(
            days: 7,
            title: '7 วันล่าสุด (แนะนำ)',
            subtitle: 'พบสลิปประมาณ 5–15 ใบ กำลังพอดี ไม่เหนื่อยปัด',
            icon: Icons.bolt_rounded,
            iconColor: AppColors.mintioMint,
          ),
          const SizedBox(height: 10),
          _buildScanScopeOption(
            days: 0,
            title: 'เริ่มต้นใหม่ตั้งแต่วันนี้',
            subtitle: 'เริ่มต้นนับ 1 ใหม่แบบคลีนๆ สแกนเฉพาะสลิปใหม่ที่จะเกิดขึ้น',
            icon: Icons.today_rounded,
            iconColor: AppColors.mintioIndigo,
          ),
          const SizedBox(height: 10),
          _buildScanScopeOption(
            days: 30,
            title: '30 วันล่าสุด',
            subtitle: 'ดึงสลิปของเดือนนี้เพื่อสรุปสถิติและวิเคราะห์งบประมาณ',
            icon: Icons.calendar_month_rounded,
            iconColor: AppColors.mintioPurple,
          ),
          const Spacer(),
          _buildPrimaryButton('ไปต่อ', _nextStep),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildScanScopeOption({
    required int days,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedScanHistoryDays == days;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedScanHistoryDays = days;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintioCardElevated : AppColors.mintioCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.mintioIndigo : AppColors.mintioBorder,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.mintioIndigo.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.innerRadius(18, 14)),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.mintioTextSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.mintioIndigo : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.mintioIndigo : AppColors.mintioBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Step 5: ขอสิทธิ์การแจ้งเตือน (IMG_3476.PNG)
  Widget _buildStepNotifications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                MonetaGoddessPixelWidget(size: 115, mood: GoddessMood.streakFlame),
                SizedBox(width: 14),
                SacredGoosePixelWidget(size: 56),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'เปิดให้เราแจ้งเตือน',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem('สรุปว่าเงินใช้ไปกับอะไรบ้าง'),
          _buildBenefitItem('สรุปยอดรายวันและสัปดาห์'),
          _buildBenefitItem('เตือนเช็คอินรักษาสตรีคประจำวัน'),
          const Spacer(),
          _buildPrimaryButton('อนุญาต', _finishOnboarding),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _finishOnboarding,
              child: const Text(
                'ไว้ก่อน',
                style: TextStyle(
                  color: AppColors.mintioTextSecondary,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.mintioMint, size: 22),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mintioIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }
}

