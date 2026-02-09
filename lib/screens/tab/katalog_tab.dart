import 'package:flutter/material.dart';
import '../../../db/database_helper.dart';
import '../../../screens/detail_screen.dart';

class KatalogTab extends StatefulWidget {
  final String role;
  final Function(Map<String, dynamic>) onAddToCart;

  const KatalogTab({super.key, required this.role, required this.onAddToCart});

  @override
  State<KatalogTab> createState() => _KatalogTabState();
}

class _KatalogTabState extends State<KatalogTab> {
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void didUpdateWidget(covariant KatalogTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshData();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.queryAllProducts();
    if (!mounted) return;
    setState(() => _products = data);
  }

  // ======================
  // IMAGE HANDLER
  // ======================
  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.image_not_supported, size: 80);
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
      );
    }

    return Image.asset(imageUrl, fit: BoxFit.cover);
  }

  // ======================
  // USER QTY POPUP
  // ======================
  void _showQtyDialog(Map<String, dynamic> product) {
    int qty = 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(product['name']),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  if (qty > 1) setLocal(() => qty--);
                },
                icon: const Icon(Icons.remove),
              ),
              Text(qty.toString(), style: const TextStyle(fontSize: 18)),
              IconButton(
                onPressed: () => setLocal(() => qty++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("BATAL"),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onAddToCart({
                  'id': product['id'],
                  'name': product['name'],
                  'price': product['price'],
                  'qty': qty,
                  'total': product['price'] * qty,
                });
                Navigator.pop(ctx);
              },
              child: const Text("TAMBAH"),
            ),
          ],
        ),
      ),
    );
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == 'admin';

    if (_products.isEmpty) {
      return const Center(child: Text("Produk kosong"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _products.length,
      itemBuilder: (context, i) {
        final product = _products[i];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(product: product)),
            );
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: _buildProductImage(product['image']),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        product['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Rp ${product['price']}"),
                      const SizedBox(height: 6),
                      isAdmin
                          ? const SizedBox()
                          : ElevatedButton(
                              onPressed: () => _showQtyDialog(product),
                              child: const Text("Beli"),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
