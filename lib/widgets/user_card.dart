import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/user_model.dart';

/// A tappable row representing a single user on the home screen.
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    this.colorIndex = 0,
    this.onTap,
  });

  final UserModel user;
  final int colorIndex;
  final VoidCallback? onTap;

  /// (background, foreground) pairs for the avatar chip.
  static const List<List<Color>> _palettes = [
    [Color(0xFFEEEDFE), Color(0xFF3C3489)], // purple
    [Color(0xFFE1F5EE), Color(0xFF0F6E56)], // teal
    [Color(0xFFFAECE7), Color(0xFF993C1D)], // coral
    [Color(0xFFE6F1FB), Color(0xFF0C447C)], // blue
    [Color(0xFFFBEAF0), Color(0xFF72243E)], // pink
  ];

  @override
  Widget build(BuildContext context) {
    final p = _palettes[colorIndex % _palettes.length];
    final r = context.responsive;
    final avatar = r.pad(40);

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.pad(12),
              vertical: r.pad(10),
            ),
            child: Row(
              children: [
                Container(
                  width: avatar,
                  height: avatar,
                  decoration: BoxDecoration(
                    color: p[0],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: p[1],
                    ),
                  ),
                ),
                SizedBox(width: r.pad(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.phoneNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
