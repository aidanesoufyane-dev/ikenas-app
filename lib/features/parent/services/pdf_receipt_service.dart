import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/models/models.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class PdfReceiptService {
  // ──────────────────────────────────────────────────────────
  // Color Palette
  // ──────────────────────────────────────────────────────────
  static const _blue      = PdfColor.fromInt(0xFF003366);
  static const _gold      = PdfColor.fromInt(0xFFD4AF37);
  static const _lightBlue = PdfColor.fromInt(0xFFD6E4F0);
  static const _textDark  = PdfColor.fromInt(0xFF1A1A2E);
  static const _highlight = PdfColor.fromInt(0xFFF0F5FA);

  // ──────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────
  static String _month(String m) {
    const map = {
      'january': 'Janvier',   'february': 'Février',   'march': 'Mars',
      'april': 'Avril',       'may': 'Mai',            'june': 'Juin',
      'july': 'Juillet',      'august': 'Août',        'september': 'Septembre',
      'october': 'Octobre',   'november': 'Novembre',  'december': 'Décembre',
    };
    return map[m.toLowerCase()] ?? m;
  }

  static String _date(String raw) {
    if (raw.isEmpty) return DateFormat('dd/MM/yyyy').format(DateTime.now());
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw).toLocal());
    } catch (_) { return raw; }
  }

  // ──────────────────────────────────────────────────────────
  // Main entry point
  // ──────────────────────────────────────────────────────────
  static Future<List<int>> generateReceipt(PaymentModel payment) async {
    final fontBase = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontBase, bold: fontBold),
    );
    final bytes = await rootBundle.load('assets/images/image3.png');
    final logo = pw.MemoryImage(bytes.buffer.asUint8List());

    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final payDate = _date(payment.date);
    final receiptNo = payment.invoiceNumber ?? 'REC-${payment.id.substring(0, 8).toUpperCase()}';
    final typeLabel = payment.paymentType == PaymentType.scolarity ? 'Scolarité' : 'Transport';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.only(left: 45, top: 40, right: 38, bottom: 40),
          buildBackground: (ctx) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Stack(
                children: [
                  // Watermark
                  pw.Center(
                    child: pw.Opacity(
                      opacity: 0.05,
                      child: pw.Image(logo, width: 400, height: 400),
                    ),
                  ),
                  
                  // Top-Left Gold Curve
                  pw.Positioned(
                    top: 0, left: 0,
                    child: pw.SizedBox(
                      width: 220, height: 220,
                      child: pw.CustomPaint(painter: (g, s) {
                        g..moveTo(s.x, s.y) // Top-Right of curve box
                         ..curveTo(s.x * 0.5, s.y, 0, s.y * 0.5, 0, 0) // Curve down to Bottom-Left
                         ..lineTo(0, s.y) // Line up to Top-Left
                         ..closePath() // Close to Top-Right
                         ..setFillColor(_gold)
                         ..fillPath();
                      }),
                    ),
                  ),

                  // Top-Left Blue Curve
                  pw.Positioned(
                    top: 0, left: 0,
                    child: pw.SizedBox(
                      width: 150, height: 150,
                      child: pw.CustomPaint(painter: (g, s) {
                        g..moveTo(s.x, s.y)
                         ..curveTo(s.x * 0.5, s.y, 0, s.y * 0.5, 0, 0)
                         ..lineTo(0, s.y)
                         ..closePath()
                         ..setFillColor(_blue)
                         ..fillPath();
                      }),
                    ),
                  ),

                  // Bottom Gold Wave
                  pw.Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: pw.SizedBox(
                      height: 100,
                      child: pw.CustomPaint(painter: (g, s) {
                        g..moveTo(0, s.y) // Top-Left of this box
                         ..curveTo(s.x * 0.3, s.y * 0.2, s.x * 0.7, s.y * 0.2, s.x, s.y * 0.8) // Dip down
                         ..lineTo(s.x, 0) // down to Bottom-Right
                         ..lineTo(0, 0) // left to Bottom-Left
                         ..closePath() // Back to Top-Left
                         ..setFillColor(_gold)
                         ..fillPath();
                      }),
                    ),
                  ),

                  // Bottom Blue Wave
                  pw.Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: pw.SizedBox(
                      height: 80,
                      child: pw.CustomPaint(painter: (g, s) {
                        g..moveTo(0, s.y) // Top-left of this box
                         ..curveTo(s.x * 0.1, s.y * 0.7, s.x * 0.4, s.y * 0.2, s.x * 0.6, 0) // Sweep right-down
                         ..lineTo(0, 0) // Left to Bottom-Left
                         ..closePath() // Back to Top-Left
                         ..setFillColor(_blue)
                         ..fillPath();
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        build: (ctx) => [
          // Header Text (aligned right)
          pw.Row(
             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
             crossAxisAlignment: pw.CrossAxisAlignment.start,
             children: [
               pw.SizedBox(width: 80), // spacer for top left curve
               pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.end,
                 children: [
                   pw.Text('DATE : $today', style: pw.TextStyle(color: _blue, fontSize: 10, letterSpacing: 0.5)),
                   pw.SizedBox(height: 2),
                   pw.Text('REÇU N° : $receiptNo', style: pw.TextStyle(color: _blue, fontSize: 10, letterSpacing: 0.5)),
                 ],
               ),
             ]
          ),

          pw.SizedBox(height: 45), // Clear curves

          // Title Area
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('IKENAS EDUCATION MANAGEMENT', 
                  style: pw.TextStyle(fontSize: 16, color: _blue, letterSpacing: 1)),
                pw.SizedBox(height: 2),
                pw.Text('REÇU DE PAIEMENT', 
                  style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: _gold, letterSpacing: 1.5)),
              ],
            ),
          ),

          pw.SizedBox(height: 35),

          // Section 1 : Details
          pw.Text('DÉTAILS DE L\'ÉLÈVE', 
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _gold, letterSpacing: 0.5)),
          pw.SizedBox(height: 12),
          _formRow('Nom Complet', payment.studentName?.isNotEmpty == true ? payment.studentName! : '—'),
          _formRow('Classe', payment.className?.isNotEmpty == true ? payment.className! : '—'),

          pw.SizedBox(height: 30),

          // Section 2 : Payment
          pw.Text('INFORMATION DU PAIEMENT', 
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _gold, letterSpacing: 0.5)),
          pw.SizedBox(height: 12),
          _formRow('Type de Paiement', typeLabel),
          _formRow('Mois', _month(payment.month)),
          _formRow('Méthode de Paiement', payment.paymentMethod?.isNotEmpty == true ? payment.paymentMethod! : 'Espèces'),
          _formRow('Date de Paiement', payDate),
          
          pw.SizedBox(height: 12),
          
          _formRow('Montant Total', '${payment.amount.toStringAsFixed(2)} DH', isTotal: true),

          pw.SizedBox(height: 60),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _signatureLine('DATE'),
              _signatureLine('SIGNATURE D\'ADMINISTRATION'),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ──────────────────────────────────────────────────────────
  // Form Row
  // ──────────────────────────────────────────────────────────
  static pw.Widget _formRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 11, color: _blue)),
          ),
          pw.Text(':', style: pw.TextStyle(fontSize: 11, color: _blue)),
          pw.SizedBox(width: 15),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _lightBlue, width: 1.2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                color: isTotal ? _highlight : null,
              ),
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: isTotal ? 14 : 11,
                  fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: isTotal ? _gold : _textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Signature Line
  // ──────────────────────────────────────────────────────────
  static pw.Widget _signatureLine(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 160,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _blue, width: 1)),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(label, 
          style: pw.TextStyle(fontSize: 10, color: _blue, letterSpacing: 0.5)),
      ],
    );
  }
}
