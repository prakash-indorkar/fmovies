import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fmovies/src/features/cinemas/domain/cinemas_bloc.dart';
import 'package:fmovies/src/features/cinemas/domain/cinemas_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_permissions/location_permissions.dart';

class CinemasPage extends StatefulWidget {
  @override
  State<CinemasPage> createState() => CinemasPageState();
}

class CinemasPageState extends State<CinemasPage> {
  final Map<String, Marker> _markers = {};
  CameraPosition _currentCameraPosition;
  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _initialCamera = CameraPosition(
    target: LatLng(0, 0),
    zoom: 1,
  );

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  void getLocation() async {
    var isEnabled = await checkPermission();
    if (isEnabled) {
      Position position = await Geolocator()
          .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
      print(position);
      _currentCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 16);
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
          CameraUpdate.newCameraPosition(_currentCameraPosition));
      final marker = Marker(
        markerId: MarkerId('user'),
        position: LatLng(position.latitude, position.longitude),
      );
      setState(() {
        _markers.clear();
        _markers['user'] = marker;
      });
    }
  }

  Future<bool> checkPermission() async {
    PermissionStatus permission =
        await LocationPermissions().checkPermissionStatus();
    switch (permission) {
      case PermissionStatus.granted:
        return true;
        break;
      default:
        PermissionStatus permission =
            await LocationPermissions().requestPermissions();
        if (permission == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
//    final bloc = BlocProvider.of<CinemasBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Cinemas nearby"),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            initialCameraPosition: _initialCamera,
            markers: _markers.values.toSet(),
          ),
          BlocBuilder<CinemasBloc, CinemasState>(
            builder: (context, state) {
              if (state is CinemasLoading) {
                print('Loading map');
                return Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                );
              }
              if (state is CinemasLoaded) {
                return Text('Finished loading');
              }
              return Text('Something went wrong');
            },
          ),
        ],
      ),
    );
  }
}
