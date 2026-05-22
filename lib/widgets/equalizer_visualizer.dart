import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class EqualizerVisualizer extends StatefulWidget {
  const EqualizerVisualizer({
    super.key,
    required this.active,
    this.height = 88,
  });

  final bool active;
  final double height;

  @override
  State<EqualizerVisualizer> createState() => _EqualizerVisualizerState();
}

class _EqualizerVisualizerState extends State<EqualizerVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random(7);
  late final List<double> _phases;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _phases = List<double>.generate(18, (_) => _random.nextDouble() * pi);
  }

  @override
  void didUpdateWidget(EqualizerVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _phases.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FractionallySizedBox(
                      heightFactor: widget.active
                          ? 0.22 +
                                0.72 *
                                    (sin(
                                          (_controller.value * 2 * pi) +
                                              _phases[i],
                                        ).abs() *
                                        (0.55 + (i % 5) * 0.09))
                          : 0.18,
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: i.isEven ? AppTheme.cyan : AppTheme.magenta,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
