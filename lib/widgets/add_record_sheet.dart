// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../providers/item_provider.dart';
import '../providers/user_provider.dart';

/// Bottom sheet for creating a new item record.
///
/// The Name field is a searchable autocomplete:
///   • Typing filters existing users by name or phone.
///   • Picking a suggestion auto-fills the phone and locks it.
///   • Typing a name that isn't in the list is treated as a new customer,
///     and the row is saved along with the item on submit.
///
/// Live calculations update Total / Discount / Remaining / Balance as the
/// numeric fields change.
class AddRecordSheet extends StatefulWidget {
  const AddRecordSheet({super.key});

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  final _formKey = GlobalKey<FormState>();

  // Non-name fields use their own controllers.
  final _phone = TextEditingController();
  final _item = TextEditingController();
  final _quality = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController();

  // Name is managed by Autocomplete's internal controller. We mirror its
  // text here so the "new customer" hint and the save-logic can react.
  String _nameText = '';
  UserModel? _selectedUser;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_qty, _price, _discount]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _item.dispose();
    _quality.dispose();
    _qty.dispose();
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  // ───────── live calculations ─────────
  double get _quantity => double.tryParse(_qty.text.trim()) ?? 0;
  double get _itemPrice => double.tryParse(_price.text.trim()) ?? 0;
  double get _discountValue => double.tryParse(_discount.text.trim()) ?? 0;
  double get _total => _quantity * _itemPrice;
  double get _remaining => (_total - _discountValue).clamp(0, double.infinity);
  // New formula: Balance = Total − Remaining − Discount.
  // At creation nothing is paid yet, so this evaluates to 0 and matches
  // what the user-detail view expects.
  double get _balance =>
      (_total - _remaining - _discountValue).clamp(0, double.infinity);

  // ───────── name / user selection ─────────
  void _handleUserSelected(UserModel user) {
    setState(() {
      _selectedUser = user;
      _nameText = user.name;
      _phone.text = user.phoneNumber;
    });
    FocusScope.of(context).unfocus();
  }

  void _handleNameChanged(String text) {
    final stillMatches =
        _selectedUser != null && text.trim() == _selectedUser!.name.trim();
    setState(() {
      _nameText = text;
      if (!stillMatches) _selectedUser = null;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUser = null;
    });
  }

  /// Show the "new customer" hint when the user has typed a plausible name
  /// that doesn't match any cached user.
  bool _shouldShowNewCustomerHint(List<UserModel> users) {
    if (_selectedUser != null) return false;
    final trimmed = _nameText.trim();
    if (trimmed.length < 2) return false;
    final lc = trimmed.toLowerCase();
    return !users.any((u) => u.name.trim().toLowerCase() == lc);
  }

  // ───────── save ─────────
  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_discountValue > _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discount cannot exceed the total price.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final userProv = context.read<UserProvider>();
      final itemProv = context.read<ItemProvider>();

      final UserModel user;
      if (_selectedUser != null) {
        // Path 1: Existing user picked from dropdown — reuse the id.
        user = _selectedUser!;
      } else {
        final typedName = _nameText.trim();
        final typedPhone = _phone.text.trim();

        // Path 2: Check the cache for a case-insensitive name/phone match.
        // This catches the case where the user typed a known name instead of
        // picking from the dropdown.
        final cached = userProv.findByNameOrPhone(typedName, typedPhone);
        if (cached != null) {
          user = cached;
        } else {
          // Path 3: Genuinely new customer — insert into Supabase.
          user = await userProv.createUser(
            name: typedName,
            phoneNumber: typedPhone,
          );
        }
      }

      final item = ItemModel(
        id: '',
        userId: user.id,
        itemName: _item.text.trim(),
        quality: _quality.text.trim().isEmpty ? null : _quality.text.trim(),
        quantity: _quantity,
        price: _itemPrice,
        discount: _discountValue,
        remaining: _remaining,
        balance: _balance,
      );

      await itemProv.addItem(item);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Record saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final users = context.watch<UserProvider>().users;

    return Padding(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 14),
                Center(
                  child: const Text(
                    'Add Record',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Customer info: autocomplete name + phone
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _UserAutocomplete(
                        allUsers: users,
                        hasSelection: _selectedUser != null,
                        onUserSelected: _handleUserSelected,
                        onTextChanged: _handleNameChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Field(
                        controller: _phone,
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                        readOnly: _selectedUser != null,
                        validator: _phoneValidator,
                      ),
                    ),
                  ],
                ),

                // Status strip: existing customer, new customer, or nothing
                if (_selectedUser != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _StatusChip.existing(
                      user: _selectedUser!,
                      onClear: _clearSelection,
                    ),
                  )
                else if (_shouldShowNewCustomerHint(users))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: _StatusChip.newCustomer(),
                  ),

                const SizedBox(height: 10),

                _Field(
                  controller: _item,
                  label: 'Item name',
                  validator: _required,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _quality,
                        label: 'Quality (optional)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Field(
                        controller: _qty,
                        label: 'Quantity',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: _decimalFormatters,
                        validator: _positiveNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _price,
                        label: 'Item price',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: _decimalFormatters,
                        validator: _positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Field(
                        controller: _discount,
                        label: 'Discount (optional)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: _decimalFormatters,
                        validator: _nonNegativeOptional,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _CalcBlock(
                  total: _total,
                  discount: _discountValue,
                  remaining: _remaining,
                  balance: _balance,
                ),
                const SizedBox(height: 14),

                ElevatedButton(
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
                      : const Text('Save Record'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────── validators ─────────
  static final List<TextInputFormatter> _decimalFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
  ];

  static String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  static String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final cleaned = v.replaceAll(RegExp(r'[\s\-()+]'), '');
    if (cleaned.length < 7) return 'Phone looks too short';
    return null;
  }

  static String? _positiveNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null || n <= 0) return 'Must be greater than 0';
    return null;
  }

  static String? _nonNegativeOptional(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim());
    if (n == null || n < 0) return 'Invalid';
    return null;
  }
}

// ══════════════════════════════════════════════════════════════════════
//  User autocomplete
// ══════════════════════════════════════════════════════════════════════

/// Searchable dropdown for customers. Filters by name or phone digits.
class _UserAutocomplete extends StatelessWidget {
  const _UserAutocomplete({
    required this.allUsers,
    required this.hasSelection,
    required this.onUserSelected,
    required this.onTextChanged,
  });

  final List<UserModel> allUsers;
  final bool hasSelection;
  final void Function(UserModel) onUserSelected;
  final void Function(String) onTextChanged;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<UserModel>(
      displayStringForOption: (u) => u.name,
      optionsBuilder: (TextEditingValue value) {
        final raw = value.text.trim();
        if (raw.isEmpty) {
          // Show the 6 most-recent customers on focus.
          return allUsers.take(6);
        }
        final query = raw.toLowerCase();
        final queryDigits = raw.replaceAll(RegExp(r'\D'), '');
        return allUsers.where((u) {
          final nameHit = u.name.toLowerCase().contains(query);
          final phoneDigits = u.phoneNumber.replaceAll(RegExp(r'\D'), '');
          final phoneHit =
              queryDigits.isNotEmpty && phoneDigits.contains(queryDigits);
          return nameHit || phoneHit;
        });
      },
      onSelected: onUserSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onTextChanged,
          onFieldSubmitted: (_) => onFieldSubmitted(),
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: 'Name',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: hasSelection
                ? const Icon(
                    Icons.check_circle,
                    color: AppTheme.primary,
                    size: 18,
                  )
                : const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _OptionsPanel(options: options.toList(), onSelected: onSelected);
      },
    );
  }
}

/// The dropdown panel that floats under the name field.
class _OptionsPanel extends StatelessWidget {
  const _OptionsPanel({required this.options, required this.onSelected});

  final List<UserModel> options;
  final void Function(UserModel) onSelected;

  static const List<List<Color>> _palettes = [
    [Color(0xFFEEEDFE), Color(0xFF3C3489)],
    [Color(0xFFE1F5EE), Color(0xFF0F6E56)],
    [Color(0xFFFAECE7), Color(0xFF993C1D)],
    [Color(0xFFE6F1FB), Color(0xFF0C447C)],
    [Color(0xFFFBEAF0), Color(0xFF72243E)],
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: options.length,
            separatorBuilder: (_, __) => const Divider(
              height: 0.5,
              thickness: 0.5,
              color: AppTheme.divider,
            ),
            itemBuilder: (context, i) {
              final user = options[i];
              final p = _palettes[i % _palettes.length];
              return InkWell(
                onTap: () => onSelected(user),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: p[0],
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user.initials,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: p[1],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              user.phoneNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Status chip (existing / new customer)
// ══════════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onClear,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onClear;

  factory _StatusChip.existing({
    required UserModel user,
    required VoidCallback onClear,
  }) {
    return _StatusChip(
      backgroundColor: const Color(0xFFE1F5EE),
      foregroundColor: const Color(0xFF0F6E56),
      icon: Icons.check_circle,
      title: 'Existing customer',
      subtitle: '${user.name} · ${user.phoneNumber}',
      onClear: onClear,
    );
  }

  const factory _StatusChip.newCustomer() = _NewCustomerChip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: foregroundColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: foregroundColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: foregroundColor.withOpacity(0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onClear != null)
            InkResponse(
              onTap: onClear,
              radius: 14,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close, size: 14, color: foregroundColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// Const-friendly variant for the "new customer" state so the chip can be
/// instantiated as a compile-time constant.
class _NewCustomerChip extends _StatusChip {
  const _NewCustomerChip()
    : super(
        backgroundColor: const Color(0xFFEEEDFE),
        foregroundColor: const Color(0xFF3C3489),
        icon: Icons.person_add_alt,
        title: 'New customer',
        subtitle: 'Will be added when you save',
      );
}

// ══════════════════════════════════════════════════════════════════════
//  Low-level field + calc block
// ══════════════════════════════════════════════════════════════════════

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: 13,
        color: readOnly ? AppTheme.textSecondary : AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}

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
          _row('Discount', '− ${_fmt.format(discount)}'),
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
