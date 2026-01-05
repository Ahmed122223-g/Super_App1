import 'package:flutter/material.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/widgets/map/provider_details_panel.dart';
import 'package:jiwar_web/pages/dashboard/user/user_map_page.dart';


class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _allFavorites = [];
  List<dynamic> _filteredFavorites = [];
  
  // Filters
  String _selectedType = 'all'; // all, doctor, pharmacy, teacher
  String? _selectedSpecialty; // For dynamic sub-filtering based on provider_specialty
  
  // Selected provider for details panel
  MapProviderData? _selectedProvider;
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final response = await _api.getFavorites(); // Fetch all
    
    if (response.isSuccess && response.data != null) {
      setState(() {
        _allFavorites = response.data as List;
        _favoriteIds = _allFavorites.map((f) => '${f['provider_type']}-${f['provider_id']}').toSet();
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

  void _showProviderDetails(dynamic fav) {
    // Convert favorite data to MapProviderData
    final provider = MapProviderData(
      id: fav['provider_id'],
      type: fav['provider_type'],
      name: fav['provider_name'] ?? 'Unknown',
      specialty: fav['provider_specialty'],
      address: fav['provider_address'] ?? '',
      latitude: (fav['provider_latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (fav['provider_longitude'] as num?)?.toDouble() ?? 0.0,
      rating: (fav['provider_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: fav['provider_total_ratings'] ?? 0,
      phone: fav['provider_phone'],
      profileImage: fav['provider_image'],
      description: fav['provider_description'],
      whatsapp: fav['provider_whatsapp'],
    );
    setState(() => _selectedProvider = provider);
  }

  void _closePanel() {
    setState(() => _selectedProvider = null);
  }

  Future<void> _toggleFavorite(MapProviderData provider) async {
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
    } else {
      // Refresh list if removed
      _loadFavorites();
    }
  }

  Future<void> _removeFavorite(int id, String type) async {
    // Optimistic remove
    final item = _allFavorites.firstWhere((f) => f['id'] == id, orElse: () => null);
    if (item == null) return;
    
    setState(() {
      _allFavorites.removeWhere((f) => f['id'] == id);
      _applyFilters();
    });

    final response = await _api.toggleFavorite(item['provider_id'], type);
    
    if (!response.isSuccess) {
      // Revert
      setState(() {
        _allFavorites.add(item);
        _applyFilters();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.errorMessage ?? 'Error removing favorite')),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = _allFavorites;
    
    // Filter by Type
    if (_selectedType != 'all') {
      filtered = filtered.where((f) => f['provider_type'] == _selectedType).toList();
    }
    
    // Filter by Specialty/Subject
    if (_selectedSpecialty != null) {
      filtered = filtered.where((f) => f['provider_specialty'] == _selectedSpecialty).toList();
    }
    
    _filteredFavorites = filtered;
  }

  List<String> _getAvailableSpecialties() {
    // Extract unique specialties based on current type filter
    if (_selectedType == 'all') return [];
    
    final specialties = <String>{};
    for (var fav in _allFavorites) {
      if (fav['provider_type'] == _selectedType && fav['provider_specialty'] != null) {
        specialties.add(fav['provider_specialty']);
      }
    }
    return specialties.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites), // Ensure this key exists or use 'المفضلة'
        centerTitle: true,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Column(
            children: [
              // Filters Section
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1E1E1E),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(l10n.filterAll, 'all', Icons.grid_view),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.doctors, 'doctor', Icons.local_hospital),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.teachers, 'teacher', Icons.school),
                          const SizedBox(width: 8),
                          _buildFilterChip(l10n.pharmacies, 'pharmacy', Icons.local_pharmacy),
                        ],
                      ),
                    ),
                    
                    // Specialty Filter Chips (only if type selected)
                    if (_selectedType != 'all' && _selectedType != 'pharmacy') ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSubFilterChip('الكل', null),
                            ..._getAvailableSpecialties().map((spec) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildSubFilterChip(spec, spec),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // List Section
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredFavorites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد عناصر في المفضلة',
                              style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredFavorites.length,
                        itemBuilder: (context, index) {
                          final fav = _filteredFavorites[index];
                          return _buildFavoriteCard(fav, isDark, l10n);
                        },
                      ),
              ),
            ],
          ),
          
          // Provider Details Panel
          if (_selectedProvider != null)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.9,
              child: ProviderDetailsPanel(
                provider: _selectedProvider!,
                onClose: _closePanel,
                onRefresh: _loadFavorites,
                isFavorite: _favoriteIds.contains('${_selectedProvider!.type}-${_selectedProvider!.id}'),
                onFavoriteToggle: () => _toggleFavorite(_selectedProvider!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[300]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[200])),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedType = value;
          _selectedSpecialty = null;
          _isLoading = true;
          _applyFilters();
           Future.delayed(const Duration(milliseconds: 100), () => setState(() => _isLoading = false));
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: AppColors.primary,
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    );
  }

  Widget _buildSubFilterChip(String label, String? value) {
    final isSelected = _selectedSpecialty == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[200], fontSize: 13)),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedSpecialty = value;
          _applyFilters();
        });
      },
      backgroundColor: Colors.grey[700],
      selectedColor: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[600]!),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildFavoriteCard(dynamic fav, bool isDark, AppLocalizations l10n) {
    final type = fav['provider_type'];
    final name = fav['provider_name'] ?? 'Unknown';
    final specialty = fav['provider_specialty'];
    final image = fav['provider_image'];
    
    Color typeColor;
    IconData typeIcon;
    
    switch (type) {
      case 'doctor':
        typeColor = Colors.blue;
        typeIcon = Icons.local_hospital;
        break;
      case 'pharmacy':
        typeColor = Colors.green;
        typeIcon = Icons.local_pharmacy;
        break;
      case 'teacher':
        typeColor = Colors.purple;
        typeIcon = Icons.school;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.location_on;
    }

    String imageUrl = '';
    if (image != null) {
       imageUrl = image.startsWith('http') ? image : '${ApiService.staticUrl}$image';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showProviderDetails(fav),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: typeColor.withOpacity(0.1),
                    image: imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                  ),
                  child: imageUrl.isEmpty
                      ? Icon(typeIcon, color: typeColor, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      if (specialty != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            specialty,
                            style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Actions
                IconButton(
                  onPressed: () => _removeFavorite(fav['id'], type),
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  tooltip: 'إزالة من المفضلة',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
