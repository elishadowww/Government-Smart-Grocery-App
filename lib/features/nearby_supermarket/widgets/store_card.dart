import 'package:flutter/material.dart';
import '../models/supermarket_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';

class StoreCard extends ConsumerWidget {
  final SupermarketModel supermarket;
  final VoidCallback onTap;

  const StoreCard({
    super.key,
    required this.supermarket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.green,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              /// Store Information
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      supermarket.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          supermarket.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "${supermarket.distance.toStringAsFixed(1)} km",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [

                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          supermarket.rating
                              .toStringAsFixed(1),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: supermarket.isOpen
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius:
                            BorderRadius.circular(30),
                          ),
                          child: Text(
                            supermarket.isOpen
                                ? ref.tr('open')
                                : ref.tr('closed'),
                            style: TextStyle(
                              color: supermarket.isOpen
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight:
                              FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}