import 'package:flutter/material.dart';
import '../../../db/database_helper.dart';

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
  // IMAGE HANDLER (AMAN)
  // ======================
  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const Icon(Icons.image_not_supported, size: 80);
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
        loadingBuilder: (c, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    return Image.asset(imageUrl, fit: BoxFit.cover, width: double.infinity);
  }

  // ======================
  // USER BELI
  // ======================
  void _showQtyDialog(Map<String, dynamic> product) {
    int qty = 1;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(product['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Harga: Rp ${product['price']}"),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (qty > 1) setLocal(() => qty--);
                    },
                  ),
                  Text(
                    qty.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setLocal(() => qty++),
                  ),
                ],
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
                  'image': product['image'], // 🔥 FIX
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
  // ADMIN EDIT (FIX IMAGE)
  // ======================
  void _editProduct(Map<String, dynamic> product) {
    final nameCtrl = TextEditingController(text: product['name']);
    final priceCtrl = TextEditingController(text: product['price'].toString());
    final imageCtrl = TextEditingController(text: product['image'] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Produk"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nama"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Harga"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imageCtrl,
                decoration: const InputDecoration(
                  labelText: "URL Gambar",
                  hintText: "https://...",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateProduct(product['id'], {
                'name': nameCtrl.text,
                'price': int.parse(priceCtrl.text),
                'image': imageCtrl.text, // 🔥 FIX UTAMA
              });

              if (!mounted) return;
              Navigator.pop(context);
              _refreshData();
            },
            child: const Text("SIMPAN"),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _refreshData();
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.role == 'admin';

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
      itemBuilder: (_, i) {
        final product = _products[i];

        return Card(
          elevation: 3,
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text("Rp ${product['price']}"),
                    const SizedBox(height: 6),
                    isAdmin
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editProduct(product),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteProduct(product['id']),
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () => _showQtyDialog(product),
                            child: const Text("Beli"),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
