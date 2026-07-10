// ===============================================================
// availability_log_service.dart
// ---------------------------------------------------------------
// Logs every Check Availability attempt from the Flutter app.
//
// PURPOSE
// ---------------------------------------------------------------
// Creates records in availability_search_logs using:
//
//   action=logAvailabilitySearch
//
// IMPORTANT
// ---------------------------------------------------------------
// Logging is analytical only.
//
// A logging failure must never:
// - block route search
// - show an error to the customer
// - change booking state
// - interrupt payment flow
// ===============================================================

import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants/app_constants.dart';


// ===============================================================
// AVAILABILITY LOG REQUEST
// ===============================================================
class AvailabilityLogRequest {
  final String tripType;
  final String travelDate;
  final String fromStop;
  final String toStop;
  final int seatsRequired;

  final String userEmail;
  final String userName;

  const AvailabilityLogRequest({
    required this.tripType,
    required this.travelDate,
    required this.fromStop,
    required this.toStop,
    required this.seatsRequired,
    required this.userEmail,
    required this.userName,
  });
}


// ===============================================================
// DEVICE INFORMATION MODEL
// ===============================================================
class AvailabilityDeviceInfo {
  final String device;
  final String deviceType;

  final String os;
  final String osVersion;

  final String browser;
  final String browserVersion;

  final String model;

  final String screenSize;
  final String viewportSize;

  final String networkType;

  final Map<String, dynamic> rawJson;

  const AvailabilityDeviceInfo({
    required this.device,
    required this.deviceType,
    required this.os,
    required this.osVersion,
    required this.browser,
    required this.browserVersion,
    required this.model,
    required this.screenSize,
    required this.viewportSize,
    required this.networkType,
    required this.rawJson,
  });
}


// ===============================================================
// AVAILABILITY LOG SERVICE
// ===============================================================
class AvailabilityLogService {
  final DeviceInfoPlugin _deviceInfoPlugin =
      DeviceInfoPlugin();

  final Connectivity _connectivity =
      Connectivity();

  // =============================================================
  // LOG AVAILABILITY SEARCH
  // -------------------------------------------------------------
  // This method catches its own errors intentionally.
  //
  // Call it without await from booking_screen.dart.
  // =============================================================
  Future<void> logAvailabilitySearch({
    required BuildContext context,
    required AvailabilityLogRequest request,
  }) async {
    try {
      debugPrint(
        '📝 Logging mobile availability search...',
      );

      final deviceInfo =
          await _collectDeviceInfo(context);

      final parameters = <String, String>{
        'action': 'logAvailabilitySearch',

        'trip_type':
            request.tripType.trim().isEmpty
                ? 'ONEWAY'
                : request.tripType
                    .trim()
                    .toUpperCase(),

        'travel_date':
            request.travelDate.trim(),

        'from_stop':
            request.fromStop.trim(),

        'to_stop':
            request.toStop.trim(),

        'seats_required':
            '${request.seatsRequired}',

        'user_email':
            request.userEmail.trim().isEmpty
                ? 'GUEST'
                : request.userEmail.trim(),

        'user_name':
            request.userName.trim().isEmpty
                ? 'Guest User'
                : request.userName.trim(),

        'device':
            deviceInfo.device,

        'device_type':
            deviceInfo.deviceType,

        'os':
            deviceInfo.os,

        'os_version':
            deviceInfo.osVersion,

        'browser':
            deviceInfo.browser,

        'browser_version':
            deviceInfo.browserVersion,

        'model':
            deviceInfo.model,

        'screen_size':
            deviceInfo.screenSize,

        'viewport_size':
            deviceInfo.viewportSize,

        'network_type':
            deviceInfo.networkType,

        'device_json':
            jsonEncode(deviceInfo.rawJson),

        // Mobile application screen identifier.
        'page_url': 'shrd://booking',
      };

      final baseUri = Uri.parse(
        AppConstants.apiUrl,
      );

      final uri = baseUri.replace(
        queryParameters: parameters,
      );

      debugPrint(
        '🌐 Availability log URL: $uri',
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) {
        debugPrint(
          '⚠️ Availability log HTTP '
          '${response.statusCode}',
        );

        return;
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map) {
        final data = Map<String, dynamic>.from(
          decoded,
        );

        debugPrint(
          '✅ Availability log response: $data',
        );
      } else {
        debugPrint(
          '⚠️ Availability log returned invalid JSON',
        );
      }
    } catch (error, stackTrace) {
      // Logging is intentionally non-blocking.
      debugPrint(
        '⚠️ Availability logging failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }


  // =============================================================
  // COLLECT DEVICE INFORMATION
  // =============================================================
  Future<AvailabilityDeviceInfo> _collectDeviceInfo(
    BuildContext context,
  ) async {
    final mediaQuery =
        MediaQuery.of(context);

    final physicalSize =
        mediaQuery.size *
        mediaQuery.devicePixelRatio;

    final viewportWidth =
        mediaQuery.size.width.round();

    final viewportHeight =
        mediaQuery.size.height.round();

    final screenWidth =
        physicalSize.width.round();

    final screenHeight =
        physicalSize.height.round();

    final pixelRatio =
        mediaQuery.devicePixelRatio;

    final packageInfo =
        await PackageInfo.fromPlatform();

    final networkType =
        await _getNetworkType();

    if (kIsWeb) {
      return AvailabilityDeviceInfo(
        device: 'Flutter Web',
        deviceType: 'Web',
        os: 'Web',
        osVersion: '',
        browser: 'Flutter Web',
        browserVersion:
            packageInfo.version,
        model: 'Web Browser',
        screenSize:
            '${screenWidth}x$screenHeight',
        viewportSize:
            '${viewportWidth}x$viewportHeight',
        networkType:
            networkType,
        rawJson: {
          'platform': 'web',
          'device_type': 'Web',
          'os': 'Web',
          'os_version': '',
          'browser': 'Flutter Web',
          'browser_version':
              packageInfo.version,
          'model': 'Web Browser',
          'screen_width': screenWidth,
          'screen_height': screenHeight,
          'viewport_width': viewportWidth,
          'viewport_height': viewportHeight,
          'device_pixel_ratio': pixelRatio,
          'connection_type': networkType,
          'app_name': packageInfo.appName,
          'app_version': packageInfo.version,
          'build_number':
              packageInfo.buildNumber,
          'package_name':
              packageInfo.packageName,
          'is_mobile': false,
        },
      );
    }

    if (Platform.isAndroid) {
      final androidInfo =
          await _deviceInfoPlugin.androidInfo;

      final manufacturer =
          androidInfo.manufacturer.trim();

      final model =
          androidInfo.model.trim();

      final brand =
          androidInfo.brand.trim();

      final deviceDescription = [
        manufacturer,
        model,
        'Android ${androidInfo.version.release}',
      ].where((value) {
        return value.trim().isNotEmpty;
      }).join(' ');

      return AvailabilityDeviceInfo(
        device: deviceDescription,
        deviceType: 'Android',
        os: 'Android',
        osVersion:
            androidInfo.version.release,
        browser: 'Flutter App',
        browserVersion:
            packageInfo.version,
        model: model.isNotEmpty
            ? model
            : 'Android Device',
        screenSize:
            '${screenWidth}x$screenHeight',
        viewportSize:
            '${viewportWidth}x$viewportHeight',
        networkType:
            networkType,
        rawJson: {
          'platform': 'android',
          'device_type': 'Android',
          'os': 'Android',
          'os_version':
              androidInfo.version.release,
          'sdk_int':
              androidInfo.version.sdkInt,
          'manufacturer': manufacturer,
          'brand': brand,
          'model': model,
          'device':
              androidInfo.device,
          'product':
              androidInfo.product,
          'hardware':
              androidInfo.hardware,
          'is_physical_device':
              androidInfo.isPhysicalDevice,
          'browser': 'Flutter App',
          'browser_version':
              packageInfo.version,
          'app_name':
              packageInfo.appName,
          'app_version':
              packageInfo.version,
          'build_number':
              packageInfo.buildNumber,
          'package_name':
              packageInfo.packageName,
          'screen_width':
              screenWidth,
          'screen_height':
              screenHeight,
          'viewport_width':
              viewportWidth,
          'viewport_height':
              viewportHeight,
          'device_pixel_ratio':
              pixelRatio,
          'connection_type':
              networkType,
          'is_mobile': true,
        },
      );
    }

    if (Platform.isIOS) {
      final iosInfo =
          await _deviceInfoPlugin.iosInfo;

      final model =
          iosInfo.utsname.machine.trim();

      final systemVersion =
          iosInfo.systemVersion.trim();

      final deviceDescription = [
        iosInfo.name,
        iosInfo.model,
        'iOS $systemVersion',
      ].where((value) {
        return value.trim().isNotEmpty;
      }).join(' ');

      return AvailabilityDeviceInfo(
        device: deviceDescription,
        deviceType: 'iPhone',
        os: 'iOS',
        osVersion: systemVersion,
        browser: 'Flutter App',
        browserVersion:
            packageInfo.version,
        model: model.isNotEmpty
            ? model
            : 'Apple iPhone',
        screenSize:
            '${screenWidth}x$screenHeight',
        viewportSize:
            '${viewportWidth}x$viewportHeight',
        networkType:
            networkType,
        rawJson: {
          'platform': 'ios',
          'device_type': 'iPhone',
          'os': 'iOS',
          'os_version': systemVersion,
          'name': iosInfo.name,
          'model': iosInfo.model,
          'machine':
              iosInfo.utsname.machine,
          'system_name':
              iosInfo.systemName,
          'is_physical_device':
              iosInfo.isPhysicalDevice,
          'browser': 'Flutter App',
          'browser_version':
              packageInfo.version,
          'app_name':
              packageInfo.appName,
          'app_version':
              packageInfo.version,
          'build_number':
              packageInfo.buildNumber,
          'package_name':
              packageInfo.packageName,
          'screen_width':
              screenWidth,
          'screen_height':
              screenHeight,
          'viewport_width':
              viewportWidth,
          'viewport_height':
              viewportHeight,
          'device_pixel_ratio':
              pixelRatio,
          'connection_type':
              networkType,
          'is_mobile': true,
        },
      );
    }

    return AvailabilityDeviceInfo(
      device: Platform.operatingSystem,
      deviceType: 'Desktop',
      os: Platform.operatingSystem,
      osVersion:
          Platform.operatingSystemVersion,
      browser: 'Flutter App',
      browserVersion:
          packageInfo.version,
      model: 'Desktop Device',
      screenSize:
          '${screenWidth}x$screenHeight',
      viewportSize:
          '${viewportWidth}x$viewportHeight',
      networkType:
          networkType,
      rawJson: {
        'platform':
            Platform.operatingSystem,
        'device_type': 'Desktop',
        'os':
            Platform.operatingSystem,
        'os_version':
            Platform.operatingSystemVersion,
        'browser': 'Flutter App',
        'browser_version':
            packageInfo.version,
        'model': 'Desktop Device',
        'app_name':
            packageInfo.appName,
        'app_version':
            packageInfo.version,
        'build_number':
            packageInfo.buildNumber,
        'package_name':
            packageInfo.packageName,
        'screen_width':
            screenWidth,
        'screen_height':
            screenHeight,
        'viewport_width':
            viewportWidth,
        'viewport_height':
            viewportHeight,
        'device_pixel_ratio':
            pixelRatio,
        'connection_type':
            networkType,
        'is_mobile': false,
      },
    );
  }


  // =============================================================
  // GET NETWORK TYPE
  // -------------------------------------------------------------
  // Connectivity type does not guarantee working Internet.
  // It is logged only for analytics.
  // =============================================================
  Future<String> _getNetworkType() async {
    try {
      final results =
          await _connectivity.checkConnectivity();

      if (results.isEmpty) {
        return '';
      }

      if (
          results.contains(
            ConnectivityResult.mobile,
          )) {
        return 'mobile';
      }

      if (
          results.contains(
            ConnectivityResult.wifi,
          )) {
        return 'wifi';
      }

      if (
          results.contains(
            ConnectivityResult.ethernet,
          )) {
        return 'ethernet';
      }

      if (
          results.contains(
            ConnectivityResult.vpn,
          )) {
        return 'vpn';
      }

      if (
          results.contains(
            ConnectivityResult.bluetooth,
          )) {
        return 'bluetooth';
      }

      if (
          results.contains(
            ConnectivityResult.none,
          )) {
        return 'none';
      }

      return results
          .map((result) => result.name)
          .join(',');
    } catch (error) {
      debugPrint(
        '⚠️ Unable to detect network type: $error',
      );

      return '';
    }
  }
}