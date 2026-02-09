import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../db/database_helper.dart';

class KeranjangTab extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Function(int) onRemove;

  const KeranjangTab({super.key, required this.cart, required this.onRemove});

  @override
  State<KeranjangTab> createState() => _KeranjangTabState();
}

class _KeranjangTabState extends State<KeranjangTab> {
  // POPUP PROFIL BELUM LENGKAP
  void _showProfileWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Profil Belum Lengkap"),
          ],
        ),
        content: const Text(
          "Silakan lengkapi Nama dan Alamat Anda di menu Profil sebelum checkout.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OKE"),
          ),
        ],
      ),
    );
  }

  // CHECKOUT VIA WHATSAPP
  Future<void> _checkoutWA() async {
    if (widget.cart.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final String username = prefs.getString('username') ?? "";

    // Ambil data profil
    final profile = await DatabaseHelper.instance.getProfile(username);
    final String namaLengkap = (profile?['full_name'] ?? "").trim();
    final String alamat = (profile?['address'] ?? "").trim();

    // Validasi profil
    if (namaLengkap.isEmpty || alamat.isEmpty) {
      _showProfileWarning();
      return;
    }

    // CEK PROMO
    bool hasPromo = prefs.getBool('hasPromo') ?? false;

    // HITUNG TOTAL
    int subtotal = 0;
    for (var item in widget.cart) {
      subtotal += item['total'] as int;
    }

    int diskon = 0;
    if (hasPromo) {
      diskon = (subtotal * 0.1).toInt(); // 10% dari TOTAL
    }

    final int totalBayar = subtotal - diskon;

    // SUSUN PESAN WA
    String pesan = "🛒 *PESANAN BARU - TOKO KITA*\n";
    pesan += "----------------------------------\n";
    pesan += "*Data Pembeli:*\n";
    pesan += "👤 Nama: $namaLengkap\n";
    pesan += "📍 Alamat: $alamat\n";
    pesan += "----------------------------------\n\n";
    pesan += "*Daftar Belanja:*\n";

    for (var item in widget.cart) {
      pesan += "• ${item['name']} (x${item['qty']}) = Rp ${item['total']}\n";
    }

    pesan += "\nSubtotal: Rp $subtotal";

    if (diskon > 0) {
      pesan += "\n🎉 *Diskon 10%: -Rp $diskon*";
    }

    pesan += "\n💰 *TOTAL BAYAR: Rp $totalBayar*";
    pesan += "\n\nTerima kasih 🙏";

    final url = Uri.parse(
      "https://wa.me/6285642447207?text=${Uri.encodeComponent(pesan)}",
    );

    // BUKA WHATSAPP
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);

      // 🔒 KUNCI PROMO PERMANEN
      if (hasPromo) {
        await DatabaseHelper.instance.setPurchased(username);
        await prefs.setBool('hasPromo', false);
      }

      // KOSONGKAN KERANJANG
      setState(() {
        widget.cart.clear();
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp")));
    }
  }

  // UI KERANJANG
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.cart.isEmpty
              ? const Center(child: Text("Keranjang masih kosong"))
              : ListView.builder(
                  itemCount: widget.cart.length,
                  itemBuilder: (context, i) => Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        widget.cart[i]['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${widget.cart[i]['qty']} x Rp ${widget.cart[i]['price']}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => widget.onRemove(i),
                      ),
                    ),
                  ),
                ),
        ),
        if (widget.cart.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _checkoutWA,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text(
                "CHECKOUT VIA WA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
