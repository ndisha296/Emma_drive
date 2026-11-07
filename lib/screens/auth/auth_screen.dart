import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/emma_logo_widget.dart';
import '../participant/participant_home_screen.dart';
import '../manufacturer/manufacturer_dashboard_screen.dart';
import '../developer/developer_analytics_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.participant;
  XFile? _selectedProfileImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );
      if (image != null) {
        setState(() {
          _selectedProfileImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  void _showImagePickerSheet() {
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
                'Select Profile Photo',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGreen),
                title: Text('Take Photo with Camera', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accentOrange),
                title: Text('Choose from Gallery', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      if (_isSignUp) {
        await authNotifier.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          profileImageFile: _selectedProfileImage,
        );
      } else {
        await authNotifier.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      _navigateForRole(ref.read(currentUserProvider)?.role ?? _selectedRole);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginAsDemo(UserRole role) {
    ref.read(authNotifierProvider.notifier).loginAsDemo(role);
    _navigateForRole(role);
  }

  void _navigateForRole(UserRole role) {
    if (role == UserRole.manufacturer) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ManufacturerDashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ParticipantHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isKeyboardOpen) ...[
                  const Center(
                    child: EmmaLogoWidget(size: 100, showText: true, animate: false),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tab Switcher: Login vs Sign Up
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCardElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkCardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSignUp = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isSignUp ? AppTheme.primaryGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: !_isSignUp ? Colors.black : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSignUp = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isSignUp ? AppTheme.primaryGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Create Account',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: _isSignUp ? Colors.black : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_isSignUp) ...[
                  // Role Selector
                  Text(
                    'Select Your Account Type',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text('Participant', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          selected: _selectedRole == UserRole.participant,
                          selectedColor: AppTheme.primaryGreen,
                          backgroundColor: AppTheme.darkCardElevated,
                          labelStyle: TextStyle(
                            color: _selectedRole == UserRole.participant ? Colors.black : AppTheme.textLight,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedRole = UserRole.participant);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.factory_outlined, size: 18),
                              const SizedBox(width: 6),
                              Text('Manufacturer', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          selected: _selectedRole == UserRole.manufacturer,
                          selectedColor: AppTheme.accentOrange,
                          backgroundColor: AppTheme.darkCardElevated,
                          labelStyle: TextStyle(
                            color: _selectedRole == UserRole.manufacturer ? Colors.white : AppTheme.textLight,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedRole = UserRole.manufacturer);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Avatar Picker
                  Center(
                    child: GestureDetector(
                      onTap: _showImagePickerSheet,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: AppTheme.darkCardElevated,
                            child: _selectedProfileImage != null
                                ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 36)
                                : Icon(
                                    _selectedRole == UserRole.manufacturer
                                        ? Icons.business_rounded
                                        : Icons.person_rounded,
                                    size: 40,
                                    color: AppTheme.textMuted,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _selectedRole == UserRole.manufacturer ? 'Company / Plant Name' : 'Full Name',
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 14),

                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '+1 555-0199',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!v.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRole == UserRole.manufacturer && _isSignUp
                        ? AppTheme.accentOrange
                        : AppTheme.primaryGreen,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Text(
                          _isSignUp
                              ? 'Register as ${_selectedRole.displayName}'
                              : 'Sign In to Emma',
                          style: TextStyle(
                            color: _selectedRole == UserRole.manufacturer && _isSignUp
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                ),
                const SizedBox(height: 28),

                // Fast Demo Access Section
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.darkCardBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR TEST WITH DEMO PROFILES',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppTheme.darkCardBorder)),
                  ],
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: () => _loginAsDemo(UserRole.participant),
                  icon: const Icon(Icons.person_rounded, color: AppTheme.primaryGreen),
                  label: const Text('Instant Login as Participant (Jane Doe)'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _loginAsDemo(UserRole.manufacturer),
                  icon: const Icon(Icons.factory_rounded, color: AppTheme.accentOrange),
                  label: const Text('Instant Login as Manufacturer (Revive Tech)'),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeveloperAnalyticsScreen()),
                    );
                  },
                  icon: const Icon(Icons.dashboard_customize_rounded, size: 16, color: AppTheme.textMuted),
                  label: Text(
                    'Explore Developer Data & Analytics Hub',
                    style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
