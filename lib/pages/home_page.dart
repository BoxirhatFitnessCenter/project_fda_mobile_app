import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.driverId});

  final String driverId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<Position>? _positionSub;
  bool _isSending = false;
  String _status = 'Stopped';

  @override
  void dispose() {
    _stopSending();
    super.dispose();
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

    final DatabaseReference ref = FirebaseDatabase.instance.ref('locations/${widget.driverId}');

    setState(() {
      _isSending = true;
      _status = 'Sending location…';
    });

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((Position position) async {
      final DateTime now = DateTime.now();
      final int timestampMs = now.millisecondsSinceEpoch;
      final String readable = now.toIso8601String();

      final Map<String, dynamic> payload = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'readableTimestamp': readable,
      };

      try {
        await ref.child(timestampMs.toString()).set(payload);
      } catch (e) {
        if (mounted) {
          setState(() => _status = 'Error sending: ${e.toString()}');
        }
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => _status = 'Location stream error: ${e.toString()}');
      }
    });
  }

  Future<void> _stopSending() async {
    await _positionSub?.cancel();
    _positionSub = null;
    setState(() {
      _isSending = false;
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
                  onPressed: _isSending ? null : _startSending,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSending ? _stopSending : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
