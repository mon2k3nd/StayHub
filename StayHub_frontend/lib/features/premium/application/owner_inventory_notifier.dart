import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class InventoryItem {
  final String id;
  final String name;
  final String category; // 'Nội thất', 'Điện tử', 'Thiết bị vệ sinh'
  final int quantity;
  final int inUse;
  final int broken;
  final double unitPrice;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.inUse,
    required this.broken,
    required this.unitPrice,
  });

  int get available => quantity - inUse - broken;

  InventoryItem copyWith({int? quantity, int? inUse, int? broken}) {
    return InventoryItem(
      id: id,
      name: name,
      category: category,
      quantity: quantity ?? this.quantity,
      inUse: inUse ?? this.inUse,
      broken: broken ?? this.broken,
      unitPrice: unitPrice,
    );
  }
}

class InventoryState {
  final bool isLoading;
  final List<InventoryItem> items;

  const InventoryState({this.isLoading = false, this.items = const []});

  InventoryState copyWith({bool? isLoading, List<InventoryItem>? items}) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }
}

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  build() {
    unawaited(Future.microtask(_loadInventory));
    return const InventoryState();
  }

  Future<void> _loadInventory() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final mockItems = [
      const InventoryItem(
        id: 'i1',
        name: 'Máy lạnh Daikin 1.5HP',
        category: 'Điện tử',
        quantity: 50,
        inUse: 45,
        broken: 2,
        unitPrice: 8500000,
      ),
      const InventoryItem(
        id: 'i2',
        name: 'Giường gỗ 1m6',
        category: 'Nội thất',
        quantity: 80,
        inUse: 75,
        broken: 0,
        unitPrice: 2200000,
      ),
      const InventoryItem(
        id: 'i3',
        name: 'Tủ lạnh Aqua 90L',
        category: 'Điện tử',
        quantity: 40,
        inUse: 38,
        broken: 1,
        unitPrice: 2500000,
      ),
      const InventoryItem(
        id: 'i4',
        name: 'Khóa cửa vân tay',
        category: 'Thiết bị',
        quantity: 100,
        inUse: 98,
        broken: 2,
        unitPrice: 1500000,
      ),
    ];

    // if (!mounted) return;
    state = state.copyWith(isLoading: false, items: mockItems);
  }

  void reportBroken(String id) {
    final idx = state.items.indexWhere((i) => i.id == id);
    if (idx == -1) return;

    final item = state.items[idx];
    if (item.available <= 0 && item.inUse <= 0) {
      return; // Cannot break what we don't have
    }

    final updated = List<InventoryItem>.from(state.items);
    updated[idx] = item.copyWith(
      broken: item.broken + 1,
      inUse: item.inUse > 0 ? item.inUse - 1 : item.inUse,
    );
    state = state.copyWith(items: updated);
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(
  InventoryNotifier.new,
);
