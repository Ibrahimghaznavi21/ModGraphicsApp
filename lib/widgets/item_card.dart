/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/item_model.dart';

/// Read-only card for a single item on the user detail screen.
///
/// Tapping opens the edit sheet (see [ItemEditSheet]) via [onTap].
///
/// Balance is computed live here (Total − Remaining − Discount, clamped
/// at 0) rather than trusting the stored value — that way any rows
/// persisted under the previous Balance semantics display correctly
/// under the new formula. Fresh saves write the new formula back.
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, this.onTap});

  final ItemModel item;
  final VoidCallback? onTap;

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  String _fmtQty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final total = item.quantity * item.price;
    final balance = (total - item.remaining - item.discount).clamp(
      0,
      double.infinity,
    );

    final subtitle = [
      'Qty ${_fmtQty(item.quantity)}',
      if ((item.quality ?? '').isNotEmpty) item.quality!,
    ].join(' · ');

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
              horizontal: r.pad(14),
              vertical: r.pad(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.itemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: r.pad(8)),
                    Text(
                      _money.format(total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.pad(8)),
                _row('Item Price', _money.format(item.price)),
                _row('Discount', '− ${_money.format(item.discount)}'),
                SizedBox(height: r.pad(4)),
                Container(height: 0.5, color: AppTheme.divider),
                SizedBox(height: r.pad(5)),
                _row(
                  'Remaining',
                  _money.format(item.remaining),
                  emphasize: true,
                ),
                _row('Balance', _money.format(balance)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: emphasize ? FontWeight.w500 : FontWeight.w400,
              color: emphasize ? AppTheme.danger : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/item_model.dart';

/// Read-only card for a single item on the user detail screen.
///
/// Tapping opens the edit sheet (see [ItemEditSheet]) via [onTap].
///
/// Balance is computed live here (Total − Remaining − Discount, clamped
/// at 0) rather than trusting the stored value — that way any rows
/// persisted under the previous Balance semantics display correctly
/// under the new formula. Fresh saves write the new formula back.
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, this.onTap});

  final ItemModel item;
  final VoidCallback? onTap;

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  /// Time-of-day formatter, e.g. "3:45 PM".
  static final DateFormat _timeFmt = DateFormat('h:mm a');

  /// Day + month for items created this year, e.g. "12 Apr".
  static final DateFormat _shortDateFmt = DateFormat('d MMM');

  /// Full date for items from prior years, e.g. "12 Apr 2025".
  static final DateFormat _fullDateFmt = DateFormat('d MMM yyyy');

  String _fmtQty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  /// Human-friendly timestamp, tiered by age:
  ///   • under 1 min        → "Just now"
  ///   • under 1 hour       → "Nm ago"        (e.g. "12m ago")
  ///   • same calendar day  → "Today, 3:45 PM"
  ///   • previous day       → "Yesterday, 3:45 PM"
  ///   • this calendar year → "12 Apr, 3:45 PM"
  ///   • older              → "12 Apr 2025, 3:45 PM"
  ///
  /// Supabase returns timestamptz values as UTC; [DateTime.toLocal] shifts
  /// them into the device's local time zone before formatting.
  static String _formatTimestamp(DateTime raw) {
    final local = raw.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inSeconds < 60 && !diff.isNegative) return 'Just now';
    if (diff.inMinutes < 60 && !diff.isNegative)
      return '${diff.inMinutes}m ago';

    final isSameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isSameDay) return 'Today, ${_timeFmt.format(local)}';

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (isYesterday) return 'Yesterday, ${_timeFmt.format(local)}';

    if (local.year == now.year) {
      return '${_shortDateFmt.format(local)}, ${_timeFmt.format(local)}';
    }
    return '${_fullDateFmt.format(local)}, ${_timeFmt.format(local)}';
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final total = item.quantity * item.price;
    final balance = (total - item.remaining - item.discount).clamp(
      0,
      double.infinity,
    );

    final subtitle = [
      'Qty ${_fmtQty(item.quantity)}',
      if ((item.quality ?? '').isNotEmpty) item.quality!,
    ].join(' · ');

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
              horizontal: r.pad(14),
              vertical: r.pad(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      _formatTimestamp(item.createdAt!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.itemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: r.pad(8)),
                    Text(
                      _money.format(total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.pad(8)),
                _row('Price', _money.format(item.price)),
                _row('Discount', '− ${_money.format(item.discount)}'),
                SizedBox(height: r.pad(4)),
                Container(height: 0.5, color: AppTheme.divider),
                SizedBox(height: r.pad(5)),
                _row(
                  'Remaining',
                  _money.format(item.remaining),
                  emphasize: true,
                ),
                _row('Balance', _money.format(balance)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: emphasize ? FontWeight.w500 : FontWeight.w400,
              color: emphasize ? AppTheme.danger : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
