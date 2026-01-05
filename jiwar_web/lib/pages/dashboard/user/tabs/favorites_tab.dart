import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/widgets/search/provider_list_card.dart';
import 'package:go_router/go_router.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  final _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final response = await _api.getFavorites();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.isSuccess) {
          _favorites = response.data ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.heart, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: TextStyle(color: Colors.grey[500], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    final provider = fav['provider'];
                    // Provider structure depends on type, unified by favorites router?
                    // favorites router returns {id, provider_id, provider_type, provider_details: {...}}
                    if (provider == null) return const SizedBox.shrink();
                    
                    return ProviderListCard(
                      id: fav['provider_id'],
                      type: fav['provider_type'],
                      name: provider['name'],
                      specialty: provider['specialty'] ?? provider['subject'], // subject for teacher
                      address: provider['address'],
                      rating: (provider['rating'] as num?)?.toDouble() ?? 0.0,
                      image: provider['profile_image'],
                      isFavorite: true,
                      onTap: () {
                         if (fav['provider_type'] == 'doctor' || fav['provider_type'] == 'teacher') {
                            context.push(
                              '/booking/${fav['provider_type']}/${fav['provider_id']}',
                              extra: {
                                'name': provider['name'],
                                'specialty': provider['specialty'] ?? provider['subject'],
                              }
                            );
                          } else if (fav['provider_type'] == 'pharmacy') {
                            context.push(
                              '/order-pharmacy/${fav['provider_id']}',
                              extra: {
                                'name': provider['name'],
                              }
                            );
                          }
                      },
                    );
                  },
                ),
    );
  }
}
