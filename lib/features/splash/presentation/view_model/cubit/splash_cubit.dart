import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mushaf_alsawy/core/cache_manager/cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashCubit extends Cubit<String> {
  SplashCubit() : super('');

  Future<void> startSplashScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final String? token = await CacheManager.getAccessToken();
    // If the user hasn't seen onboarding yet, show it first.
    if (!hasSeenOnboarding) {
      emit('onboarding');
      return;
    }

    // If there is a valid token, go to home. Otherwise, go to login.
    if (token != null && token.isNotEmpty) {
      emit('home');
    } else {
      emit('login');
    }
  }

  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuestMode', true);
  }

  // Method to disable Guest mode
  Future<void> disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuestMode', false);
  }
}
