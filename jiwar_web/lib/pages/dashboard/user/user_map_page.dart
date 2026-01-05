import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:jiwar_web/widgets/map/provider_details_panel.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/pages/dashboard/user/favorites_page.dart';

/// User Map Page - Interactive map with all providers (OpenStreetMap)
class UserMapPage extends StatefulWidget {
  const UserMapPage({super.key});

  @override
  State<UserMapPage> createState() => _UserMapPageState();
}

class _UserMapPageState extends State<UserMapPage> {
  late MapController _mapController;
  final _api = ApiService();
  
  bool _isLoading = true;
  bool _isLocationLoading = true;
  List<MapProviderData> _providers = [];
  List<MapProviderData> _filteredProviders = [];
  MapProviderData? _selectedProvider;
  LatLng? _userLocation;
  bool _locationPermissionDenied = false;
  
  // Search and filter state
  final _searchController = TextEditingController();
  String? _selectedType; // doctor, pharmacy, teacher, or null for all
  int? _selectedSpecialtyId; // For doctor specialty
  int? _selectedSubjectId; // For teacher subject
  List<Map<String, dynamic>> _subjects = [];
  bool _showFilters = false;
  
  // Doctor specialties
  static const List<Map<String, dynamic>> _doctorSpecialties = [
    {'id': 1, 'name_ar': 'طبيب أسنان', 'name_en': 'Dentist'},
    {'id': 2, 'name_ar': 'طبيب عيون', 'name_en': 'Ophthalmologist'},
    {'id': 3, 'name_ar': 'طبيب أطفال', 'name_en': 'Pediatrician'},
    {'id': 4, 'name_ar': 'طبيب قلب', 'name_en': 'Cardiologist'},
    {'id': 5, 'name_ar': 'طبيب جلدية', 'name_en': 'Dermatologist'},
    {'id': 6, 'name_ar': 'طبيب عظام', 'name_en': 'Orthopedist'},
    {'id': 7, 'name_ar': 'طبيب أعصاب', 'name_en': 'Neurologist'},
    {'id': 8, 'name_ar': 'طبيب نساء وتوليد', 'name_en': 'Gynecologist'},
    {'id': 9, 'name_ar': 'طبيب باطنة', 'name_en': 'Internist'},
    {'id': 10, 'name_ar': 'طبيب أنف وأذن', 'name_en': 'ENT'},
    {'id': 14, 'name_ar': 'طبيب عام', 'name_en': 'General'},
  ];
  
  // Default center: Al-Wasty, Beni Suef
  static const _defaultCenter = LatLng(29.3385, 31.2081);
  
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadSubjects();
    _loadProviders();
    _fetchFavorites();
    _requestUserLocation();
  }

  Future<void> _fetchFavorites() async {
    final response = await _api.getFavorites();
    if (response.isSuccess && response.data != null) {
      final favs = response.data as List;
      setState(() {
        _favoriteIds = favs.map((f) => '${f['provider_type']}-${f['provider_id']}').toSet();
      });
    }
  }

  Future<void> _toggleFavorite(MapProviderData provider) async {
    // Optimistic update
    final key = '${provider.type}-${provider.id}';
    final isFav = _favoriteIds.contains(key);
    
    setState(() {
      if (isFav) {
        _favoriteIds.remove(key);
      } else {
        _favoriteIds.add(key);
      }
    });

    final response = await _api.toggleFavorite(provider.id, provider.type);

    if (!response.isSuccess) {
      // Revert on failure
      setState(() {
        if (isFav) {
          _favoriteIds.add(key);
        } else {
          _favoriteIds.remove(key);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.errorMessage ?? 'Error updating favorite')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final response = await _api.getSubjects();
    if (response.isSuccess && response.data != null) {
      setState(() {
        _subjects = (response.data as List).map((s) => Map<String, dynamic>.from(s)).toList();
      });
    }
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    
    final response = await _api.getAllProviders(
      teacherName: _selectedType == 'teacher' && _searchController.text.isNotEmpty ? _searchController.text : null,
      subjectId: _selectedType == 'teacher' ? _selectedSubjectId : null,
    );
    
    if (response.isSuccess && response.data != null) {
      final List providers = response.data!['providers'] ?? [];
      setState(() {
        _providers = providers.map((p) => MapProviderData.fromJson(p)).toList();
        _applyFilters();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorDialog.show(context, errorCode: 'LOAD_ERROR', errorMessage: response.errorMessage);
      }
    }
  }

  void _applyFilters() {
    var filtered = _providers.toList();
    
    // Filter by type
    if (_selectedType != null) {
      filtered = filtered.where((p) => p.type == _selectedType).toList();
    }
    
    // Filter by name (search)
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(searchText)
      ).toList();
    }
    
    // Filter doctors by specialty (client-side, match by specialty name)
    if (_selectedType == 'doctor' && _selectedSpecialtyId != null) {
      final specialtyData = _doctorSpecialties.firstWhere(
        (s) => s['id'] == _selectedSpecialtyId,
        orElse: () => {},
      );
      if (specialtyData.isNotEmpty) {
        final specialtyName = specialtyData['name_ar'] as String?;
        if (specialtyName != null) {
          filtered = filtered.where((p) => 
            p.specialty?.contains(specialtyName.replaceFirst('طبيب ', '')) == true
          ).toList();
        }
      }
    }
    
    _filteredProviders = filtered;
  }

  Future<void> _requestUserLocation() async {
    setState(() => _isLocationLoading = true);
    
    try {
      // Use browser's navigator.geolocation API via JS interop
      final geolocation = js.context['navigator']['geolocation'];
      
      if (geolocation == null) {
        setState(() {
          _isLocationLoading = false;
          _locationPermissionDenied = true;
        });
        return;
      }
      
      final completer = Completer<void>();
      
      geolocation.callMethod('getCurrentPosition', [
        // Success callback
        js.allowInterop((position) {
          final coords = position['coords'];
          final lat = (coords['latitude'] as num).toDouble();
          final lng = (coords['longitude'] as num).toDouble();
          
          debugPrint('=== LOCATION FOUND: Lat: $lat, Lng: $lng ===');
          
          if (mounted) {
            setState(() {
              _userLocation = LatLng(lat, lng);
              _isLocationLoading = false;
              _locationPermissionDenied = false;
            });
            
            // Move map to user location
            _mapController.move(_userLocation!, 15);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديد موقعك بنجاح ✅'), duration: Duration(seconds: 2)),
            );
          }
          
          if (!completer.isCompleted) completer.complete();
        }),
        // Error callback
        js.allowInterop((error) {
          debugPrint('Location error: ${error['message']}');
          if (mounted) {
            setState(() {
              _isLocationLoading = false;
              _locationPermissionDenied = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                content: Text('تعذر تحديد الموقع: ${error['message']}'),
                action: SnackBarAction(
                  label: 'محاولة مرة أخرى',
                  onPressed: _requestUserLocation,
                  textColor: Colors.white,
                ),
              ),
            );
          }
          if (!completer.isCompleted) completer.complete();
        }),
        // Options: Increased timeout to 30s, allow cached (5 min max age)
        js.JsObject.jsify({
          'enableHighAccuracy': true,
          'timeout': 30000,
          'maximumAge': 300000, 
        }),
      ]);
      
      // Wait for the callback to complete
      await completer.future.timeout(const Duration(seconds: 31), onTimeout: () {
        if (mounted) {
          setState(() {
            _isLocationLoading = false;
            _locationPermissionDenied = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: const Text('انتهت مهلة تحديد الموقع'),
              action: SnackBarAction(
                label: 'محاولة مرة أخرى',
                onPressed: _requestUserLocation,
                textColor: Colors.white,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() {
        _isLocationLoading = false;
        _locationPermissionDenied = true;
      });
    }
  }

  void _onMarkerTap(MapProviderData provider) {
    setState(() {
      _selectedProvider = provider;
    });
  }

  void _closePanel() {
    setState(() {
      _selectedProvider = null;
    });
  }

  Color _getProviderColor(String type) {
    switch (type) {
      case 'doctor': return const Color(0xFF2196F3);
      case 'pharmacy': return const Color(0xFF4CAF50);
      case 'teacher': return const Color(0xFF9C27B0);
      default: return Colors.grey;
    }
  }

  IconData _getProviderIcon(String type) {
    switch (type) {
      case 'doctor': return Icons.local_hospital;
      case 'pharmacy': return Icons.local_pharmacy;
      case 'teacher': return Icons.school;
      case 'restaurant': return Icons.restaurant;
      case 'engineer': return Icons.engineering;
      case 'company': return Icons.business;
      case 'mechanic': return Icons.build;
      default: return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Flutter Map (OSM)
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation ?? _defaultCenter,
            initialZoom: 14.0,
            onTap: (_, __) => _closePanel(),
          ),
          children: [
            TileLayer(
              // Always use light mode map as requested
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.jiwar.app',
            ),
            MarkerLayer(
              markers: [
                ...(_filteredProviders.isEmpty && _selectedType == null ? _providers : _filteredProviders).map((provider) {
                  return Marker(
                    key: ValueKey('provider-${provider.type}-${provider.id}'),
                    point: LatLng(provider.latitude, provider.longitude),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _onMarkerTap(provider),
                      child: _ProviderMarker(
                        type: provider.type,
                        isSelected: _selectedProvider?.id == provider.id,
                        color: _getProviderColor(provider.type),
                        icon: _getProviderIcon(provider.type),
                      ),
                    ),
                  );
                }),
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
              ],
            ),
          ],
        ),
        
        // Top Bar with filters and search
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.discoverNearby,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      // Provider count badges
                      _buildCountBadge('doctor', _providers.where((p) => p.type == 'doctor').length),
                      const SizedBox(width: 8),
                      _buildCountBadge('pharmacy', _providers.where((p) => p.type == 'pharmacy').length),
                      const SizedBox(width: 8),
                      _buildCountBadge('teacher', _providers.where((p) => p.type == 'teacher').length),
                      const SizedBox(width: 8),
                      // Favorites Page
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        tooltip: 'المفضلة',
                        onPressed: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const FavoritesPage())
                        ).then((_) => _fetchFavorites()), // Refresh favorites on return
                      ),
                      const SizedBox(width: 4),
                      // Filter toggle
                      IconButton(
                        icon: Icon(
                          _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                          color: _showFilters ? AppColors.primary : Colors.grey,
                        ),
                        tooltip: 'فلترة',
                        onPressed: () => setState(() => _showFilters = !_showFilters),
                      ),
                    ],
                  ),
                  
                  // Search field (always visible)
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم... Search by name...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedType = null;
                                  _selectedSpecialtyId = null;
                                  _selectedSubjectId = null;
                                  _applyFilters();
                                });
                              },
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) {
                      setState(() => _applyFilters());
                    },
                    onChanged: (value) {
                      setState(() => _applyFilters());
                    },
                  ),
                  
                  // Filters Section (expandable)
                  if (_showFilters) ...[
                    const Divider(height: 16),
                    
                    // Type filter dropdown
                    Row(
                      children: [
                        // Type dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedType != null ? AppColors.primary : Colors.grey[600]!,
                              ),
                            ),
                            child: DropdownButton<String?>(
                              value: _selectedType,
                              hint: const Text('كل الأنواع - All Types'),
                              underline: const SizedBox(),
                              isExpanded: true,
                              isDense: true,
                              items: const [
                                DropdownMenuItem<String?>(value: null, child: Text('كل الأنواع')),
                                DropdownMenuItem(value: 'doctor', child: Row(
                                  children: [Icon(Icons.local_hospital, size: 18, color: Colors.blue), SizedBox(width: 8), Text('أطباء')],
                                )),
                                DropdownMenuItem(value: 'pharmacy', child: Row(
                                  children: [Icon(Icons.local_pharmacy, size: 18, color: Colors.green), SizedBox(width: 8), Text('صيدليات')],
                                )),
                                DropdownMenuItem(value: 'teacher', child: Row(
                                  children: [Icon(Icons.school, size: 18, color: Colors.purple), SizedBox(width: 8), Text('معلمين')],
                                )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value;
                                  _selectedSpecialtyId = null;
                                  _selectedSubjectId = null;
                                  _applyFilters();
                                });
                                if (value == 'teacher') {
                                  _loadProviders();
                                }
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Specialty dropdown for doctors
                        if (_selectedType == 'doctor')
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: DropdownButton<int?>(
                                value: _selectedSpecialtyId,
                                hint: const Text('كل التخصصات', style: TextStyle(fontSize: 12)),
                                underline: const SizedBox(),
                                isExpanded: true,
                                isDense: true,
                                items: [
                                  const DropdownMenuItem<int?>(value: null, child: Text('كل التخصصات')),
                                  ..._doctorSpecialties.map((s) => DropdownMenuItem<int?>(
                                    value: s['id'] as int,
                                    child: Text(s['name_ar'] ?? '', style: const TextStyle(fontSize: 12)),
                                  )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSpecialtyId = value;
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                          ),
                        
                        // Subject dropdown for teachers
                        if (_selectedType == 'teacher')
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                              ),
                              child: DropdownButton<int?>(
                                value: _selectedSubjectId,
                                hint: const Text('كل المواد', style: TextStyle(fontSize: 12)),
                                underline: const SizedBox(),
                                isExpanded: true,
                                isDense: true,
                                items: [
                                  const DropdownMenuItem<int?>(value: null, child: Text('كل المواد')),
                                  ..._subjects.map((s) => DropdownMenuItem<int?>(
                                    value: s['id'] as int,
                                    child: Text(s['name_ar'] ?? '', style: const TextStyle(fontSize: 12)),
                                  )),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedSubjectId = value);
                                  _loadProviders();
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        // Loading indicator
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        
        // Provider Details Panel
        if (_selectedProvider != null)
           Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.85,
            child: ProviderDetailsPanel(
              provider: _selectedProvider!,
              onClose: _closePanel,
              onRefresh: _loadProviders,
              isFavorite: _favoriteIds.contains('${_selectedProvider!.type}-${_selectedProvider!.id}'),
              onFavoriteToggle: () => _toggleFavorite(_selectedProvider!),
            ),
          ),
        
        // Legend
        Positioned(
          bottom: 100,
          left: 16,
          child: _buildLegend(),
        ),
        
        // Refresh button
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'refresh_map',
            onPressed: () {
               _loadProviders();
               if (_userLocation != null) {
                  _mapController.move(_userLocation!, _mapController.camera.zoom);
               }
            },
            backgroundColor: AppColors.surfaceDark,
            child: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ),
        
        // Locate me button
        Positioned(
          bottom: 170,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'locate_me',
            onPressed: () {
              if (_userLocation != null) {
                _mapController.move(_userLocation!, 15);
              } else if (_locationPermissionDenied) {
                // Try requesting location again
                _requestUserLocation();
              }
            },
            backgroundColor: AppColors.surfaceDark,
            child: Icon(
              _locationPermissionDenied ? Icons.location_disabled : Icons.my_location,
              color: _locationPermissionDenied ? Colors.grey : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountBadge(String type, int count) {
    final color = _getProviderColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getProviderIcon(type), color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem('doctor', l10n.doctors),
          const SizedBox(height: 6),
          _buildLegendItem('pharmacy', l10n.pharmacies),
          const SizedBox(height: 6),
          _buildLegendItem('teacher', l10n.teachers),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String type, String label) {
    final color = _getProviderColor(type);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(_getProviderIcon(type), color: Colors.white, size: 10),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }
}

class _ProviderMarker extends StatelessWidget {
  final String type;
  final bool isSelected;
  final Color color;
  final IconData icon;

  const _ProviderMarker({
    required this.type,
    required this.isSelected,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 10 : 8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: isSelected ? 24 : 18,
      ),
    );
  }
}

/// Data model for map providers
class MapProviderData {
  final int id;
  final String type;
  final String name;
  final String? specialty;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int totalRatings;
  final String? phone;
  final String? profileImage;
  final String? description;
  final double? consultationFee;
  final double? examinationFee;
  final bool? deliveryAvailable;
  final String? whatsapp;
  final Map<String, dynamic>? workingHours;
  final List<dynamic>? pricing;

  MapProviderData({
    required this.id,
    required this.type,
    required this.name,
    this.specialty,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.totalRatings,
    this.phone,
    this.profileImage,
    this.description,
    this.consultationFee,
    this.examinationFee,
    this.deliveryAvailable,
    this.whatsapp,
    this.workingHours,
    this.pricing,
  });

  factory MapProviderData.fromJson(Map<String, dynamic> json) {
    return MapProviderData(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      specialty: json['specialty'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] ?? 0,
      phone: json['phone'],
      profileImage: json['profile_image'],
      description: json['description'],
      consultationFee: (json['consultation_fee'] as num?)?.toDouble(),
      examinationFee: (json['examination_fee'] as num?)?.toDouble(),
      deliveryAvailable: json['delivery_available'],
      whatsapp: json['whatsapp'],
      workingHours: json['working_hours'] != null 
        ? Map<String, dynamic>.from(json['working_hours']) 
        : null,
      pricing: json['pricing'] as List<dynamic>?,
    );
  }
}
