import 'package:flutter/material.dart';

/// A utility class to provide consistent bottom padding and SafeArea implementation
/// across all screens to prevent button visibility issues on devices with 
/// transparent bottom navigation bars or gesture areas.
class SafeScaffoldWrapper {
  
  /// Wraps the body content with SafeArea and proper bottom padding
  /// Usage: Replace your body with this wrapper
  static Widget wrapBody(BuildContext context, Widget child) {
    return SafeArea(
      bottom: true,
      child: child,
    );
  }

  /// Provides consistent bottom padding that accounts for system UI elements
  static EdgeInsets getBottomSafePadding(BuildContext context, {double extraPadding = 20.0}) {
    return EdgeInsets.fromLTRB(
      20.0,
      20.0,
      20.0,
      extraPadding + MediaQuery.of(context).viewPadding.bottom,
    );
  }

  /// Creates a SafeArea wrapped SingleChildScrollView with proper padding
  static Widget createSafeScrollView({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
    double extraBottomPadding = 20.0,
  }) {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        padding: padding ?? getBottomSafePadding(context, extraPadding: extraBottomPadding),
        child: child,
      ),
    );
  }

  /// Creates a SafeArea wrapped Column with proper padding
  static Widget createSafeColumn({
    required BuildContext context,
    required List<Widget> children,
    EdgeInsets? padding,
    double extraBottomPadding = 20.0,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  }) {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: padding ?? getBottomSafePadding(context, extraPadding: extraBottomPadding),
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: mainAxisAlignment,
          children: children,
        ),
      ),
    );
  }

  /// Wraps any widget with bottom-safe padding
  static Widget wrapWithBottomPadding(BuildContext context, Widget child, {double extraPadding = 20.0}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: extraPadding + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: child,
    );
  }

  /// For screens with complex Stack layouts
  static Widget wrapStackContent({
    required BuildContext context,
    required List<Widget> children,
    double extraBottomPadding = 20.0,
  }) {
    return SafeArea(
      bottom: true,
      child: Stack(
        children: children.map((child) {
          // Only add bottom padding to the last (topmost) widget in the stack
          if (children.indexOf(child) == children.length - 1) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: extraBottomPadding + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: child,
            );
          }
          return child;
        }).toList(),
      ),
    );
  }
}

/// Extension to make it easier to apply safe padding to any widget
extension SafePaddingExtension on Widget {
  /// Adds bottom safe padding to any widget
  Widget withBottomSafePadding(BuildContext context, {double extraPadding = 20.0}) {
    return SafeScaffoldWrapper.wrapWithBottomPadding(context, this, extraPadding: extraPadding);
  }

  /// Wraps widget with SafeArea
  Widget withSafeArea({bool bottom = true}) {
    return SafeArea(
      bottom: bottom,
      child: this,
    );
  }
}
