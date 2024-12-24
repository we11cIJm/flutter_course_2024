import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fridge/presentation/screens/product_details/expiry_date_page.dart';
import 'package:fridge/presentation/screens/scanner/barcode_scanner_page.dart';

class HomePage extends StatefulWidget { // editable page
  final VoidCallback toggleTheme; 

  const HomePage({super.key, required this.toggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> scannedProducts = [];
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProducts = prefs.getString('scannedProducts');
    if (savedProducts != null) {
      setState(() {
        scannedProducts = List<Map<String, dynamic>>.from(json.decode(savedProducts));
        _sortProducts();

        // Проверяем сроки годности
        final now = DateTime.now();
        for (final product in scannedProducts) {
          final expiryDate = DateTime.tryParse(product['expiryDate'] ?? '');
          if (expiryDate != null && expiryDate.isBefore(now.add(const Duration(days: 3)))) {
            // Логика для выделения товара
            product['isExpiringSoon'] = true;

            // Отправляем уведомление (упрощённая версия для демонстрации)
            _sendExpiryNotification(product['name']);
          } else {
            product['isExpiringSoon'] = false;
          }
        }
      });
    }
  }

  Future<void> _sendExpiryNotification(String productName) async {
    const androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      'Expiry Notifications',
      channelDescription: 'Notifies when products are expiring soon',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      0,
      'Product Expiring Soon',
      '$productName is expiring in 3 days!',
      notificationDetails,
    );
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('scannedProducts', json.encode(scannedProducts));
  }

  void _sortProducts() {
    scannedProducts.sort((a, b) {
      final dateA = DateTime.tryParse(a['expiryDate'] ?? '') ?? DateTime(9999);
      final dateB = DateTime.tryParse(b['expiryDate'] ?? '') ?? DateTime(9999);
      return dateA.compareTo(dateB);
    });
  }

  void navigateToScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          onBarcodeScanned: (product) {
            setState(() {
              scannedProducts.add(product);
              _sortProducts();
              _saveProducts();
            });
          },
        ),
      ),
    );
  }

  void _editProduct(int index) {
    final product = scannedProducts[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpiryDatePage(
          product: product,
          onSave: (updatedProduct) {
            setState(() {
              scannedProducts[index] = updatedProduct;
              _sortProducts();
              _saveProducts();
            });
          },
        ),
      ),
    );
  }


  void _deleteProduct(int index) {
    setState(() {
      scannedProducts.removeAt(index);
      _saveProducts();
    });
  }


  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('app_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await notificationsPlugin.initialize(initSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: scannedProducts.length,
        itemBuilder: (context, index) {
          final product = scannedProducts[index];
          final expiryDate = product['expiryDate'] != null
              ? DateTime.tryParse(product['expiryDate'])
              : null;

          // Подсветка товаров с истекающим сроком годности
          final isExpiringSoon = expiryDate != null &&
              expiryDate.difference(DateTime.now()).inDays <= 3;

          return ListTile(
            tileColor: isExpiringSoon
                ? Colors.red.withOpacity(0.1) // Нежная подсветка
                : null,
            title: Text(
              product['name'] ?? 'Unknown Product',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expiry Date: ${product['expiryDate'] != null ? product['expiryDate'].split('T')[0] : 'Not set'}'),
                Text('Quantity: ${product['quantity'] ?? '1'}'),
              ]
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editProduct(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteProduct(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: navigateToScanner,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpiryDatePage(
                    product: {
                      'name': '',
                      'quantity': 1,
                      'expiryDate': null,
                    },
                    onSave: (newProduct) {
                      setState(() {
                        scannedProducts.add(newProduct);
                        _sortProducts();
                        _saveProducts();
                      });
                    },
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}