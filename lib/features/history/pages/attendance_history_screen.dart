import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../shared/components/kmfri_navigation_drawer.dart';
import '../../authentication/model/mobile_user.dart';
import '../../authentication/service/mobile_api_service.dart';
import '../../clocking/model/attendance_history_record.dart';
import '../../clocking/repository/mobile_clocking_repository.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  final MobileUser user;
  final VoidCallback onSignOut;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  late final MobileClockingRepository _repository;
  List<AttendanceHistoryRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = MobileClockingRepository(MobileApiService());
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<AttendanceHistoryRecord> records;
      try {
        records = await _repository.refreshAttendanceHistory(widget.user.id);
      } catch (_) {
        records = await _repository.loadAttendanceHistory(widget.user.id);
      }
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load attendance history: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      pw.MemoryImage? kmfriImage;
      pw.MemoryImage? govImage;
      try {
        final kmfriLogoBytes =
            await rootBundle.load('assets/images/kmfri_logo.png');
        kmfriImage = pw.MemoryImage(kmfriLogoBytes.buffer.asUint8List());
      } catch (_) {}

      try {
        final govLogoBytes = await rootBundle.load('assets/images/gov_logo.png');
        govImage = pw.MemoryImage(govLogoBytes.buffer.asUint8List());
      } catch (_) {}

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    if (kmfriImage != null)
                      pw.Image(kmfriImage, width: 110, height: 38),
                    if (kmfriImage != null && govImage != null)
                      pw.SizedBox(width: 10),
                    if (govImage != null)
                      pw.Image(govImage, width: 28, height: 38),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'KMFRI Attendance Report',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Generated: ${_formatDate(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.grey400, thickness: 1),
            pw.SizedBox(height: 14),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Employee: ${widget.user.name}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Email: ${widget.user.email}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Station: ${widget.user.station.isEmpty ? 'KMFRI' : widget.user.station}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data:
                        'https://clocking.kmfri.go.ke/verify?userId=${widget.user.id}&email=${widget.user.email}',
                    width: 50,
                    height: 50,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Clock In', 'Clock Out', 'Status'],
              data: _records
                  .map(
                    (record) => [
                      _formatDate(record.date),
                      record.clockInLabel,
                      record.clockOutLabel,
                      record.missedClockOut ? 'Missed Out' : 'Present',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
              ),
              cellHeight: 26,
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'kmfri_attendance_report_${widget.user.id}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[local.month - 1];
    final year = local.year;
    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A3D62),
        foregroundColor: Colors.white,
        title: const Text(
          'Attendance History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Download PDF Report',
            onPressed: _records.isEmpty ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'Refresh history',
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: KmfriNavigationDrawer(
        user: widget.user,
        onSignOut: widget.onSignOut,
        currentIndex: 1,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF005B96)),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Color(0xFFB42318),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFB42318)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHistory,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                ),
              )
            : _records.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF3FA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          size: 40,
                          color: Color(0xFF005B96),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Attendance Records',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A3D62),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your historical attendance records will appear here.',
                        style: TextStyle(color: Color(0xFF667085)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final record = _records[index];
                  return _historyCard(record);
                },
              ),
      ),
    );
  }

  Widget _historyCard(AttendanceHistoryRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF005B96),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.date),
                  style: const TextStyle(
                    color: Color(0xFF0A3D62),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'In: ${record.clockInLabel}  •  Out: ${record.clockOutLabel}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: record.missedClockOut
                  ? const Color(0xFFFFF4E5)
                  : const Color(0xFFE8F6F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.missedClockOut ? 'MISSED OUT' : 'PRESENT',
              style: TextStyle(
                color: record.missedClockOut
                    ? const Color(0xFF8A5700)
                    : const Color(0xFF16856B),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
