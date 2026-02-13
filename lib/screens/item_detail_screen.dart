import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import '../models/item_model.dart';
import '../services/items_service.dart';
import '../services/storage_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  final String itemName;

  const ItemDetailScreen({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _itemsService = ItemsService();
  final _storageService = StorageService();
  String? _coupleId;

  // Edit controllers
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  bool _isEditing = false;

  // Data holder to reset buffers
  Item? _itemData;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemName);
    _costController = TextEditingController();
    _notesController = TextEditingController();
    _loadCoupleId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupleId() async {
    final id = await _itemsService.getCoupleIdPublic();
    setState(() {
      _coupleId = id;
    });
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    final newCost =
        double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0.0;
    final newNotes = _notesController.text.trim();

    // Create updated item object
    // We can't access _itemData easily if it wasn't set, but it should be set in build.
    // Ideally we should use the item passed in widget or fetch it, but here we can just create a copy if we have the original item.
    // However, _itemData is only set in build.
    // Better to just create a new Item object with the ID and updated fields if the service supports it, 
    // OR ensure _itemData is valid.
    // Since _saveChanges is called from UI, build must have run.

    if (_itemData == null) return;

    final updatedItem = _itemData!.copyWith(
      name: newName,
      cost: newCost,
      notes: newNotes,
    );

    final error = await _itemsService.updateItem(updatedItem);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Değişiklikler kaydedildi!')));
        setState(() {
          _isEditing = false;
        });
      }
    } else {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTexts.deleteBtn),
        content: const Text('Bu eşyayı silmek istediğine emin misin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppTexts.cancelBtn)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final error = await _itemsService.deleteItem(widget.itemId);

              if (context.mounted) {
                Navigator.pop(context); // Close loading

                if (error == null) {
                  Navigator.pop(context); // Close screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Eşya silindi")),
                  );
                } else {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(AppTexts.deleteBtn),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentDialog() {
    final nameController = TextEditingController();
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Belge Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Belge Adı (Örn: Fatura, Garanti)",
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final file = await _storageService.pickFile();
                  if (file != null) {
                    setDialogState(() {
                      selectedFile = file;
                      if (nameController.text.isEmpty) {
                        nameController.text = file.name;
                      }
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(
                          selectedFile != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          color: selectedFile != null
                              ? Colors.green
                              : Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedFile?.name ?? "Dosya Seç (PDF, Resim...)",
                          style: TextStyle(
                              color: selectedFile != null
                                  ? Colors.black87
                                  : Colors.grey,
                              fontWeight: selectedFile != null
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                      ),
                    ],
                  ),
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
                if (nameController.text.isEmpty || selectedFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Lütfen bir ad girin ve dosya seçin')),
                  );
                  return;
                }

                Navigator.pop(context); // Close dialog

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                // 1. Upload File
                final downloadUrl = await _storageService.uploadFile(
                  file: selectedFile!,
                  path: 'items/${widget.itemId}/docs',
                );

                if (downloadUrl == null) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Dosya yüklenirken hata oluştu')),
                    );
                  }
                  return;
                }

                // 2. Add Document Metadata to Firestore
                final error = await _itemsService.addDocument(
                  itemId: widget.itemId,
                  name: nameController.text,
                  link: downloadUrl,
                  type: selectedFile!.extension ?? 'unknown',
                );

                if (!mounted) return;
                Navigator.pop(context); // Close loading

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Belge başarıyla eklendi')),
                  );
                }
              },
              child: Text(AppTexts.addBtn),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_coupleId == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(_coupleId)
          .collection('items')
          .doc(widget.itemId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        
        if (!snapshot.data!.exists)
          return const Scaffold(body: Center(child: Text("Eşya bulunamadı")));

        final item = Item.fromFirestore(snapshot.data!);

        // Sync controllers only if not currently editing (or first load)
        if (!_isEditing) {
          _itemData = item;
          _nameController.text = item.name;
          _costController.text = item.cost.toString();
          if (_costController.text == '0' || _costController.text == '0.0')
            _costController.text = '';
          _notesController.text = item.notes ?? '';
        }

        final status = item.status;
        final isBought = status == 'bought' || status == 'received';
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // documents are directly in Item model as a List<DocumentAttachment>
        final documents = item.documents;

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Düzenle' : item.name),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveChanges,
                )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card (Status)
                if (!_isEditing)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isBought
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isBought
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                            isBought
                                ? Icons.check_circle
                                : Icons.shopping_cart,
                            size: 48,
                            color: isBought ? Colors.green : Colors.orange),
                        const SizedBox(height: 12),
                        Text(
                          isBought
                              ? AppTexts.statusBought
                              : AppTexts.statusToBuy,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isBought ? Colors.green : Colors.orange),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final newStatus = isBought ? 'to_buy' : 'bought';
                            await _itemsService.updateItemStatus(
                                itemId: widget.itemId, status: newStatus);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            foregroundColor:
                                isBought ? Colors.green : Colors.orange,
                            elevation: 0,
                            side: BorderSide(
                                color: isBought ? Colors.green : Colors.orange),
                          ),
                          child: Text(isBought
                              ? "Alınmadı Olarak İşaretle"
                              : "Alındı Olarak İşaretle"),
                        )
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Fields
                _buildField(
                  label: "Eşya Adı",
                  icon: Icons.label_outline,
                  controller: _nameController,
                  enabled: _isEditing,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: "Fiyat (₺)",
                  icon: Icons.attach_money,
                  controller: _costController,
                  enabled: _isEditing,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: "Notlar",
                  icon: Icons.note_alt_outlined,
                  controller: _notesController,
                  enabled: _isEditing,
                  isDark: isDark,
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // Documents Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Belgeler",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                      onPressed: _showAddDocumentDialog,
                    ),
                  ],
                ),
                if (documents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Henüz belge eklenmemiş",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ...documents.map((doc) => Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                            doc.type == 'pdf'
                                ? Icons.picture_as_pdf
                                : Icons.description,
                            color: AppColors.primary),
                        title: Text(doc.name),
                        subtitle: doc.createdAt != null
                            ? Text(
                                DateFormat('dd.MM.yyyy HH:mm')
                                    .format(doc.createdAt!),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              )
                            : null,
                        onTap: () async {
                          final url = doc.link;
                          if (url.isNotEmpty) {
                            try {
                              await launchUrl(Uri.parse(url),
                                  mode: LaunchMode.externalApplication);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Dosya açılamadı')),
                              );
                            }
                          }
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Belgeyi Sil"),
                                content: const Text(
                                    "Bu belgeyi silmek istediğinize emin misiniz?"),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("İptal")),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Sil")),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _itemsService.deleteDocument(
                                itemId: widget.itemId,
                                doc: doc,
                              );
                            }
                          },
                        ),
                      ),
                    )),

                const SizedBox(height: 40),

                if (_isEditing) ...[
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Kaydet",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text("İptal"),
                  ),
                ] else
                  TextButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label:
                        const Text("Sil", style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = false,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    // If not enabled, show as read-only container
    if (!enabled) {
      if (controller.text.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 8),
            Text(controller.text,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
    );
  }
}
