import 'package:flutter/material.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:jiwar_web/widgets/dialogs/success_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';

/// Rating dialog for rating providers with stars, comment, and anonymous option
class RatingDialog extends StatefulWidget {
  final int providerId;
  final String providerType;
  final String providerName;
  final VoidCallback onSuccess;

  const RatingDialog({
    super.key,
    required this.providerId,
    required this.providerType,
    required this.providerName,
    required this.onSuccess,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final _api = ApiService();

  bool get _needsReason => _rating > 0 && _rating < 5;

  Future<void> _submitRating() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_rating == 0) {
      ErrorDialog.show(context, errorCode: 'VALIDATION_ERROR', errorMessage: l10n.ratingRequired);
      return;
    }

    if (_needsReason && _commentController.text.trim().isEmpty) {
      ErrorDialog.show(context, errorCode: 'VALIDATION_ERROR', errorMessage: l10n.reasonRequired);
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await _api.createRating(
      providerId: widget.providerId,
      providerType: widget.providerType,
      rating: _rating,
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      isAnonymous: _isAnonymous,
    );

    setState(() => _isSubmitting = false);

    if (response.isSuccess) {
      if (mounted) {
        Navigator.pop(context);
        SuccessDialog.show(
          context,
          title: l10n.updateSuccess,
          message: l10n.ratingSubmitted,
          onDismiss: widget.onSuccess,
        );
      }
    } else {
      if (mounted) {
        ErrorDialog.show(context, errorCode: 'RATING_ERROR', errorMessage: response.errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.addRating,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
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
              const SizedBox(height: 8),
              Text(
                widget.providerName,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedScale(
                        scale: _rating >= starIndex ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          _rating >= starIndex ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: _rating >= starIndex ? Colors.amber : Colors.grey[300],
                          size: 44,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _getRatingLabel(l10n),
                  key: ValueKey(_rating),
                  style: TextStyle(
                    color: _rating > 0 ? AppColors.primary : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Comment/Reason
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: _needsReason ? '${l10n.reason} *' : l10n.comment,
                  hintText: _needsReason ? l10n.reasonHint : l10n.commentHint,
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  prefixIcon: Icon(
                    _needsReason ? Icons.info_outline : Icons.comment,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Anonymous toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isAnonymous ? AppColors.primary : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAnonymous ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.rateAnonymously,
                            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                          ),
                          Text(
                            l10n.anonymousHint,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isAnonymous,
                      onChanged: (v) => setState(() => _isAnonymous = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(l10n.submit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(AppLocalizations l10n) {
    switch (_rating) {
      case 1: return l10n.ratingPoor;
      case 2: return l10n.ratingFair;
      case 3: return l10n.ratingGood;
      case 4: return l10n.ratingVeryGood;
      case 5: return l10n.ratingExcellent;
      default: return l10n.tapToRate;
    }
  }
}
