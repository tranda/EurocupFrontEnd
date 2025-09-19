import 'package:flutter/material.dart';
import 'package:eurocup_frontend/src/services/startup_service.dart';
import 'package:eurocup_frontend/src/login_view.dart';
import 'package:eurocup_frontend/src/widgets.dart';

/// Wrapper widget that handles app initialization before showing content
class StartupWrapper extends StatefulWidget {
  final Widget child;
  final String? targetRoute;

  const StartupWrapper({
    super.key,
    required this.child,
    this.targetRoute,
  });

  @override
  State<StartupWrapper> createState() => _StartupWrapperState();
}

class _StartupWrapperState extends State<StartupWrapper> {
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final success = await StartupService.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          if (!success) {
            _errorMessage = StartupService.errorMessage;
          }
        });

        // If initialization failed, redirect to login
        if (!success && StartupService.errorMessage != null) {
          Navigator.of(context).pushReplacementNamed(LoginView.routeName);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to initialize app: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (!StartupService.isAuthenticated) {
      // Not authenticated, should redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(LoginView.routeName);
      });
      return _buildLoadingScreen();
    }

    // All good, show the actual content
    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: appBar(title: 'Events Platform'),
      body: Container(
        decoration: bckDecoration(),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: appBar(title: 'Events Platform'),
      body: Container(
        decoration: bckDecoration(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load app data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _errorMessage = null;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  StartupService.reset();
                  Navigator.of(context).pushReplacementNamed(LoginView.routeName);
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}