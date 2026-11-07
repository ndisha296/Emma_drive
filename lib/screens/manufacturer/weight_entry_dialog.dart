import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../models/drive_submission_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/drive_provider.dart';
import '../../widgets/item_image_viewer.dart';

class WeightEntryDialog extends ConsumerStatefulWidget {
  final DriveSubmissionModel submission;

  const WeightEntryDialog({
    super.key,
    required this.submission,
  });

  @override
  ConsumerState<WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends ConsumerState<WeightEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  bool _isLbs = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentWeight = widget.submission.weightKg;
    _weightController = TextEditingController(
      text: currentWeight != null ? currentWeight.toStringAsFixed(1) : '',
    );
    _notesController = TextEditingController(text: widget.submission.notes);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveWeight() async {
    if (!_formKey.currentState!.validate()) return;

    final rawVal = double.tryParse(_weightController.text.trim());
    if (rawVal == null || rawVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive weight measurement.')),
      );
      return;
    }

    // Convert lbs to kg if user entered in lbs
    final double weightKg = _isLbs ? (rawVal * 0.45359237) : rawVal;

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      final verifiedBy = user?.name ?? 'Authorized Manufacturer';

      await ref.read(driveOperationsProvider.notifier).verifyWeight(
            submissionId: widget.submission.submissionId,
            weightKg: double.parse(weightKg.toStringAsFixed(2)),
            verifiedBy: verifiedBy,
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weight verified successfully: ${weightKg.toStringAsFixed(2)} kg logged!',
          ),
          backgroundColor: AppTheme.statusVerified,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update weight: $e')),
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
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
                              color: AppTheme.accentOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.scale_rounded, color: AppTheme.accentOrange, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weight Inspection & Log',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              Text(
                                'Participant: ${widget.submission.participantName}',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppTheme.darkCardBorder, height: 1),
                  const SizedBox(height: 16),

                  // Submitted Item Inspection Photo Preview
                  Text(
                    'Item Photo Inspection',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: ItemImageViewer(
                        imageUrl: widget.submission.itemImageUrl,
                        height: 150,
                        title: '${widget.submission.category} - ${widget.submission.participantName}',
                        enableLightbox: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category: ${widget.submission.category}',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                      ),
                      Text(
                        'Tap photo to zoom',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Unit Selector & Weight Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Measured Weight',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('KG'),
                            selected: !_isLbs,
                            selectedColor: AppTheme.primaryGreen,
                            backgroundColor: AppTheme.darkCardElevated,
                            labelStyle: TextStyle(
                              color: !_isLbs ? Colors.black : AppTheme.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected && _isLbs) {
                                final current = double.tryParse(_weightController.text);
                                if (current != null) {
                                  _weightController.text = (current * 0.453592).toStringAsFixed(1);
                                }
                                setState(() => _isLbs = false);
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('LBS'),
                            selected: _isLbs,
                            selectedColor: AppTheme.accentOrange,
                            backgroundColor: AppTheme.darkCardElevated,
                            labelStyle: TextStyle(
                              color: _isLbs ? Colors.white : AppTheme.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected && !_isLbs) {
                                final current = double.tryParse(_weightController.text);
                                if (current != null) {
                                  _weightController.text = (current * 2.20462).toStringAsFixed(1);
                                }
                                setState(() => _isLbs = true);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _weightController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.fitness_center_rounded),
                      suffixText: _isLbs ? 'lbs' : 'kg',
                      suffixStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      hintText: '0.0',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter measured weight';
                      if (double.tryParse(v.trim()) == null) return 'Enter a numeric weight';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Inspection Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Verification Notes',
                      hintText: 'e.g. Verified copper motor coils, intact casing',
                      prefixIcon: Icon(Icons.fact_check_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveWeight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.check_circle_rounded, color: Colors.black),
                    label: Text(
                      _isSaving ? 'Logging Verified Weight...' : 'Save & Verify Weight',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
