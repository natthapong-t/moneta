import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/expense_card_item.dart';

class ThaiBankInfo {
  final String name;
  final Color color;

  const ThaiBankInfo({required this.name, required this.color});
}

class SlipScanProgress {
  final int scanned;
  final int total;
  final int foundCount;
  final ExpenseCardItem? newSlip;
  final String? currentSource;

  const SlipScanProgress({
    required this.scanned,
    required this.total,
    required this.foundCount,
    this.newSlip,
    this.currentSource,
  });

  bool get isFinished => scanned >= total;
}

class SlipParserService {
  // Official Bank Identification Codes in Thailand (BOT / PromptPay EMVCo)
  static const Map<String, ThaiBankInfo> bankCodeMap = {
    '004': ThaiBankInfo(name: 'กสิกรไทย', color: Color(0xFF138F46)),
    '014': ThaiBankInfo(name: 'ไทยพาณิชย์', color: Color(0xFF4E2A84)),
    '006': ThaiBankInfo(name: 'กรุงไทย', color: Color(0xFF00A3E0)),
    '002': ThaiBankInfo(name: 'กรุงเทพ', color: Color(0xFF1E3A8A)),
    '011': ThaiBankInfo(name: 'ทีทีบี', color: Color(0xFF002D62)),
    '025': ThaiBankInfo(name: 'กรุงศรี / ทรูมันนี่', color: Color(0xFFFA5A00)),
    '034': ThaiBankInfo(name: 'ธ.ก.ส.', color: Color(0xFF006633)),
    '030': ThaiBankInfo(name: 'ออมสิน', color: Color(0xFFEB198B)),
    '067': ThaiBankInfo(name: 'ทิสโก้', color: Color(0xFF005DAA)),
    '069': ThaiBankInfo(name: 'เกียรตินาคินภัทร', color: Color(0xFF6B2C8B)),
    '073': ThaiBankInfo(name: 'แลนด์ แอนด์ เฮ้าส์', color: Color(0xFF6D6E71)),
  };

  /// Known Thai Mobile Banking, Fintech & Payment album/folder keywords
  static const List<String> thaiFinancialAlbumKeywords = [
    // Banking Apps
    'k plus', 'kplus', 'kbank', 'make by kbank', 'make',
    'scb easy', 'scbeasy', 'scb',
    'krungthai next', 'krungthai', 'next', 'paotang', 'เป๋าตัง',
    'bangkok bank', 'bualuang', 'bbl',
    'ttb touch', 'ttb', 'tmb touch', 'tmb',
    'kma', 'krungsri', 'uchoose', 'kept',
    'mymo', 'gsb', 'ออมสิน',
    'baac mobile', 'baac', 'ธกส', 'ธ.ก.ส.',
    'ghb all', 'ghb', 'ธอส', 'ธ.อ.ส.',
    'kkp mobile', 'kkp',
    'tisco', 'lh bank', 'lhb', 'lhb you',
    'cimb', 'uob tmrw', 'tmrw', 'uob',
    // Authorized Wallets & Transit Auto-Debit
    'truemoney', 'true money', 'true wallet',
    'shopeepay', 'shopee pay', 'airpay',
    'rabbit', 'rabbit line pay', 'line pay',
    // Generic slip folder names
    'slip', 'slips', 'สลิป', 'receipt', 'ใบเสร็จ', 'transfer', 'โอนเงิน',
  ];

  /// Albums, folders, and path keywords explicitly EXCLUDED from scanning:
  /// 1. Screenshots (banks block screenshots anyway; avoids noisy non-slip images and saves CPU)
  /// 2. Stock / Investment platforms (e.g. Dime, InnovestX, Streaming)
  /// 3. Food delivery / Ride apps (user settles through bank app anyway; prevents bogus OCR matches)
  static const List<String> excludedAlbumKeywords = [
    // Screenshots
    'screenshot', 'screenshots', 'screen_shot', 'screen-shot',
    'screen capture', 'screencapture', 'screencap',
    'ภาพหน้าจอ', 'จับภาพหน้าจอ', 'แคปหน้าจอ', 'สกรีนช็อต',
    // Stock / Investments
    'dime', 'dime!', 'innovestx', 'streaming', 'settrade', 'invest',
    // Food delivery / rides
    'line man', 'lineman', 'grab', 'robinhood', 'foodpanda', 'shopeefood',
  ];

  /// Tests whether a path or album name should be strictly excluded
  static bool isExcludedAlbumOrPath(String nameOrPath) {
    final clean = nameOrPath.trim().toLowerCase();
    if (clean.isEmpty) return false;
    for (final kw in excludedAlbumKeywords) {
      if (clean.contains(kw)) return true;
    }
    return false;
  }

  /// Tests whether an album name corresponds to a financial, banking, or slip folder
  static bool isFinancialAlbum(String albumName) {
    final clean = albumName.trim().toLowerCase();
    if (clean.isEmpty) return false;
    if (isExcludedAlbumOrPath(clean)) return false;

    // Direct exact names & short abbreviations
    const exactNames = {
      'make', 'make by kbank', 'next', 'krungthai next',
      'k plus', 'kplus', 'kbank', 'scb', 'scb easy', 'scbeasy',
      'baac', 'baac mobile', 'kept', 'mymo',
      'bbl', 'bangkok bank', 'ttb', 'ttb touch', 'tmb', 'tmb touch',
      'kma', 'uchoose', 'krungsri', 'gsb', 'ghb', 'ghb all', 'ghb all gen',
      'kkp', 'kkp mobile', 'tisco', 'lh bank', 'lhb', 'lhb you',
      'cimb', 'uob', 'tmrw', 'uob tmrw',
      'truemoney', 'true money', 'truemoney wallet',
      'shopeepay', 'shopee pay', 'airpay',
      'rabbit', 'rabbit line pay', 'line pay',
      'slip', 'slips', 'bank', 'banking',
      'สลิป', 'สลิปโอนเงิน', 'ใบเสร็จ', 'โอนเงิน', 'เป๋าตัง', 'ออมสิน', 'ธกส', 'ธอส',
    };
    if (exactNames.contains(clean)) return true;

    for (final kw in thaiFinancialAlbumKeywords) {
      if (kw.length <= 4 && !kw.contains(RegExp(r'[ก-๙]'))) {
        final regex = RegExp(r'(^|[^a-zA-Z0-9])' + RegExp.escape(kw) + r'($|[^a-zA-Z0-9])');
        if (regex.hasMatch(clean)) return true;
      } else {
        if (clean.contains(kw)) return true;
      }
    }
    return false;
  }

  final _picker = ImagePicker();

  /// Prompt user to select multiple slips manually from their device gallery
  Future<List<String>> pickSlipImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      return pickedFiles.map((file) => file.path).toList();
    } catch (_) {
      return [];
    }
  }

  /// Stream slips discovered in the background in chronological order (Newest -> Oldest)
  /// Walks through the unified photo gallery by creation date so the user sees a natural timeline
  Stream<SlipScanProgress> streamGallerySlips({
    int? maxScan,
    Set<String> knownReferenceNos = const {},
    Set<String> knownImagePaths = const {},
    Set<String> knownAssetIds = const {},
    void Function(String assetId, String? imagePath)? onAssetScanned,
  }) async* {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      return;
    }

    // Unified camera roll ordered strictly from newest to oldest
    final filterOption = FilterOptionGroup(
      orders: [
        const OrderOption(
          type: OrderOptionType.createDate,
          asc: false, // Descending: Newest photos first!
        ),
      ],
    );

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: filterOption,
    );
    if (albums.isEmpty) return;

    final AssetPathEntity timelineAlbum = albums.first;
    final int totalAssets = await timelineAlbum.assetCountAsync;
    final int scanTarget = (maxScan != null && maxScan > 0 && maxScan < totalAssets)
        ? maxScan
        : totalAssets;

    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    int scannedSoFar = 0;
    int foundCount = 0;
    const int batchSize = 25;
    final Set<String> processedPaths = Set<String>.from(knownImagePaths);
    final Set<String> existingRefs = Set<String>.from(knownReferenceNos);

    try {
      for (int page = 0; page * batchSize < scanTarget; page++) {
        if (maxScan != null && scannedSoFar >= maxScan) break;

        final start = page * batchSize;
        final end = (start + batchSize > scanTarget) ? scanTarget : start + batchSize;

        final List<AssetEntity> batch = await timelineAlbum.getAssetListRange(
          start: start,
          end: end,
        );

        for (final asset in batch) {
          scannedSoFar++;

          // ⚡ Instant Cache Skip: If asset was already scanned (slip or non-slip), skip in 0.001ms
          if (knownAssetIds.contains(asset.id)) {
            continue;
          }

          // Pre-filter: Bank slips are portrait or square
          if (asset.width > asset.height * 1.25) {
            onAssetScanned?.call(asset.id, null);
            continue;
          }

          final file = await asset.file;
          if (file == null || !await file.exists()) {
            onAssetScanned?.call(asset.id, null);
            continue;
          }

          // Fast-skip screenshots, stock apps, and food delivery folders to save CPU
          if (isExcludedAlbumOrPath(file.path)) {
            onAssetScanned?.call(asset.id, file.path);
            continue;
          }

          if (processedPaths.contains(file.path)) {
            onAssetScanned?.call(asset.id, file.path);
            continue;
          }
          processedPaths.add(file.path);

          final item = await parseSingleSlip(
            file.path,
            scanner: barcodeScanner,
            recognizer: textRecognizer,
            sourceAlbum: 'ไทม์ไลน์ล่าสุด',
            assetDateTime: asset.createDateTime,
          );

          // Mark this asset as analyzed so it is NEVER re-scanned in the future
          onAssetScanned?.call(asset.id, file.path);

          if (item != null) {
            if (item.referenceNo.isNotEmpty && existingRefs.contains(item.referenceNo)) {
              continue;
            }
            if (item.referenceNo.isNotEmpty) {
              existingRefs.add(item.referenceNo);
            }

            foundCount++;
            yield SlipScanProgress(
              scanned: scannedSoFar,
              total: scanTarget,
              foundCount: foundCount,
              newSlip: item,
              currentSource: 'ไทม์ไลน์ล่าสุด',
            );
          }

          await Future.delayed(const Duration(milliseconds: 5));
        }

        yield SlipScanProgress(
          scanned: scannedSoFar,
          total: scanTarget,
          foundCount: foundCount,
          newSlip: null,
          currentSource: 'ไทม์ไลน์ล่าสุด',
        );
      }
    } finally {
      barcodeScanner.close();
      textRecognizer.close();
    }
  }

  /// Automatically scans recent gallery images in chronological order (Newest -> Oldest)
  Future<List<String>> scanDeviceGalleryImagePaths({int? limit}) async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth && !ps.hasAccess) {
        return [];
      }

      final filterOption = FilterOptionGroup(
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false, // Newest first
          ),
        ],
      );

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: filterOption,
      );

      if (albums.isEmpty) return [];
      final generalAlbum = albums.first;
      final int totalGeneral = await generalAlbum.assetCountAsync;
      final int end = (limit != null && limit > 0 && limit < totalGeneral)
          ? limit
          : totalGeneral;

      final List<AssetEntity> generalAssets = await generalAlbum.getAssetListRange(
        start: 0,
        end: end,
      );

      final List<String> paths = [];
      final Set<String> seenPaths = {};

      for (final asset in generalAssets) {
        if (asset.width > asset.height * 1.25) continue;

        final file = await asset.file;
        if (file != null &&
            await file.exists() &&
            !isExcludedAlbumOrPath(file.path) &&
            seenPaths.add(file.path)) {
          paths.add(file.path);
          if (limit != null && paths.length >= limit) return paths;
        }
      }

      return paths;
    } catch (e) {
      debugPrint('Error accessing device photo gallery: $e');
      return [];
    }
  }

  /// Parses Thai PromptPay Slip Verification QR payload (EMVCo TLV format)
  static Map<String, String> parseEMVCoTLV(String raw) {
    final Map<String, String> tags = {};
    int index = 0;

    while (index + 4 <= raw.length) {
      final tag = raw.substring(index, index + 2);
      final lenStr = raw.substring(index + 2, index + 4);
      final len = int.tryParse(lenStr);
      if (len == null) break;

      index += 4;
      if (index + len > raw.length) break;

      final val = raw.substring(index, index + len);
      tags[tag] = val;
      index += len;
    }

    return tags;
  }

  /// Extracts amount from OCR text lines
  static double? extractAmountFromText(String fullText) {
    // 1. Look for amount explicitly attached to labels
    final explicitRegex = RegExp(
      r'(?:จำนวนเงิน|จำนวน|ยอดเงิน|ยอดชำระ|Amount|THB|฿)\s*[:]?\s*([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})',
      caseSensitive: false,
    );
    final explicitMatch = explicitRegex.firstMatch(fullText);
    if (explicitMatch != null) {
      final raw = explicitMatch.group(1)?.replaceAll(',', '');
      final val = raw != null ? double.tryParse(raw) : null;
      if (val != null && val > 0) return val;
    }

    // 2. Find all decimal candidates with 2 decimal places
    final decimalRegex = RegExp(r'\b([0-9]{1,3}(?:,[0-9]{3})*\.[0-9]{2})\b');
    final matches = decimalRegex.allMatches(fullText);

    final List<double> candidates = [];
    for (final m in matches) {
      final raw = m.group(1)?.replaceAll(',', '');
      if (raw != null) {
        final val = double.tryParse(raw);
        // Exclude fee 0.00
        if (val != null && val > 0) {
          candidates.add(val);
        }
      }
    }

    if (candidates.isEmpty) return null;

    // Usually the transfer amount is the first or primary candidate on a slip
    return candidates.first;
  }

  /// Extracts receiver name from OCR text lines
  static String extractReceiverName(String fullText) {
    final lines = fullText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('ไปยัง') || line.contains('ถึง') || line.contains('To:') || line.contains('To ')) {
        if (i + 1 < lines.length && lines[i + 1].length > 2) {
          return lines[i + 1].replaceAll(RegExp(r'(พร้อมเพย์|ไทยพาณิชย์|กสิกร|กรุงไทย|ธ\.ก\.ส\.)'), '').trim();
        }
        final cleaned = line.replaceAll(RegExp(r'(ไปยัง|ถึง|To:|To)'), '').trim();
        if (cleaned.isNotEmpty) return cleaned;
      }
    }
    return '';
  }

  /// Extracts note (บันทึกช่วยจำ) from text if present
  static String? extractNote(String fullText) {
    final lines = fullText.split('\n').map((l) => l.trim()).toList();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('บันทึกช่วยจำ') || line.contains('Memo') || line.contains('Note')) {
        if (i + 1 < lines.length && lines[i + 1].isNotEmpty) {
          return lines[i + 1];
        }
        final cleaned = line.replaceAll(RegExp(r'(บันทึกช่วยจำ|Memo|Note|:)'), '').trim();
        if (cleaned.isNotEmpty) return cleaned;
      }
    }
    return null;
  }

  /// Scan a single image and parse it into an ExpenseCardItem if it's a valid slip
  Future<ExpenseCardItem?> parseSingleSlip(
    String path, {
    BarcodeScanner? scanner,
    TextRecognizer? recognizer,
    String? sourceAlbum,
    DateTime? assetDateTime,
  }) async {
    final file = File(path);
    if (!await file.exists()) return null;

    // Fast-skip screenshots, stock apps (Dime), and food delivery paths
    if (isExcludedAlbumOrPath(path) ||
        (sourceAlbum != null && isExcludedAlbumOrPath(sourceAlbum))) {
      return null;
    }

    final bool ownsScanner = scanner == null;
    final bool ownsRecognizer = recognizer == null;

    final barcodeScanner = scanner ?? BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    final textRecognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(path);

      // 1. Scan QR code (Bank of Thailand PromptPay Mini-QR / BScanC)
      final barcodes = await barcodeScanner.processImage(inputImage);
      String? detectedBankCode;
      String? refFromQR;
      bool isPromptPaySlipQR = false;

      for (final barcode in barcodes) {
        final raw = barcode.rawValue;
        if (raw == null) continue;

        // Thai Bank Slip QR signature
        if (raw.contains('000001') || raw.startsWith('003') || raw.startsWith('004') || raw.startsWith('005')) {
          final topLevelTLV = parseEMVCoTLV(raw);
          final tag00Val = topLevelTLV['00'];

          if (tag00Val != null && tag00Val.contains('000001')) {
            isPromptPaySlipQR = true;
            final subTLV = parseEMVCoTLV(tag00Val);
            detectedBankCode = subTLV['01'];
            refFromQR = subTLV['02'];
            break;
          }
        }
      }

      // 2. OCR Text Recognition
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final fullText = recognizedText.text;

      // Extract details
      final double? amount = extractAmountFromText(fullText);
      final String receiver = extractReceiverName(fullText);
      final String? note = extractNote(fullText);

      // Detect Bank Brand from Text
      String bankName = 'สลิปธนาคาร';
      Color bankColor = const Color(0xFF003D79);

      if (detectedBankCode != null && bankCodeMap.containsKey(detectedBankCode)) {
        final info = bankCodeMap[detectedBankCode]!;
        bankName = info.name;
        bankColor = info.color;
      }

      final fullLower = fullText.toLowerCase();

      // Contextual bank text recognition
      if (fullLower.contains('truemoney') || fullText.contains('ทรูมันนี่')) {
        bankName = 'TrueMoney Wallet';
        bankColor = const Color(0xFFFA5A00);
      } else if (fullLower.contains('make') && fullLower.contains('kbank')) {
        bankName = 'MAKE by KBank';
        bankColor = const Color(0xFF00A9E0);
      } else if (fullText.contains('K PLUS') || fullText.contains('KBANK')) {
        bankName = 'กสิกรไทย';
        bankColor = const Color(0xFF138F46);
      } else if (fullText.contains('SCB')) {
        bankName = 'ไทยพาณิชย์';
        bankColor = const Color(0xFF4E2A84);
      } else if (fullText.contains('Krungthai') || fullText.contains('กรุงไทย')) {
        bankName = 'กรุงไทย';
        bankColor = const Color(0xFF00A3E0);
      } else if (fullText.contains('BAAC') || fullText.contains('ธ.ก.ส.')) {
        bankName = 'ธ.ก.ส.';
        bankColor = const Color(0xFF006633);
      } else if (fullLower.contains('rabbit') || fullText.contains('แรบบิท')) {
        bankName = 'แรบบิท ไลน์เพย์';
        bankColor = const Color(0xFF00B900);
      } else if (fullLower.contains('ttb') || fullText.contains('ทีทีบี')) {
        bankName = 'ทีทีบี';
        bankColor = const Color(0xFF002D62);
      } else if (fullLower.contains('bangkok bank') || fullText.contains('บัวหลวง') || fullText.contains('กรุงเทพ')) {
        bankName = 'กรุงเทพ';
        bankColor = const Color(0xFF1E3A8A);
      } else if (fullLower.contains('kept')) {
        bankName = 'กรุงศรี';
        bankColor = const Color(0xFF0075FF);
      } else if (fullLower.contains('mymo') || fullText.contains('ออมสิน')) {
        bankName = 'ออมสิน';
        bankColor = const Color(0xFFEB198B);
      } else if (fullLower.contains('shopee')) {
        bankName = 'ช้อปปี้เพย์';
        bankColor = const Color(0xFFEE4D2D);
      }

      // If bank name is still generic, infer from sourceAlbum if available
      if (bankName == 'สลิปธนาคาร' && sourceAlbum != null) {
        final albumLower = sourceAlbum.toLowerCase();
        if (albumLower.contains('rabbit')) {
          bankName = 'Rabbit';
          bankColor = const Color(0xFF00B900);
        } else if (albumLower.contains('make')) {
          bankName = 'MAKE by KBank';
          bankColor = const Color(0xFF00A9E0);
        } else if (albumLower.contains('scb')) {
          bankName = 'ไทยพาณิชย์';
          bankColor = const Color(0xFF4E2A84);
        } else if (albumLower.contains('krungthai') || albumLower.contains('next')) {
          bankName = 'กรุงไทย';
          bankColor = const Color(0xFF00A3E0);
        } else if (albumLower.contains('k plus') || albumLower.contains('kplus') || albumLower.contains('kbank')) {
          bankName = 'กสิกรไทย';
          bankColor = const Color(0xFF138F46);
        } else if (albumLower.contains('baac')) {
          bankName = 'ธ.ก.ส.';
          bankColor = const Color(0xFF006633);
        } else if (albumLower.contains('ttb')) {
          bankName = 'ทีทีบี';
          bankColor = const Color(0xFF002D62);
        } else if (albumLower.contains('mymo') || albumLower.contains('gsb')) {
          bankName = 'ออมสิน';
          bankColor = const Color(0xFFEB198B);
        } else if (albumLower.contains('truemoney')) {
          bankName = 'ทรูมันนี่ วอลเล็ท';
          bankColor = const Color(0xFFFA5A00);
        } else if (albumLower.contains('shopee')) {
          bankName = 'ช้อปปี้เพย์';
          bankColor = const Color(0xFFEE4D2D);
        }
      }

      // Strict Bank & Auto-Debit Slip Qualification Gate
      final bool isQrVerified = isPromptPaySlipQR;

      final bool isKnownFinancialSource = sourceAlbum != null &&
          isFinancialAlbum(sourceAlbum) &&
          sourceAlbum != 'คลังภาพทั่วไป' &&
          !isExcludedAlbumOrPath(sourceAlbum);

      final bool hasIdentifiedBankBrand = bankName != 'สลิปธนาคาร';

      final bool hasTransferKeywords = fullText.contains('โอนเงินสำเร็จ') ||
          fullText.contains('โอนสำเร็จ') ||
          fullText.contains('ทำรายการสำเร็จ') ||
          fullText.contains('สแกนจ่ายสำเร็จ') ||
          fullText.contains('ชำระเงินสำเร็จ') ||
          fullText.contains('หักบัญชีสำเร็จ') ||
          fullText.contains('บันทึกช่วยจำ') ||
          fullText.contains('รหัสอ้างอิง') ||
          fullText.contains('เลขที่รายการ') ||
          fullText.contains('Transfer Successful') ||
          fullText.contains('Transaction Successful') ||
          fullText.contains('Payment Successful') ||
          (fullText.contains('PromptPay') &&
              (fullText.contains('โอนเงิน') || fullText.contains('Transfer')));

      final bool isAuthorizedWallet = (bankName == 'TrueMoney Wallet' ||
              bankName == 'Rabbit LINE Pay' ||
              bankName == 'Rabbit' ||
              bankName == 'ShopeePay') &&
          (fullText.contains('สำเร็จ') ||
              fullText.contains('Successful') ||
              fullText.contains('รายการ') ||
              fullText.contains('ชำระเงิน'));

      final bool isValidSlip = isQrVerified ||
          (isKnownFinancialSource && (hasTransferKeywords || (amount != null && amount > 0))) ||
          (hasIdentifiedBankBrand && hasTransferKeywords && (amount != null && amount > 0)) ||
          isAuthorizedWallet;

      if (!isValidSlip) {
        return null; // Reject immediately! Not a verified bank or wallet slip.
      }

      final finalAmount = amount ?? 0.0;
      if (finalAmount <= 0 && !isPromptPaySlipQR && !isKnownFinancialSource) {
        return null; // No amount found and not verified QR or financial source
      }

      final finalRef = refFromQR ??
          'REF-${path.hashCode.abs()}-${finalAmount.toStringAsFixed(2)}';

      DateTime slipDate = assetDateTime ?? DateTime.now();
      if (assetDateTime == null) {
        try {
          final file = File(path);
          if (await file.exists()) {
            slipDate = await file.lastModified();
          }
        } catch (_) {}
      }

      return ExpenseCardItem(
        id: 'slip-${(refFromQR ?? path).hashCode.abs()}',
        receiverName: receiver.isNotEmpty
            ? receiver
            : (note ?? 'รายการโอนเงิน ($bankName)'),
        amount: finalAmount > 0 ? finalAmount : 100.0, // fallback if QR verified
        dateTime: slipDate,
        bankName: bankName,
        bankColor: bankColor,
        referenceNo: finalRef,
        note: note,
        imagePath: path,
      );
    } catch (e) {
      debugPrint('Error parsing slip at $path: $e');
      return null;
    } finally {
      if (ownsScanner) barcodeScanner.close();
      if (ownsRecognizer) textRecognizer.close();
    }
  }

  /// Scan a list of image paths and return detected bank slips with progress updates
  Future<List<ExpenseCardItem>> parseSlipImages(
    List<String> imagePaths, {
    void Function(int current, int total, int found)? onProgress,
  }) async {
    final List<ExpenseCardItem> parsedItems = [];
    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      for (int i = 0; i < imagePaths.length; i++) {
        final path = imagePaths[i];
        final item = await parseSingleSlip(
          path,
          scanner: barcodeScanner,
          recognizer: textRecognizer,
        );

        if (item != null) {
          parsedItems.add(item);
        }

        if (onProgress != null) {
          onProgress(i + 1, imagePaths.length, parsedItems.length);
        }
      }
    } finally {
      barcodeScanner.close();
      textRecognizer.close();
    }

    // Sort chronologically: newest first
    parsedItems.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return parsedItems;
  }
}
