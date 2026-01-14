import 'package:flutter/material.dart';
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
  bool _hasShownPromo = false;
  final List<Map<String, dynamic>> _cart = [];

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _imgCtrl = TextEditingController();

  final GlobalKey<KatalogTabState> _katalogKey = GlobalKey<KatalogTabState>();

  late String userRole;

  @override
  void initState() {
    super.initState();
    userRole = widget.role.toLowerCase();
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

                  _katalogKey.currentState?.refreshData();

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
      KatalogTab(
        key: _katalogKey,
        role: userRole,
        onAddToCart: _tambahKeKeranjang,
        hasShownPromo: _hasShownPromo,
        onPromoShown: () => setState(() => _hasShownPromo = true),
      ),
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
