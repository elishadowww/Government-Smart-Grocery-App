import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/shopping_provider.dart';

/// Persistent cart entry point for the app bar — icon plus an item-count
/// badge — so the cart is reachable from wherever the user is without
/// opening the nav drawer, matching typical e-commerce app placement.
class CartAppBarAction extends ConsumerWidget {
  const CartAppBarAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
      tooltip: 'Cart',
      onPressed: () => context.push('/cart'),
    );
  }
}
