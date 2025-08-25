import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' show Prediction;
import 'package:http/http.dart' as http;
import 'package:google_api_headers/google_api_headers.dart';
import 'package:geocoding/geocoding.dart';

import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/customer/customer_states.dart';
import 'package:taxi_app/common/api_keys.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/view/widgets/customer/home/location_search_widgets/search_app_bar.dart';
import 'package:taxi_app/view/widgets/customer/home/location_search_widgets/search_history_item.dart';
import 'package:taxi_app/view/widgets/customer/home/location_search_widgets/search_input_field.dart';
import 'package:taxi_app/view/widgets/customer/home/location_search_widgets/search_prediction_item.dart';
import 'package:uuid/uuid.dart';

class DestinationSearchScreen extends StatefulWidget {
  final LatLng currentUserPosition;
  const DestinationSearchScreen({super.key, required this.currentUserPosition});

  @override
  State<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final _searchController = TextEditingController();
  final _client = http.Client();

  List<Prediction> _predictions = [];
  String _sessionToken = const Uuid().v4();
  List<Map<String, dynamic>> _searchHistory = [];
  Timer? _debounce;
  static const _debounceDur = Duration(milliseconds: 350);

// Current city and aliases (en/ar) to match in predictions
  String? _currentCity;
  String? _currentAdmin; // governorate
  late final List<String> _cityAliases = [];

  @override
  void initState() {
    super.initState();
    final customerState = context.read<CustomerCubit>().state;
    if (customerState is CustomerLoaded) {
      _searchHistory = customerState.customer.searchHistory ?? [];
    }
    _resolveCurrentCity(); // fetch once
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _client.close();
    super.dispose();
  }

// Get the user's city name once (English/Arabic if available)
  Future<void> _resolveCurrentCity() async {
    try {
      final placemarks = await placemarkFromCoordinates(
        widget.currentUserPosition.latitude,
        widget.currentUserPosition.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _currentCity = (p.locality?.trim().isNotEmpty ?? false)
            ? p.locality
            : (p.subAdministrativeArea?.trim().isNotEmpty ?? false)
                ? p.subAdministrativeArea
                : p.administrativeArea;
        _currentAdmin = p.administrativeArea;
      }

      try {
        final arPlacemarks = await placemarkFromCoordinates(
          widget.currentUserPosition.latitude,
          widget.currentUserPosition.longitude,
        );
        if (arPlacemarks.isNotEmpty) {
          final ar = arPlacemarks.first;
          if (ar.locality != null && ar.locality!.trim().isNotEmpty) {
            _cityAliases.add(ar.locality!.toLowerCase());
          }
          if (ar.administrativeArea != null &&
              ar.administrativeArea!.trim().isNotEmpty) {
            _cityAliases.add(ar.administrativeArea!.toLowerCase());
          }
        }
      } catch (_) {}

      // Add English aliases
      if (_currentCity != null) _cityAliases.add(_currentCity!.toLowerCase());
      if (_currentAdmin != null) _cityAliases.add(_currentAdmin!.toLowerCase());
      // Always include Egypt
      _cityAliases.addAll(['egypt', 'مصر']);

      setState(() {}); // ready for ranking
    } catch (e) {
      // Not critical; ranking will just skip city-priority
      debugPrint('resolve city error: $e');
    }
  }

  void _onSearchChanged(String input) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDur, () => _fetchQueryAutocomplete(input));
  }

  Future<void> _fetchQueryAutocomplete(String input) async {
    final q = input.trim();
    if (q.isEmpty) {
      if (mounted) setState(() => _predictions = []);
      return;
    }

    try {
      final params = <String, String>{
        'input': q,
        'key': KapiKeys.googeleMapsApiKey,
        'language': 'en', // or 'ar'
        'sessiontoken': _sessionToken,
        // Bias to current position & radius so local items come first
        'location':
            '${widget.currentUserPosition.latitude},${widget.currentUserPosition.longitude}',
        'radius': '30000', // 30km bias (tune as needed)
      };

      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/queryautocomplete/json',
        params,
      );

      final headers = <String, String>{'Accept': 'application/json'};
      // Important for restricted keys (Android/iOS)
      try {
        headers.addAll(await const GoogleApiHeaders().getHeaders());
      } catch (_) {}

      final res = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || res.body.isEmpty) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      Map<String, dynamic> map;
      try {
        map = json.decode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception(
            'Bad JSON: ${res.body.substring(0, res.body.length > 180 ? 180 : res.body.length)}');
      }

      final status = (map['status'] as String?) ?? 'UNKNOWN';
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        final msg = map['error_message'] ?? status;
        throw Exception('Places error: $msg');
      }

      final list = (map['predictions'] as List?) ?? [];
      final preds = list
          .whereType<Map<String, dynamic>>()
          .map((m) => Prediction.fromJson(m))
          .toList();

      // Re-rank: current-city/Egypt first
      final ranked = _rankPredictions(preds);

      if (!mounted) return;
      setState(() => _predictions = ranked);
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Places timeout. Check connection.')),
      );
      setState(() => _predictions = []);
    } catch (e) {
      if (!mounted) return;
      debugPrint('QueryAutocomplete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Places error: $e')),
      );
      setState(() => _predictions = []);
    }
  }

// Simple scorer: predictions mentioning current city (en/ar) or Egypt rank higher
  List<Prediction> _rankPredictions(List<Prediction> preds) {
    if (_cityAliases.isEmpty) return preds; // nothing to rank by yet
    int score(Prediction p) {
      final buf = StringBuffer();
      if (p.description != null) buf.write(p.description!.toLowerCase());
      final sf = p.structuredFormatting;
      if (sf != null) {
        buf.write(' ${sf.mainText.toLowerCase()}');
        if (sf.secondaryText != null) {
          buf.write(' ${sf.secondaryText!.toLowerCase()}');
        }
      }
      final text = buf.toString();

      int s = 0;
      for (final alias in _cityAliases) {
        if (alias.isEmpty) continue;
        if (text.contains(alias)) s += 100;
      }
      // De-emphasize some out-of-country hints (very light penalty)
      if (text.contains('london') ||
          text.contains('uk') ||
          text.contains('abu dhabi')) {
        s -= 5;
      }
      return s;
    }

    final ranked = [...preds]..sort((a, b) => score(b).compareTo(score(a)));
    return ranked;
  }

  Future<({double lat, double lng, String? address, String? title})?>
      _fetchPlaceDetails(String placeId) async {
    try {
      final params = <String, String>{
        'place_id': placeId,
        'key': KapiKeys.googeleMapsApiKey,
        'language': 'en',
        'sessiontoken': _sessionToken,
        'fields': 'name,formatted_address,geometry/location',
      };
      final uri = Uri.https(
          'maps.googleapis.com', '/maps/api/place/details/json', params);

      final headers = <String, String>{'Accept': 'application/json'};
      try {
        headers.addAll(await const GoogleApiHeaders().getHeaders());
      } catch (_) {}

      final res = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || res.body.isEmpty) {
        throw Exception('Details HTTP ${res.statusCode}: ${res.body}');
      }

      final body = json.decode(res.body) as Map<String, dynamic>;
      final status = (body['status'] as String?) ?? 'UNKNOWN';
      if (status != 'OK') throw Exception(body['error_message'] ?? status);

      final result = (body['result'] as Map<String, dynamic>?) ?? {};
      final geom = (result['geometry'] as Map<String, dynamic>?) ?? {};
      final loc = (geom['location'] as Map<String, dynamic>?) ?? {};
      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      final address = (result['formatted_address'] as String?) ??
          (result['name'] as String?);
      final title = (result['name'] as String?);
      if (lat == null || lng == null) return null;
      return (lat: lat, lng: lng, address: address, title: title);
    } catch (e) {
      debugPrint('PlaceDetails error: $e');
      return null;
    }
  }

  Future<void> _onPlaceSelected(Prediction prediction) async {
    final pid = prediction.placeId;
    if (pid == null) return;

    final det = await _fetchPlaceDetails(pid);
    if (!mounted) return;

    if (det != null) {
      final title = det.title ?? prediction.description ?? 'Selected place';
      final addr = det.address ?? prediction.description ?? 'Selected place';
      print("-----------------------$addr");
      final result = {'address': title, 'location': LatLng(det.lat, det.lng)};
      final st = context.read<CustomerCubit>().state;
      if (st is CustomerLoaded) {
        context.read<CustomerCubit>().addSearchToHistory(st.customer.uid, {
          'title': det.title,
          'address': addr,
          'latitude': det.lat,
          'longitude': det.lng,
        });
      }
      Navigator.of(context).pop(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch place details.')),
      );
    }

    if (mounted) setState(() => _sessionToken = const Uuid().v4());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(onBackPressed: context.pop),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 22.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              "Search for a destination",
              style: appStyle(
                size: 25.sp,
                color: KColor.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SearchInputField(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
          Expanded(
            child: BlocBuilder<CustomerCubit, CustomerState>(
              builder: (context, state) {
                final showHistory = _searchController.text.trim().isEmpty &&
                    _predictions.isEmpty;

                if (state is CustomerLoaded) {
                  _searchHistory = state.customer.searchHistory ?? [];
                }

                return _searchHistory.isEmpty && _predictions.isEmpty
                    ? Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 200.h),
                            Text(
                              "No Search History",
                              style: appStyle(
                                  size: 18.sp,
                                  color: KColor.lightGray,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        separatorBuilder: (context, index) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: Divider(
                            thickness: 3,
                            color: KColor.lightGray.withOpacity(0.4),
                          ),
                        ),
                        itemCount: showHistory
                            ? _searchHistory.length
                            : _predictions.length,
                        itemBuilder: (context, index) {
                          if (showHistory) {
                            final historyItem = _searchHistory[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index == 0)
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: 24.w, top: 20.h),
                                    child: Text(
                                      "Search History",
                                      style: appStyle(
                                        size: 16.sp,
                                        color: KColor.placeholder,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                SearchHistoryItem(
                                  historyItem: historyItem,
                                  onTap: () {
                                    Navigator.of(context).pop({
                                      'address': historyItem['title'],
                                      'location': LatLng(
                                        historyItem['latitude'],
                                        historyItem['longitude'],
                                      ),
                                    });
                                  },
                                ),
                              ],
                            );
                          } else {
                            final prediction = _predictions[index];
                            return SearchPredictionItem(
                              prediction: prediction,
                              onTap: () => _onPlaceSelected(prediction),
                            );
                          }
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
