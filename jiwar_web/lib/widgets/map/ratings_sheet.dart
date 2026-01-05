import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';

/// Bottom sheet showing all ratings for a provider
class RatingsSheet extends StatefulWidget {
  final int providerId;
  final String providerType;
  final String providerName;

  const RatingsSheet({
    super.key,
    required this.providerId,
    required this.providerType,
    required this.providerName,
  });

  @override
  State<RatingsSheet> createState() => _RatingsSheetState();
}

class _RatingsSheetState extends State<RatingsSheet> {
  final _api = ApiService();
  bool _isLoading = true;
  List<RatingData> _ratings = [];
  double _averageRating = 0.0;
  int _totalRatings = 0;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() => _isLoading = true);

    final response = await _api.getProviderRatings(
      providerId: widget.providerId,
      providerType: widget.providerType,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      setState(() {
        _ratings = (data['ratings'] as List)
            .map((r) => RatingData.fromJson(r))
            .toList();
        _averageRating = (data['average'] as num?)?.toDouble() ?? 0.0;
        _totalRatings = data['total'] ?? 0;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorDialog.show(context, errorCode: 'LOAD_ERROR', errorMessage: response.errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.viewRatings,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        widget.providerName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ratings.isEmpty
                    ? _buildEmptyState(l10n, textColor)
                    : RefreshIndicator(
                        onRefresh: _loadRatings,
                        child: CustomScrollView(
                          slivers: [
                            // Summary Card
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: _buildRatingSummary(context, isDark, cardColor, textColor),
                              ),
                            ),

                            // Reviews List Title
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Text(
                                  '${_ratings.length} ${l10n.reviews}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),

                            // Reviews List
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final rating = _ratings[index];
                                  return _buildRatingItem(rating, l10n, isDark, cardColor, textColor);
                                },
                                childCount: _ratings.length,
                              ),
                            ),
                            const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rate_review_outlined, size: 64, color: AppColors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noRatings,
            style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'كن أول من يقيّم هذا مقدم الخدمة',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(BuildContext context, bool isDark, Color cardColor, Color textColor) {
    // Calculate counts for chart
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in _ratings) {
      if (counts.containsKey(r.rating)) {
        counts[r.rating] = counts[r.rating]! + 1;
      }
    }
    final maxCount = _totalRatings > 0 ? _totalRatings : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Big Number
          Column(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  if (_averageRating >= index + 1) {
                    return const Icon(Icons.star_rounded, color: Colors.amber, size: 16);
                  } else if (_averageRating >= index + 0.5) {
                    return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 16);
                  } else {
                    return Icon(Icons.star_outline_rounded, color: Colors.grey[300], size: 16);
                  }
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '$_totalRatings تقييم',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: 24),
          
          // Chart
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = counts[star] ?? 0;
                final percentage = count / maxCount;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            color: Colors.amber,
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(
    RatingData rating,
    AppLocalizations l10n,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: rating.isAnonymous
                        ? [Colors.grey[400]!, Colors.grey[600]!]
                        : [AppColors.primary.withOpacity(0.7), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  rating.isAnonymous ? Icons.person_off : Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.isAnonymous ? l10n.anonymous : rating.userName ?? l10n.anonymous,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy', 'ar').format(rating.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      rating.rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  ],
                ),
              ),
            ],
          ),
          if (rating.reason != null && rating.reason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.orange.withOpacity(0.1) : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                rating.reason!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[800],
                ),
              ),
            ),
          ],
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              rating.comment!,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Data model for ratings
class RatingData {
  final int id;
  final int userId;
  final String? userName;
  final int rating;
  final String? comment;
  final String? reason;
  final bool isAnonymous;
  final DateTime createdAt;

  RatingData({
    required this.id,
    required this.userId,
    this.userName,
    required this.rating,
    this.comment,
    this.reason,
    required this.isAnonymous,
    required this.createdAt,
  });

  factory RatingData.fromJson(Map<String, dynamic> json) {
    return RatingData(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      rating: json['rating'],
      comment: json['comment'],
      reason: json['reason'],
      isAnonymous: json['is_anonymous'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
