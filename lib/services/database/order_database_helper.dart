import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/OrderedProduct.dart';
import '../authentification/authentification_service.dart';

class OrderDatabaseHelper {
  static const String ORDERS_COLLECTION_NAME = 'orders';

  OrderDatabaseHelper._privateConstructor();
  static OrderDatabaseHelper _instance =
      OrderDatabaseHelper._privateConstructor();
  factory OrderDatabaseHelper() {
    return _instance;
  }
  FirebaseFirestore? _firebaseFirestore;
  FirebaseFirestore? get firestore {
    if (_firebaseFirestore == null) {
      _firebaseFirestore = FirebaseFirestore.instance;
    }
    return _firebaseFirestore;
  }

  Future<bool> addToMyOrders(
      List<OrderedProduct> orders, Position position) async {
    String uid = AuthentificationService().currentUser!.uid;
    GeoFirePoint geoFirePoint = Geoflutterfire()
        .point(latitude: position.latitude, longitude: position.longitude);

    final orderedProductsCollectionRef =
        firestore!.collection(ORDERS_COLLECTION_NAME);
    for (final order in orders) {
      await orderedProductsCollectionRef.add({
        'position': geoFirePoint.data,
        'details': order.toMap(),
      });
    }
    return true;
  }
}
