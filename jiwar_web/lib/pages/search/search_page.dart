import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jiwar_web/widgets/search/search_filter_sheet.dart';
import 'package:jiwar_web/widgets/search/provider_list_card.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../widgets/dialogs/auth_required_dialog.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? query;
  final String? type; // doctor, pharmacy, teacher

  const SearchPage({
    super.key,
    this.query,
    this.type,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  // View State
  bool _isMapView = true;
  
  // Map State
  late MapController _mapController;
  int? _selectedMarkerId;
  static const LatLng _defaultLocation = LatLng(29.0626, 31.0958); // El Wasty

  // Filter State
  String? _selectedType;
  final _searchController = TextEditingController(); 
  
  // Filter Options (populated from Sheet)
  String _sortBy = 'rating';
  RangeValues? _priceRange;
  
  // Data State
  bool _isLoading = false;
  List<SearchResultItem> _results = [];
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedType = widget.type;
    
    if (widget.query != null && widget.query!.isNotEmpty) {
      _searchController.text = widget.query!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    } else {
       WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAllProviders(); 
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _selectedMarkerId = null;
    });

    final query = _searchController.text;
    final result = await _api.search(
      query: query, 
      type: _selectedType ?? 'all',
      sort: _sortBy,
      minPrice: _priceRange?.start,
      maxPrice: _priceRange?.end,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _results = (result.data?['results'] as List).map((r) => SearchResultItem.fromJson(r)).toList();
          
          if (_results.isNotEmpty && _isMapView) {
             _mapController.move(_results.first.location, 14);
          }
        }
      });
    }
  }

  Future<void> _loadAllProviders() async {
     setState(() => _isLoading = true);
     final result = await _api.getAllProviders();
      if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
           List<SearchResultItem> all = (result.data?['providers'] as List).map((r) => SearchResultItem.fromJson(r)).toList();
           
           if (_selectedType != null) {
             _results = all.where((r) => r.type == _selectedType).toList();
           } else {
             _results = all;
           }
        }
      });
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterSheet(
        initialType: _selectedType,
        onApply: (filters) {
          setState(() {
            _selectedType = filters['type'] == 'all' ? null : filters['type'];
            _sortBy = filters['sort'];
            if (filters['min_price'] != null) {
              _priceRange = RangeValues(filters['min_price'], filters['max_price']);
            }
          });
          if (_searchController.text.isNotEmpty) {
            _performSearch();
          } else {
            // Re-filter locally if just "All" loaded, or refresh?
            // "All Providers" endpoint is static map data, doesn't support advanced filter params usually.
            // But if user applies filters, we should probably toggle to Search Mode?
            // For now, if filters applied, we treat it as search (even with empty query if API allows, or handle locally)
            _performSearch(); 
          }
        },
      ),
    );
  }
  


  void _navigateToDetails(SearchResultItem item) {
    // Check Auth
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      AuthRequiredDialog.show(context);
      return;
    }

    if (item.type == 'doctor' || item.type == 'teacher') {
      context.push(
        '/booking/${item.type}/${item.id}',
        extra: {
          'name': item.name,
          'specialty': item.specialty,
          'examinationFee': item.examinationFee,
        }
      );
    } else if (item.type == 'pharmacy') {
      context.push(
        '/order-pharmacy/${item.id}',
        extra: {
           'name': item.name,
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Content (Map or List)
          if (_isMapView)
            _buildMap(context)
          else
            _buildList(context),

          // Search Bar & Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.goNamed('home');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Search Field
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: l10n.searchStore,
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Filter Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                        ),
                        child: IconButton(
                          icon: const Icon(Iconsax.setting_4, color: Colors.white),
                          onPressed: _showFilters,
                        ),
                      ),
                    ],
                  ),
                  
                  // Toggle View & Chips
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // View Toggle
                         GestureDetector(
                          onTap: () => setState(() => _isMapView = !_isMapView),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Row(
                              children: [
                                Icon(_isMapView ? Iconsax.menu_1 : Iconsax.map_1, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _isMapView ? l10n.list : l10n.map, 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Type Filter Chips (Quick Access)
                        _buildFilterChip(l10n.doctors, 'doctor'),
                        const SizedBox(width: 8),
                        _buildFilterChip(l10n.pharmacies, 'pharmacy'),
                        const SizedBox(width: 8),
                        _buildFilterChip(l10n.teachers, 'teacher'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
             ColoredBox(
               color: AppColors.backgroundDark.withOpacity(0.7),
               child: const Center(child: CircularProgressIndicator()),
             ),
             
          // Map Selected Marker Popup
          if (_isMapView && _selectedMarkerId != null && _results.any((r) => r.id == _selectedMarkerId))
             Positioned(
               bottom: 24,
               left: 16,
               right: 16,
               child: _buildResultCard(
                 context, 
                 _results.firstWhere((r) => r.id == _selectedMarkerId),
                 l10n
               ),
             ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = isSelected ? null : value);
        if (_searchController.text.isNotEmpty) _performSearch(); else _loadAllProviders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return Container(
      color: AppColors.backgroundDark,
      padding: const EdgeInsets.only(top: 180, left: 16, right: 16),
      child: _results.isEmpty && !_isLoading
        ? Center(child: Text('No results found', style: TextStyle(color: Colors.grey[400])))
        : ListView.builder(
            itemCount: _results.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              final r = _results[index];
              return ProviderListCard(
                id: r.id,
                type: r.type,
                name: r.name,
                specialty: r.specialty,
                address: r.address,
                rating: r.rating,
                image: r.image,
                isFavorite: false, // TODO: Load actual fav state.
                onTap: () => _navigateToDetails(r),
              );
            },
          ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultLocation,
        initialZoom: 13.0,
        onTap: (_, __) => setState(() => _selectedMarkerId = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.jiwar.app',
        ),
        MarkerLayer(
          markers: _results.map((r) => Marker(
            point: r.location,
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => setState(() => _selectedMarkerId = r.id),
               child: Container(
                decoration: BoxDecoration(
                  color: _selectedMarkerId == r.id ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4)
                  ],
                ),
                 child: Icon(
                  r.type == 'doctor' ? Iconsax.health : 
                  r.type == 'pharmacy' ? Iconsax.hospital : Iconsax.teacher,
                  color: _selectedMarkerId == r.id ? Colors.white : AppColors.primary,
                  size: 24,
                ),
               ),
            ),
          )).toList(),
        ),
      ],
    );
  }
  
  // Floating Card for Map View
  Widget _buildResultCard(BuildContext context, SearchResultItem result, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  image: result.image != null
                       ? DecorationImage(image: NetworkImage(result.image!), fit: BoxFit.cover)
                       : null,
                ),
                child: result.image == null 
                  ? Icon(
                      result.type == 'doctor' ? Iconsax.health : 
                      result.type == 'pharmacy' ? Iconsax.hospital : Iconsax.teacher,
                      color: Colors.grey[400]) 
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        result.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                    ),
                    if (result.specialty != null)
                      Text(
                        result.specialty!,
                        style: TextStyle(color: AppColors.primary, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                     Row(
                        children: [
                          const Icon(Iconsax.star1, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            result.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Direction button or Fav?
              IconButton(
                onPressed: () => _navigateToDetails(result),
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
              )
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToDetails(result),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.viewDetails),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchResultItem {
  final int id;
  final String type;
  final String name;
  final String address;
  final LatLng location;
  final String? specialty;
  final double rating;
  final String? image;
  final double? examinationFee;

  SearchResultItem({
    required this.id,
    required this.type,
    required this.name,
    required this.address,
    required this.location,
    this.specialty,
    required this.rating,
    this.image,
    this.examinationFee,
  });
  
  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      address: json['address'],
      location: LatLng((json['latitude'] as num).toDouble(), (json['longitude'] as num).toDouble()),
      specialty: json['specialty'],
      rating: (json['rating'] as num).toDouble(),
      image: json['profile_image'],
      examinationFee: json['examination_fee'] != null ? (json['examination_fee'] as num).toDouble() : null,
    );
  }
}
