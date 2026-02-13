import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Partner Step
  final _partnerCodeController = TextEditingController();
  String? _myPairCode;
  
  // Event Step
  String _selectedEventType = 'wedding'; // wedding, engagement, henna
  DateTime? _selectedDate;

  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _myPairCode = doc.data()?['myPairCode'];
        });
      }
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300), 
      curve: Curves.easeInOut
    );
  }

  Future<void> _connectPartner() async {
    if (_partnerCodeController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _authService.linkPartner(_partnerCodeController.text.trim());
      
      // On success, go to Main App directly (skip event setup as they sync with partner)
      if (mounted) {
        // Mark onboarding complete just in case
        await _authService.updateOnboardingStatus(true);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finishOnboarding() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Get couple ID
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final String coupleId = userDoc.data()?['coupleId'] ?? user.uid;

      // 2. Save Event Data if date is selected
      if (_selectedDate != null) {
        await _firestore.collection('couples').doc(coupleId).set({
          'events': {
            _selectedEventType: _selectedDate!.toIso8601String(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 3. Mark Complete
      await _firestore.collection('users').doc(user.uid).update({
        'onboardingCompleted': true,
      });

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildTutorialPage(
                    title: "Hoş Geldin!",
                    description: "Yuvam ile evlilik sürecini, bütçeni ve yapılacakları tek bir yerden yönet.",
                    icon: Icons.favorite,
                    color: Colors.pink,
                  ),
                  _buildTutorialPage(
                    title: "Hizmetler & Bütçe",
                    description: "Tüm hizmet sağlayıcılarını, ödemelerini ve belgelerini kolayca takip et.",
                    icon: Icons.account_balance_wallet,
                    color: Colors.blue,
                  ),
                  _buildTutorialPage(
                    title: "Alışveriş & Görevler",
                    description: "Partnerinle ortak alışveriş listeleri ve görevler oluştur. Kimse bir şey unutmasın!",
                    icon: Icons.check_circle_outline,
                    color: Colors.purple,
                  ),
                  _buildPartnerStep(isDark),
                  _buildEventStep(isDark),
                ],
              ),
            ),
            
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(5, (index) => _buildIndicator(index == _currentPage)),
                  ),
                  
                  // Next/Finish Button
                  if (_currentPage < 4)
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.arrow_forward),
                    )
                  else
                     const SizedBox(width: 50), // Verify handles the button in the last page itself or we add here?
                     // Actually, the last page has the "Start" button. Let's keep arrow for nav but maybe hide it on last page if we want explicit action.
                     // On page 3 (Partner), we have explicit actions.
                     // On page 4 (Event), we have explicit actions.
                     
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildTutorialPage({required String title, required String description, required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.link, size: 60, color: Colors.orange),
          ),
          const SizedBox(height: 32),
          const Text(
            "Partnerinle Bağlan",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Hesaplarınızı birleştirerek her şeyi ortak yönetin.",
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          const SizedBox(height: 32),
          
          Text("Partnerinin kodunu gir:", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 12),
          
          TextField(
            controller: _partnerCodeController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "Partner Kodu",
              filled: true,
              fillColor: isDark ? Colors.grey.shade900 : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) => setState(() {}),
          ),
          
          const SizedBox(height: 24),
          
          if (_isLoading)
             const CircularProgressIndicator()
          else ...[
             ElevatedButton(
              onPressed: _partnerCodeController.text.isNotEmpty ? _connectPartner : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Bağlan"),
            ),
            TextButton(
              onPressed: _nextPage,
              child: const Text("Şimdilik Atla"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
           Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available, size: 60, color: Colors.purple),
          ),
          const SizedBox(height: 32),
          const Text(
            "Ne Planlıyorsunuz?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Geri sayımı başlatmak için bir tarih seç.",
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Event Type Selection
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildChoiceChip('Düğün', 'wedding', isDark),
              _buildChoiceChip('Nişan', 'engagement', isDark),
              _buildChoiceChip('Kına', 'henna', isDark),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Date Picker
          InkWell(
            onTap: () async {
              final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 90)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                locale: languageProvider.currentLocale,
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary.withOpacity(0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.calendar_today, color: AppColors.primary),
                   const SizedBox(width: 12),
                   Text(
                     _selectedDate == null 
                       ? "Tarih Seçin" 
                       : "${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}",
                     style: const TextStyle(
                       fontSize: 18, 
                       fontWeight: FontWeight.bold,
                       color: AppColors.primary
                     ),
                   ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),

          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _finishOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: const Text("Yuvam'a Başla", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
  
  Widget _buildChoiceChip(String label, String value, bool isDark) {
    final isSelected = _selectedEventType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedEventType = value);
      },
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}