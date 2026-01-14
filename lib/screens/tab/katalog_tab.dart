import 'package:flutter/material.dart';
import '../../../db/database_helper.dart';

class KatalogTab extends StatefulWidget {
  final String role;
  final Function(Map<String, dynamic>) onAddToCart;
  final bool hasShownPromo;
  final VoidCallback onPromoShown;

  const KatalogTab({
    super.key,
    required this.role,
    required this.onAddToCart,
    required this.hasShownPromo,
    required this.onPromoShown,
  });

  @override
  KatalogTabState createState() => KatalogTabState();
}

class KatalogTabState extends State<KatalogTab> {
  List<Map<String, dynamic>> _products = [];
  bool _isPromoActive = false;

  @override
  void initState() {
    super.initState();
    refreshData();

    // Munculkan promo hanya untuk user
    if (widget.role.toLowerCase() != 'admin' && !widget.hasShownPromo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPromoPopup();
        widget.onPromoShown();
      });
    }
  }

  Future<void> refreshData() async {
    final data = await DatabaseHelper.instance.queryAllProducts();
    if (mounted) {
      setState(() => _products = data);
    }
  }

  void _showPromoPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                "assets/images/PROMO.png",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.card_giftcard,
                  size: 80,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "PROMO DISKON 10%",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text("Klaim sekarang untuk harga lebih hemat!"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("TIDAK"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              setState(() => _isPromoActive = true);
              Navigator.pop(ctx);
            },
            child: const Text("KLAIM", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Produk"),
        content: Text("Yakin ingin menghapus '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("BATAL"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteProduct(id);
              if (!mounted) return;
              Navigator.of(context).pop();
              refreshData();
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> product) {
    final nameCtrl = TextEditingController(text: product['name']);
    final priceCtrl = TextEditingController(text: product['price'].toString());
    final imgCtrl = TextEditingController(text: product['image']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Edit Produk",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nama Produk",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Harga",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: imgCtrl,
              decoration: const InputDecoration(
                labelText: "URL Gambar",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                await DatabaseHelper.instance.updateProduct(product['id'], {
                  'name': nameCtrl.text,
                  'price': int.parse(priceCtrl.text),
                  'image': imgCtrl.text,
                });
                if (!mounted) return;
                Navigator.of(context).pop();
                refreshData();
              },
              child: const Text(
                "SIMPAN PERUBAHAN",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showQtyDialog(Map<String, dynamic> product) {
    int selectedQty = 1;
    int basePrice = int.tryParse(product['price'].toString()) ?? 0;
    int currentPrice = (!isAdminGlobal && _isPromoActive)
        ? (basePrice * 0.9).toInt()
        : basePrice;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Beli ${product['name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Tentukan jumlah pesanan:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      if (selectedQty > 1) setDialogState(() => selectedQty--);
                    },
                  ),
                  Text(
                    "$selectedQty",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => setDialogState(() => selectedQty++),
                  ),
                ],
              ),
              Text(
                "Total: Rp ${currentPrice * selectedQty}",
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("BATAL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                widget.onAddToCart({
                  'name': product['name'],
                  'price': currentPrice,
                  'qty': selectedQty,
                  'total': currentPrice * selectedQty,
                });
                Navigator.pop(context);
              },
              child: const Text(
                "TAMBAH",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get isAdminGlobal => widget.role.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) {
      return const Center(child: Text("Katalog produk kosong"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final p = _products[index];
        int price = int.tryParse(p['price'].toString()) ?? 0;

        bool showPromo = !isAdminGlobal && _isPromoActive;
        int displayPrice = showPromo ? (price * 0.9).toInt() : price;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: p['image'] != null && p['image'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            p['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // --- BAGIAN HARGA CORET ---
                    if (showPromo) ...[
                      Row(
                        children: [
                          Text(
                            "Rp $price",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration:
                                  TextDecoration.lineThrough, // EFEK CORET
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "10%",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    Text(
                      "Rp $displayPrice",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    // --- SELESAI BAGIAN HARGA CORET ---
                    const SizedBox(height: 10),
                    if (isAdminGlobal)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => _showEditDialog(p),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () =>
                                  _confirmDelete(p['id'], p['name']),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () => _showQtyDialog(p),
                          child: const Text(
                            "Beli",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
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
