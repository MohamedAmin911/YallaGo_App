import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
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
  final _places = GoogleMapsPlaces(apiKey: KapiKeys.googeleMapsApiKey);
  List<Prediction> _predictions = [];
  String _sessionToken = const Uuid().v4();
  List<Map<String, dynamic>> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    final customerState = context.read<CustomerCubit>().state;
    if (customerState is CustomerLoaded) {
      _searchHistory = customerState.customer.searchHistory ?? [];
    }
  }

  void _onSearchChanged(String input) async {
    if (input.trim().isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    final response = await _places.autocomplete(
      input,
      sessionToken: _sessionToken,
      location: Location(
          lat: widget.currentUserPosition.latitude,
          lng: widget.currentUserPosition.longitude),
      radius: 30000,
      language: "en",
      components: [Component(Component.country, "eg")],
    );

    if (mounted) {
      if (response.isOkay) {
        setState(() => _predictions = response.predictions);
      } else {
        print("Places API Error: ${response.errorMessage}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response.errorMessage ?? "An unknown error occurred."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _predictions = []);
      }
    }
  }

  void _onPlaceSelected(Prediction prediction) async {
    if (prediction.placeId == null) return;

    final response = await _places.getDetailsByPlaceId(prediction.placeId!,
        sessionToken: _sessionToken);

    if (mounted && response.isOkay) {
      final location = response.result.geometry?.location;
      final address = prediction.description;

      if (location != null && address != null) {
        final result = {
          'address': address,
          'location': LatLng(location.lat, location.lng)
        };

        final customerState = context.read<CustomerCubit>().state;
        if (customerState is CustomerLoaded) {
          final searchData = {
            'address': address,
            'latitude': location.lat,
            'longitude': location.lng,
          };
          context
              .read<CustomerCubit>()
              .addSearchToHistory(customerState.customer.uid, searchData);
        }

        Navigator.of(context).pop(result);
      }
    }
    if (mounted) {
      setState(() => _sessionToken = const Uuid().v4());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _places.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        onBackPressed: context.pop,
      ),
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

                return ListView.builder(
                  itemCount:
                      showHistory ? _searchHistory.length : _predictions.length,
                  itemBuilder: (context, index) {
                    if (showHistory) {
                      final historyItem = _searchHistory[index];
                      return SearchHistoryItem(
                        historyItem: historyItem,
                        onTap: () {
                          final result = {
                            'address': historyItem['address'],
                            'location': LatLng(
                              historyItem['latitude'],
                              historyItem['longitude'],
                            ),
                          };
                          Navigator.of(context).pop(result);
                        },
                      );
                    } else {
                      final prediction = _predictions[index];
                      return SearchPredictionItem(
                        prediction: prediction,
                        onTap: () {
                          if (prediction.placeId != null) {
                            _onPlaceSelected(prediction);
                          }
                        },
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
