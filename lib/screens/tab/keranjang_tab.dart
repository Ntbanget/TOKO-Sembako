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
  // Fungsi untuk menampilkan Pop-up Peringatan
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
          "Silakan lengkapi Nama dan Alamat Anda di menu Profil terlebih dahulu sebelum melakukan checkout.",
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

  void _checkoutWA() async {
    if (widget.cart.isEmpty) return;

    // 1. Ambil Username
    final prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? "";

    // 2. Ambil Data Profil
    final profile = await DatabaseHelper.instance.getProfile(username);

    // Ambil data dan bersihkan spasi kosong
    String namaLengkap = (profile?['full_name'] ?? "").trim();
    String alamat = (profile?['address'] ?? "").trim();

    // 3. VALIDASI: Jika nama atau alamat kosong, munculkan pop-up dan hentikan proses
    if (namaLengkap.isEmpty || alamat.isEmpty) {
      _showProfileWarning();
      return;
    }

    // 4. Susun Pesan WhatsApp (Jika validasi lolos)
    String daftar = "🛒 *PESANAN BARU - TOKO KITA*\n";
    daftar += "------------------------------------------\n";
    daftar += "*Data Pengirim:*\n";
    daftar += "👤 Nama: $namaLengkap\n";
    daftar += "📍 Alamat: $alamat\n";
    daftar += "------------------------------------------\n\n";
    daftar += "*Daftar Belanja:*\n";

    int total = 0;
    for (var item in widget.cart) {
      daftar += "• ${item['name']} (x${item['qty']}) = Rp ${item['total']}\n";
      total += item['total'] as int;
    }

    daftar += "\n💰 *TOTAL BAYAR: Rp $total*";
    daftar += "\n\nMohon segera diproses ya Admin, terima kasih!";

    final url = Uri.parse(
      "https://wa.me/6285642447207?text=${Uri.encodeComponent(daftar)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... Bagian build tetap sama seperti kode Anda sebelumnya ...
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
                      vertical: 5,
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
