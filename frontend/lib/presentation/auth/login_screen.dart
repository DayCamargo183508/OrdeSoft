import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/theme/app_theme.dart';
import '../admin/admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final AuthRepository _authRepository = AuthRepository();
  String _pin = '';
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _onKeyPress('DEL');
      } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (_pin.length == 4 && !_isLoading) _login();
      } else {
        String? digit;
        if (event.character != null && RegExp(r'^[0-9]$').hasMatch(event.character!)) {
          digit = event.character;
        } else if (event.logicalKey == LogicalKeyboardKey.numpad0 || event.logicalKey == LogicalKeyboardKey.digit0) digit = '0';
        else if (event.logicalKey == LogicalKeyboardKey.numpad1 || event.logicalKey == LogicalKeyboardKey.digit1) digit = '1';
        else if (event.logicalKey == LogicalKeyboardKey.numpad2 || event.logicalKey == LogicalKeyboardKey.digit2) digit = '2';
        else if (event.logicalKey == LogicalKeyboardKey.numpad3 || event.logicalKey == LogicalKeyboardKey.digit3) digit = '3';
        else if (event.logicalKey == LogicalKeyboardKey.numpad4 || event.logicalKey == LogicalKeyboardKey.digit4) digit = '4';
        else if (event.logicalKey == LogicalKeyboardKey.numpad5 || event.logicalKey == LogicalKeyboardKey.digit5) digit = '5';
        else if (event.logicalKey == LogicalKeyboardKey.numpad6 || event.logicalKey == LogicalKeyboardKey.digit6) digit = '6';
        else if (event.logicalKey == LogicalKeyboardKey.numpad7 || event.logicalKey == LogicalKeyboardKey.digit7) digit = '7';
        else if (event.logicalKey == LogicalKeyboardKey.numpad8 || event.logicalKey == LogicalKeyboardKey.digit8) digit = '8';
        else if (event.logicalKey == LogicalKeyboardKey.numpad9 || event.logicalKey == LogicalKeyboardKey.digit9) digit = '9';
        
        if (digit != null) _onKeyPress(digit);
      }
    }
  }

  void _onKeyPress(String value) {
    if (_isLoading) return;
    setState(() {
      if (value == 'C') {
        _pin = '';
      } else if (value == 'DEL') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_pin.length < 4) _pin += value;
      }
    });
    if (_pin.length == 4) _login();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final usuario = await _authRepository.login(_pin);
      if (mounted) {
        if (usuario.rol == 'admin') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminScreen()));
        } else {
          Navigator.of(context).pushReplacementNamed('/mesas');
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bienvenido, ${usuario.nombre}')));
      }
    } catch (e) {
      if (mounted) {
        setState(() { _pin = ''; _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Widget _buildNumpadButton(String label, {IconData? icon}) {
    final isClear = label == 'C';
    return GestureDetector(
      onTap: () => _onKeyPress(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 76, height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isClear ? AppColors.error.withOpacity(0.15) : AppColors.overlayLight,
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 26, color: Colors.white.withOpacity(0.9))
                  : Text(label, style: AppTextStyles.numpad.copyWith(
                      color: isClear ? AppColors.error.withOpacity(0.9) : Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDot(bool isFilled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: isFilled ? 18 : 16, height: isFilled ? 18 : 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? AppColors.accent : Colors.transparent,
        border: Border.all(color: isFilled ? AppColors.accent : Colors.white.withOpacity(0.5), width: 2),
        boxShadow: isFilled ? [BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : [],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map(_buildNumpadButton).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.translucent,
        child: RawKeyboardListener(
          focusNode: _focusNode,
          onKey: _onKeyEvent,
          autofocus: true,
          child: Stack(
            children: [
          Container(
            width: size.width, height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(top: -80, right: -60,
            child: Container(width: 280, height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withOpacity(0.08)))),
          Positioned(bottom: -100, left: -80,
            child: Container(width: 320, height: 320,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryLight.withOpacity(0.3)))),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, AppColors.accent],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text('OrderSoft', style: AppTextStyles.displayLarge),
                    ),
                    const SizedBox(height: 8),
                    Text('Sistema de Punto de Venta',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withOpacity(0.55), letterSpacing: 1.2)),
                    const Spacer(flex: 2),
                    Text('Ingresa tu codigo de acceso',
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.white.withOpacity(0.7), letterSpacing: 0.5)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) => _buildPinDot(i < _pin.length)),
                    ),
                    const SizedBox(height: 28),
                    if (_isLoading)
                      const SpinKitThreeBounce(color: AppColors.accent, size: 28)
                    else
                      const SizedBox(height: 28),
                    const Spacer(flex: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          _buildRow(['1', '2', '3']),
                          const SizedBox(height: 18),
                          _buildRow(['4', '5', '6']),
                          const SizedBox(height: 18),
                          _buildRow(['7', '8', '9']),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildNumpadButton('C'),
                              _buildNumpadButton('0'),
                              _buildNumpadButton('DEL', icon: Icons.backspace_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  );
}
}
