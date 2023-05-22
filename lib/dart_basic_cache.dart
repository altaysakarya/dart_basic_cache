library dart_basic_cache;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DartBasicCache {
  static final DartBasicCache _instance = DartBasicCache._internal();

  factory DartBasicCache() {
    return _instance;
  }

  DartBasicCache._internal();

  late String _cacheFileName;
  late Duration _cacheDuration;
  Map<String, dynamic> _cacheData = {};

  bool _isInitialized = false;

  /// Initializes the cache with the specified parameters.
  ///
  /// [cacheFileName] is the name of the cache file (default is "dbc").
  /// [cacheTimeHour] is the cache duration in hours (default is 1 hour).
  Future<void> init({String cacheFileName = "dbc", int cacheTimeHour = 1}) async {
    if (_isInitialized) {
      throw Exception('init function has already been called');
    }
    _cacheFileName = "$cacheFileName.json";
    _cacheDuration = Duration(hours: cacheTimeHour);
    _cacheData = await _loadCacheFromFile();
    _isInitialized = true;
  }

  /// Caches the data with the specified URL.
  ///
  /// [url] is the unique identifier for the data.
  /// [data] is the data to be cached.
  Future<void> cacheData(String url, dynamic data) async {
    _validateInit();
    _cacheData[url] = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _saveCacheToFile(_cacheData);
  }

  /// Retrieves the cached data for the specified URL.
  ///
  /// Returns the cached data if available and not expired, otherwise returns null.
  Future<dynamic> getDataFromCache(String url) async {
    _validateInit();
    final data = _cacheData[url];
    if (data != null && !_isDataExpired(data['timestamp'])) {
      return data['data'];
    } else {
      _cacheData.remove(url);
      await _saveCacheToFile(_cacheData);
      return null;
    }
  }

  /// Deletes the cached data for the specified URL.
  Future<void> deleteCachedData(String url) async {
    _cacheData.remove(url);
    await _saveCacheToFile(_cacheData);
  }

  bool _isDataExpired(String timestamp) {
    _validateInit();
    final cachedTime = DateTime.parse(timestamp);
    final currentTime = DateTime.now();
    final difference = currentTime.difference(cachedTime);
    return difference > _cacheDuration;
  }

  Future<Map<String, dynamic>> _loadCacheFromFile() async {
    _validateInit();
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return jsonDecode(jsonString);
      }
    } catch (e) {
      throw Exception("Cache load error: $e");
    }
    return {};
  }

  Future<void> _saveCacheToFile(Map<String, dynamic> cacheData) async {
    _validateInit();
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');
      final jsonString = jsonEncode(cacheData);
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception("Cache load error: $e");
    }
  }

  void _validateInit() {
    if (_cacheFileName.isEmpty) {
      throw Exception('Please call the init function first');
    }
  }
}
