import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabbit_app/core/theme/app_colors.dart';
import 'package:grabbit_app/core/utils/image_url_utils.dart';
import 'package:grabbit_app/features/admin/deals/providers/admin_deals_provider.dart';

class AdminDealsScreen extends StatelessWidget {
  const AdminDealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Deal moderation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminDealsProvider>().loadDeals(refresh: true),
          ),
        ],
      ),
      body: Consumer<AdminDealsProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Review listings, view images, and remove deals that violate policy.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('Show removed deals'),
                subtitle: const Text('Includes deals already taken down by an admin'),
                value: provider.includeRemoved,
                onChanged: provider.setIncludeRemoved,
              ),
              if (provider.error != null && !provider.loading && provider.deals.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(provider.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => provider.loadDeals(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: provider.loading && provider.deals.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        onRefresh: () => provider.loadDeals(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: provider.deals.length,
                          itemBuilder: (context, index) {
                            final deal = provider.deals[index];
                            return _AdminDealCard(
                              deal: deal,
                              reasons: provider.reasons,
                              onRemove: (code) => _confirmRemove(context, provider, deal, code),
                            );
                          },
                        ),
                      ),
              ),
              if (provider.totalPages > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: provider.hasPrevPage && !provider.loading
                            ? () => provider.prevPage()
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Page ${provider.page} / ${provider.totalPages}'),
                      IconButton(
                        onPressed: provider.hasNextPage && !provider.loading
                            ? () => provider.nextPage()
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _confirmRemove(
    BuildContext context,
    AdminDealsProvider provider,
    Map<String, dynamic> deal,
    String reasonCode,
  ) async {
    final id = deal['id'] as String?;
    if (id == null) return;
    final err = await provider.removeDeal(id, reasonCode);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deal removed. Vendor was notified.')),
      );
    }
  }
}

class _AdminDealCard extends StatefulWidget {
  const _AdminDealCard({
    required this.deal,
    required this.reasons,
    required this.onRemove,
  });

  final Map<String, dynamic> deal;
  final List<DealModerationReason> reasons;
  final Future<void> Function(String reasonCode) onRemove;

  @override
  State<_AdminDealCard> createState() => _AdminDealCardState();
}

class _AdminDealCardState extends State<_AdminDealCard> {
  int _imageIndex = 0;

  List<String> _imageUrls() {
    final imgs = widget.deal['images'];
    if (imgs is! List) return [];
    return imgs.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.deal;
    final title = d['title']?.toString() ?? 'Deal';
    final removed = d['removed_by_admin'] == true;
    final reasonLabel = d['admin_removal_reason_label']?.toString();
    final vendor = d['vendor'] is Map ? Map<String, dynamic>.from(d['vendor'] as Map) : null;
    final vendorName = vendor?['full_name']?.toString() ?? vendor?['email']?.toString() ?? 'Vendor';
    final urls = _imageUrls();
    final resolved = resolveImageUrls(urls);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resolved.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        resolved[_imageIndex.clamp(0, resolved.length - 1)],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.broken_image_outlined, size: 48),
                        ),
                      ),
                      if (resolved.length > 1)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(resolved.length, (i) {
                              return GestureDetector(
                                onTap: () => setState(() => _imageIndex = i),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _imageIndex ? Colors.white : Colors.white54,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image_not_supported_outlined, color: AppColors.primary.withOpacity(0.4), size: 40),
              ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Vendor: $vendorName', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            if (d['subcity_name'] != null)
              Text('Subcity: ${d['subcity_name']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            if (d['category_name'] != null)
              Text('Category: ${d['category_name']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            if (removed) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.block, size: 18),
                label: Text(reasonLabel != null ? 'Removed: $reasonLabel' : 'Removed by admin'),
                backgroundColor: Colors.red.shade50,
              ),
            ],
            if (!removed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.reasons.isEmpty
                      ? null
                      : () => _showRemoveDialog(context, title),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove deal…'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showRemoveDialog(BuildContext context, String dealTitle) async {
    if (widget.reasons.isEmpty) return;
    String? selectedCode = widget.reasons.first.code;
    final picked = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Remove deal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'The vendor will be notified with the reason you select. This is stored for audit.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Text(dealTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCode,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: widget.reasons
                          .map(
                            (r) => DropdownMenuItem<String>(
                              value: r.code,
                              child: Text(r.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => selectedCode = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                  onPressed: selectedCode == null ? null : () => Navigator.pop(ctx, selectedCode),
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked != null && picked.isNotEmpty && context.mounted) {
      await widget.onRemove(picked);
    }
  }
}
