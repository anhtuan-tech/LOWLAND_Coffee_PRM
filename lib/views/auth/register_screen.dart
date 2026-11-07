import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Màn hình Đăng ký tài khoản LOWLAND Coffee
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitRegister() async {
    final authVM = context.read<AuthViewModel>();
    authVM.clearError();

    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu nhập lại không trùng khớp!')),
        );
        return;
      }

      final success = await authVM.register(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký tài khoản LOWLAND Coffee thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 75,
                      height: 75,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Tạo tài khoản mới',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Trở thành thành viên để tích điểm và nhận nhiều ưu đãi độc quyền',
                    style: AppTextStyles.subtitleMuted,
                  ),
                  const SizedBox(height: 24),

                  // Lỗi nếu có
                  if (authVM.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        authVM.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Họ và tên
                  CustomTextField(
                    controller: _nameController,
                    label: 'Họ và tên',
                    hint: 'Ví dụ: Nguyễn Văn A',
                    prefixIcon: Icons.person_outline,
                    validator: authVM.validateDisplayName,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'nhapemail@gmail.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: authVM.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Mật khẩu
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    hint: 'Tối thiểu 6 ký tự',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !authVM.isPasswordVisible,
                    validator: authVM.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        authVM.isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: authVM.togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nhập lại mật khẩu
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Xác nhận mật khẩu',
                    hint: 'Nhập lại mật khẩu trên',
                    prefixIcon: Icons.lock_reset_rounded,
                    obscureText: !authVM.isConfirmPasswordVisible,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu.';
                      }
                      if (val != _passwordController.text) {
                        return 'Mật khẩu xác nhận không trùng khớp.';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        authVM.isConfirmPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: authVM.toggleConfirmPasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Nút Đăng ký
                  CustomButton(
                    text: 'Tạo tài khoản',
                    isLoading: authVM.isLoading,
                    onPressed: _submitRegister,
                  ),
                  const SizedBox(height: 20),

                  // Đã có tài khoản
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          authVM.clearError();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

