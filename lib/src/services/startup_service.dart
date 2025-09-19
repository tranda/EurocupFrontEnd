import 'package:eurocup_frontend/src/common.dart';
import 'package:eurocup_frontend/src/model/user.dart';
import 'package:eurocup_frontend/src/api_helper.dart' as api;

/// Service responsible for loading critical data during app startup
/// This ensures all essential data is available before navigating to pages
class StartupService {
  static bool _isInitialized = false;
  static bool _isLoading = false;
  static String? _errorMessage;

  /// Check if the app has been properly initialized with all critical data
  static bool get isInitialized => _isInitialized;

  /// Check if initialization is currently in progress
  static bool get isLoading => _isLoading;

  /// Get any error message from failed initialization
  static String? get errorMessage => _errorMessage;

  /// Initialize all critical app data
  /// Returns true if successful, false if failed
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true; // Already initialized
    }

    if (_isLoading) {
      // Wait for current initialization to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    _isLoading = true;
    _errorMessage = null;

    try {
      // Step 1: Load token from storage
      loadToken();

      // Step 2: Load competitions list (needed for all users, public or authenticated)
      try {
        competitions = await api.getCompetitions();
      } catch (e) {
        print('Warning: Failed to load competitions: $e');
        competitions = []; // Continue with empty list
      }

      // Step 3: If token exists, try to restore user data
      if (token != null && token!.isNotEmpty) {
        final user = await api.getCurrentUser();
        if (user == null) {
          print('Warning: Failed to get user data - token may be expired');
          clearToken(); // Clear invalid token
        } else {
          currentUser = user;
        }

        // Step 4: Load disciplines (for authenticated users)
        try {
          disciplines = await api.getDisciplinesAll(eventId: EVENTID);
        } catch (e) {
          print('Warning: Failed to load disciplines: $e');
          disciplines = []; // Continue with empty list
        }
      }

      _isInitialized = true;
      _isLoading = false;
      return true; // Always return true since we loaded basic data

    } catch (e) {
      _errorMessage = 'Initialization failed: $e';
      _isLoading = false;
      _isInitialized = false;
      return false;
    }
  }

  /// Reset initialization state (useful for logout)
  static void reset() {
    _isInitialized = false;
    _isLoading = false;
    _errorMessage = null;

    // Clear global data
    currentUser = User();
    competitions = [];
    disciplines = [];
    clearToken();
  }

  /// Check if user is properly authenticated
  static bool get isAuthenticated {
    return token != null &&
           token!.isNotEmpty &&
           currentUser.accessLevel != null;
  }

  /// Get initialization status for debugging
  static Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading,
      'hasToken': token?.isNotEmpty ?? false,
      'hasUser': currentUser.accessLevel != null,
      'competitionsCount': competitions.length,
      'disciplinesCount': disciplines.length,
      'errorMessage': _errorMessage,
    };
  }
}