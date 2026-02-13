import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import '../models/note_model.dart';
import '../services/notes_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class UsScreen extends StatefulWidget {
  const UsScreen({super.key});

  @override
  State<UsScreen> createState() => _UsScreenState();
}

class _UsScreenState extends State<UsScreen> {
  final _notesService = NotesService();
  final _authService = AuthService();
  final _db = FirebaseFirestore.instance;

  // --- ACTIONS ---

  void _showAddNoteDialog() {
    final messageController = TextEditingController();
    String selectedEmoji = '❤️';
    final emojis = ['❤️', '💕', '🎉', '✨', '🥰', '💖', '💍', '🏠'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppTexts.addNote,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: AppTexts.noteHint,
                    prefixIcon: const Icon(Icons.edit_note),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppTexts.selectEmoji,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: emojis.map((emoji) {
                    final isSelected = emoji == selectedEmoji;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedEmoji = emoji),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppTexts.cancelBtn,
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.trim().isEmpty) return;
                Navigator.pop(context);

                final error = await _notesService.addNote(
                  message: messageController.text.trim(),
                  emoji: selectedEmoji,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error ?? AppTexts.noteAdded)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppTexts.addBtn),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkPartnerDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTexts.pairButton,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppTexts.partnerCodeHint,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: "Partner Kodu",
                hintText: "Örn: ABC123",
                prefixIcon: const Icon(Icons.favorite_border),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTexts.cancelBtn,
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty) return;
              Navigator.pop(context);

              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()));

              try {
                await _authService.linkPartner(codeController.text.trim());
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppTexts.pairingSuccess)));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Hata: ${e.toString()}")));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppTexts.pairButton),
          ),
        ],
      ),
    );
  }

  Future<void> _selectRelationshipDate(
      BuildContext context, String coupleId, DateTime? currentDate) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: languageProvider.currentLocale,
      helpText: languageProvider.isEnglish ? "Select Start Date" : "İlişki Başlangıç Tarihi",
    );

    if (picked != null) {
      // Save to Firestore
      await _db.collection('couples').doc(coupleId).update({
        'relationshipStartDate': picked.toIso8601String(),
      });
    }
  }

  // --- HELPERS ---

  String _calculateDuration(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate);

    // Simple calculation
    int days = difference.inDays;
    int years = (days / 365).floor();
    int months = ((days % 365) / 30).floor();
    int remainingDays = (days % 365) % 30;

    if (years > 0) {
      return '$years Yıl $months Ay';
    } else if (months > 0) {
      return '$months Ay $remainingDays Gün';
    } else {
      return '$days Gün';
    }
  }

  String _getRelativeTime(DateTime? timestamp) {
    if (timestamp == null) return AppTexts.justNow;
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return AppTexts.justNow;
    if (diff.inHours < 1) return '${diff.inMinutes} ${AppTexts.minutesAgo}';
    if (diff.inDays < 1) return '${diff.inHours} ${AppTexts.hoursAgo}';
    return '${diff.inDays} ${AppTexts.daysAgo}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTexts.usTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.edit),
        label: Text(AppTexts.addNote),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(user.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final coupleId = userData?['coupleId'];
          final isLinked = userData?['partnerId'] != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. Partner Code (Only if not linked)
                if (!isLinked) _buildPartnerCodeCard(userData, isDark),

                if (!isLinked) const SizedBox(height: 24),

                // 2. Relationship Header (Heart & Duration)
                if (coupleId != null)
                  _buildRelationshipHeader(coupleId, isDark),

                const SizedBox(height: 24),

                // 3. Notes Section
                _buildNotesList(isDark),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartnerCodeCard(Map<String, dynamic>? userData, bool isDark) {
    final code = userData?['myPairCode'] ?? '---';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.link, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            "Henüz Bağlı Değilsin",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Partnerinle eşleşmek için kodunu paylaş veya onun kodunu gir.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // My Code
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(AppTexts.codeCopied)));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.copy, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Connect Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showLinkPartnerDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(AppTexts.pairButton,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipHeader(String coupleId, bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('couples').doc(coupleId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final userIds = List<String>.from(data?['users'] ?? []);
        final startDateStr = data?['relationshipStartDate'];
        DateTime? startDate =
            startDateStr != null ? DateTime.tryParse(startDateStr) : null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.pink.shade900, Colors.purple.shade900]
                  : [Colors.pink.shade50, Colors.purple.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark
                    ? Colors.pink.withOpacity(0.3)
                    : Colors.pink.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Avatars Row
              SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // User 1
                    if (userIds.isNotEmpty) _buildAvatarStream(userIds[0]),

                    // Heart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                          onLongPress: () => _selectRelationshipDate(
                              context, coupleId, startDate),
                          borderRadius: BorderRadius.circular(50),
                          child: const Icon(Icons.favorite,
                              color: Colors.pink, size: 32)),
                    ),

                    // User 2
                    if (userIds.length > 1)
                      _buildAvatarStream(userIds[1])
                    else
                      _buildPlaceholderAvatar(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Duration Text
              InkWell(
                onLongPress: () =>
                    _selectRelationshipDate(context, coupleId, startDate),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        startDate != null
                            ? _calculateDuration(startDate)
                            : "Tarih Belirle (Basılı Tut)",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (startDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Birliktelik",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarStream(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final photoUrl = data?['photoUrl'];
        final name = data?['name'] ?? '?';

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
                ],
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey))
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
        ],
      ),
      child: CircleAvatar(
        radius: 32,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person_add, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildNotesList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.sticky_note_2, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(AppTexts.ourNotes,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Note>>(
          stream: _notesService.getNotesStream(limit: 10),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    AppTexts.noNotes,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = snapshot.data![index];
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final isOwn = note.authorId == currentUserId;

                return InkWell(
                  onLongPress: isOwn
                      ? () {
                          showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                    title: Text(AppTexts.deleteBtn),
                                    content: Text(AppTexts.deleteNoteConfirm),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(c),
                                          child: Text(AppTexts.cancelBtn)),
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(c);
                                            _notesService
                                                .deleteNote(note.id);
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white),
                                          child: Text(AppTexts.deleteBtn)),
                                    ],
                                  ));
                        }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.message,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    note.authorName,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                  ),
                                  Text(
                                    " • ${_getRelativeTime(note.createdAt)}",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
