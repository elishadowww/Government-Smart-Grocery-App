import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/localization/app_strings.dart';
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

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {

  final LocationService _locationService =
  LocationService();

  final SupermarketService _supermarketService =
  SupermarketService();

  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};

  static const CameraPosition _initialCamera =
  CameraPosition(
    target: LatLng(
      5.9804,
      116.0735,
    ),
    zoom: 14,
  );

  final TextEditingController _searchController =
  TextEditingController();

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

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _loadNearbySupermarkets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();

    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final position =
      await _locationService.getCurrentLocation();

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              position.latitude,
              position.longitude,
            ),
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

      final position =
      await _locationService.getCurrentLocation();

      final supermarkets =
      await _supermarketService.getNearbySupermarkets(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _supermarkets = supermarkets;
      _filteredSupermarkets = supermarkets;

      _buildMarkers();

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              position.latitude,
              position.longitude,
            ),
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
    final keyword =
    _searchController.text.toLowerCase();

    setState(() {
      _filteredSupermarkets =
          _supermarkets.where((store) {
            final name = store.name.toLowerCase();
            final address =
            store.address.toLowerCase();

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

            final matchesRating =
                store.rating >= _minimumRating;

            final matchesOpen =
                !_openOnly || store.isOpen;

            final matchesDistance =
                store.distance <=
                    _maximumDistance;

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

    for (final supermarket
    in _filteredSupermarkets) {
      _markers.add(
        Marker(
          markerId:
          MarkerId(supermarket.id),

          position: LatLng(
            supermarket.latitude,
            supermarket.longitude,
          ),

          infoWindow: InfoWindow(
            title: supermarket.name,
            snippet:
            "${supermarket.distance.toStringAsFixed(1)} km • ${supermarket.address}",
          ),

          onTap: () {
            _showSupermarketBottomSheet(
              supermarket,
            );
          },
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showSupermarketBottomSheet(
      SupermarketModel supermarket) {
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
                    SupermarketDetailScreen(
                      supermarket: supermarket,
                    ),
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
        title: Text(
          ref.tr('nearby_supermarkets'),
        ),
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
    const Center(
    child: CircularProgressIndicator(),
    ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  0,
                  0,
                  0,
                ),
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
                          onApply: (
                              openOnly,
                              rating,
                              distance,
                              ) {
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
            initialChildSize: 0.32,
            minChildSize: 0.18,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.25, 0.50, 0.75],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            ref.tr('nearby_stores'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${_filteredSupermarkets.length} ${ref.tr('found')}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: _filteredSupermarkets.isEmpty
                          ? Center(
                        child: Text(
                          ref.tr('no_supermarkets_found'),
                        ),
                      )
                          : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(
                            16, 8, 16, 20),
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
              );
            },
          ),
        ],
      ),
    );
  }
}
