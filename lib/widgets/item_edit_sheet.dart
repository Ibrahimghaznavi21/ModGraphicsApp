// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/item_model.dart';
import '../providers/item_provider.dart';

/// Bottom sheet for updating an item's Remaining amount.
///
/// Semantics reminder:
///   • Total     = quantity × price        (read-only)
///   • Discount  = from the saved item     (read-only)
///   • Remaining = what the customer still owes  (EDITABLE)
///   • Balance   = Total − Remaining − Discount  (derived, = amount paid)
///
/// Behaviour:
///   • Typing Remaining re-computes Balance live.
///   • Save validates, hits Supabase via [ItemProvider.updateItem], and
///     closes the sheet on success. A snackbar reports the outcome.
///   • Attempting to dismiss (system back, drag-down, backdrop tap) when
///     the form is dirty shows a Discard-changes confirmation dialog.
class ItemEditSheet extends StatefulWidget {
  const ItemEditSheet({super.key, required this.item});

  final ItemModel item;

  @override
  State<ItemEditSheet> createState() => _ItemEditSheetState();
}

class _ItemEditSheetState extends State<ItemEditSheet> {
  static final NumberFormat _money = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _remainingController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _remainingController = TextEditingController(
      text: _formatForInput(widget.item.remaining),
    );
    _remainingController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _remainingController.removeListener(_onChanged);
    _remainingController.dispose();
    super.dispose();
  }

  // ───────── helpers ─────────

  static String _formatForInput(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  static String _fmtQty(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  double get _total => widget.item.quantity * widget.item.price;
  double get _discount => widget.item.discount;

  /// Parsed current input. Falls back to the saved value while the user is
  /// mid-edit so derived fields stay meaningful when input is transiently
  /// invalid (e.g. empty during backspace).
  double get _remaining {
    final parsed = double.tryParse(_remainingController.text.trim());
    return parsed ?? widget.item.remaining;
  }

  double get _balance =>
      (_total - _remaining - _discount).clamp(0, double.infinity);

  bool get _isDirty {
    final parsed = double.tryParse(_remainingController.text.trim());
    if (parsed == null) return false;
    return (parsed - widget.item.remaining).abs() > 0.001;
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  // ───────── validation ─────────

  String? _validateRemaining(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Invalid';
    if (n < 0) return "Can't be negative";
    if (n > _total + 0.001) {
      return "Can't exceed ${_money.format(_total)}";
    }
    return null;
  }

  // ───────── dismiss flow ─────────

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Discard changes?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        content: const Text(
          'Your unsaved changes will be lost.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleCancel() async {
    if (_saving) return;
    final canClose = await _confirmDiscard();
    if (canClose && mounted) Navigator.pop(context);
  }

  // ───────── save ─────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // No-op when nothing changed — just close.
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    FocusScope.of(context).unfocus();

    try {
      final updated = widget.item.copyWith(
        remaining: _remaining,
        balance: _balance,
      );
      await context.read<ItemProvider>().updateItem(updated);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record updated.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ───────── build ─────────

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    // Block auto-pop whenever there are unsaved changes OR a save is
    // in flight. The onPopInvoked hook shows the discard dialog.
    final canPop = !_isDirty && !_saving;

    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_saving) return; // ignore dismiss attempts while saving
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && mounted) Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: r.keyboardInset),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: EdgeInsets.fromLTRB(r.pad(18), 8, r.pad(18), r.pad(20)),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3D1C7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  SizedBox(height: r.pad(14)),
                  Text(
                    widget.item.itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Qty ${_fmtQty(widget.item.quantity)} · '
                    '${_money.format(widget.item.price)} each',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: r.pad(20)),

                  // Remaining — the only editable field.
                  TextFormField(
                    controller: _remainingController,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      // Digits only + one optional decimal with up to 2
                      // places — negative signs are blocked at the
                      // input level.
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    validator: _validateRemaining,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Remaining amount',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      prefixText: 'Rs. ',
                      prefixStyle: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onFieldSubmitted: (_) => _save(),
                  ),

                  SizedBox(height: r.pad(14)),

                  _CalcBlock(
                    total: _total,
                    discount: _discount,
                    remaining: _remaining,
                    balance: _balance,
                  ),

                  SizedBox(height: r.pad(16)),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _handleCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: AppTheme.border,
                              width: 0.8,
                            ),
                            foregroundColor: AppTheme.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Update'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Calculation summary
// ══════════════════════════════════════════════════════════════════════

class _CalcBlock extends StatelessWidget {
  const _CalcBlock({
    required this.total,
    required this.discount,
    required this.remaining,
    required this.balance,
  });

  final double total;
  final double discount;
  final double remaining;
  final double balance;

  static final NumberFormat _fmt = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row('Total price', _fmt.format(total)),
          if (discount > 0) _row('Discount', '− ${_fmt.format(discount)}'),
          _row('Remaining', _fmt.format(remaining)),
          Container(
            height: 0.5,
            color: const Color(0xFFE5E2D9),
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          _row('Balance', _fmt.format(balance), isTotal: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13 : 12,
              color: isTotal ? AppTheme.textPrimary : const Color(0xFF5F5E5A),
              fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 13 : 12,
              fontWeight: FontWeight.w500,
              color: isTotal ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
