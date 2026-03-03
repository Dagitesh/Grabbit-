import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/api/vendor_api_service.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/features/vendor/deals/providers/vendor_deal_provider.dart';
import 'package:grabbit_app/features/vendor/deals/presentation/screens/deal_form_mixin.dart';

class CreateDealScreen extends StatefulWidget {
  const CreateDealScreen({super.key});

  @override
  State<CreateDealScreen> createState() => _CreateDealScreenState();
}

class _CreateDealScreenState extends State<CreateDealScreen> with DealFormMixin<CreateDealScreen> {
  final List<String> _imageUrls = [];
  final _api = VendorApiService();

  @override
  void initState() {
    super.initState();
    expiryDate = DateTime.now().add(const Duration(days: 7));
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (xFile == null || !mounted) return;
    final url = await _api.uploadFile(xFile);
    if (url != null && mounted) {
      setState(() => _imageUrls.add(url));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Deal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: buildForm(
        context,
        onSave: () async {
          final ok = await context.read<VendorDealProvider>().createDeal(
                title: titleController.text.trim(),
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
                originalPrice: double.tryParse(originalPriceController.text) ?? 0,
                discountedPrice: double.tryParse(discountedPriceController.text) ?? 0,
                quantityAvailable: int.tryParse(quantityController.text) ?? 0,
                expiryDate: expiryDate!,
                images: _imageUrls.isEmpty ? null : _imageUrls,
              );
          if (!mounted) return;
          if (ok != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deal created successfully')),
            );
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.read<VendorDealProvider>().error ?? 'Failed')),
            );
          }
        },
        saveLabel: 'Create',
        saving: context.watch<VendorDealProvider>().saving,
        imageUrls: _imageUrls,
        onAddImage: _addImage,
        onRemoveImage: (i) => setState(() => _imageUrls.removeAt(i)),
      ),
    );
  }
}
