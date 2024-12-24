import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fridge/presentation/screens/product_details/expiry_date_page.dart';

class BarcodeScannerPage extends StatelessWidget {
  final Function(Map<String, dynamic>) onBarcodeScanned;

  const BarcodeScannerPage({super.key, required this.onBarcodeScanned});

  Future<void> fetchProductData(String barcode, BuildContext context) async {
    final apiUrl = 'https://ean-db.com/api/v2/product/$barcode';
    final jwtToken = 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIzZWE0NDMzMi1jYmI2LTQ5MzktOGQyNC01N2FhZWE0NTA4ZjUiLCJpc3MiOiJjb20uZWFuLWRiIiwiaWF0IjoxNzM0MzQ2MDMxLCJleHAiOjE3NjU4ODIwMzEsImlzQXBpIjoidHJ1ZSJ9.YVmMZeGlzErk_wkpZxfXnK92MQW5S8Z07QKzi6rmTdkMRUbIG6qSmAffn-o3p1ar2OGWYxquj32C9Hy8LE6ycg';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(utf8.decode(response.bodyBytes));
        final product = decodedResponse['product'] ?? {};

        final name = product['titles']?['ru'] ?? 'Unknown Product';

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ExpiryDatePage(
              product: {
                'name': name,
                'barcode': barcode,
                'quantity': 1,
              },
              onSave: (updatedProduct) {
                onBarcodeScanned(updatedProduct);
              },
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ExpiryDatePage(
              product: {
                'name': 'Unknown Product',
                'barcode': barcode,
                'quantity': 1,
              },
              onSave: (updatedProduct) {
                onBarcodeScanned(updatedProduct);
              },
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found in the database. Please add details.')),
        );
      }
      else {
        throw Exception(
            'Failed to fetch product data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null) {
            final code = barcode.rawValue!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Scanning barcode: $code')),
            );
            fetchProductData(code, context);
          }
        },
      ),
    );
  }
}