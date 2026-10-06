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

  const SlipScanProgress({
    required this.scanned,
    required this.total,
    required this.foundCount,
    this.newSlip,
  });

  bool get isFinished => scanned >= total;
}

class SlipParserService {
  // Official Bank Identification Codes in Thailand (BOT / PromptPay EMVCo)
  static const Map<String, ThaiBankInfo> bankCodeMap = {
    '004': ThaiBankInfo(name: 'K PLUS (กสิกรไทย)', color: Color(0xFF138F46)),
    '014': ThaiBankInfo(name: 'SCB EASY (ไทยพาณิชย์)', color: Color(0xFF4E2A84)),
    '006': ThaiBankInfo(name: 'Krungthai NEXT (กรุงไทย)', color: Color(0xFF00A3E0)),
    '002': ThaiBankInfo(name: 'Bangkok Bank (กรุงเทพ)', color: Color(0xFF1E3A8A)),
    '011': ThaiBankInfo(name: 'ttb touch (ทีทีบี)', color: Color(0xFF002D62)),
    '025': ThaiBankInfo(name: 'TrueMoney / กรุงศรี', color: Color(0xFFFA5A00)),
    '034': ThaiBankInfo(name: 'BAAC (ธ.ก.ส.)', color: Color(0xFF006633)),
    '030': ThaiBankInfo(name: 'GSB (ออมสิน)', color: Color(0xFFEB198B)),
    '067': ThaiBankInfo(name: 'TISCO', color: Color(0xFF005DAA)),
    '069': ThaiBankInfo(name: 'Kiatnakin Phatra', color: Color(0xFF6B2C8B)),
    '073': ThaiBankInfo(name: 'LH Bank', color: Color(0xFF6D6E71)),
  };

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

  /// Stream slips discovered in the background across recent gallery images
  /// Processes in non-blocking batches, yielding each detected slip immediately.
  Stream<SlipScanProgress> streamGallerySlips({
    int maxScan = 500,
    Set<String> knownReferenceNos = const {},
  }) async* {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      return;
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return;

    final AssetPathEntity recentAlbum = albums.first;
    final int totalAssets = await recentAlbum.assetCountAsync;
    final int scanTarget = totalAssets < maxScan ? totalAssets : maxScan;

    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    int scannedSoFar = 0;
    int foundCount = 0;
    const int batchSize = 25;

    try {
      for (int page = 0; page * batchSize < scanTarget; page++) {
        final start = page * batchSize;
        final end = (start + batchSize > scanTarget) ? scanTarget : start + batchSize;

        final List<AssetEntity> batch = await recentAlbum.getAssetListRange(
          start: start,
          end: end,
        );

        for (final asset in batch) {
          scannedSoFar++;

          // 1. Ultra-fast portrait pre-filter (0ms)
          if (asset.width > asset.height * 1.25) {
            continue;
          }

          final file = await asset.file;
          if (file == null || !await file.exists()) continue;

          final item = await parseSingleSlip(
            file.path,
            scanner: barcodeScanner,
            recognizer: textRecognizer,
          );

          if (item != null) {
            // De-duplication: Skip if reference number is already known
            if (knownReferenceNos.contains(item.referenceNo)) {
              continue;
            }

            foundCount++;
            yield SlipScanProgress(
              scanned: scannedSoFar,
              total: scanTarget,
              foundCount: foundCount,
              newSlip: item,
            );
          }

          // Yield execution to keep the Flutter UI at 60/120 FPS
          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Emit batch progress milestone
        yield SlipScanProgress(
          scanned: scannedSoFar,
          total: scanTarget,
          foundCount: foundCount,
          newSlip: null,
        );
      }
    } finally {
      barcodeScanner.close();
      textRecognizer.close();
    }
  }

  /// Automatically scans recent gallery images on device without user manual picking
  Future<List<String>> scanDeviceGalleryImagePaths({int limit = 100}) async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth && !ps.hasAccess) {
        return [];
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isEmpty) return [];

      final AssetPathEntity recentAlbum = albums.first;
      final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
        start: 0,
        end: limit,
      );

      final List<String> paths = [];
      for (final asset in assets) {
        // Pre-filter: Bank slips are portrait or square (height >= width * 0.8)
        // Skip wide landscapes (scenery, wallpaper, camera landscapes)
        if (asset.width > asset.height * 1.25) {
          continue;
        }

        final file = await asset.file;
        if (file != null && await file.exists()) {
          paths.add(file.path);
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
  }) async {
    final file = File(path);
    if (!await file.exists()) return null;

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

      // Contextual bank text recognition
      if (fullText.toLowerCase().contains('truemoney') || fullText.contains('ทรูมันนี่')) {
        bankName = 'TrueMoney Wallet';
        bankColor = const Color(0xFFFA5A00);
      } else if (fullText.toLowerCase().contains('make') && fullText.toLowerCase().contains('kbank')) {
        bankName = 'MAKE by KBank';
        bankColor = const Color(0xFF00A9E0);
      } else if (fullText.contains('K PLUS') || fullText.contains('KBANK')) {
        bankName = 'K PLUS (กสิกรไทย)';
        bankColor = const Color(0xFF138F46);
      } else if (fullText.contains('SCB')) {
        bankName = 'SCB EASY (ไทยพาณิชย์)';
        bankColor = const Color(0xFF4E2A84);
      } else if (fullText.contains('Krungthai') || fullText.contains('กรุงไทย')) {
        bankName = 'Krungthai NEXT (กรุงไทย)';
        bankColor = const Color(0xFF00A3E0);
      } else if (fullText.contains('BAAC') || fullText.contains('ธ.ก.ส.')) {
        bankName = 'BAAC (ธ.ก.ส.)';
        bankColor = const Color(0xFF006633);
      }

      // Final Slip Validation:
      // Must either have genuine PromptPay Slip Mini-QR OR have clear amount + bank signature
      final bool hasBankSignature = fullText.contains('Transfer') ||
          fullText.contains('Successful') ||
          fullText.contains('PromptPay') ||
          fullText.contains('Ref') ||
          fullText.contains('โอนเงิน') ||
          fullText.contains('จ่ายเงิน');

      if (!isPromptPaySlipQR && !hasBankSignature) {
        return null; // Not a bank slip, filter out!
      }

      final finalAmount = amount ?? 0.0;
      if (finalAmount <= 0 && !isPromptPaySlipQR) {
        return null; // No amount found and not verified QR
      }

      final finalRef = refFromQR ??
          'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      return ExpenseCardItem(
        id: 'slip-${DateTime.now().millisecondsSinceEpoch}-${path.hashCode.abs() % 10000}',
        receiverName: receiver.isNotEmpty
            ? receiver
            : (note ?? 'รายการโอนเงิน ($bankName)'),
        amount: finalAmount > 0 ? finalAmount : 100.0, // fallback if QR verified
        dateTime: DateTime.now(),
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

  return parsedItems;
  }
}
