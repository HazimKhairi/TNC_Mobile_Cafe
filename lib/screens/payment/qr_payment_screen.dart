import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/linen_background.dart';

/// Result returned by [QrPaymentScreen] when the receipt is uploaded.
class PaymentReceipt {
  final String url;
  final String type; // "image" or "pdf"
  const PaymentReceipt({required this.url, required this.type});
}

/// QR Payment screen — user scans QR, then uploads receipt for admin
/// verification. Returns a [PaymentReceipt] on success, null if cancelled.
class QrPaymentScreen extends StatefulWidget {
  final double amount;
  final String orderType;
  final int? tableNumber;

  const QrPaymentScreen({
    super.key,
    required this.amount,
    required this.orderType,
    this.tableNumber,
  });

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  static const int _expirySeconds = 300; // 5 minutes
  Timer? _timer;
  int _remaining = _expirySeconds;
  bool _uploading = false;

  File? _pickedFile;
  String? _pickedType; // "image" or "pdf"
  String? _pickedFileName;

  final _imagePicker = ImagePicker();
  final _cloudinary = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload Receipt',
                style: GoogleFonts.spectral(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how to attach your payment proof',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _SourceTile(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromImagePicker(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _SourceTile(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromImagePicker(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              _SourceTile(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Upload PDF',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPdf();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromImagePicker(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _pickedFile = File(picked.path);
        _pickedType = 'image';
        _pickedFileName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Could not pick image: $e', isError: true);
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.first;
      if (file.path == null) return;
      setState(() {
        _pickedFile = File(file.path!);
        _pickedType = 'pdf';
        _pickedFileName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Could not pick PDF: $e', isError: true);
    }
  }

  Future<void> _submitReceipt() async {
    if (_pickedFile == null || _pickedType == null) return;
    if (_uploading) return;

    setState(() => _uploading = true);

    try {
      final url = await _cloudinary.uploadReceipt(
        _pickedFile!,
        isPdf: _pickedType == 'pdf',
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        PaymentReceipt(url: url, type: _pickedType!),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _snack('Upload failed: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining == 0;
    final hasFile = _pickedFile != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LinenBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _uploading ? null : _cancel,
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textPrimary),
                    ),
                    Expanded(
                      child: Text(
                        'Scan & Upload Receipt',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spectral(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      // Amount card
                      _AmountCard(
                        amount: widget.amount,
                        timeLabel: _timeLabel,
                        expired: expired,
                      ),

                      const SizedBox(height: 20),

                      // QR card
                      _QrCard(expired: expired),

                      const SizedBox(height: 16),

                      // Step 2 — Upload receipt
                      _UploadCard(
                        pickedFileName: _pickedFileName,
                        pickedType: _pickedType,
                        pickedFile: _pickedFile,
                        onPick: expired || _uploading ? null : _showSourceSheet,
                        onClear: _uploading
                            ? null
                            : () => setState(() {
                                  _pickedFile = null;
                                  _pickedType = null;
                                  _pickedFileName = null;
                                }),
                      ),

                      const SizedBox(height: 16),

                      // Order info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.divider, width: 1),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Order Type',
                              value: widget.orderType == 'dine_in'
                                  ? 'Dine-in'
                                  : 'Takeaway',
                            ),
                            if (widget.orderType == 'dine_in' &&
                                widget.tableNumber != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Table',
                                value: '#${widget.tableNumber}',
                              ),
                            ],
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Merchant',
                              value: 'TNC Café',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (expired || _uploading || !hasFile)
                            ? null
                            : _submitReceipt,
                        icon: _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: Text(
                          _uploading
                              ? 'Uploading...'
                              : (hasFile
                                  ? 'Submit for Verification'
                                  : 'Upload Receipt to Continue'),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrand,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.divider,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _uploading ? null : _cancel,
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final double amount;
  final String timeLabel;
  final bool expired;
  const _AmountCard({
    required this.amount,
    required this.timeLabel,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Amount',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'RM${amount.toStringAsFixed(2)}',
            style: GoogleFonts.spectral(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBrand,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: expired
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: expired ? AppColors.error : AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  expired ? 'QR expired' : 'Expires in $timeLabel',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        expired ? AppColors.error : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final bool expired;
  const _QrCard({required this.expired});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Step 1 — Scan to Pay',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Open any banking app and scan the QR code',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: expired ? 0.3 : 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/qr_code.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: const [
              _MethodChip('DuitNow QR'),
              _MethodChip('TNG eWallet'),
              _MethodChip('GrabPay'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  const _MethodChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String? pickedFileName;
  final String? pickedType;
  final File? pickedFile;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  const _UploadCard({
    required this.pickedFileName,
    required this.pickedType,
    required this.pickedFile,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = pickedFile != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasFile
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.divider,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2 — Upload Receipt',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Attach your payment receipt (image or PDF) for admin verification',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (!hasFile)
            InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 36,
                      color: AppColors.textSecondary
                          .withValues(alpha: onPick == null ? 0.3 : 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to choose file',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Image or PDF',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _PickedFilePreview(
              file: pickedFile!,
              type: pickedType!,
              fileName: pickedFileName ?? 'receipt',
              onClear: onClear,
            ),
        ],
      ),
    );
  }
}

class _PickedFilePreview extends StatelessWidget {
  final File file;
  final String type;
  final String fileName;
  final VoidCallback? onClear;
  const _PickedFilePreview({
    required this.file,
    required this.type,
    required this.fileName,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = type == 'image';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: isImage
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.error.withValues(alpha: 0.08),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 32,
                        color: AppColors.error,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isImage ? 'Image' : 'PDF',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBrand),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
