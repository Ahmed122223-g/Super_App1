import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// API Service for backend communication
class ApiService {
  /// Dynamic Base URL that supports:
  /// - Environment variable from .env (Priority 1)
  /// - Compile-time dart-define (Priority 2): flutter run --dart-define=API_URL=http://10.0.2.2:8000/api
  /// - Default fallback for web/localhost (Priority 3)
  static String get baseUrl {
    try {
      // Priority 1: Environment variable
      final envUrl = dotenv.env['API_URL'];
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    } catch (_) {}
    
    // Priority 2: Compile-time dart-define
    const definedUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (definedUrl.isNotEmpty) return definedUrl;
    
    // Priority 3: Platform-aware default
    // For web and iOS simulator, localhost works
    // For Android Emulator, use: flutter run --dart-define=API_URL=http://10.0.2.2:8000/api
    // For physical devices, use: flutter run --dart-define=API_URL=http://YOUR_IP:8000/api
    return 'http://localhost:8000/api';
  }
  static String get staticUrl => '${baseUrl.replaceAll('/api', '')}/static/';
  static const String _tokenKey = 'auth_token';
  
  late final Dio _dio;
  String? _token;
  Completer<void>? _initCompleter;
  final _storage = const FlutterSecureStorage();
  
  static final ApiService _instance = ApiService._internal();
  
  // Callback for when 401 Unauthorized occurs
  VoidCallback? onUnauthorized;
  
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure token is loaded before making requests
        await _ensureInitialized();
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 Unauthorized globally (Single Session / Token Expiry)
        if (error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        return handler.next(error);
      },
    ));
    
    // Load token from storage on initialization
    _initCompleter = Completer<void>();
    _loadToken();
  }
  
  Future<void> _ensureInitialized() async {
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      await _initCompleter!.future;
    }
  }
  
  Future<void> _loadToken() async {
    // In secure storage, ready value is async
    _token = await _storage.read(key: _tokenKey);
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      _initCompleter!.complete();
    }
  }
  
  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }
  
  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }
  
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  
  // ==================== Auth Endpoints ====================
  
  /// Register a new user
  Future<ApiResponse<Map<String, dynamic>>> registerUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    int? age,
    String? address,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': password,
        if (phone != null) 'phone': phone,
        if (age != null) 'age': age,
        if (address != null) 'address': address,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Register a doctor
  Future<ApiResponse<Map<String, dynamic>>> registerDoctor({
    required String name,
    required String email,
    required String password,
    required String registrationCode,
    required int specialtyId,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final data = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': password,
        'registration_code': registrationCode,
        'specialty_id': specialtyId,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null && description.isNotEmpty) 'description': description,
      };
      
      if (kDebugMode) {
        print('=== REGISTER DOCTOR REQUEST ===');
        // Do not print sensitive data in production
        print('Data: ${data.keys.toList()}'); 
      }
      
      final response = await _dio.post('/auth/register/doctor', data: data);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== REGISTER DOCTOR ERROR ===');
        print('Status: ${e.response?.statusCode}');
      }
      return _handleError(e);
    }
  }
  
  /// Register a teacher
  Future<ApiResponse<Map<String, dynamic>>> registerTeacher({
    required String name,
    required String email,
    required String password,
    required String registrationCode,
    required int subjectId,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required List<Map<String, dynamic>> pricing,
    String? description,
  }) async {
    try {
      final data = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': password,
        'registration_code': registrationCode,
        'subject_id': subjectId,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'pricing': pricing,
        if (description != null) 'description': description,
      };
      
      if (kDebugMode) {
        print('=== REGISTER TEACHER REQUEST ===');
      }
      
      final response = await _dio.post('/auth/register/teacher', data: data);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== REGISTER TEACHER ERROR ===');
        print('Status: ${e.response?.statusCode}');
      }
      return _handleError(e);
    }
  }

  /// Register a pharmacy
  Future<ApiResponse<Map<String, dynamic>>> registerPharmacy({
    required String name,
    required String email,
    required String password,
    required String registrationCode,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final response = await _dio.post('/auth/register/pharmacy', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': password,
        'registration_code': registrationCode,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null) 'description': description,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Login
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.data['access_token'] != null) {
        await setToken(response.data['access_token']);
      }
      
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Verify registration code
  Future<ApiResponse<Map<String, dynamic>>> verifyCode({
    required String code,
    required String type, // doctor, pharmacy, etc.
  }) async {
    try {
      final response = await _dio.post('/auth/register/verify-code', data: {
        'code': code,
        'type': type,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  // ==================== Doctors Endpoints ====================
  
  /// Get all doctors
  Future<ApiResponse<List<dynamic>>> getDoctors({
    int? specialtyId,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get('/doctors', queryParameters: {
        if (specialtyId != null) 'specialty_id': specialtyId,
        'skip': skip,
        'limit': limit,
      });
      if (response.data is List) {
        return ApiResponse.success(response.data as List<dynamic>);
      } else if (response.data is Map) {
        final items = response.data['doctors'] ?? response.data['items'] ?? response.data['data'] ?? [];
        return ApiResponse.success(items as List<dynamic>);
      }
      return ApiResponse.success([]);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  Future<ApiResponse<List<dynamic>>> searchDoctors({
    String? name,
    int? specialtyId,
  }) async {
    try {
      final response = await _dio.get('/doctors/search', queryParameters: {
        if (name != null) 'name': name,
        if (specialtyId != null) 'specialty_id': specialtyId,
      });
      if (response.data is List) {
        return ApiResponse.success(response.data as List<dynamic>);
      } else if (response.data is Map) {
        final items = response.data['items'] ?? response.data['data'] ?? [];
        return ApiResponse.success(items as List<dynamic>);
      }
      return ApiResponse.success([]);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  // ==================== Pharmacies Endpoints ====================
  
  /// Get all pharmacies
  Future<ApiResponse<List<dynamic>>> getPharmacies({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get('/pharmacies', queryParameters: {
        'skip': skip,
        'limit': limit,
      });
      // Handle both List and paginated Map responses
      if (response.data is List) {
        return ApiResponse.success(response.data as List<dynamic>);
      } else if (response.data is Map) {
        final items = response.data['pharmacies'] ?? response.data['items'] ?? response.data['data'] ?? [];
        return ApiResponse.success(items as List<dynamic>);
      }
      return ApiResponse.success([]);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Search pharmacies
  Future<ApiResponse<List<dynamic>>> searchPharmacies({
    String? name,
  }) async {
    try {
      final response = await _dio.get('/pharmacies/search', queryParameters: {
        if (name != null) 'name': name,
      });
      // Handle both List and paginated Map responses
      if (response.data is List) {
        return ApiResponse.success(response.data as List<dynamic>);
      } else if (response.data is Map) {
        final items = response.data['items'] ?? response.data['data'] ?? [];
        return ApiResponse.success(items as List<dynamic>);
      }
      return ApiResponse.success([]);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  // ==================== Teachers Endpoints ====================
  
  /// Get all teachers
  Future<ApiResponse<List<dynamic>>> getTeachers({
    int? subjectId,
    String? name,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get('/teachers', queryParameters: {
        if (subjectId != null) 'subject_id': subjectId,
        if (name != null && name.isNotEmpty) 'name': name,
        'skip': skip,
        'limit': limit,
      });
      if (response.data is List) {
        return ApiResponse.success(response.data as List<dynamic>);
      } else if (response.data is Map) {
        final items = response.data['teachers'] ?? response.data['items'] ?? response.data['data'] ?? [];
        return ApiResponse.success(items as List<dynamic>);
      }
      return ApiResponse.success([]);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Search teachers
  Future<ApiResponse<List<dynamic>>> searchTeachers({
    String? name,
    int? subjectId,
  }) async {
    try {
      final response = await _dio.get('/teachers/search', queryParameters: {
        if (name != null) 'q': name,
        if (subjectId != null) 'subject_id': subjectId,
      });
      if (response.data is List) {
        return ApiResponse.success(response.data as List<dynamic>);
      } else if (response.data is Map) {
        final items = response.data['teachers'] ?? response.data['items'] ?? response.data['data'] ?? [];
        return ApiResponse.success(items as List<dynamic>);
      }
      return ApiResponse.success([]);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get subjects
  Future<ApiResponse<List<dynamic>>> getSubjects() async {
    try {
      final response = await _dio.get('/teachers/subjects');
      return ApiResponse.success(response.data as List<dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ==================== Dashboard Endpoints ====================

  /// Get provider profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final response = await _dio.get('/dashboard/profile');
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Update doctor profile
  Future<ApiResponse<Map<String, dynamic>>> updateDoctorProfile({
    double? consultationFee,
    double? examinationFee,
    String? phone,
    String? address,
    String? description,
    String? profileImage,
    Map<String, dynamic>? workingHours,
  }) async {
    try {
      final response = await _dio.patch('/dashboard/profile/doctor', data: {
        if (consultationFee != null) 'consultation_fee': consultationFee,
        if (examinationFee != null) 'examination_fee': examinationFee,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (description != null) 'description': description,
        if (profileImage != null) 'profile_image': profileImage,
        if (workingHours != null) 'working_hours': workingHours,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Update pharmacy profile
  Future<ApiResponse<Map<String, dynamic>>> updatePharmacyProfile({
    bool? deliveryAvailable,
    String? profileImage,
    Map<String, dynamic>? workingHours,
    String? phone,
  }) async {
    try {
      final response = await _dio.patch('/dashboard/profile/pharmacy', data: {
        if (deliveryAvailable != null) 'delivery_available': deliveryAvailable,
        if (profileImage != null) 'profile_image': profileImage,
        if (workingHours != null) 'working_hours': workingHours,
        if (phone != null) 'phone': phone,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Update teacher profile
  Future<ApiResponse<Map<String, dynamic>>> updateTeacherProfile({
    String? phone,
    String? whatsapp,
    String? profileImage,
    String? description,
    List<Map<String, dynamic>>? pricing,
  }) async {
    try {
      final response = await _dio.patch('/dashboard/profile/teacher', data: {
        if (phone != null) 'phone': phone,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (profileImage != null) 'profile_image': profileImage,
        if (description != null) 'description': description,
        if (pricing != null) 'pricing': pricing,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get reservations (Doctor/Teacher)
  Future<ApiResponse<List<dynamic>>> getReservations() async {
    try {
      final response = await _dio.get('/dashboard/reservations');
      return ApiResponse.success(response.data as List<dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Respond to reservation
  Future<ApiResponse<Map<String, dynamic>>> respondToReservation({
    required int id,
    required String action, // accept, reject, complete
    String? reason,
    Map<String, List<String>>? schedule, // {"Sunday": ["10:00", "11:00"]}
  }) async {
    try {
      final response = await _dio.post('/dashboard/reservations/$id/action', data: {
        'action': action,
        if (reason != null) 'reason': reason,
        if (schedule != null) 'schedule': schedule,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get pharmacy orders
  Future<ApiResponse<List<dynamic>>> getOrders() async {
    try {
      final response = await _dio.get('/dashboard/orders');
      return ApiResponse.success(response.data as List<dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Respond to order (Set Price)
  Future<ApiResponse<Map<String, dynamic>>> updateOrderPrice({
    required int id,
    required double totalPrice,
    double deliveryFee = 0.0,
    required String estimatedTime,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/dashboard/orders/$id/price', data: {
        'total_price': totalPrice,
        'delivery_fee': deliveryFee,
        'estimated_time': estimatedTime,
        if (notes != null) 'notes': notes,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ==================== Specialties Endpoints ====================
  
  /// Get all specialties
  Future<ApiResponse<List<dynamic>>> getSpecialties() async {
    try {
      final response = await _dio.get('/specialties');
      // Handle both List and paginated Map responses
      if (response.data is List) {
        return ApiResponse.success(response.data as List<dynamic>);
      } else if (response.data is Map) {
        final items = response.data['items'] ?? response.data['data'] ?? [];
        return ApiResponse.success(items as List<dynamic>);
      }
      return ApiResponse.success([]);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  // ==================== Error Handling ====================
  
  ApiResponse<T> _handleError<T>(DioException e) {
    String errorCode = 'UNKNOWN_ERROR';
    String message = 'Unknown error';
    
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map) {
        // Check for new structured error format: {error_code, message, details[]}
        if (data['error_code'] != null) {
          errorCode = data['error_code'].toString();
          message = data['message']?.toString() ?? 'Unknown error';
          
          // Extract details if present
          if (data['details'] is List && (data['details'] as List).isNotEmpty) {
            final details = data['details'] as List;
            final List<String> errorDetails = [];
            for (final detail in details) {
              if (detail is Map) {
                final field = detail['field']?.toString() ?? '';
                final fieldMsg = detail['message']?.toString() ?? '';
                errorDetails.add('$field: $fieldMsg');
              }
            }
            if (errorDetails.isNotEmpty) {
              message = errorDetails.join('\n');
            }
          }
        }
        // Check for legacy detail format
        else if (data['detail'] != null) {
          final detail = data['detail'];
          if (detail is Map) {
            errorCode = detail['error_code']?.toString() ?? 'UNKNOWN_ERROR';
            message = detail['message']?.toString() ?? 'Unknown error';
          } else if (detail is String) {
            // Parse string error
            if (detail.contains('PASSWORD_NEEDS_UPPERCASE')) {
              errorCode = 'PASSWORD_NEEDS_UPPERCASE';
            } else if (detail.contains('PASSWORD_NEEDS_LOWERCASE')) {
              errorCode = 'PASSWORD_NEEDS_LOWERCASE';
            } else if (detail.contains('PASSWORD_NEEDS_NUMBER')) {
              errorCode = 'PASSWORD_NEEDS_NUMBER';
            } else if (detail.contains('SHORT')) {
              errorCode = 'PASSWORD_TOO_SHORT';
            } else if (detail.contains('MATCH')) {
              errorCode = 'PASSWORDS_DO_NOT_MATCH';
            } else {
              message = detail;
            }
          } else if (detail is List && detail.isNotEmpty) {
            // Pydantic validation errors
            final List<String> errorMessages = [];
            for (final err in detail) {
              if (err is Map) {
                final msg = err['msg']?.toString() ?? '';
                final loc = err['loc'] as List?;
                final fieldName = loc != null && loc.length > 1 ? loc.last.toString() : '';
                errorMessages.add('$fieldName: $msg');
              }
            }
            if (errorMessages.isNotEmpty) {
              errorCode = 'VALIDATION_ERROR';
              message = errorMessages.join(', ');
            }
          }
        }
      }
      
      // Fallback based on status code
      if (errorCode == 'UNKNOWN_ERROR') {
        if (e.response!.statusCode == 400) {
          errorCode = 'INVALID_REQUEST';
        } else if (e.response!.statusCode == 401) {
          errorCode = 'INVALID_CREDENTIALS';
        } else if (e.response!.statusCode == 404) {
          errorCode = 'NOT_FOUND';
        } else if (e.response!.statusCode == 409) {
          errorCode = 'EMAIL_ALREADY_EXISTS';
        } else if (e.response!.statusCode == 422) {
          errorCode = 'VALIDATION_ERROR';
          message = 'Data validation failed';
        } else if (e.response!.statusCode! >= 500) {
          errorCode = 'SERVER_ERROR';
        }
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout) {
      errorCode = 'CONNECTION_TIMEOUT';
    } else if (e.type == DioExceptionType.connectionError) {
      errorCode = 'CONNECTION_ERROR';
    }
    
    return ApiResponse.error(errorCode, message);
  }

  // ==================== User Map & Search Endpoints ====================

  /// Unified search
  Future<ApiResponse<Map<String, dynamic>>> search({
    required String query, 
    String type = 'all',
    String? sort,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'type': type,
      };
      
      if (sort != null) queryParams['sort'] = sort;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (minRating != null) queryParams['min_rating'] = minRating.toString();

      final response = await _dio.get('/search/', queryParameters: queryParams);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // --- Favorites ---
  
  Future<ApiResponse<Map<String, dynamic>>> toggleFavorite(int providerId, String providerType) async {
    try {
      final response = await _dio.post('/favorites/toggle', data: {
        'provider_id': providerId,
        'provider_type': providerType,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<dynamic>>> getFavorites({String? type}) async {
    try {
      final response = await _dio.get('/favorites/', queryParameters: type != null ? {'type': type} : null);
      if (response.data is List) {
        return ApiResponse.success(response.data as List<dynamic>);
      }
      return ApiResponse.error("Invalid response format");
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get all providers for the map with optional teacher filters
  Future<ApiResponse<Map<String, dynamic>>> getAllProviders({
    String city = 'الواسطي',
    String? teacherName,
    int? subjectId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'city': city};
      if (teacherName != null && teacherName.isNotEmpty) {
        queryParams['teacher_name'] = teacherName;
      }
      if (subjectId != null) {
        queryParams['subject_id'] = subjectId;
      }
      final response = await _dio.get('/search/all', queryParameters: queryParams);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Create a rating for a provider
  Future<ApiResponse<Map<String, dynamic>>> createRating({
    required int providerId,
    required String providerType,
    required int rating,
    String? comment,
    bool isAnonymous = false,
  }) async {
    try {
      final response = await _dio.post('/ratings/', data: {
        if (providerType == 'doctor') 'doctor_id': providerId,
        if (providerType == 'pharmacy') 'pharmacy_id': providerId,
        if (providerType == 'teacher') 'teacher_id': providerId,
        'rating': rating,
        if (comment != null) 'comment': comment,
        'is_anonymous': isAnonymous,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get ratings for a provider
  Future<ApiResponse<Map<String, dynamic>>> getProviderRatings({
    required int providerId,
    required String providerType,
    String? sort,
    int? stars,
  }) async {
    try {
      final endpoint = '/ratings/$providerType/$providerId';
      final response = await _dio.get(endpoint, queryParameters: {
        if (sort != null) 'sort': sort,
        if (stars != null) 'stars': stars,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  
  /// Check if filename is an image
  bool _isImage(String filename) {
    final ext = filename.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || 
           ext.endsWith('.png') || ext.endsWith('.webp');
  }
  
  /// Compress image bytes for optimal upload
  /// Always compresses images to reduce bandwidth and upload time
  Future<List<int>> _compressImage(List<int> bytes, String filename) async {
    if (!_isImage(filename)) return bytes;
    
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        minHeight: 1920,  // Max height (maintains aspect ratio)
        minWidth: 1080,   // Max width
        quality: 75,      // Good quality/size balance
        format: CompressFormat.jpeg,
      );
      
      if (kDebugMode) {
        final originalSize = (bytes.length / 1024).toStringAsFixed(1);
        final compressedSize = (compressed.length / 1024).toStringAsFixed(1);
        final savings = ((1 - compressed.length / bytes.length) * 100).toStringAsFixed(0);
        print('📷 Image compressed: ${originalSize}KB → ${compressedSize}KB (${savings}% saved)');
      }
      
      return compressed;
    } catch (e) {
      if (kDebugMode) print('⚠️ Compression failed, using original: $e');
      return bytes;
    }
  }
  
  /// Upload file with automatic image compression
  Future<ApiResponse<Map<String, dynamic>>> uploadFile(List<int> bytes, String filename) async {
    try {
      // Always compress images for optimal upload
      final fileBytes = await _compressImage(bytes, filename);

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: filename),
      });
      
      final response = await _dio.post('/utils/upload', data: formData);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ==================== User Profile Updates ====================

  Future<ApiResponse<void>> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> updateUserProfile(Map<String, dynamic> data) async {
    try {
      // Reverting to sending JSON as backend will be reverted to Pydantic model or we can keep FormData logic but without avatar support if backend accepts Form.
      // But user requested removal of avatar upload.
      // If backend is reverted to `UserProfileUpdate`, it expects JSON.
      // So I will revert to sending `data` directly (which Dio handles as JSON usually if not FormData).
      await _dio.patch('/dashboard/profile/user', data: data);
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteAccount(String email) async {
    try {
      await _dio.delete('/auth/delete-account', queryParameters: {'email': email});
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ==========================================
  // BOOKING & ORDERS (User)
  // ==========================================

  Future<ApiResponse<Map<String, dynamic>>> createBooking({
    required int providerId,
    required String providerType,
    required String bookingType,
    required DateTime visitDate,
    required String patientName,
    required String patientPhone,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/dashboard/reservations/book', data: {
        'provider_id': providerId,
        'provider_type': providerType,
        'booking_type': bookingType,
        'visit_date': visitDate.toIso8601String(),
        'patient_name': patientName,
        'patient_phone': patientPhone,
        'notes': notes,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<String>>> getDoctorSlots({
    required int doctorId,
    required DateTime date,
  }) async {
    try {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final response = await _dio.get(
        '/doctors/$doctorId/slots',
        queryParameters: {'date': dateStr},
      );
      return ApiResponse.success(List<String>.from(response.data));
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> requestTeacherBooking({
    required int teacherId,
    required String studentName,
    required String studentPhone,
    String? gradeLevel,
    String? notes,
    required DateTime requestedDate,
  }) async {
    try {
      final response = await _dio.post('/teachers/request', data: {
        'teacher_id': teacherId,
        'student_name': studentName,
        'student_phone': studentPhone,
        'grade_level': gradeLevel,
        'notes': notes,
        'requested_date': requestedDate.toIso8601String(),
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<dynamic>>> getMyReservations() async {
    try {
      final response = await _dio.get('/dashboard/my-reservations');
      return ApiResponse.success(response.data as List<dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> cancelReservation(int id, String providerType) async {
    try {
      await _dio.delete('/dashboard/reservations/$id', queryParameters: {'provider_type': providerType});
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createOrder({
    required int pharmacyId,
    String? itemsText,
    String? prescriptionImage,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/dashboard/orders/create', data: {
        'pharmacy_id': pharmacyId,
        'items_text': itemsText,
        'prescription_image': prescriptionImage,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'notes': notes,
      });
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> respondToOrder({required int id, required String action}) async {
    try {
      await _dio.post('/dashboard/orders/$id/action', data: {'action': action});
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> pharmacyOrderAction({required int id, required String action}) async {
    try {
      await _dio.post('/dashboard/orders/$id/pharmacy-action', data: {'action': action});
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<dynamic>>> getMyOrders() async {
    try {
      final response = await _dio.get('/dashboard/my-orders');
      return ApiResponse.success(response.data as List<dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }



  Future<ApiResponse<void>> deleteProviderReservation(int id, String providerType) async {
    try {
      await _dio.delete('/dashboard/provider/reservations/$id', queryParameters: {'provider_type': providerType});
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> deletePharmacyOrder(int id) async {
    try {
      await _dio.delete('/dashboard/provider/orders/$id');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // --- Addresses ---
  
  Future<ApiResponse<List<dynamic>>> getAddresses() async {
    try {
      final response = await _dio.get('/addresses/');
      return ApiResponse.success(response.data as List<dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createAddress(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/addresses/', data: data);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAddress(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/addresses/$id', data: data);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteAddress(int id) async {
    try {
      await _dio.delete('/addresses/$id');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }



  Future<ApiResponse<void>> registerFcmToken(String token) async {
    try {
      // Determine device type for multi-device support
      String deviceType = 'unknown';
      if (kIsWeb) {
        deviceType = 'web';
      } else {
        // For mobile, we'd need dart:io Platform check
        // Default to 'mobile' for now
        deviceType = 'mobile';
      }
      
      await _dio.post('/auth/fcm-token', data: {
        'token': token,
        'device_type': deviceType,
      });
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
  // ==========================================
  // NOTIFICATIONS
  // ==========================================
  
  Future<ApiResponse<List<dynamic>>> getNotifications({int skip = 0, int limit = 20}) async {
    try {
      final response = await _dio.get('/notifications/', queryParameters: {
        'skip': skip,
        'limit': limit,
      });
      
      return ApiResponse.success(response.data as List<dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> markNotificationRead(int id) async {
    try {
      await _dio.patch('/notifications/$id/read');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> markAllNotificationsRead() async {
    try {
      await _dio.post('/notifications/read-all');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? errorCode;
  final String? errorMessage;
  final bool isSuccess;
  
  ApiResponse._({this.data, this.errorCode, this.errorMessage, required this.isSuccess});
  
  factory ApiResponse.success(T data) => ApiResponse._(data: data, isSuccess: true);
  factory ApiResponse.error(String code, [String? message]) => ApiResponse._(
    errorCode: code, 
    errorMessage: message,
    isSuccess: false,
  );
  
  // Legacy getter for compatibility
  String? get error => errorCode;
}

