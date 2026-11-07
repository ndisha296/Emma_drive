import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drive_provider.dart';
import 'submission_success_screen.dart';

class ParticipantRegistrationDialog extends ConsumerStatefulWidget {
  final String driveId;

  const ParticipantRegistrationDialog({
    super.key,
    required this.driveId,
  });

  @override
  ConsumerState<ParticipantRegistrationDialog> createState() =>
      _ParticipantRegistrationDialogState();
}

class _ParticipantRegistrationDialogState
    extends ConsumerState<ParticipantRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'Laptops & PCs';
  final List<String> _categories = [
    'Laptops & PCs',
    'Smartphones & Tablets',
    'Small Appliances',
    'Monitors & TVs',
    'Lithium Batteries',
    'Cables & Circuit Boards',
  ];

  XFile? _capturedImage;
  bool _isSubmitting = false;
  String? _uploadStatusText;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 60,
      );
      if (photo != null) {
        setState(() {
          _capturedImage = photo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  void _showCaptureSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Photograph Recyclable Item',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a clear picture of the device or waste item you are bringing to the drive.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGreen),
                title: Text('Camera (Snap Photo)', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accentOrange),
                title: Text('Gallery (Upload Image)', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take or upload a photo of your recyclable item.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadStatusText = 'Uploading item photo to storage...';
    });

    try {
      final user = ref.read(currentUserProvider);
      final notifier = ref.read(driveOperationsProvider.notifier);

      final submission = await notifier.submitRegistration(
        driveId: widget.driveId,
        participantUid: user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
        participantName: _nameController.text.trim(),
        participantEmail: _emailController.text.trim(),
        participantPhone: _phoneController.text.trim(),
        category: _selectedCategory,
        notes: _notesController.text.trim(),
        imageFile: _capturedImage!,
      );

      if (!mounted) return;

      // Close the modal dialog
      Navigator.of(context).pop();

      // Navigate to dedicated submission success screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SubmissionSuccessScreen(submission: submission),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.darkCardBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.recycling_rounded, color: AppTheme.primaryGreen, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Register for Drive',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              Text(
                                'Drive ID: ${widget.driveId}',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppTheme.darkCardBorder, height: 1),
                  const SizedBox(height: 18),

                  // Pre-filled Email & Phone
                  Text(
                    'Participant Details (Pre-filled)',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Item Category
                  Text(
                    'Material Category',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    dropdownColor: AppTheme.darkCardElevated,
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Item Description / Condition (Optional)',
                      hintText: 'e.g. 2 laptop bodies, no battery, broken screen',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Photo Submission Section
                  Text(
                    'Item Photograph (Required)',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),

                  if (_capturedImage == null)
                    InkWell(
                      onTap: _showCaptureSourcePicker,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: AppTheme.darkCardElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryGreen, size: 28),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to Capture or Upload Photo',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enables manufacturer inspection before drop-off',
                              style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
                            color: AppTheme.darkCardElevated,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Photo Captured: ${_capturedImage!.name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ready for verification upload',
                                    style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: _showCaptureSourcePicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Retake',
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  if (_isSubmitting) ...[
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primaryGreen),
                          const SizedBox(height: 12),
                          Text(
                            _uploadStatusText ?? 'Submitting registration...',
                            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _submitRegistration,
                      icon: const Icon(Icons.send_rounded, color: Colors.black),
                      label: const Text('Submit Drive Registration'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
