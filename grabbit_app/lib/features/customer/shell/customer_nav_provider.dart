import 'package:flutter/foundation.dart';

/// Allows any screen to request switching the bottom nav tab (e.g. after placing order).
class CustomerNavProvider with ChangeNotifier {
  int? _requestedTabIndex;

  int? get requestedTabIndex => _requestedTabIndex;

  void requestTab(int index) {
    _requestedTabIndex = index;
    notifyListeners();
  }

  void clearRequest() {
    _requestedTabIndex = null;
    notifyListeners();
  }
}
