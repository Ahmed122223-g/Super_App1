import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/widgets/common/secure_network_image.dart';

class ProviderListCard extends StatefulWidget {
  final int id;
  final String type;
  final String name;
  final String? specialty;
  final String address;
  final double rating;
  final String? image;
  final bool isFavorite;
  final VoidCallback onTap;

  const ProviderListCard({
    super.key,
    required this.id,
    required this.type,
    required this.name,
    this.specialty,
    required this.address,
    required this.rating,
    this.image,
    this.isFavorite = false, 
    required this.onTap,
  });

  @override
  State<ProviderListCard> createState() => _ProviderListCardState();
}

class _ProviderListCardState extends State<ProviderListCard> {
  late bool _isFavorite;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    // Optimistic update
    setState(() => _isFavorite = !_isFavorite);
    
    final result = await _api.toggleFavorite(widget.id, widget.type);
    if (!result.isSuccess) {
      // Revert if failed
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    image: widget.image != null
                        ? DecorationImage(image: secureNetworkImageProvider(widget.image!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: widget.image == null
                      ? Icon(
                          widget.type == 'doctor' ? Iconsax.health : 
                          widget.type == 'pharmacy' ? Iconsax.hospital : Iconsax.teacher,
                          color: Colors.grey[400], size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: _toggleFavorite,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                _isFavorite ? Iconsax.heart5 : Iconsax.heart,
                                color: _isFavorite ? Colors.red : Colors.grey[400],
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (widget.specialty != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.specialty!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Iconsax.location, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Iconsax.star1, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating.toStringAsFixed(1),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
