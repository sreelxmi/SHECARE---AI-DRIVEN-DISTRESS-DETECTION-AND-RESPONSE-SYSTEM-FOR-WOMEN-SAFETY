import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SOSService {
  static const platform = MethodChannel('volume.channel');
  static final Telephony telephony = Telephony.instance;

  static String latitude = "0.0";
  static String longitude = "0.0";
  static bool _sending = false;

  // ✅ Trigger SOS (you can call this from anywhere)
  static Future<void> triggerSOS({ required phone}) async {
    if (_sending) return; // avoid multiple triggers
    _sending = true;
    Fluttertoast.showToast(msg: "🚨 SOS Triggered!");

    try {
      await _getLocation();
      final message = """ Emergency Alert!
My current location:
https://maps.google.com/?q=$latitude+$longitude""";

      for (int i = 0; i < phone.length; i++) {
        String phn = phone[i].toString();
        print(phn);
        final bool result = await platform.invokeMethod('sendSms', {
          'phoneNumber': phn,
          'message': message,
        });
        if (result) {
          Fluttertoast.showToast(msg: "✅ SOS message sent!");
        } else {
          Fluttertoast.showToast(msg: "❌ Failed to send SOS");
        }
      }
      // Send SMS via native Android (your MainActivity)
    } catch (e) {
      Fluttertoast.showToast(msg: "❌ SOS Error: $e");
    }

    await Future.delayed(const Duration(seconds: 5));
    _sending = false;
  }

  static Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location service disabled");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permanently denied");
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude = position.latitude.toStringAsFixed(6);
      longitude = position.longitude.toStringAsFixed(6);

      await platform.invokeMethod("updateLocation", {
        "latitude": latitude,
        "longitude": longitude,
      });
    } catch (e) {
      throw Exception("Error getting location: $e");
    }
  }
}
