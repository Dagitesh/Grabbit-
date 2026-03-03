import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kFavoritesKey = 'grabbit_favorite_deal_ids';
const String _kFavoritesDataKey = 'grabbit_favorite_deal_data';

class FavoriteItem {
  FavoriteItem({required this.id, required this.title, required this.discountedPrice});
  final String id;
  final String title;
  final double discountedPrice;
}

class FavoritesProvider with ChangeNotifier {
  FavoritesProvider() {
    _load();
  }

  final Set<String> _ids = {};
  final Map<String, FavoriteItem> _items = {};
  bool _loaded = false;

  Set<String> get favoriteIds => Set.unmodifiable(_ids);
  List<FavoriteItem> get favoriteItems => _ids.map((id) => _items[id]).whereType<FavoriteItem>().toList();
  bool get loaded => _loaded;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kFavoritesKey);
    if (list != null) _ids.addAll(list);
    final jsonList = prefs.getStringList(_kFavoritesDataKey);
    if (jsonList != null) {
      for (final s in jsonList) {
        try {
          final parts = s.split('|');
          if (parts.length >= 3) {
            _items[parts[0]] = FavoriteItem(
              id: parts[0],
              title: parts[1].replaceAll(r'\n', '\n'),
              discountedPrice: double.tryParse(parts[2]) ?? 0,
            );
          }
        } catch (_) {}
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavoritesKey, _ids.toList());
    final data = _ids.map((id) {
      final item = _items[id];
      return item != null ? '${item.id}|${item.title.replaceAll('\n', r'\n')}|${item.discountedPrice}' : '';
    }).where((s) => s.isNotEmpty).toList();
    await prefs.setStringList(_kFavoritesDataKey, data);
  }

  bool isFavorite(String dealId) => _ids.contains(dealId);

  Future<void> toggle(String dealId, {String? title, double? discountedPrice}) async {
    if (_ids.contains(dealId)) {
      _ids.remove(dealId);
      _items.remove(dealId);
    } else {
      _ids.add(dealId);
      if (title != null && discountedPrice != null) {
        _items[dealId] = FavoriteItem(id: dealId, title: title, discountedPrice: discountedPrice);
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> add(String dealId, {String? title, double? discountedPrice}) async {
    _ids.add(dealId);
    if (title != null && discountedPrice != null) {
      _items[dealId] = FavoriteItem(id: dealId, title: title, discountedPrice: discountedPrice);
    }
    await _save();
    notifyListeners();
  }

  Future<void> remove(String dealId) async {
    _ids.remove(dealId);
    _items.remove(dealId);
    await _save();
    notifyListeners();
  }
}
