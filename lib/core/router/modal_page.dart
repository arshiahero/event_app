import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModalPage extends Page<void> {
  const ModalPage({required this.child, super.key, super.name});
  final Widget child;
  @override
  Route<void> createRoute(BuildContext context) => RawDialogRoute<void>(
    settings: this,
    barrierDismissible: true,
    barrierLabel: 'Close reservation',
    barrierColor: AppColors.overlay,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, animation, secondaryAnimation) => child,
    transitionBuilder: (_, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, .12),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
  );
}
