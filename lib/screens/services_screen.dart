import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/texts.dart';
import '../models/service_model.dart';
import '../services/services_service.dart';
import 'service_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _servicesService = ServicesService();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  String _formatCurrency(double amount) {
    // 90000 -> 90.000 ₺
    final formatter = NumberFormat("#,##0", "tr_TR");
    return '${formatter.format(amount)} ₺';
  }

  void _showAddServiceDialog() {
    final nameController = TextEditingController(); // Service Name
    final providerController = TextEditingController(); // Provider Name
    final totalAmountController = TextEditingController();
    final depositController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final websiteController = TextEditingController();
    final locationController = TextEditingController();

    // We can keep a hidden category or just set default, since user wants to remove categories from UI view
    String selectedCategory = AppTexts.categoryOther;
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppTexts.addService),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: providerController,
                  decoration: InputDecoration(
                    labelText: "Hizmet Veren (Firma/Kişi)", // Provider
                    prefixIcon: const Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Verilen Hizmet (Açıklama)", // Service Name
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: totalAmountController,
                  decoration: InputDecoration(
                    labelText: AppTexts.totalAmountHint,
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: '₺',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: depositController,
                  decoration: InputDecoration(
                    labelText: AppTexts.depositHint,
                    prefixIcon: const Icon(Icons.payment),
                    suffixText: '₺',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDeadline == null
                        ? AppTexts.paymentDeadlineHint
                        : '${selectedDeadline!.day}.${selectedDeadline!.month}.${selectedDeadline!.year}',
                  ),
                  onTap: () async {
                    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      locale: languageProvider.currentLocale,
                    );
                    if (date != null) {
                      setDialogState(() => selectedDeadline = date);
                    }
                  },
                ),
                // Optional Details
                ExpansionTile(
                  title: const Text("Ekstra Detaylar (İletişim)"),
                  children: [
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: AppTexts.contactPhone,
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: AppTexts.contactEmail,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: websiteController,
                      decoration: InputDecoration(
                        labelText: AppTexts.contactWebsite,
                        prefixIcon: const Icon(Icons.language),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: AppTexts.location,
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                  ],
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
                if (providerController.text.isEmpty ||
                    totalAmountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Hizmet veren ve tutar alanları zorunludur.'),
                    ),
                  );
                  return;
                }

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  useRootNavigator: true,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final double totalAmount =
                    double.tryParse(totalAmountController.text) ?? 0;
                final double deposit =
                    double.tryParse(depositController.text) ?? 0;

                // Create initial payment if deposit > 0
                final List<PaymentRecord> payments = [];
                if (deposit > 0) {
                  payments.add(PaymentRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    amount: deposit,
                    date: DateTime.now(),
                    note: 'İlk ödeme / Kaparo',
                  ));
                }

                final newService = Service(
                  id: '', // Generated by Firestore
                  name: nameController.text.isEmpty
                      ? "Genel Hizmet"
                      : nameController.text,
                  provider: providerController.text,
                  totalCost: totalAmount,
                  paidAmount: deposit,
                  // Status is derived in getters usually, but we need to set a string here.
                  // 'pending' or 'paid'. Logic: if remaining > 0 then pending.
                  status: (totalAmount - deposit) <= 0 ? 'paid' : 'pending',
                  paymentDate: selectedDeadline,
                  contactPhone: phoneController.text,
                  contactEmail: emailController.text,
                  contactWebsite: websiteController.text,
                  location: locationController.text,
                  payments: payments,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final error = await _servicesService.addService(newService);

                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop(); // Close loading

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hizmet başarıyla eklendi!')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTexts.servicesTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Hizmet veya firma ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    isDark ? Colors.grey.shade900 : Colors.grey.shade200,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Services list
          Expanded(
            child: StreamBuilder<List<Service>>(
              stream: _servicesService.getServicesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppTexts.noServices,
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Filter locally based on search query
                final services = snapshot.data!.where((service) {
                  final name = service.name.toLowerCase();
                  final provider = service.provider.toLowerCase();
                  return name.contains(_searchQuery) ||
                      provider.contains(_searchQuery);
                }).toList();

                if (services.isEmpty) {
                  return const Center(child: Text('Sonuç bulunamadı.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return _buildServiceCard(
                      services[index],
                      isDark,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddServiceDialog,
        icon: const Icon(Icons.add),
        label: Text(AppTexts.addBtn),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildServiceCard(Service service, bool isDark) {
    final totalAmount = service.totalCost;
    final remainingAmount = service.remainingAmount; // getter in model
    final provider = service.provider;
    final name = service.name;
    final paymentDeadline = service.paymentDate;

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
              builder: (_) => ServiceDetailScreen(
                serviceId: service.id,
                serviceName: name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (paymentDeadline != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(paymentDeadline),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(totalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (remainingAmount > 0)
                    Text(
                      'Kalan: ${_formatCurrency(remainingAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const Text(
                      'Ödendi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}.${date.month}.${date.year}';
  }
}
