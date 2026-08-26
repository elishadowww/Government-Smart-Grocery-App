import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final bool openOnly;
  final double minimumRating;
  final double maximumDistance;

  final Function(
      bool openOnly,
      double rating,
      double distance,
      ) onApply;

  const FilterBottomSheet({
    super.key,
    required this.openOnly,
    required this.minimumRating,
    required this.maximumDistance,
    required this.onApply,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() =>
      _FilterBottomSheetState();
}

class _FilterBottomSheetState
    extends ConsumerState<FilterBottomSheet> {
  late bool _openOnly;
  late double _rating;
  late double _distance;

  @override
  void initState() {
    super.initState();

    _openOnly = widget.openOnly;
    _rating = widget.minimumRating;
    _distance = widget.maximumDistance;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius:
                  BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              ref.tr('filter_supermarkets'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            SwitchListTile(
              value: _openOnly,
              title: Text(ref.tr('open_now')),
              onChanged: (value) {
                setState(() {
                  _openOnly = value;
                });
              },
            ),

            const SizedBox(height: 10),

            Text(
              ref.tr('minimum_rating'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Slider(
              value: _rating,
              min: 0,
              max: 5,
              divisions: 10,
              label: _rating.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _rating = value;
                });
              },
            ),

            Text(
              "${_rating.toStringAsFixed(1)} ★ ${ref.tr('and_above')}",
            ),

            const SizedBox(height: 20),

            Text(
              ref.tr('maximum_distance'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Slider(
              value: _distance,
              min: 1,
              max: 10,
              divisions: 9,
              label:
              "${_distance.toInt()} km",
              onChanged: (value) {
                setState(() {
                  _distance = value;
                });
              },
            ),

            Text(
              "${_distance.toInt()} km",
            ),

            const SizedBox(height: 30),

            Row(
              children: [

                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(ref.tr('cancel')),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        _openOnly,
                        _rating,
                        _distance,
                      );

                      Navigator.pop(context);
                    },
                    child: Text(ref.tr('apply')),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}