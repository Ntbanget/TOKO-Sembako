import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../db/database_helper.dart';

class ProfilTab extends StatefulWidget {
  final String role;
  const ProfilTab({super.key, required this.role});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  String username = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username') ?? "";

    final profile = await DatabaseHelper.instance.getProfile(savedUsername);

    if (!mounted) return;

    setState(() {
      username = savedUsername;
      _nameCtrl.text = profile?['full_name'] ?? "";
      _addrCtrl.text = profile?['address'] ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.role.toLowerCase() == 'admin';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.orange,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            isAdmin ? "AKUN ADMIN" : "AKUN PELANGGAN",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 25),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: isAdmin ? "Nama Admin" : "Nama Lengkap",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.badge, color: Colors.orange),
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(height: 15),
            TextField(
              controller: _addrCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Alamat Pengiriman",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home, color: Colors.orange),
              ),
            ),
          ],
          const SizedBox(height: 25),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);

              await DatabaseHelper.instance.saveProfile({
                'username': username,
                'full_name': _nameCtrl.text,
                'address': isAdmin ? "" : _addrCtrl.text,
              });

              if (!mounted) return;

              messenger.showSnackBar(
                const SnackBar(
                  content: Text("Profil Berhasil Diperbarui!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              "SIMPAN PERUBAHAN",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final prf = await SharedPreferences.getInstance();
              await prf.clear();

              if (!mounted) return;

              navigator.pushReplacementNamed('/login');
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "KELUAR AKUN",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
