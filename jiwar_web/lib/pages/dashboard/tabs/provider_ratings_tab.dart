import 'package:flutter/material.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ProviderRatingsTab extends StatefulWidget {
  final String providerType; // 'doctor', 'pharmacy', 'teacher'

  const ProviderRatingsTab({
    super.key,
    required this.providerType,
  });

  @override
  State<ProviderRatingsTab> createState() => _ProviderRatingsTabState();
}

class _ProviderRatingsTabState extends State<ProviderRatingsTab> {
  bool _isLoading = true;
  List<dynamic> _ratings = [];
  double _averageRating = 0.0;
  int _totalRatings = 0;
  String? _errorMessage;

  // Filters
  String _selectedSort = 'newest';
  int? _selectedStars;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      setState(() => _isLoading = true);

      // 1. Get Profile to get ID
      final profileResponse = await ApiService().getProfile();
      if (!profileResponse.isSuccess || profileResponse.data == null) {
        throw Exception(profileResponse.errorMessage ?? 'Failed to load profile');
      }

      final profileId = profileResponse.data!['id'];

      // 2. Get Ratings with filters
      final ratingsResponse = await ApiService().getProviderRatings(
        providerId: profileId,
        providerType: widget.providerType,
        sort: _selectedSort,
        stars: _selectedStars,
      );

      if (!ratingsResponse.isSuccess || ratingsResponse.data == null) {
        throw Exception(ratingsResponse.errorMessage ?? 'Failed to load ratings');
      }

      final data = ratingsResponse.data!;
      
      if (mounted) {
        setState(() {
          _ratings = data['ratings'] ?? [];
          _averageRating = (data['average'] ?? 0.0).toDouble();
          _totalRatings = (data['total'] ?? 0) as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'حدث خطأ أثناء تحميل التقييمات' : 'Error loading ratings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRatings,
              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            )
          ],
        ),
      );
    }
    
    // No Ratings Empty State
    if (_ratings.isEmpty && _selectedStars == null && _selectedSort == 'newest') {
       // Only show completely empty state if no filters are applied
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد تقييمات بعد' : 'No ratings yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < _averageRating.round() ? Icons.star : Icons.star_border,
                          color: AppColors.warning,
                          size: 20,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                   child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'إجمالي التقييمات' : 'Total Ratings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondaryDark),
                      ),
                      Text(
                        '$_totalRatings',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Filters UI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Sort Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      icon: const Icon(Icons.sort, color: AppColors.textSecondaryDark),
                      dropdownColor: AppColors.surfaceDark,
                      style: const TextStyle(color: AppColors.textPrimaryDark),
                      items: [
                        DropdownMenuItem(value: 'newest', child: Text(isArabic ? 'الأحدث' : 'Newest')),
                        DropdownMenuItem(value: 'oldest', child: Text(isArabic ? 'الأقدم' : 'Oldest')),
                        DropdownMenuItem(value: 'highest', child: Text(isArabic ? 'الأعلى تقييماً' : 'Highest Rated')),
                        DropdownMenuItem(value: 'lowest', child: Text(isArabic ? 'الأقل تقييماً' : 'Lowest Rated')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSort = val);
                          _loadRatings();
                        }
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Star Filters
                ...List.generate(6, (index) { // 0 for All, 1-5 for stars
                  final starCount = index == 0 ? null : (6 - index); // All, 5, 4, 3, 2, 1
                  final isSelected = _selectedStars == starCount;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (starCount != null) const Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(starCount == null ? (isArabic ? 'الكل' : 'All') : '$starCount'),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStars = selected ? starCount : null; 
                        });
                        _loadRatings();
                      },
                      checkmarkColor: Colors.white,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            isArabic ? 'أحدث التقييمات' : 'Recent Reviews',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 16),
          
          // List of Ratings
          Expanded(
            child: ListView.separated(
              itemCount: _ratings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final rating = _ratings[index];
                final comment = rating['comment'] as String?;
                final userName = rating['user_name'] ?? (isArabic ? 'مجهول' : 'Anonymous');
                final stars = (rating['rating'] as num).toDouble();
                final dateStr = rating['created_at'] as String?;
                final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  userName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
                                  ),
                                  if (date != null)
                                    Text(
                                      DateFormat.yMMMd().format(date),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.warning, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  stars.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (comment != null && comment.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.dividerDark),
                        const SizedBox(height: 12),
                         Text(
                          comment,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimaryDark),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
