import 'package:flutter/material.dart';

class ExpiryDatePage extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onSave;

  const ExpiryDatePage({
    super.key,
    required this.product,
    required this.onSave,
  });

  @override
  State<ExpiryDatePage> createState() => _ExpiryDatePageState();
}

class _ExpiryDatePageState extends State<ExpiryDatePage> {
  DateTime? expiryDate;
  DateTime? manufactureDate;
  int storageDays = 0;
  late TextEditingController quantityController;
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    expiryDate = widget.product['expiryDate'] != null
        ? DateTime.tryParse(widget.product['expiryDate'])
        : null;
    quantityController = TextEditingController(
      text: widget.product['quantity']?.toString() ?? '1',
    );
    nameController = TextEditingController( // Инициализация контроллера имени
      text: widget.product['name'] ?? '',
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    nameController.dispose(); // Удаляем контроллер имени
    super.dispose();
  }

  void calculateExpiryDate() {
    if (manufactureDate != null && storageDays > 0) {
      setState(() {
        expiryDate = manufactureDate!.add(Duration(days: storageDays));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Product Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 20),
            Text(
              expiryDate != null
                  ? 'Expiry Date: ${expiryDate!.toLocal()}'.split(' ')[0]
                  : 'No Expiry Date Set',
            ),
            ElevatedButton(
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (selectedDate != null) {
                  setState(() {
                    expiryDate = selectedDate;
                  });
                }
              },
              child: const Text('Set Expiry Date'),
            ),
            const SizedBox(height: 20),
            Text(
              manufactureDate != null
                  ? 'Manufacture Date: ${manufactureDate!.toLocal()}'.split(' ')[0]
                  : 'No Manufacture Date Set',
            ),
            ElevatedButton(
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (selectedDate != null) {
                  setState(() {
                    manufactureDate = selectedDate;
                    calculateExpiryDate();
                  });
                }
              },
              child: const Text('Set Manufacture Date'),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Storage Days'),
              onChanged: (value) {
                setState(() {
                  storageDays = int.tryParse(value) ?? 0;
                  calculateExpiryDate();
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final updatedProduct = {
                  ...widget.product,
                  'name': nameController.text, // Сохраняем введённое имя
                  'quantity': int.tryParse(quantityController.text) ?? 1,
                  'expiryDate': expiryDate?.toIso8601String(),
                  'manufactureDate': manufactureDate?.toIso8601String(),
                  'storageDays': storageDays,
                };
                widget.onSave(updatedProduct);
                Navigator.of(context).pop();
              },
              child: const Text('Save Product'),
            ),
          ],
        ),
      ),
    );
  }
}
