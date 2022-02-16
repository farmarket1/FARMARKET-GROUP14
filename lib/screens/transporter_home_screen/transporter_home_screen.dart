import 'dart:async';
import 'package:e_commerce_app_flutter/models/Product.dart';
import 'package:e_commerce_app_flutter/services/database/product_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransporterHomeScreen extends StatefulWidget {
  @override
  _MechanicMapState createState() => _MechanicMapState();
}

class _MechanicMapState extends State<TransporterHomeScreen> {
  Completer<GoogleMapController> _mapController = Completer();

  Product? _currentSeller;
  bool _disappear = false;

  // firestore init
  final _firestore = FirebaseFirestore.instance;
  late Geoflutterfire geo;
  // late Stream<List<DocumentSnapshot>> stream;
  var radius = BehaviorSubject.seeded(100.0);

  //Map markers
  List<Marker> markers = [];
  Position _position = Position(
      longitude: 32.56496949865432,
      latitude: 0.32493815086864625,
      timestamp: DateTime.now(),
      accuracy: 99.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 90.0);
  late BitmapDescriptor workshopIcon;

  bool _isFindingMechanic = false;

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Stream<List<DocumentSnapshot<Object?>>> streamNearByMechanics() {
    GeoFirePoint center =
        geo.point(latitude: _position.latitude, longitude: _position.longitude);
    return radius.switchMap((rad) {
      var collectionReference = _firestore.collection('orders');
      //          .where('name', isEqualTo: 'darshan');
      return geo
          .collection(collectionRef: collectionReference)
          .within(center: center, radius: rad, field: 'position');
    });
  }

  @override
  void initState() {
    super.initState();
    geo = Geoflutterfire();

    getIcons();

    _determinePosition().then((myPosition) {
      setState(() {
        _position = myPosition;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    radius.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  markers: markers.toSet(),
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_position.latitude, _position.longitude),
                    zoom: 15.0,
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).pop();
                    }),
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                            Colors.grey.shade900,
                            Colors.transparent
                          ])),
                    ),
                    const Spacer(),
                    if (_currentSeller != null) _sellerDetailsWidget(),
                  ],
                ),
              ],
            ),
          ),
          if (_isFindingMechanic) LinearProgressIndicator(),
        ],
      ),
    ));
  }

  getIcons() async {
    var icon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 3.2),
        "assets/images/Image Popular Product 3.png");
    setState(() {
      this.workshopIcon = icon;
    });
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    final str = streamNearByMechanics();
    str.listen((List<DocumentSnapshot> documentList) {
      _updateMarkers(documentList);
    });
  }


  void _addMarker(DocumentSnapshot document) async {
    GeoPoint point = document['position']['geopoint'];
    final product = await ProductDatabaseHelper()
        .getProductWithID(document['details']['product_uid']);

    var _marker = Marker(
      onTap: () {
        if (_currentSeller != product) {
          setState(() {
            _currentSeller = product;
            _disappear = false;
          });
        }
      },
      markerId: MarkerId(UniqueKey().toString()),
      position: LatLng(point.latitude, point.longitude),
      infoWindow: InfoWindow(title: product!.seller),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      // icon: workshopIcon,
    );
    setState(() {
      markers.add(_marker);
    });
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    documentList.forEach((DocumentSnapshot document) {
      _addMarker(document);
    });
  }


  changed(value) {
    setState(() {
      markers.clear();
      radius.add(value);
    });
  }

  _sellerDetailsWidget() {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(10),
            leading: CircleAvatar(
              foregroundImage: AssetImage('assets/images/Profile Image.png'),
            ),
            title: Text(_currentSeller!.seller!),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(),
                Text(_currentSeller!.title!),
              ],
            ),
          ),
          if (!_disappear)
            Row(
              children: [
                SizedBox(width: 15.0),
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        _disappear = true;
                      });
                    },
                    child: Text('Confirm'),
                    color: Colors.green,
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0)),
                  ),
                ),
                SizedBox(width: 15.0),
              ],
            ),
          SizedBox(width: 20.0),
        ],
      ),
    );
  }
}
