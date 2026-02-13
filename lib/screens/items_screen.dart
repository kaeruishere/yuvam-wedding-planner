import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import '../models/item_model.dart';
import '../services/items_service.dart';
import 'item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _itemsService = ItemsService();

  // Filters: null = all, 'to_buy', 'bought'
  String? _selectedItemFilter;

  // --- ADD ITEM DIALOG ---
  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final costController = TextEditingController();
    final notesController = TextEditingController();

    // Default status: false = to_buy (Alınacak), true = bought (Alındı)
    bool isBought = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppTexts.addItem,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppTexts.itemNameHint,
                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Price
                TextField(
                  controller: costController,
                  decoration: InputDecoration(
                    labelText: AppTexts.priceHint,
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: '₺',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: AppTexts.notesHint,
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Status Switch
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isBought
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isBought
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3)),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      isBought ? AppTexts.statusBought : AppTexts.statusToBuy,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBought ? Colors.green : Colors.orange,
                      ),
                    ),
                    subtitle: Text(
                      isBought
                          ? "Bu eşya alındı olarak işaretlenecek"
                          : "Henüz alınmadı",
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isBought,
                    activeColor: Colors.green,
                    onChanged: (val) => setDialogState(() => isBought = val),
                    secondary: Icon(
                      isBought
                          ? Icons.check_circle
                          : Icons.shopping_cart_outlined,
                      color: isBought ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppTexts.cancelBtn,
                    style: TextStyle(color: Colors.grey.shade600))),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen eşya adı giriniz')));
                  return;
                }

                showDialog(
                    context: context,
                    barrierDismissible: false,
                    useRootNavigator: true,
                    builder: (c) =>
                        const Center(child: CircularProgressIndicator()));

                // Logic to map bool to string status
                final status = isBought ? 'bought' : 'to_buy';

                // Create Item object
                final newItem = Item(
                  id: '', // Will be generated
                  name: nameController.text.trim(),
                  category: 'Genel',
                  quantity: 1,
                  notes: notesController.text.trim(),
                  location: '',
                  supplier: '',
                  cost: double.tryParse(
                          costController.text.replaceAll(',', '.')) ??
                      0.0,
                  status: status,
                  createdAt: DateTime.now(),
                );

                final error = await _itemsService.addItem(newItem);

                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop(); // Close loading

                if (error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                } else {
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Eşya eklendi!')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTexts.shoppingTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // Full Width Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterButton('Tümü', null, isDark),
                const SizedBox(width: 8),
                _buildFilterButton(AppTexts.statusToBuy, 'to_buy', isDark),
                const SizedBox(width: 8),
                _buildFilterButton(AppTexts.statusBought, 'bought', isDark),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _selectedItemFilter == null
                  ? _itemsService.getItemsStream()
                  : _itemsService.getItemsByStatus(_selectedItemFilter!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 80, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(AppTexts.noItems,
                            style: TextStyle(
                                color: Colors.grey.withOpacity(0.5),
                                fontSize: 16),
                            textAlign: TextAlign.center)
                      ]));
                }

                final items = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildItemCard(items[index], isDark),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: Text(AppTexts.addItem),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterButton(String label, String? filterValue, bool isDark) {
    final isSelected = _selectedItemFilter == filterValue;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedItemFilter = filterValue),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item, bool isDark) {
    // Normalize status
    String status = item.status;
    if (status == 'pending' || status == 'ordered') status = 'to_buy';
    if (status == 'received') status = 'bought';

    final isBought = status == 'bought';
    final name = item.name;
    final notes = item.notes ?? '';
    final cost = item.cost;

    // Status visual
    final statusColor = isBought ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(
                      itemId: item.id, itemName: name)));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 1. Status icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBought ? Icons.check : Icons.shopping_bag_outlined,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // 2. Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration:
                            isBought ? TextDecoration.lineThrough : null,
                        color: isBought
                            ? Colors.grey
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (cost > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '₺${cost.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Action Button (If not bought)
              if (!isBought)
                ElevatedButton(
                  onPressed: () async {
                    await _itemsService.updateItemStatus(
                        itemId: item.id, status: 'bought');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    foregroundColor: Colors.green,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(60, 36),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Aldım",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                )
              else
                Icon(Icons.check_circle,
                    color: Colors.green.withOpacity(0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
