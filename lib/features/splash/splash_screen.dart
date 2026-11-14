import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/constants/app_brand.dart';
import '../../core/design_system/design_system.dart';
import '../../shared/widgets/widgets.dart';

/// Launch screen: the wordmark fades in, the flight trail is drawn with an
/// aircraft at its head, the aircraft becomes a star, the slogan appears,
/// and the app moves on to sign-in.
///
/// Timings follow the reference recording; see [SysflyMotion].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: SysflyMotion.splashTotal);
  late final Animation<double> _logo = CurvedAnimation(parent: _controller, curve: SysflyMotion.splashLogo);
  late final Animation<double> _arc = CurvedAnimation(parent: _controller, curve: SysflyMotion.splashArc);
  late final Animation<double> _flare = CurvedAnimation(parent: _controller, curve: SysflyMotion.splashFlare);
  late final Animation<double> _slogan = CurvedAnimation(parent: _controller, curve: SysflyMotion.splashSlogan);
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      // Reduce Motion: show the finished logo briefly, then continue.
      _controller.value = 0.7;
      _controller.animateTo(1, duration: const Duration(milliseconds: 900));
    } else {
      _controller.forward();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) context.go(Routes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final fontSize = (size.width * 0.168).clamp(54.0, 84.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SysflyColors.ink,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: SysflyGradients.splash),
          child: SizedBox.expand(
            child: Align(
              // The wordmark sits just above the middle of the screen.
              alignment: const Alignment(0, -0.115),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SysflyLogo(fontSize: fontSize, wordmark: _logo.value, arc: _arc.value, flare: _flare.value),
                    const SizedBox(height: 22),
                    Opacity(
                      opacity: _slogan.value,
                      child: TrText(
                        AppBrand.slogan,
                        style: SysflyTypography.caption.copyWith(color: const Color(0xB3FFFFFF), fontSize: 13, letterSpacing: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
