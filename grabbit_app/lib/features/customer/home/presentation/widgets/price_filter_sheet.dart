import 'package:flutter/material.dart';

class PriceFilterSheet extends StatefulWidget {
  const PriceFilterSheet({
    super.key,
    required this.onApply,
    required this.onClear,
    this.initialMin,
    this.initialMax,
  });

  final void Function(double? min, double? max) onApply;
  final VoidCallback onClear;
  final double? initialMin;
  final double? initialMax;

  @override
  State<PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<PriceFilterSheet> {
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialMin != null) _minController.text = widget.initialMin!.toStringAsFixed(0);
    if (widget.initialMax != null) _maxController.text = widget.initialMax!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Price range', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(onPressed: widget.onClear, child: const Text('Clear')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min (Br)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max (Br)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final min = double.tryParse(_minController.text.trim());
                  final max = double.tryParse(_maxController.text.trim());
                  widget.onApply(min, max);
                },
                child: const Text('Apply'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
