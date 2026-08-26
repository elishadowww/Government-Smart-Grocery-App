import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/supermarket_model.dart';
import '../services/location_service.dart';
import '../services/supermarket_service.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/location_error_card.dart';
import '../widgets/map_header.dart';
import '../widgets/route_button.dart';
import '../widgets/store_card.dart';
import '../widgets/supermarket_bottom_sheet.dart';

import 'supermarket_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();

  final SupermarketService _supermarketService = SupermarketService();

  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(5.9804, 116.0735),
    zoom: 14,
  );

  final TextEditingController _searchController = TextEditingController();

  // DraggableScrollableSheet only detects drag-to-resize through the
  // Scrollable it's given (the ListView below) — the grey handle and header
  // sit outside that ListView, so without this controller, dragging the
  // handle itself (the part users naturally reach for) does nothing at all.
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const double _sheetMinSize = 0.18;
  static const double _sheetMaxSize = 0.85;
  static const List<double> _sheetMidSnapSizes = [0.25, 0.50, 0.75];

  List<SupermarketModel> _supermarkets = [];
  List<SupermarketModel> _filteredSupermarkets = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = "All";
  bool _openOnly = false;
  double _minimumRating = 0;
  double _maximumDistance = 10;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbySupermarkets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _sheetController.dispose();

    super.dispose();
  }

  void _onSheetHandleDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (screenHeight == 0) return;

    final delta = (details.primaryDelta ?? 0) / screenHeight;
    final newSize = (_sheetController.size - delta).clamp(
      _sheetMinSize,
      _sheetMaxSize,
    );
    _sheetController.jumpTo(newSize);
  }

  void _onSheetHandleDragEnd(DragEndDetails details) {
    final snapSizes = [_sheetMinSize, ..._sheetMidSnapSizes, _sheetMaxSize];
    final currentSize = _sheetController.size;

    var nearest = snapSizes.first;
    var smallestDiff = (currentSize - nearest).abs();
    for (final size in snapSizes.skip(1)) {
      final diff = (currentSize - size).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        nearest = size;
      }
    }

    _sheetController.animateTo(
      nearest,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          ),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadNearbySupermarkets() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final position = await _locationService.getCurrentLocation();

      final supermarkets = await _supermarketService.getNearbySupermarkets(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _supermarkets = supermarkets;
      _filteredSupermarkets = supermarkets;

      _buildMarkers();

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }

      debugPrint(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final keyword = _searchController.text.toLowerCase();

    setState(() {
      _filteredSupermarkets = _supermarkets.where((store) {
        final name = store.name.toLowerCase();
        final address = store.address.toLowerCase();

        final matchesSearch =
            keyword.isEmpty ||
            name.contains(keyword) ||
            address.contains(keyword);

        bool matchesCategory = true;

        switch (_selectedCategory) {
          case "Hypermarket":
            matchesCategory =
                name.contains("hypermarket") ||
                name.contains("lotus") ||
                name.contains("aeon") ||
                name.contains("servay");
            break;

          case "Convenience":
            matchesCategory =
                name.contains("7-eleven") ||
                name.contains("family") ||
                name.contains("speedmart") ||
                name.contains("orange") ||
                name.contains("kk") ||
                name.contains("mart");
            break;

          case "Grocery":
            matchesCategory =
                !name.contains("hypermarket") &&
                !name.contains("lotus") &&
                !name.contains("aeon") &&
                !name.contains("family") &&
                !name.contains("7-eleven") &&
                !name.contains("speedmart");
            break;

          case "All":
          default:
            matchesCategory = true;
        }

        final matchesRating = store.rating >= _minimumRating;

        final matchesOpen = !_openOnly || store.isOpen;

        final matchesDistance = store.distance <= _maximumDistance;

        return matchesSearch &&
            matchesCategory &&
            matchesRating &&
            matchesOpen &&
            matchesDistance;
      }).toList();

      _buildMarkers();
    });
  }

  void _buildMarkers() {
    _markers.clear();

    for (final supermarket in _filteredSupermarkets) {
      _markers.add(
        Marker(
          markerId: MarkerId(supermarket.id),

          position: LatLng(supermarket.latitude, supermarket.longitude),

          infoWindow: InfoWindow(
            title: supermarket.name,
            snippet:
                "${supermarket.distance.toStringAsFixed(1)} km • ${supermarket.address}",
          ),

          onTap: () {
            _showSupermarketBottomSheet(supermarket);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showSupermarketBottomSheet(SupermarketModel supermarket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SupermarketBottomSheet(
          supermarket: supermarket,

          onNavigate: () async {
            Navigator.pop(context);

            await RouteButton.navigate(
              latitude: supermarket.latitude,
              longitude: supermarket.longitude,
            );
          },

          onViewPrices: () {
            Navigator.pop(context);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SupermarketDetailScreen(supermarket: supermarket),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Supermarkets"),
        centerTitle: true,
      ),

      body: _errorMessage != null
          ? LocationErrorCard(
              message: _errorMessage!,
              onRetry: _loadNearbySupermarkets,
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: _initialCamera,

                    onMapCreated: (controller) {
                      _mapController = controller;
                    },

                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,

                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    buildingsEnabled: true,
                    mapToolbarEnabled: false,

                    markers: _markers,
                  ),
                ),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: MapHeader(
                        searchController: _searchController,
                        selectedCategory: _selectedCategory,

                        onSearchChanged: (_) {
                          _applyFilters();
                        },

                        onCategoryChanged: (value) {
                          _selectedCategory = value;
                          _applyFilters();
                        },

                        onFilterPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) {
                              return FilterBottomSheet(
                                openOnly: _openOnly,
                                minimumRating: _minimumRating,
                                maximumDistance: _maximumDistance,
                                onApply: (openOnly, rating, distance) {
                                  _openOnly = openOnly;
                                  _minimumRating = rating;
                                  _maximumDistance = distance;
                                  _applyFilters();
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 16,
                  bottom: 280,
                  child: FloatingActionButton.small(
                    heroTag: "locationButton",
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 4,
                    onPressed: _goToCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),

                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.32,
                  minChildSize: _sheetMinSize,
                  maxChildSize: _sheetMaxSize,
                  snap: true,
                  snapSizes: _sheetMidSnapSizes,
                  builder: (context, scrollController) {
                    // A RepaintBoundary + Material(elevation: ...) instead of a
                    // manually blurred BoxShadow: the sheet's Container is rebuilt
                    // on every frame of the drag (its size changes continuously),
                    // and re-rasterizing a blurred shadow that often — on top of
                    // the live GoogleMap underneath — is what made dragging feel
                    // janky. Material's elevation shadow is cast by the engine
                    // instead of blurred per frame, so it's far cheaper to animate.
                    return RepaintBoundary(
                      child: Material(
                        color: Colors.white,
                        elevation: 12,
                        shadowColor: Colors.black45,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // The handle + title row is a dedicated drag
                            // target (via _sheetController) rather than
                            // relying on DraggableScrollableSheet's built-in
                            // detection, which only responds to drags inside
                            // the ListView below — dragging the grey bar
                            // itself did nothing before this.
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragUpdate: _onSheetHandleDragUpdate,
                              onVerticalDragEnd: _onSheetHandleDragEnd,
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),

                                  Container(
                                    width: 45,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          "Nearby Stores",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          "${_filteredSupermarkets.length} found",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            Expanded(
                              child: _filteredSupermarkets.isEmpty
                                  ? const Center(
                                      child: Text("No supermarkets found."),
                                    )
                                  : ListView.builder(
                                      controller: scrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        20,
                                      ),
                                      itemCount: _filteredSupermarkets.length,
                                      itemBuilder: (context, index) {
                                        final supermarket =
                                            _filteredSupermarkets[index];

                                        return StoreCard(
                                          supermarket: supermarket,
                                          onTap: () {
                                            _mapController?.animateCamera(
                                              CameraUpdate.newLatLngZoom(
                                                LatLng(
                                                  supermarket.latitude,
                                                  supermarket.longitude,
                                                ),
                                                17,
                                              ),
                                            );

                                            _showSupermarketBottomSheet(
                                              supermarket,
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
