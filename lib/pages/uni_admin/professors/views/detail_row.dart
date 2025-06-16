import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ScaleConfig scaleConfig;
  final bool isMultiLine;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.scaleConfig,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: scaleConfig.scaleText(14),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: scaleConfig.scale(4)),
          Text(
            value,
            style: TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: scaleConfig.scaleText(14),
            ),
            overflow: isMultiLine ? null : TextOverflow.ellipsis,
            maxLines: isMultiLine ? null : 1,
          ),
        ],
      ),
    );
  }
}