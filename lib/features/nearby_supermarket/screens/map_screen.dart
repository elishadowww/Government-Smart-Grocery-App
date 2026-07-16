import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/supermarket_model.dart';
import '../services/location_service.dart';
import '../services/supermarket_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/map_header.dart';
import '../widgets/route_button.dart';
import '../widgets/search_bar.dart';
import '../widgets/store_card.dart';
import '../widgets/supermarket_bottom_sheet.dart';
import 'supermarket_detail_screen.dart';
import '../widgets/filter_bottom_sheet.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final SupermarketService _supermarketService =
  SupermarketService();

  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};

  final TextEditingController _searchController =
  TextEditingController();

  List<SupermarketModel> _supermarkets = [];

  List<SupermarketModel> _filteredSupermarkets = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = "All";
  bool _openOnly = false;
  double _minimumRating = 0;
  double _maximumDistance = 10;

  static const CameraPosition _initialCamera =
  CameraPosition(
    target: LatLng(
      5.9804,
      116.0735,
    ),
    zoom: 14,
  );

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
    super.dispose();
  }

  Future<void> _loadNearbySupermarkets() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final position =
      await _locationService.getCurrentLocation();

      final supermarkets =
      await _supermarketService
          .getNearbySupermarkets(
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
      _error = e.toString();
      debugPrint(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterStores(String keyword) {
    _applyFilters();
  }

  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;

      if (category == "All") {
        _filteredSupermarkets = List.from(_supermarkets);
      } else {
        _filteredSupermarkets = _supermarkets.where((store) {
          final name = store.name.toLowerCase();

          switch (category) {
            case "Hypermarket":
              return name.contains("hypermarket");

            case "Convenience":
              return name.contains("7-Eleven") ||
                  name.contains("orange Convenience Store") ||
                  name.contains("convenience");

            case "Grocery":
              return !name.contains("hypermarket") &&
                  !name.contains("7-eleven") &&
                  !name.contains("kk");

            default:
              return true;
          }
        }).toList();
      }

      _buildMarkers();
    });
  }

  void _applyFilters() {
    final keyword = _searchController.text.toLowerCase();

    setState(() {
      _filteredSupermarkets = _supermarkets.where((store) {
        final name = store.name.toLowerCase();
        final address = store.address.toLowerCase();

        // Search filter
        final matchesSearch =
            keyword.isEmpty ||
                name.contains(keyword) ||
                address.contains(keyword);

        // Category filter
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
            store.distance <= _maximumDistance;

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
          markerId: MarkerId(
            supermarket.id,
          ),
          position: LatLng(
            supermarket.latitude,
            supermarket.longitude,
          ),
          infoWindow: InfoWindow(
            title: supermarket.name,
            snippet: supermarket.address,
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
      SupermarketModel supermarket,
      ) {
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
        title: const Text(
          "Nearby Supermarkets",
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [

          /// Search + Category
          MapHeader(
            searchController: _searchController,
            selectedCategory: _selectedCategory,
            onSearchChanged: (value) {
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

          Expanded(
            child: Stack(
              children: [

                GoogleMap(
                  initialCameraPosition:
                  _initialCamera,

                  onMapCreated:
                      (GoogleMapController controller) {
                    _mapController = controller;
                  },

                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,

                  zoomControlsEnabled: true,

                  compassEnabled: true,

                  buildingsEnabled: true,

                  mapToolbarEnabled: false,

                  markers: _markers,
                ),

                if (_isLoading)
                  const Center(
                    child:
                    CircularProgressIndicator(),
                  ),

                if (_error != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Card(
                      color: Colors.red.shade100,
                      elevation: 3,
                      child: Padding(
                        padding:
                        const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          style:
                          const TextStyle(
                            color: Colors.red,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!_isLoading &&
                    _error == null &&
                    _filteredSupermarkets
                        .isEmpty)
                  const Center(
                    child: Card(
                      child: Padding(
                        padding:
                        EdgeInsets.all(20),
                        child: Text(
                          "No supermarkets found.",
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black12,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "Nearby Stores",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Expanded(
                            child: ListView.builder(
                              itemCount:
                              _filteredSupermarkets.length,

                              itemBuilder:
                                  (context, index) {
                                final supermarket =
                                _filteredSupermarkets[
                                index];

                                return StoreCard(
                                  supermarket: supermarket,

                                  onTap: () {
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
