import 'package:flutter/material.dart';
import '../utils/formatters.dart'; // Import Formatter Pusat

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const DetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    int price = int.tryParse(product['price'].toString()) ?? 0;
    int oldPrice = (price * 1.2).toInt();
    return Scaffold(
      appBar: AppBar(title: Text(product['name'])),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: product['image'] != null && product['image'] != ""
                  ? Image.network(product['image'], fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Harga Coret
                  Text(
                    AppFormatters.formatRupiah(oldPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  // Harga Asli
                  Text(
                    AppFormatters.formatRupiah(price),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Divider(height: 40),
                  const Text(
                    "Deskripsi Produk",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Produk sembako berkualitas tinggi untuk kebutuhan harian keluarga Anda. "
                    "Dijamin segar dan original dengan harga yang sangat terjangkau.",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
