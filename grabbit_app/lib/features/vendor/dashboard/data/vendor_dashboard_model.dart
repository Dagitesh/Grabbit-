import 'package:grabbit_app/features/vendor/profile/data/vendor_profile_model.dart';

class VendorDashboardModel {
  VendorDashboardModel({
    required this.vendor,
    required this.totalDeals,
    required this.activeDeals,
    required this.expiredDeals,
    required this.totalOrders,
    this.revenue,
  });

  final VendorProfileModel vendor;
  final int totalDeals;
  final int activeDeals;
  final int expiredDeals;
  final int totalOrders;
  final double? revenue;

  factory VendorDashboardModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? json;
    return VendorDashboardModel(
      vendor: json['vendor'] != null
          ? VendorProfileModel.fromJson(json['vendor'] as Map<String, dynamic>)
          : VendorProfileModel(
              id: '',
              userId: '',
              businessName: '',
              phone: '',
              isApproved: true,
            ),
      totalDeals: (stats['totalDeals'] as num?)?.toInt() ?? 0,
      activeDeals: (stats['activeDeals'] as num?)?.toInt() ?? 0,
      expiredDeals: (stats['expiredDeals'] as num?)?.toInt() ?? 0,
      totalOrders: (stats['totalOrders'] as num?)?.toInt() ?? 0,
      revenue: (stats['revenue'] as num?)?.toDouble(),
    );
  }
}
