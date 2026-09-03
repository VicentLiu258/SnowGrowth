import 'package:flutter/material.dart';

/// Scrollable page body that always starts from the top, even when content
/// is shorter than the viewport.
class TopAlignedBody extends StatelessWidget {
  const TopAlignedBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 100),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: padding,
        child: SizedBox(
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}

class TopAlignedLoading extends StatelessWidget {
  const TopAlignedLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
