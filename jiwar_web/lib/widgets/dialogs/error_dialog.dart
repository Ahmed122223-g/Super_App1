import 'package:flutter/material.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';

/// Error Dialog Widget - Shows errors in a modal with translations
class ErrorDialog extends StatelessWidget {
  final String errorCode;
  final String? errorMessage;
  final VoidCallback? onRetry;
  
  const ErrorDialog({
    super.key,
    required this.errorCode,
    this.errorMessage,
    this.onRetry,
  });
  
  /// Show error dialog
  static Future<void> show(
    BuildContext context, {
    required String errorCode,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ErrorDialog(
        errorCode: errorCode,
        errorMessage: errorMessage,
        onRetry: onRetry,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final translatedError = _translateError(errorCode, l10n, isArabic);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.warning_2,
                color: AppColors.error,
                size: 48,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              isArabic ? 'حدث خطأ' : 'Error Occurred',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Error message
            Text(
              translatedError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            // Debug info (error code)
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Code: $errorCode',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isArabic ? 'إغلاق' : 'Close'),
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry!();
                      },
                      child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _translateError(String errorCode, AppLocalizations l10n, bool isArabic) {
    // Error code translations
    final Map<String, Map<String, String>> errors = {
      // Auth errors
      'INVALID_CREDENTIALS': {
        'ar': 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        'en': 'Invalid email or password',
      },
      'EMAIL_ALREADY_EXISTS': {
        'ar': 'البريد الإلكتروني مسجل مسبقاً',
        'en': 'Email already registered',
      },
      'INVALID_REGISTRATION_CODE': {
        'ar': 'كود التسجيل غير صحيح أو تم استخدامه',
        'en': 'Invalid or already used registration code',
      },
      'USER_NOT_FOUND': {
        'ar': 'المستخدم غير موجود',
        'en': 'User not found',
      },
      'USER_INACTIVE': {
        'ar': 'الحساب غير مفعّل',
        'en': 'Account is deactivated',
      },
      'INVALID_REFRESH_TOKEN': {
        'ar': 'جلسة منتهية، يرجى تسجيل الدخول مرة أخرى',
        'en': 'Session expired, please login again',
      },
      'INVALID_ADMIN_TYPE': {
        'ar': 'نوع الحساب غير صحيح',
        'en': 'Invalid account type',
      },
      'FEATURE_COMING_SOON': {
        'ar': 'هذه الميزة ستتوفر قريباً',
        'en': 'This feature will be available soon',
      },
      'SPECIALTY_NOT_FOUND': {
        'ar': 'التخصص غير موجود',
        'en': 'Specialty not found',
      },
      'INVALID_CODE_LENGTH': {
        'ar': 'الكود يجب أن يكون 10 أحرف',
        'en': 'Code must be 10 characters',
      },
      
      // Password validation errors
      'PASSWORDS_DO_NOT_MATCH': {
        'ar': 'كلمات المرور غير متطابقة',
        'en': 'Passwords do not match',
      },
      'PASSWORD_TOO_SHORT': {
        'ar': 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
        'en': 'Password must be at least 8 characters',
      },
      'PASSWORD_NEEDS_UPPERCASE': {
        'ar': 'كلمة المرور يجب أن تحتوي على حرف كبير (A-Z)',
        'en': 'Password must contain an uppercase letter (A-Z)',
      },
      'PASSWORD_NEEDS_LOWERCASE': {
        'ar': 'كلمة المرور يجب أن تحتوي على حرف صغير (a-z)',
        'en': 'Password must contain a lowercase letter (a-z)',
      },
      'PASSWORD_NEEDS_NUMBER': {
        'ar': 'كلمة المرور يجب أن تحتوي على رقم (0-9)',
        'en': 'Password must contain a number (0-9)',
      },
      
      // Validation errors
      'VALIDATION_ERROR': {
        'ar': 'خطأ في البيانات المدخلة',
        'en': 'Invalid input data',
      },
      
      // Network errors
      'CONNECTION_ERROR': {
        'ar': 'خطأ في الاتصال بالخادم',
        'en': 'Connection error to server',
      },
      'CONNECTION_TIMEOUT': {
        'ar': 'انتهت مهلة الاتصال',
        'en': 'Connection timeout',
      },
      'SERVER_ERROR': {
        'ar': 'خطأ في الخادم، يرجى المحاولة لاحقاً',
        'en': 'Server error, please try again later',
      },
      
      // Default
      'UNKNOWN_ERROR': {
        'ar': 'حدث خطأ غير متوقع',
        'en': 'An unexpected error occurred',
      },
    };
    
    // Try to find the error translation
    if (errors.containsKey(errorCode)) {
      String translated = isArabic ? errors[errorCode]!['ar']! : errors[errorCode]!['en']!;
      
      // If there's extra error message, append it
      if (errorMessage != null && errorMessage!.isNotEmpty && errorMessage != 'Unknown error') {
        translated = '$translated\n\n$errorMessage';
      }
      
      return translated;
    }
    
    // If errorMessage contains the error code, try to parse it
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      for (final key in errors.keys) {
        if (errorMessage!.contains(key)) {
          return isArabic ? errors[key]!['ar']! : errors[key]!['en']!;
        }
      }
      return errorMessage!;
    }
    
    return isArabic ? errors['UNKNOWN_ERROR']!['ar']! : errors['UNKNOWN_ERROR']!['en']!;
  }
}

