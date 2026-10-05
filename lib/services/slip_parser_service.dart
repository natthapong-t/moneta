import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/expense_card_item.dart';

class ThaiBankInfo {
  final String name;
  final Color color;

  const ThaiBankInfo({required this.name, required this.color});
}

class SlipParserService {
  // Official Bank Identification Codes in Thailand (BOT / PromptPay EMVCo)
  static const Map<String, ThaiBankInfo> bankCodeMap = {
    '004': ThaiBankInfo(name: 'K PLUS', color: Color(0xFF138F46)),
    '014': ThaiBankInfo(name: 'SCB EASY', color: Color(0xFF4E2A84)),
    '006': ThaiBankInfo(name: 'Krungthai NEXT', color: Color(0xFF00A3E0)),
    '002': ThaiBankInfo(name: 'Bangkok Bank', color: Color(0xFF1E3A8A)),
    '011': ThaiBankInfo(name: 'ttb touch', color: Color(0xFF002D62)),
    '025': ThaiBankInfo(name: 'Krungsri (BAY)', color: Color(0xFFFECB00)),
    '034': ThaiBankInfo(name: 'BAAC (ธ.ก.ส.)', color: Color(0xFF006633)),
    '030': ThaiBankInfo(name: 'GSB (ออมสิน)', color: Color(0xFFEB198B)),
    '067': ThaiBankInfo(name: 'TISCO', color: Color(0xFF005DAA)),
    '069': ThaiBankInfo(name: 'Kiatnakin Phatra', color: Color(0xFF6B2C8B)),
    '073': ThaiBankInfo(name: 'LH Bank', color: Color(0xFF6D6E71)),
  };

  final _picker = ImagePicker();

  /// Prompt user to select multiple slips from their device gallery
  Future<List<String>> pickSlipImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      return pickedFiles.map((file) => file.path).toList();
    } catch (_) {
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

  /// Scan a list of image paths and return detected bank slips
  Future<List<ExpenseCardItem>> parseSlipImages(List<String> imagePaths) async {
    final List<ExpenseCardItem> parsedItems = [];

    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      for (final path in imagePaths) {
        final file = File(path);
        if (!await file.exists()) continue;

        final inputImage = InputImage.fromFilePath(path);

        // 1. Try QR code scanning first (Fastest & 100% accurate for amount & bank)
        final barcodes = await barcodeScanner.processImage(inputImage);
        ExpenseCardItem? itemFromQR;

        for (final barcode in barcodes) {
          final rawValue = barcode.rawValue;
          if (rawValue != null && (rawValue.startsWith('000201') || rawValue.contains('5408') || rawValue.contains('5303764'))) {
            final tlv = parseEMVCoTLV(rawValue);

            final bankCode = tlv['01'] ?? '';
            final refNo = tlv['02'] ?? 'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
            final amountStr = tlv['54'];
            final amount = amountStr != null ? double.tryParse(amountStr) : null;

            if (amount != null && amount > 0) {
              final bankInfo = bankCodeMap[bankCode] ??
                  const ThaiBankInfo(name: 'PromptPay', color: Color(0xFF003D79));

              itemFromQR = ExpenseCardItem(
                id: 'slip-qr-${DateTime.now().millisecondsSinceEpoch}-${parsedItems.length}',
                receiverName: 'รายการสลิป $refNo',
                amount: amount,
                dateTime: DateTime.now(),
                bankName: bankInfo.name,
                bankColor: bankInfo.color,
                referenceNo: refNo,
                note: 'ตรวจพบจาก QR สลิปอัตโนมัติ',
              );
              break;
            }
          }
        }

        // 2. Perform Text Recognition for Receiver Name or as fallback for Amount
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        final fullText = recognizedText.text;

        String receiverName = '';
        double? amountFromText;
        String detectedBank = '';
        Color detectedBankColor = const Color(0xFF003D79);

        // Look for Receiver Name
        final lines = fullText.split('\n').map((l) => l.trim()).toList();
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];

          // Check for receiver keyword
          if (line.contains('ไปยัง') || line.contains('ถึง') || line.contains('To') || line.contains('ผู้รับเงิน')) {
            if (i + 1 < lines.length && lines[i + 1].isNotEmpty) {
              receiverName = lines[i + 1];
            } else {
              receiverName = line.replaceAll(RegExp(r'(ไปยัง|ถึง|To|ผู้รับเงิน|:)'), '').trim();
            }
            break;
          }
        }

        // Check for Bank names in text
        if (fullText.contains('K PLUS') || fullText.contains('กสิกร')) {
          detectedBank = 'K PLUS';
          detectedBankColor = const Color(0xFF138F46);
        } else if (fullText.contains('SCB') || fullText.contains('ไทยพาณิชย์')) {
          detectedBank = 'SCB EASY';
          detectedBankColor = const Color(0xFF4E2A84);
        } else if (fullText.contains('Krungthai') || fullText.contains('กรุงไทย')) {
          detectedBank = 'Krungthai NEXT';
          detectedBankColor = const Color(0xFF00A3E0);
        } else if (fullText.contains('ttb') || fullText.contains('ทหารไทยธนชาต')) {
          detectedBank = 'ttb touch';
          detectedBankColor = const Color(0xFF002D62);
        } else if (fullText.contains('ธ.ก.ส.') || fullText.contains('BAAC')) {
          detectedBank = 'BAAC (ธ.ก.ส.)';
          detectedBankColor = const Color(0xFF006633);
        } else if (fullText.contains('TrueMoney')) {
          detectedBank = 'TrueMoney';
          detectedBankColor = const Color(0xFFFA5A00);
        }

        // Check for Amount in text if QR didn't find it
        if (itemFromQR == null) {
          final amountRegex = RegExp(r'(?:จำนวนเงิน|ยอดเงิน|THB|฿|Amount)\s*[:]?\s*([0-9,]+\.[0-9]{2})', caseSensitive: false);
          final match = amountRegex.firstMatch(fullText);
          if (match != null) {
            final cleanStr = match.group(1)?.replaceAll(',', '');
            if (cleanStr != null) {
              amountFromText = double.tryParse(cleanStr);
            }
          }
        }

        // Combine findings into final item
        if (itemFromQR != null) {
          parsedItems.add(
            itemFromQR.copyWith(
              assignedCategory: null,
            ),
          );
        } else if (amountFromText != null && amountFromText > 0) {
          parsedItems.add(
            ExpenseCardItem(
              id: 'slip-ocr-${DateTime.now().millisecondsSinceEpoch}-${parsedItems.length}',
              receiverName: receiverName.isNotEmpty ? receiverName : 'สลิปโอนเงิน',
              amount: amountFromText,
              dateTime: DateTime.now(),
              bankName: detectedBank.isNotEmpty ? detectedBank : 'สลิปธนาคาร',
              bankColor: detectedBankColor,
              referenceNo: 'OCR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              note: 'ตรวจพบจากข้อความในสลิป',
            ),
          );
        }
      }
    } finally {
      barcodeScanner.close();
      textRecognizer.close();
    }

    return parsedItems;
  }
}
