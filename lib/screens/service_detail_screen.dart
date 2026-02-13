import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import '../models/service_model.dart';
import '../services/services_service.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _servicesService = ServicesService();
  final _storageService = StorageService();
  String? _coupleId;

  @override
  void initState() {
    super.initState();
    _loadCoupleId();
  }

  Future<void> _loadCoupleId() async {
    final id = await _servicesService.getCoupleIdPublic();
    setState(() {
      _coupleId = id;
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,##0", "tr_TR");
    return '${formatter.format(amount)} ₺';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showEditServiceDialog(Service service) {
    final nameController = TextEditingController(text: service.name);
    final providerController = TextEditingController(text: service.provider);
    final totalAmountController =
        TextEditingController(text: service.totalCost.toString());
    final phoneController = TextEditingController(text: service.contactPhone);
    final emailController = TextEditingController(text: service.contactEmail);
    final websiteController = TextEditingController(text: service.contactWebsite);
    final locationController = TextEditingController(text: service.location);

    DateTime? selectedDeadline = service.paymentDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Hizmeti Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: providerController,
                  decoration: const InputDecoration(
                    labelText: "Hizmet Veren",
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Hizmet",
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: totalAmountController,
                  decoration: const InputDecoration(
                    labelText: "Toplam Tutar",
                    prefixIcon: Icon(Icons.attach_money),
                    suffixText: '₺',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDeadline == null
                        ? "Ödeme Tarihi Seç"
                        : '${selectedDeadline!.day}.${selectedDeadline!.month}.${selectedDeadline!.year}',
                  ),
                  onTap: () async {
                    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: languageProvider.currentLocale,
                    );
                    if (date != null) {
                      setDialogState(() => selectedDeadline = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: "Telefon",
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "E-posta",
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(
                    labelText: "Web Sitesi",
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: "Konum",
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppTexts.cancelBtn),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final updatedService = service.copyWith(
                  name: nameController.text,
                  provider: providerController.text,
                  totalCost: double.tryParse(totalAmountController.text),
                  paymentDate: selectedDeadline,
                  contactPhone: phoneController.text,
                  contactEmail: emailController.text,
                  contactWebsite: websiteController.text,
                  location: locationController.text,
                );

                final error = await _servicesService.updateService(updatedService);

                if (!mounted) return;
                Navigator.pop(context); // Close loading

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hizmet güncellendi')),
                  );
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentDialog(Service service) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final remainingAmount = service.remainingAmount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTexts.addPayment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppTexts.remainingDebt}: ${_formatCurrency(remainingAmount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: AppTexts.paymentAmount,
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: '₺',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: AppTexts.paymentNote,
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 2,
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
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir tutar giriniz')),
                );
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final error = await _servicesService.addPayment(
                serviceId: widget.serviceId,
                amount: amount,
                note: noteController.text,
              );

              if (!mounted) return;
              Navigator.pop(context); // Close loading

              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ödeme eklendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(AppTexts.addBtn),
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
                  labelText: "Belge Adı (Örn: Sözleşme)",
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
                  path: 'services/${widget.serviceId}/docs',
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
                final error = await _servicesService.addDocument(
                  serviceId: widget.serviceId,
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTexts.deleteBtn),
        content: const Text('Bu hizmeti silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTexts.cancelBtn),
          ),
          ElevatedButton(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final error =
                  await _servicesService.deleteService(widget.serviceId);

              if (!mounted) return;
              Navigator.pop(context); // Close loading

              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              } else {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to list
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppTexts.deleteBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_coupleId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.serviceName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .doc(_coupleId)
          .collection('services')
          .doc(widget.serviceId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.serviceName)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.serviceName)),
            body: const Center(child: Text('Service not found')),
          );
        }

        final service = Service.fromFirestore(snapshot.data!);
        final totalAmount = service.totalCost;
        final paidAmount = service.paidAmount;
        final remainingAmount = service.remainingAmount;
        final payments = service.payments;
        // documents are stored as a List<DocumentAttachment> in the model
        final documents = service.documents;
        final progress = totalAmount > 0 ? paidAmount / totalAmount : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(service.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditServiceDialog(service),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _showDeleteConfirmation,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Summary Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTexts.remainingDebt,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(remainingAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Progress
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTexts.totalPaid,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(paidAmount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Toplam Tutar",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(totalAmount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Details Section
                const Text(
                  "Detaylar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.business, "Hizmet Veren",
                            service.provider),
                        const Divider(),
                        _buildDetailRow(Icons.phone, AppTexts.contactPhone,
                            service.contactPhone ?? '-'),
                        const Divider(),
                        _buildDetailRow(Icons.email, AppTexts.contactEmail,
                            service.contactEmail ?? '-'),
                        const Divider(),
                        _buildDetailRow(Icons.language, AppTexts.contactWebsite,
                            service.contactWebsite ?? '-'),
                        const Divider(),
                        _buildDetailRow(Icons.location_on, AppTexts.location,
                            service.location ?? '-'),
                        const Divider(),
                        _buildDetailRow(Icons.calendar_today, "Ödeme Tarihi",
                            _formatDate(service.paymentDate)),
                      ],
                    ),
                  ),
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
                              await _servicesService.deleteDocument(
                                serviceId: widget.serviceId,
                                doc: doc,
                              );
                              // Using doc object directly
                            }
                          },
                        ),
                      ),
                    )),

                const SizedBox(height: 24),

                // Payment History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTexts.paymentHistory,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (remainingAmount > 0)
                      TextButton.icon(
                        onPressed: () => _showAddPaymentDialog(service),
                        icon: const Icon(Icons.add),
                        label: Text(AppTexts.addPayment),
                      ),
                  ],
                ),
                if (payments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      AppTexts.noPayments,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ...payments.map((payment) {
                  // Payment is a Payment object here
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle,
                            color: Colors.green),
                      ),
                      title: Text(
                        _formatCurrency(payment.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      subtitle: Text(payment.note ?? ''),
                      trailing: Text(
                        _formatDate(payment.date),
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
