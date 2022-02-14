import 'package:e_commerce_app_flutter/services/database/product_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../constants.dart';
import 'package:e_commerce_app_flutter/models/Product.dart';

class ProductCard extends StatelessWidget {
  final String? productId;
  final GestureTapCallback press;
  const ProductCard({
    Key? key,
    required this.productId,
    required this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kTextColor.withOpacity(0.15)),
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
        ),
        child: FutureBuilder<Product?>(
          future: ProductDatabaseHelper().getProductWithID(productId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final Product product = snapshot.data!;
              return buildProductCard(product);
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              final error = snapshot.error.toString();
              Logger().e(error);
            }
            return Center(
              child: Icon(
                Icons.error,
                color: kTextColor,
                size: 60,
              ),
            );
          },
        ),
      ),
    );
  }

  buildProductCard(Product product) {
    return Column(
      children: <Widget>[
        Stack(
          children: <Widget>[
            Container(
              width: 250,
              height: 150,
              child: Image.network(product.images![0]!),
            ),
            Container(
              height: 25,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(15.0),
                  topLeft: Radius.circular(15.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.5),
                child: Text(
                  '20% Off',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(10.0),
                bottomLeft: Radius.circular(10.0),
              ),
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 10),
                  blurRadius: 30.0,
                  color: kPrimaryColor.withOpacity(0.2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${product.title}\n".toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: "${product.variant}",
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        color: kPrimaryColor.withOpacity(0.09),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(
                          'UGX ${product.discountPrice}',
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 11.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'UGX ${product.originalPrice}',
                              style: TextStyle(
                                fontSize: 11.0,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                decorationThickness: 3.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
