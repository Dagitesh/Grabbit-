import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/api/vendor_api_service.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/utils/image_url_utils.dart';
import 'package:grabbit_app/core/widgets/loading_overlay.dart';
import 'package:grabbit_app/features/customer/home/data/deal_model.dart';
import 'package:grabbit_app/features/vendor/deals/providers/vendor_deal_provider.dart';

class EditDealScreen extends StatefulWidget {
  const EditDealScreen({super.key, required this.dealId});

  final String dealId;

  @override
  State<EditDealScreen> createState() => _EditDealScreenState();
}

class _EditDealScreenState extends State<EditDealScreen> {
  final _api = VendorApiService();
  DealModel? _deal;
  bool _loading = true;
  String? _error;
  final List<String> _imageUrls = [];

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _expiryDate;
  final _formKey = GlobalKey<FormState>();

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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getDeal(widget.dealId);
      _deal = DealModel.fromJson(data);
      _titleController.text = _deal!.title;
      _descController.text = _deal!.description ?? '';
      _locationController.text = _deal!.location ?? '';
      _categoryController.text = _deal!.category ?? '';
      _originalPriceController.text = _deal!.originalPrice.toString();
      _discountedPriceController.text = _deal!.discountedPrice.toString();
      _quantityController.text = _deal!.quantityAvailable.toString();
      _expiryDate = _deal!.expiryDate;
      _imageUrls
        ..clear()
        ..addAll(_deal!.images ?? []);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _deal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Deal'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: const LoadingOverlay(message: 'Loading...'),
      );
    }
    if (_deal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Deal'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: Center(child: Text(_error ?? 'Failed to load deal')),
      );
    }

    final provider = context.watch<VendorDealProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Deal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the item and condition',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const Text('Pictures', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...List.generate(_imageUrls.length, (i) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            resolveImageUrl(_imageUrls[i]),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(width: 80, height: 80, child: Icon(Icons.broken_image)),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageUrls.removeAt(i)),
                            child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: _addImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_photo_alternate, size: 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. São Paulo, SP', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category', hintText: 'e.g. Bakery, Meals', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originalPriceController,
                decoration: const InputDecoration(labelText: 'Original price (Br)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  return (n == null || n <= 0) ? 'Must be > 0' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountedPriceController,
                decoration: const InputDecoration(labelText: 'Discounted price (Br)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Must be > 0';
                  final orig = double.tryParse(_originalPriceController.text);
                  if (orig != null && n >= orig) return 'Must be less than original';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity available', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  return (n == null || n < 0) ? 'Must be >= 0' : null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_expiryDate == null
                    ? 'Expiry date'
                    : 'Expiry: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _expiryDate = picked);
                },
              ),
              if (!_deal!.isExpired)
                SwitchListTile(
                  title: const Text('Active'),
                  value: _deal!.isActive,
                  onChanged: (value) async {
                    await provider.updateDeal(widget.dealId, isActive: value);
                    if (mounted) await _load();
                  },
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: provider.saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_expiryDate == null) return;
                        final ok = await provider.updateDeal(
                          widget.dealId,
                          title: _titleController.text.trim(),
                          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
                          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
                          originalPrice: double.tryParse(_originalPriceController.text),
                          discountedPrice: double.tryParse(_discountedPriceController.text),
                          quantityAvailable: int.tryParse(_quantityController.text),
                          expiryDate: _expiryDate,
                          images: _imageUrls,
                        );
                        if (!mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deal updated')));
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.error ?? 'Failed')),
                          );
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: provider.saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
