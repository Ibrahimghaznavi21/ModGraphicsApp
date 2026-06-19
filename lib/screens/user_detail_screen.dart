import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../providers/item_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/item_edit_sheet.dart';

/// Shows a customer's header, total-and-balance summary, and every item
/// they've been charged for.
class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  static final NumberFormat _fmt = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ItemProvider>().loadItems(widget.user.id);
    });
  }

  Future<void> _openEditSheet(ItemModel item) async {
    final r = context.responsive;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: r.sheetMaxWidth),
      // Normal dismiss is allowed; the sheet itself intercepts via PopScope
      // and asks for confirmation only when there are unsaved changes.
      builder: (_) => ItemEditSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.user.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              widget.user.phoneNumber,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<ItemProvider>(
        builder: (context, provider, _) {
          final items = provider.itemsFor(widget.user.id);
          final loading = provider.isLoadingFor(widget.user.id);
          final total = provider.totalFor(widget.user.id);
          final balance = provider.balanceFor(widget.user.id);

          if (loading && items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (provider.error != null && items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: AppTheme.danger,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => provider.loadItems(widget.user.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final r = context.responsive;
          final edge = r.edgePad;

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => provider.loadItems(widget.user.id),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(edge, 4, edge, r.pad(24)),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Stat(label: 'Total', value: _fmt.format(total)),
                    ),
                    SizedBox(width: r.pad(10)),
                    Expanded(
                      child: _Stat(
                        label: 'Balance',
                        value: _fmt.format(balance),
                        highlight: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.pad(16)),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: AppTheme.textMuted,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No items yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: r.pad(8)),
                      child: ItemCard(
                        item: item,
                        onTap: () => _openEditSheet(item),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: highlight ? AppTheme.danger : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
