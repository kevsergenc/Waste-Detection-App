import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

const String geminiApiKey = 'API_KEY_BURAYA_EKLENECEK';

class WasteAnalysis {
  final String title;
  final String binColor;
  final String binName;
  final String binDescription;
  final String material;
  final String decomposition;
  final String recycleRate;
  final String hazardLevel;

  const WasteAnalysis({
    required this.title,
    required this.binColor,
    required this.binName,
    required this.binDescription,
    required this.material,
    required this.decomposition,
    required this.recycleRate,
    required this.hazardLevel,
  });

  factory WasteAnalysis.fromCategory(String category) {
    final c = category.toLowerCase();

    if (c.contains('plastik')) {
      return const WasteAnalysis(
        title: 'Plastik Atık',
        binColor: 'Sarı Kutu',
        binName: 'Plastik Geri Dönüşüm Kutusu',
        binDescription: 'Bu atık plastik geri dönüşüm kutusuna atılmalıdır.',
        material: 'Plastik',
        decomposition: 'Uzun',
        recycleRate: 'Yüksek',
        hazardLevel: 'Düşük',
      );
    }

    if (c.contains('kağıt') || c.contains('kagit') || c.contains('karton')) {
      return const WasteAnalysis(
        title: 'Kağıt / Karton Atık',
        binColor: 'Mavi Kutu',
        binName: 'Kağıt Geri Dönüşüm Kutusu',
        binDescription: 'Bu atık kağıt ve karton kutusuna atılmalıdır.',
        material: 'Kağıt / Karton',
        decomposition: 'Orta',
        recycleRate: 'Yüksek',
        hazardLevel: 'Düşük',
      );
    }

    if (c.contains('cam')) {
      return const WasteAnalysis(
        title: 'Cam Atık',
        binColor: 'Yeşil Kutu',
        binName: 'Cam Geri Dönüşüm Kutusu',
        binDescription: 'Bu atık cam geri dönüşüm kutusuna atılmalıdır.',
        material: 'Cam',
        decomposition: 'Çok uzun',
        recycleRate: 'Yüksek',
        hazardLevel: 'Düşük',
      );
    }

    if (c.contains('metal')) {
      return const WasteAnalysis(
        title: 'Metal Atık',
        binColor: 'Gri Kutu',
        binName: 'Metal Geri Dönüşüm Kutusu',
        binDescription: 'Bu atık metal geri dönüşüm kutusuna atılmalıdır.',
        material: 'Metal',
        decomposition: 'Uzun',
        recycleRate: 'Yüksek',
        hazardLevel: 'Düşük',
      );
    }

    if (c.contains('organik')) {
      return const WasteAnalysis(
        title: 'Organik Atık',
        binColor: 'Kahverengi Kutu',
        binName: 'Organik Atık Kutusu',
        binDescription: 'Bu atık organik atık kutusuna atılmalıdır.',
        material: 'Organik',
        decomposition: 'Kısa',
        recycleRate: 'Kompost olabilir',
        hazardLevel: 'Düşük',
      );
    }

    if (c.contains('pil')) {
      return const WasteAnalysis(
        title: 'Pil Atığı',
        binColor: 'Atık Pil Kutusu',
        binName: 'Atık Pil Toplama Kutusu',
        binDescription:
            'Bu atık normal çöpe atılmamalı, pil toplama kutusuna bırakılmalıdır.',
        material: 'Pil',
        decomposition: 'Çok uzun',
        recycleRate: 'Özel işlem gerekir',
        hazardLevel: 'Yüksek',
      );
    }

    if (c.contains('elektronik')) {
      return const WasteAnalysis(
        title: 'Elektronik Atık',
        binColor: 'E-Atık Kutusu',
        binName: 'Elektronik Atık Toplama Kutusu',
        binDescription:
            'Bu atık elektronik atık toplama noktasına teslim edilmelidir.',
        material: 'Elektronik',
        decomposition: 'Çok uzun',
        recycleRate: 'Özel işlem gerekir',
        hazardLevel: 'Orta',
      );
    }

    return const WasteAnalysis(
      title: 'Genel Atık',
      binColor: 'Gri Kutu',
      binName: 'Genel Atık Kutusu',
      binDescription:
          'Bu atık geri dönüştürülemiyorsa genel atık kutusuna atılmalıdır.',
      material: 'Karma Malzeme',
      decomposition: 'Bilinmiyor',
      recycleRate: 'Değişken',
      hazardLevel: 'Düşük',
    );
  }
}

Future<WasteAnalysis> analyzeWasteImage(XFile image) async {
  final bytes = await image.readAsBytes();
  final base64Image = base64Encode(bytes);

  final fileName = image.name.toLowerCase();
  String mimeType = 'image/jpeg';

  if (fileName.endsWith('.png')) {
    mimeType = 'image/png';
  } else if (fileName.endsWith('.webp')) {
    mimeType = 'image/webp';
  }

  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey',
  );

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Bu fotoğraftaki atığı analiz et. Sadece şu kategorilerden birini yaz: Plastik, Kağıt, Cam, Metal, Organik, Elektronik, Pil, Genel Atık. Açıklama yazma. Sadece kategori adı yaz.',
            },
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ]
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Gemini API hatası: ${response.body}');
  }

  final data = jsonDecode(response.body);
  final text =
      data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Genel Atık';

  return WasteAnalysis.fromCategory(text.toString());
}

Future<void> pickAndAnalyzeWaste(
  BuildContext context,
  ImageSource source,
) async {
  final picker = ImagePicker();

  final XFile? image = await picker.pickImage(
    source: source,
    imageQuality: 80,
  );

  if (!context.mounted) return;
  if (image == null) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.green,
              ),
              SizedBox(height: 20),
              Text(
                'Atık analiz ediliyor...',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sistem fotoğrafı inceliyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    final analysis = await analyzeWasteImage(image);

    if (!context.mounted) return;
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          selectedImageName: image.name,
          analysis: analysis,
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.cardLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: const Text(
          'AI analiz kotası dolu veya bağlantı hatası oluştu. Lütfen daha sonra tekrar deneyin.',
          style: TextStyle(
            color: AppColors.textWhite,
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const AtikTaraApp());
}

class AtikTaraApp extends StatelessWidget {
  const AtikTaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AtıkTara',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class AppColors {
  static const background = Color(0xFF07120D);
  static const darkGreen = Color(0xFF0D1F17);
  static const card = Color(0xFF10241B);
  static const cardLight = Color(0xFF183429);
  static const green = Color(0xFF8CFF9A);
  static const textWhite = Color(0xFFF6FFF8);
  static const textGray = Color(0xFFB8C9BD);
  static const yellow = Color(0xFFFFD45A);
  static const blue = Color(0xFF69B7FF);
  static const glass = Color(0xFF70E4A7);
  static const gray = Color(0xFFB8BEC8);
  static const brown = Color(0xFFC8915B);
  static const red = Color(0xFFFF6B6B);

  static Color binAccent(String binColor) {
    final c = binColor.toLowerCase();

    if (c.contains('sarı')) return yellow;
    if (c.contains('mavi')) return blue;
    if (c.contains('yeşil')) return glass;
    if (c.contains('kahverengi')) return brown;
    if (c.contains('pil')) return red;
    if (c.contains('e-atık')) return const Color(0xFFB084FF);
    return gray;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        height: 108,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.green,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
                height: 1.20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget miniStat(String value, String label) {
    return Container(
      width: 86,
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 11.5,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D2A1D),
              AppColors.background,
              Color(0xFF050B08),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.green.withOpacity(0.35),
                      ),
                    ),
                    child: const Text(
                      'AI Destekli',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.green,
                        Color(0xFF2D8F55),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withOpacity(0.28),
                        blurRadius: 45,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.darkGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.recycling,
                      size: 82,
                      color: AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                const Text(
                  'AtıkTara',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'AI DESTEKLİ ATIK SINIFLANDIRMA VE GERİ DÖNÜŞÜM YÖNLENDİRME',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    miniStat('Tarama', 'Çek / Seç'),
                    const SizedBox(width: 12),
                    miniStat('AI', 'Analiz desteği'),
                    const SizedBox(width: 12),
                    miniStat('Eco', 'Geri dönüşüm'),
                  ],
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      size: 28,
                    ),
                    label: const Text(
                      'Atığı Tara',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    featureCard(
                      icon: Icons.photo_camera_outlined,
                      title: 'Kamera',
                      subtitle: 'Fotoğrafla analiz',
                    ),
                    const SizedBox(width: 12),
                    featureCard(
                      icon: Icons.auto_awesome,
                      title: 'AI Analiz',
                      subtitle: 'Akıllı sınıflandırma',
                    ),
                    const SizedBox(width: 12),
                    featureCard(
                      icon: Icons.near_me_outlined,
                      title: 'Yönlendirme',
                      subtitle: 'Uygun kutu önerisi',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  Widget scanCorner({
    required Alignment alignment,
  }) {
    BorderRadius radius;

    if (alignment == Alignment.topLeft) {
      radius = const BorderRadius.only(topLeft: Radius.circular(18));
    } else if (alignment == Alignment.topRight) {
      radius = const BorderRadius.only(topRight: Radius.circular(18));
    } else if (alignment == Alignment.bottomLeft) {
      radius = const BorderRadius.only(bottomLeft: Radius.circular(18));
    } else {
      radius = const BorderRadius.only(bottomRight: Radius.circular(18));
    }

    return Align(
      alignment: alignment,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border(
            top: alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? const BorderSide(color: AppColors.green, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: AppColors.green, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? const BorderSide(color: AppColors.green, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: AppColors.green, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget guideChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.green,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: foregroundColor.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textWhite,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atığı Tara',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fotoğraf çek veya galeriden seç.',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  guideChip(
                    icon: Icons.center_focus_strong,
                    text: 'Atığı Ortala',
                  ),
                  guideChip(
                    icon: Icons.wb_sunny_outlined,
                    text: 'Işık Net Olsun',
                  ),
                  guideChip(
                    icon: Icons.image_search_outlined,
                    text: 'Fotoğraf Net Olsun',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.cardLight,
                        AppColors.card,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.green.withOpacity(0.22),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withOpacity(0.10),
                        blurRadius: 30,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      scanCorner(alignment: Alignment.topLeft),
                      scanCorner(alignment: Alignment.topRight),
                      scanCorner(alignment: Alignment.bottomLeft),
                      scanCorner(alignment: Alignment.bottomRight),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: AppColors.green,
                            size: 76,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.only(
                            left: 18,
                            right: 18,
                            bottom: 28,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.34),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Atığı çerçeveye yerleştir',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Net fotoğraf ile analizi başlat.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textGray,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              actionButton(
                icon: Icons.photo_camera_rounded,
                title: 'Fotoğraf Çek',
                subtitle: 'Kamera ile atık görseli tara',
                backgroundColor: AppColors.green,
                foregroundColor: Colors.black,
                onTap: () async {
                  await pickAndAnalyzeWaste(context, ImageSource.camera);
                },
              ),
              const SizedBox(height: 14),
              actionButton(
                icon: Icons.photo_library_outlined,
                title: 'Galeriden Seç',
                subtitle: 'Hazır fotoğraf üzerinden analiz yap',
                backgroundColor: AppColors.cardLight,
                foregroundColor: AppColors.textWhite,
                onTap: () async {
                  await pickAndAnalyzeWaste(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String? selectedImageName;
  final WasteAnalysis? analysis;

  const ResultPage({
    super.key,
    this.selectedImageName,
    this.analysis,
  });

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textGray,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.4,
        ),
      ),
    );
  }

  Widget infoMainCard(WasteAnalysis analysisData) {
    final accent = AppColors.binAccent(analysisData.binColor);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.22),
            AppColors.card,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: accent.withOpacity(0.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accent.withOpacity(0.35),
              ),
            ),
            child: Icon(
              Icons.delete_rounded,
              color: accent,
              size: 42,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysisData.binColor,
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  analysisData.binName,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  analysisData.binDescription,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget smallInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.green,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget stepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: const Column(
        children: [
          StepRow(
            number: '1',
            title: 'Atığı kontrol edin',
            subtitle: 'Mümkünse içini boşaltıp temizleyin.',
          ),
          SizedBox(height: 18),
          StepRow(
            number: '2',
            title: 'Doğru kutuya bırakın',
            subtitle: 'Önerilen geri dönüşüm kutusunu kullanın.',
          ),
          SizedBox(height: 18),
          StepRow(
            number: '3',
            title: 'Karışık atıktan kaçının',
            subtitle: 'Geri dönüşüm verimini artırın.',
          ),
        ],
      ),
    );
  }

  Widget environmentCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.green.withOpacity(0.42),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.eco_rounded,
            color: AppColors.green,
            size: 34,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Çevresel Katkı',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Atıkları doğru ayrıştırmak geri dönüşüm sürecini kolaylaştırır, kaynak kullanımını azaltır ve çevre kirliliğinin önüne geçmeye yardımcı olur.',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 15.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisData = analysis ?? WasteAnalysis.fromCategory('Genel Atık');
    final accent = AppColors.binAccent(analysisData.binColor);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textWhite,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Analiz Sonucu',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(0.22),
                      AppColors.card,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: accent.withOpacity(0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.13),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: accent.withOpacity(0.32),
                        ),
                      ),
                      child: Text(
                        analysisData.material.toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      analysisData.title,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedImageName != null
                          ? 'Analiz edilen görsel: $selectedImageName'
                          : 'Fotoğraf başarıyla analiz edildi.',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              sectionTitle('ÖNERİLEN KUTU'),
              infoMainCard(analysisData),
              const SizedBox(height: 24),
              sectionTitle('ATIK BİLGİLERİ'),
              Row(
                children: [
                  Expanded(
                    child: smallInfoCard(
                      icon: Icons.category_outlined,
                      title: 'Malzeme',
                      value: analysisData.material,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: smallInfoCard(
                      icon: Icons.timer_outlined,
                      title: 'Ayrışma',
                      value: analysisData.decomposition,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: smallInfoCard(
                      icon: Icons.recycling_rounded,
                      title: 'Dönüşüm',
                      value: analysisData.recycleRate,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: smallInfoCard(
                      icon: Icons.warning_amber_rounded,
                      title: 'Tehlike',
                      value: analysisData.hazardLevel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              sectionTitle('NASIL ATILIR?'),
              stepsCard(),
              const SizedBox(height: 24),
              environmentCard(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Yeniden Tara',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScanPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StepRow extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const StepRow({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.green.withOpacity(0.14),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}