import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../services/background_location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.driverId});

  final String driverId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<Position>? _positionSub;
  bool _isSending = false;
  bool _isBackgroundMode = false;
  String _status = 'Stopped';

  @override
  void initState() {
    super.initState();
    _checkBackgroundServiceStatus();
  }

  @override
  void dispose() {
    _stopSending();
    super.dispose();
  }

  Future<void> _checkBackgroundServiceStatus() async {
    final isRunning = await BackgroundLocationService.isRunning();
    if (mounted) {
      setState(() {
        _isBackgroundMode = isRunning;
        if (_isBackgroundMode) {
          _status = 'Background tracking active';
        }
      });
    }
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = 'Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _status = 'Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _status = 'Location permission permanently denied');
      return false;
    }

    return true;
  }

  Future<void> _ensureAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (e) {
        setState(() => _status = 'Auth failed: ${e.toString()}');
      }
    }
  }

  Future<void> _startSending() async {
    final ok = await _ensurePermission();
    if (!ok) return;

    await _ensureAuthenticated();

    setState(() {
      _isSending = true;
      _status = 'Sending location…';
    });

    // Start foreground location tracking
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((Position position) async {
      await _sendLocationUpdate(position);
    }, onError: (e) {
      if (mounted) {
        setState(() => _status = 'Location stream error: ${e.toString()}');
      }
    });
  }

  Future<void> _startBackgroundTracking() async {
    final ok = await _ensurePermission();
    if (!ok) return;

    await _ensureAuthenticated();

    // Start background service
    await BackgroundLocationService.startService(widget.driverId);
    
    setState(() {
      _isBackgroundMode = true;
      _status = 'Background tracking started';
    });
  }

  Future<void> _sendLocationUpdate(Position position) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('locations/${widget.driverId}');
    
    final DateTime now = DateTime.now();
    final int timestampMs = now.millisecondsSinceEpoch;
    final String readable = now.toIso8601String();

    final Map<String, dynamic> payload = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'readableTimestamp': readable,
      'source': 'foreground',
    };

    try {
      await ref.child(timestampMs.toString()).set(payload);
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Error sending: ${e.toString()}');
      }
    }
  }

  Future<void> _stopSending() async {
    await _positionSub?.cancel();
    _positionSub = null;
    
    // Stop background service
    await BackgroundLocationService.stopService();
    
    setState(() {
      _isSending = false;
      _isBackgroundMode = false;
      _status = 'Stopped';
    });
  }

  void _logout() {
    _stopSending();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home - ${widget.driverId}'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isSending || _isBackgroundMode ? null : _startSending,
                  child: const Text('Start Foreground'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSending || _isBackgroundMode ? null : _startBackgroundTracking,
                  child: const Text('Start Background'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (_isSending || _isBackgroundMode) ? _stopSending : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isBackgroundMode)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.green),
                      SizedBox(height: 8),
                      Text('Background tracking is active'),
                      Text('Location will be shared every 30 seconds'),
                      Text('even when app is closed'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}