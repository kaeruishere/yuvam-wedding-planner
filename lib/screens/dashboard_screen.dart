import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import '../models/item_model.dart';
import '../models/service_model.dart';
import '../models/task_model.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';


class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigate;
  
  const DashboardScreen({super.key, this.onNavigate});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppTexts.goodMorning;
    if (hour < 18) return AppTexts.goodAfternoon;
    return AppTexts.goodEvening;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,##0", "tr_TR");
    return '${formatter.format(amount)} ₺';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final userName = userData?['name'] ?? '';
          final coupleId = userData?['coupleId'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '$userName!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: (userData?['photoUrl'] as String?)?.isNotEmpty == true
                              ? NetworkImage(userData!['photoUrl'])
                              : null,
                          child: (userData?['photoUrl'] as String?)?.isNotEmpty == true
                              ? null
                              : Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (coupleId != null) _buildCountdownCard(coupleId, context),
                
                const SizedBox(height: 16),

                _buildMotivationalNotes(coupleId, context, isDark),

                const SizedBox(height: 24),

                _buildSummaryGrid(coupleId, isDark),

                const SizedBox(height: 24),

                _buildPendingTasks(coupleId, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountdownCard(String coupleId, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final coupleData = snapshot.data!.data() as Map<String, dynamic>?;
        final events = coupleData?['events'] as Map<String, dynamic>? ?? {};
        
        DateTime? nearestDate;
        String? nearestEventName;
        
        events.forEach((key, value) {
          if (value != null) {
            final date = DateTime.parse(value);
            if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
               if (nearestDate == null || date.isBefore(nearestDate!)) {
                nearestDate = date;
                nearestEventName = key == 'engagement' 
                    ? AppTexts.eventEngagement 
                    : key == 'henna' 
                        ? AppTexts.eventHenna 
                        : AppTexts.eventWedding;
              }
            }
          }
        });

        if (nearestDate == null) {
          return Card(
             elevation: 0,
             color: AppColors.primary.withOpacity(0.1),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             child: Padding(
               padding: const EdgeInsets.all(24),
               child: Center(
                 child: Text(
                   AppTexts.dateNotSet,
                   style: TextStyle(fontSize: 16, color: AppColors.primary),
                 ),
               ),
             ),
          );
        }

        final daysUntil = nearestDate!.difference(DateTime.now()).inDays + 1;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nearestEventName ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    daysUntil == 0 ? "Bugün!" : "$daysUntil ${AppTexts.daysUntilEvent}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.timer, color: Colors.white, size: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMotivationalNotes(String? coupleId, BuildContext context, bool isDark) {
    if (coupleId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .limit(5) // Fetch a few to find one that isn't mine
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(); 
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        // Find first note NOT sent by me
        // We can't map to Note model directly here because we need to filter locally potentially?
        // Actually, we can mapped them to Note model to be safe.
        // But the logic here is slightly custom (finding first note not by me).
        // Let's keep it simple and just use map access for this specific widget as it's just display.
        // OR better: Map to Note model!
        
        // This fails if we don't import Note model but we only imported Item, Service, Task. 
        // Let's stick to map for this small widget or import Note model. 
        // I will stick to Map for this widget to minimal changes as it's not a full CRUD screen.
        // Ideally we should use Note model but I didn't import it above in my plan.
        
        final notes = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
        final otherNotes = notes.where((n) => n['authorId'] != currentUserId).toList();

        if (otherNotes.isEmpty) return const SizedBox();

        final noteData = otherNotes.first;
        final noteText = noteData['message'] ?? '';
        final senderName = noteData['authorName'] ?? '';

        return Card(
          elevation: 0,
          color: Colors.pink.withOpacity(0.08),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.pink.withOpacity(0.2))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.pink, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$senderName:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade700,
                        ),
                      ),
                      Text(
                        noteText,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryGrid(String? coupleId, bool isDark) {
    if (coupleId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('services')
          .snapshots(),
      builder: (context, servicesSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('couples')
              .doc(coupleId)
              .collection('todos')
              .snapshots(),
          builder: (context, todosSnapshot) {
             return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('couples')
                  .doc(coupleId)
                  .collection('items')
                  .snapshots(),
              builder: (context, itemsSnapshot) {
                // Calculate totals
                double remainingDebt = 0;
                int totalTasks = 0;
                int pendingTasks = 0;
                int totalItems = 0;
                int toBuyItems = 0;

                if (servicesSnapshot.hasData) {
                  for (var doc in servicesSnapshot.data!.docs) {
                    final service = Service.fromFirestore(doc);
                    remainingDebt += service.remainingAmount;
                  }
                }

                if (todosSnapshot.hasData) {
                  for (var doc in todosSnapshot.data!.docs) {
                    final task = Task.fromFirestore(doc);
                    totalTasks++;
                    if (!task.completed) pendingTasks++;
                  }
                }

                if (itemsSnapshot.hasData) {
                   for (var doc in itemsSnapshot.data!.docs) {
                    final item = Item.fromFirestore(doc);
                    totalItems++;
                    final status = item.status;
                    if (status == 'to_buy' || status == 'pending' || status == 'ordered') toBuyItems++;
                  }
                }

                return SizedBox(
                  height: 120, 
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildSummaryCard(
                          icon: Icons.account_balance_wallet,
                          title: AppTexts.remainingDebt,
                          value: _formatCurrency(remainingDebt).replaceAll(' ₺', ''), 
                          suffix: '₺',
                          color: Colors.blue,
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WalletScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        flex: 3,
                        child: _buildSummaryCard(
                          icon: Icons.check_circle_outline,
                          title: "Görev",
                          value: '$pendingTasks',
                          subValue: '/$totalTasks',
                          color: Colors.orange,
                          isDark: isDark,
                          onTap: () => onNavigate?.call(3), 
                        ),
                      ),
                       const SizedBox(width: 12),

                      Expanded(
                        flex: 3,
                        child: _buildSummaryCard(
                          icon: Icons.shopping_bag_outlined,
                          title: "Alışveriş",
                          value: '$toBuyItems',
                          subValue: '/$totalItems',
                          color: Colors.purple,
                          isDark: isDark,
                          onTap: () => onNavigate?.call(1), 
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    String? subValue,
    String? suffix,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      surfaceTintColor: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (suffix != null)
                     Padding(
                       padding: const EdgeInsets.only(bottom: 2, left: 2),
                       child: Text(
                        suffix,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                                           ),
                     ),
                  if (subValue != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        subValue,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTasks(String? coupleId, bool isDark) {
    if (coupleId == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppTexts.pendingTasks,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                onNavigate?.call(3); 
              },
              child: Text(AppTexts.viewAll),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('couples')
              .doc(coupleId)
              .collection('todos')
              .where('completed', isEqualTo: false)
              .orderBy('createdAt', descending: true) 
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.celebration, color: Colors.green, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      AppTexts.noPendingTasks,
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final task = Task.fromFirestore(doc);
                final title = task.title;
                final isUrgent = task.dueDate != null && 
                    task.dueDate!.difference(DateTime.now()).inDays <= 1 && 
                    !task.completed;

                return Card(
                  elevation: 0,
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2))),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUrgent ? Icons.priority_high : Icons.task_alt, 
                        color: isUrgent ? Colors.red : AppColors.primary,
                        size: 20
                      ),
                    ),
                    title: Text(
                      title, 
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () => onNavigate?.call(3), 
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
