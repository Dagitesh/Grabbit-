import 'package:flutter/material.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/utils/image_url_utils.dart';

mixin DealFormMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  final categoryController = TextEditingController();
  final originalPriceController = TextEditingController();
  final discountedPriceController = TextEditingController();
  final quantityController = TextEditingController();
  DateTime? expiryDate;

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    locationController.dispose();
    categoryController.dispose();
    originalPriceController.dispose();
    discountedPriceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  String? validateTitle(String? v) {
    if (v == null || v.trim().isEmpty) return 'Title is required';
    return null;
  }

  String? validateOriginalPrice(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Must be > 0';
    return null;
  }

  String? validateDiscountedPrice(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Must be > 0';
    final orig = double.tryParse(originalPriceController.text);
    if (orig != null && n >= orig) return 'Must be less than original';
    return null;
  }

  String? validateQuantity(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = int.tryParse(v);
    if (n == null || n <= 0) return 'Must be > 0';
    return null;
  }

  String? validateExpiry(DateTime? d) {
    if (d == null) return 'Required';
    if (d.isBefore(DateTime.now())) return 'Must be in the future';
    return null;
  }

  Widget buildForm(
    BuildContext context, {
    required VoidCallback onSave,
    required String saveLabel,
    required bool saving,
    List<String> imageUrls = const [],
    Future<void> Function()? onAddImage,
    void Function(int)? onRemoveImage,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: validateTitle,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the item, condition, and any relevant details',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            if (onAddImage != null) ...[
              const SizedBox(height: 16),
              const Text('Pictures', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...List.generate(imageUrls.length, (i) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            resolveImageUrl(imageUrls[i]),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(width: 80, height: 80, child: Icon(Icons.broken_image)),
                          ),
                        ),
                        if (onRemoveImage != null)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => onRemoveImage(i),
                              child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: () async {
                      await onAddImage();
                      if (context.mounted) setState(() {});
                    },
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
            ],
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g. Addis Ababa area or store address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Bakery, Veggies, Meals, Dairy, Meat',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: originalPriceController,
              decoration: const InputDecoration(
                labelText: 'Original price (Br)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: validateOriginalPrice,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: discountedPriceController,
              decoration: const InputDecoration(
                labelText: 'Discounted price (Br)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: validateDiscountedPrice,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity available',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: validateQuantity,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                expiryDate == null
                    ? 'Expiry date'
                    : 'Expiry: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => expiryDate = picked);
                }
              },
            ),
            if (validateExpiry(expiryDate) != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  validateExpiry(expiryDate)!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving
                  ? null
                  : () {
                      if (!formKey.currentState!.validate()) return;
                      if (validateExpiry(expiryDate) != null) return;
                      onSave();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(saveLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// formKey is defined in the mixin above.
