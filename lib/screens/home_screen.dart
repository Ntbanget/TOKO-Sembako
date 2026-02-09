import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tab/katalog_tab.dart';
import 'tab/keranjang_tab.dart';
import 'tab/profil_tab.dart';
import '../db/database_helper.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _cart = [];

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _imgCtrl = TextEditingController();

  late String userRole;
  bool _promoChecked = false;

  @override
  void initState() {
    super.initState();
    userRole = widget.role.toLowerCase();
    _checkPromo();
  }

  // CEK PROMO SAAT MASUK HOME
  Future<void> _checkPromo() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? "";

    if (username.isEmpty) return;

    final isFirst = await DatabaseHelper.instance.isFirstPurchase(username);

    if (!mounted) return;

    if (isFirst && !_promoChecked && userRole != 'admin') {
      _promoChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPromoPopup();
      });
    }
  }

  // POPUP PROMO
  void _showPromoPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/images/PROMO.png",
              height: 150,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.card_giftcard, size: 80),
            ),
            const SizedBox(height: 15),
            const Text(
              "PROMO KHUSUS USER BARU",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            const Text("Diskon 10% untuk pembelian pertama"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text("NANTI"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasPromo', true);

              if (!mounted) return;
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Promo aktif! 🎉"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("KLAIM", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _tambahKeKeranjang(Map<String, dynamic> item) {
    setState(() {
      _cart.add(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item['name']} ditambah ke keranjang"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAddProductForm() {
    _nameCtrl.clear();
    _priceCtrl.clear();
    _imgCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              "Tambah Produk Baru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nama Produk",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Harga",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _imgCtrl,
              decoration: const InputDecoration(
                labelText: "URL Gambar",
                border: OutlineInputBorder(),
                hintText: "https://... atau kosongkan",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                if (_nameCtrl.text.isNotEmpty && _priceCtrl.text.isNotEmpty) {
                  await DatabaseHelper.instance.addProduct({
                    'name': _nameCtrl.text,
                    'price': int.parse(_priceCtrl.text),
                    'image': _imgCtrl.text,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {
                    _selectedIndex = 0;
                  });
                }
              },
              child: const Text(
                "SIMPAN PRODUK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = userRole == 'admin';

    final List<Widget> pages = [
      KatalogTab(role: userRole, onAddToCart: _tambahKeKeranjang),
      isAdmin
          ? const Center(
              child: Text(
                "Gunakan tombol di bawah\nuntuk mengelola barang",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : KeranjangTab(
              cart: _cart,
              onRemove: (index) => setState(() => _cart.removeAt(index)),
            ),
      ProfilTab(role: userRole),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/images/logo.png",
              height: 35,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.store, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              "TOKO KITA",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (isAdmin && index == 1) {
            _showAddProductForm();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: "Katalog",
          ),
          BottomNavigationBarItem(
            icon: Icon(isAdmin ? Icons.add_circle : Icons.shopping_cart),
            label: isAdmin ? "Tambah" : "Keranjang",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}
