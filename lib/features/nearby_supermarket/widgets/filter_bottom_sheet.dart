import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
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
  State<FilterBottomSheet> createState() =>
      _FilterBottomSheetState();
}

class _FilterBottomSheetState
    extends State<FilterBottomSheet> {
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

            const Text(
              "Filter Supermarkets",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            SwitchListTile(
              value: _openOnly,
              title: const Text("Open Now"),
              onChanged: (value) {
                setState(() {
                  _openOnly = value;
                });
              },
            ),

            const SizedBox(height: 10),

            const Text(
              "Minimum Rating",
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
              "${_rating.toStringAsFixed(1)} ★ & Above",
            ),

            const SizedBox(height: 20),

            const Text(
              "Maximum Distance",
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
                    child: const Text("Cancel"),
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
                    child: const Text("Apply"),
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