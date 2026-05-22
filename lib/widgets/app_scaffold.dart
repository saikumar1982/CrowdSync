import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.bottom,
    this.leading,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? bottom;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(title), leading: leading, actions: actions),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF05070D), Color(0xFF0B1020), Color(0xFF07080D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: child,
                ),
              ),
              if (bottom != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.bg.withValues(alpha: 0.92),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: SafeArea(top: false, child: bottom!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
