import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';

import 'settings_screen.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  // --- CRUD: Image Upload ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);

    if (pickedFile == null || user == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${user!.uid}.jpg');

      if (pickedFile.path.isNotEmpty) {
        // For web, we might need readAsBytes, but putData works for both if we get bytes
        final bytes = await pickedFile.readAsBytes(); 
        await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      }
      
      // 2. Get Download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // 3. Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'photoUrl': downloadUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- CRUD: Etkinlik Tarihi Güncelleme ---
  Future<void> _updateEventDate(String coupleId, String eventKey, DateTime? currentDate) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    // Ensure initialDate is within valid range
    final firstDate = DateTime(1900);
    final lastDate = DateTime(2100);
    
    DateTime initialDate = currentDate ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: languageProvider.currentLocale,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await FirebaseFirestore.instance.collection('couples').doc(coupleId).update({
        'events.$eventKey': picked.toIso8601String(),
      });
    }
  }

  // --- CRUD: Etkinlik Silme ---
  Future<void> _removeEvent(String coupleId, String eventKey) async {
    await FirebaseFirestore.instance.collection('couples').doc(coupleId).update({
      'events.$eventKey': FieldValue.delete(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppTexts.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final coupleId = userData?['coupleId'];

          return Consumer2<ThemeProvider, LanguageProvider>(
            builder: (context, themeProvider, languageProvider, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileInfo(userData, themeProvider.isDark),
                    const SizedBox(height: 24),
                    
                    if (coupleId != null)
                      _buildEventsManager(coupleId, themeProvider.isDark),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic>? data, bool isDark) {
    final profileImage = data?['photoUrl'] as String?;
    final name = data?['name'] as String? ?? '';
    final surname = data?['surname'] as String? ?? '';
    final email = data?['email'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: profileImage != null && profileImage.isNotEmpty 
                      ? NetworkImage(profileImage) 
                      : null,
                  child: profileImage == null || profileImage.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "U",
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : (_isUploading ? const CircularProgressIndicator() : null),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _isUploading ? Icons.hourglass_empty : Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "$name $surname",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showEditProfileDialog(data),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(AppTexts.isEnglish ? "Edit Information" : "Bilgileri Düzenle"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsManager(String coupleId, bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('couples').doc(coupleId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final coupleData = snapshot.data!.data() as Map<String, dynamic>?;
        final events = coupleData?['events'] as Map<String, dynamic>? ?? {};

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppTexts.editEvents, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                )),
              const SizedBox(height: 16),
              _buildEventItem(coupleId, events, 'engagement', AppTexts.eventEngagement, isDark),
              const Divider(height: 24),
              _buildEventItem(coupleId, events, 'henna', AppTexts.eventHenna, isDark),
              const Divider(height: 24),
              _buildEventItem(coupleId, events, 'wedding', AppTexts.eventWedding, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventItem(String coupleId, Map<String, dynamic> events, String key, String title, bool isDark) {
    final dateStr = events[key];
    final DateTime? date = dateStr != null ? DateTime.parse(dateStr) : null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, 
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                )),
              Text(date == null ? AppTexts.dateNotSet : "${date.day}.${date.month}.${date.year}", 
                style: TextStyle(
                  color: date == null ? const Color(0xFF94A3B8) : AppColors.primary, 
                  fontSize: 13
                )),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _updateEventDate(coupleId, key, date),
          icon: Icon(date == null ? Icons.add_circle_outline : Icons.edit_calendar, color: AppColors.primary),
        ),
        if (date != null)
          IconButton(
            onPressed: () => _removeEvent(coupleId, key),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          ),
      ],
    );
  }

  Future<void> _showEditProfileDialog(Map<String, dynamic>? data) async {
    final nameController =
        TextEditingController(text: data?['name'] as String? ?? '');
    final surnameController =
        TextEditingController(text: data?['surname'] as String? ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppTexts.isEnglish ? "Edit Profile" : "Profili Düzenle",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: AppTexts.nameHint,
                labelText: AppTexts.isEnglish ? "Name" : "Ad",
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: surnameController,
              decoration: InputDecoration(
                hintText: AppTexts.surnameHint,
                 labelText: AppTexts.isEnglish ? "Surname" : "Soyad",
                 prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTexts.cancelBtn),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final surname = surnameController.text.trim();
              if (name.isEmpty || surname.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .update({
                'name': name,
                'surname': surname,
              });

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(AppTexts.settingsSaveBtn),
          ),
        ],
      ),
    );
  }
}
