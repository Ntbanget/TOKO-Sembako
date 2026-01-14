import 'package:flutter_test/flutter_test.dart';
import 'package:toko_sembako/main.dart'; // Pastikan nama project sesuai

void main() {
  testWidgets('TOKO KITA Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const TokoKitaApp());

    // 2. Memastikan aplikasi menampilkan nama toko di halaman login
    // Kita gunakan findsWidgets karena nama TOKO POJOK muncul di judul dan teks
    expect(find.text('TOKO KITA'), findsWidgets);

    // 3. Memastikan ada tombol MASUK di layar awal (Login Screen)
    expect(find.text('MASUK'), findsOneWidget);
  });
}
