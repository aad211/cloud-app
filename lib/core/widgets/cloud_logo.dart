import 'package:flutter/material.dart';
import 'package:cloud_app/app/theme/app_colors.dart';

enum CloudLogoSize {
  small,
  medium,
  large,
}

class CloudLogo extends StatelessWidget {
  const CloudLogo({
    super.key,
    this.size = CloudLogoSize.medium,
    this.iconColor,
    this.textColor,
  });

  final CloudLogoSize size;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final (iconSize, textSize, spacing) = switch (size) {
      CloudLogoSize.small => (24.0, 16.0, 4.0),
      CloudLogoSize.medium => (40.0, 28.0, 8.0),
      CloudLogoSize.large => (120.0, 56.0, 12.0),
    };

    final effectiveIconColor = iconColor ?? AppColors.navy;
    final effectiveTextColor = textColor ?? AppColors.navy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud,
          size: iconSize,
          color: effectiveIconColor,
        ),
        SizedBox(height: spacing),
        Text(
          'CLOUD',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w700,
            letterSpacing: size == CloudLogoSize.large ? 2 : 0,
            color: effectiveTextColor,
          ),
        ),
      ],
    );
  }
}
