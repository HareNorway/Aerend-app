import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'models/campaign_order_pojo.dart';

/// Builds a branded A4 receipt PDF for a campaign matkasse order and opens the
/// system share sheet so the user can save or send it.
///
/// Important: the `pdf` package does **not** support alpha in [PdfColor].
/// Semi-transparent colors corrupt the graphics state (wrong fills / clips).
class CampaignOrderPdfExporter {
  CampaignOrderPdfExporter._();

  static Future<void> share(
    BuildContext context, {
    required CampaignMyOrder order,
    required String Function(CampaignMyOrder) statusLabel,
    required String Function(CampaignMyOrder) deliveryMethodLabel,
    required Map<String, String> labels,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    late final Rect origin;
    if (box != null && box.hasSize && box.size.width > 0) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    } else {
      final size = MediaQuery.sizeOf(context);
      final top = MediaQuery.paddingOf(context).top + 12;
      origin = Rect.fromLTWH(size.width / 2 - 1, top, 2, 2);
    }

    final bytes = await buildPdf(
      order: order,
      statusLabel: statusLabel(order),
      deliveryMethodLabel: deliveryMethodLabel(order),
      labels: labels,
    );

    final dir = await getTemporaryDirectory();
    final safeNo = order.orderNo.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final path = '${dir.path}/ordre_$safeNo.pdf';
    await File(path).writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf', name: 'ordre_$safeNo.pdf')],
      subject: '${labels['title']} #${order.orderNo}',
      sharePositionOrigin: origin,
    );
  }

  static Future<Uint8List> buildPdf({
    required CampaignMyOrder order,
    required String statusLabel,
    required String deliveryMethodLabel,
    required Map<String, String> labels,
  }) async {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final semi = await PdfGoogleFonts.notoSansSemiBold();

    final logoData = await rootBundle.load('assets/Logo/reen/mark-coral-navy.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());

    // Opaque only — matches ScSaasThemeTokens. Never pass alpha to PdfColor.
    const ink = PdfColor.fromInt(0xFF2D1B5B);
    const labelColor = PdfColor.fromInt(0xFF4B4458);
    const muted = PdfColor.fromInt(0xFF6B6578);
    const line = PdfColor.fromInt(0xFFD8D2E6);
    const pageBg = PdfColor.fromInt(0xFFF4F0FB);
    const cardBg = PdfColors.white;
    const purple = PdfColor.fromInt(0xFF7F5FC4);
    const purpleDeep = PdfColor.fromInt(0xFF2D1B5B);
    const purpleBand = PdfColor.fromInt(0xFF3D2A6E);
    const success = PdfColor.fromInt(0xFF1F8A5B);
    const successBg = PdfColor.fromInt(0xFFEAFAF0);
    const pillBg = PdfColor.fromInt(0xFFE8DEF5);

    String fmtDateTime(String? iso) {
      if (iso == null || iso.isEmpty) return '—';
      try {
        final dt = DateTime.parse(iso).toLocal();
        return DateFormat('d. MMM yyyy, HH:mm').format(dt);
      } catch (_) {
        return iso;
      }
    }

    String fmtDate(String? iso) {
      if (iso == null || iso.isEmpty) return '—';
      try {
        return DateFormat('d. MMM yyyy').format(DateTime.parse(iso).toLocal());
      } catch (_) {
        return iso;
      }
    }

    final amount = '${order.totalPay.round()} kr';
    final generated = DateFormat('d. MMM yyyy, HH:mm').format(DateTime.now());
    final campaign =
        order.campaignName ?? labels['matkasseFallback'] ?? 'Matkasse';
    final club = order.clubName ?? '—';
    final paid = order.paymentStatus == 1;

    pw.Widget sectionTitle(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          children: [
            pw.Container(width: 3, height: 12, color: purple),
            pw.SizedBox(width: 8),
            pw.Text(
              text.toUpperCase(),
              style: pw.TextStyle(
                font: bold,
                fontSize: 9,
                letterSpacing: 1.0,
                color: purpleDeep,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget kv(
      String label,
      String value, {
      bool last = false,
      bool emphasize = false,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 11),
        decoration: last
            ? null
            : const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: line, width: 0.8),
                ),
              ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 42,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  font: semi,
                  fontSize: 10.5,
                  color: labelColor,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              flex: 58,
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  font: emphasize ? bold : semi,
                  fontSize: emphasize ? 12 : 10.5,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget card(List<pw.Widget> children) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: pw.BoxDecoration(
          color: cardBg,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: line, width: 1),
        ),
        child: pw.Column(children: children),
      );
    }

    pw.Widget statusChip(String text, {required bool highlight}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: highlight ? successBg : pillBg,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: bold,
            fontSize: 9.5,
            color: highlight ? success : purpleDeep,
          ),
        ),
      );
    }

    final doc = pw.Document(
      title: '${labels['title']} #${order.orderNo}',
      author: 'Reen Dugnad',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(base: base, bold: bold),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header — solid opaque purple, no ClipRRect / no alpha.
              pw.Container(
                color: purpleDeep,
                padding: const pw.EdgeInsets.fromLTRB(32, 28, 32, 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Image(logo, width: 44, height: 44),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Reen Dugnad',
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 18,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                labels['title'] ?? 'Ordredetaljer',
                                style: pw.TextStyle(
                                  font: semi,
                                  fontSize: 11,
                                  color: const PdfColor.fromInt(0xFFD4C8F0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                (labels['amount'] ?? 'Beløp').toUpperCase(),
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 7.5,
                                  letterSpacing: 0.6,
                                  color: muted,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                amount,
                                style: pw.TextStyle(
                                  font: bold,
                                  fontSize: 17,
                                  color: purpleDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: pw.BoxDecoration(
                        color: purpleBand,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  campaign,
                                  style: pw.TextStyle(
                                    font: semi,
                                    fontSize: 12,
                                    color: PdfColors.white,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  club,
                                  style: pw.TextStyle(
                                    font: base,
                                    fontSize: 10,
                                    color: const PdfColor.fromInt(0xFFC9BBE8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Text(
                            '#${order.orderNo}',
                            style: pw.TextStyle(
                              font: semi,
                              fontSize: 9,
                              color: const PdfColor.fromInt(0xFFD4C8F0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        statusChip(statusLabel, highlight: false),
                        pw.SizedBox(width: 8),
                        statusChip(
                          order.paymentStatusLabel,
                          highlight: paid,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Body
              pw.Expanded(
                child: pw.Container(
                  color: pageBg,
                  padding: const pw.EdgeInsets.fromLTRB(32, 22, 32, 24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      sectionTitle(labels['orderNumber'] ?? 'Ordrenummer'),
                      card([
                        kv(
                          labels['orderNumber'] ?? 'Ordrenummer',
                          '#${order.orderNo}',
                        ),
                        kv(
                          labels['placedOn'] ?? 'Bestilt',
                          fmtDateTime(order.createdAt),
                        ),
                        kv(
                          labels['deliveryMethod'] ?? 'Leveringsmåte',
                          deliveryMethodLabel,
                        ),
                        kv(
                          labels['distributionDate'] ?? 'Distribusjonsdato',
                          fmtDate(order.distributionDate),
                        ),
                        kv(
                          labels['pickupLocation'] ?? 'Utleveringssted',
                          order.distributionLocation?.trim().isNotEmpty == true
                              ? order.distributionLocation!
                              : '—',
                          last: true,
                        ),
                      ]),
                      pw.SizedBox(height: 16),
                      sectionTitle(
                        labels['paymentStatus'] ?? 'Betalingsstatus',
                      ),
                      card([
                        kv(
                          labels['paymentStatus'] ?? 'Betalingsstatus',
                          order.paymentStatusLabel,
                        ),
                        kv(
                          labels['paymentMethod'] ?? 'Betalingsmåte',
                          (order.paymentProvider ?? '—').toUpperCase(),
                        ),
                        kv(
                          labels['amount'] ?? 'Beløp',
                          amount,
                          last: true,
                          emphasize: true,
                        ),
                      ]),
                      if (order.productSummary != null &&
                          order.productSummary!.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 16),
                        sectionTitle(labels['products'] ?? 'Produkter'),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: pw.BoxDecoration(
                            color: cardBg,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: line, width: 1),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Image(logo, width: 28, height: 28),
                              pw.SizedBox(width: 12),
                              pw.Expanded(
                                child: pw.Text(
                                  order.productSummary!,
                                  style: pw.TextStyle(
                                    font: semi,
                                    fontSize: 11.5,
                                    color: ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 18),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: pw.BoxDecoration(
                          color: purpleDeep,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              labels['amount'] ?? 'Beløp',
                              style: pw.TextStyle(
                                font: semi,
                                fontSize: 12,
                                color: const PdfColor.fromInt(0xFFD4C8F0),
                              ),
                            ),
                            pw.Text(
                              amount,
                              style: pw.TextStyle(
                                font: bold,
                                fontSize: 17,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Spacer(),
                      pw.Container(
                        padding: const pw.EdgeInsets.only(top: 12),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(color: line, width: 1),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              labels['pdfFooter'] ??
                                  'Generert fra Reen Dugnad-appen',
                              style: pw.TextStyle(
                                font: base,
                                fontSize: 8.5,
                                color: muted,
                              ),
                            ),
                            pw.Text(
                              generated,
                              style: pw.TextStyle(
                                font: base,
                                fontSize: 8.5,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
