import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class BackgroundLocationService {
  static const String _serviceName = 'location_tracking_service';
  static const String _notificationTitle = 'Location Tracking';
  static const String _notificationContent = 'Sharing location in background';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _serviceName,
        initialNotificationTitle: _notificationTitle,
        initialNotificationContent: _notificationContent,
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp();

    Timer? locationTimer;
    String? driverId;

    service.on('startLocationTracking').listen((event) {
      driverId = event?['driverId'] as String?;
      if (driverId == null) return;

      // Start periodic location updates every 30 seconds
      locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        await _sendLocationUpdate(driverId!);
      });

      // Send initial location
      _sendLocationUpdate(driverId!);

      service.invoke('updateNotification', {
        'title': _notificationTitle,
        'content': 'Tracking location for driver: $driverId',
      });
    });

    service.on('stopLocationTracking').listen((event) {
      locationTimer?.cancel();
      locationTimer = null;
      driverId = null;

      service.invoke('updateNotification', {
        'title': _notificationTitle,
        'content': 'Location tracking stopped',
      });
    });

    service.on('setAsForeground').listen((event) {
      // Service is already running in foreground mode
    });

    service.on('setAsBackground').listen((event) {
      // Service is already running in foreground mode
    });
  }

  static Future<void> _sendLocationUpdate(String driverId) async {
    try {
      // Ensure we're authenticated
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      // Prepare data
      final DateTime now = DateTime.now();
      final int timestampMs = now.millisecondsSinceEpoch;
      final String readable = now.toIso8601String();

      final Map<String, dynamic> payload = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'readableTimestamp': readable,
        'source': 'background_service',
      };

      // Send to Firebase Realtime Database
      final DatabaseReference ref = FirebaseDatabase.instance.ref('locations/$driverId');
      await ref.child(timestampMs.toString()).set(payload);

      // Location successfully sent to Firebase
    } catch (e) {
      // Error sending background location - will retry on next interval
    }
  }

  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  static Future<void> startService(String driverId) async {
    final service = FlutterBackgroundService();
    service.invoke('startLocationTracking', {'driverId': driverId});
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopLocationTracking');
  }
}
