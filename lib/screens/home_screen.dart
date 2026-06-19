import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/add_record_sheet.dart';
import '../widgets/user_card.dart';
import 'user_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openAddSheet(BuildContext context) async {
    final r = context.responsive;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Capped on tablets so the sheet doesn't span the whole screen.
      constraints: BoxConstraints(maxWidth: r.sheetMaxWidth),
      builder: (_) => const AddRecordSheet(),
    );
  }

  /// Called by [Dismissible.confirmDismiss]. Returning `true` lets the
  /// swipe complete (card animates away); `false` or `null` snaps it back.
  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete user?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        content: Text(
          'Are you sure you want to delete "$name"? '
          'All their items will also be removed.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Called after the card is dismissed and the dialog confirmed.
  /// Delegates to [UserProvider.deleteUser], which handles optimistic
  /// removal and rollback on failure.
  Future<void> _handleDelete(BuildContext context, UserModel user) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<UserProvider>().deleteUser(user);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Deleted ${user.name}.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Provider has already re-inserted the user at its original index
      // and fired notifyListeners, so the card will reappear in place.
      messenger.showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, provider, _) {
            final allUsers = provider.users;
            final filtered = provider.filteredUsers;
            final r = context.responsive;
            final edge = r.edgePad;

            return RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: provider.loadUsers,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(edge + 4, 16, edge + 4, 10),
                    sliver: const SliverToBoxAdapter(child: _Header()),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(edge, 0, edge, 12),
                    sliver: const SliverToBoxAdapter(child: _SearchField()),
                  ),
                  if (provider.isLoading && allUsers.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  else if (provider.error != null && allUsers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(
                        message: provider.error!,
                        onRetry: provider.loadUsers,
                      ),
                    )
                  else if (allUsers.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NoMatchesState(
                        query: provider.searchQuery,
                        onClear: provider.clearSearch,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(edge, 0, edge, 100),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => SizedBox(height: r.pad(8)),
                        itemBuilder: (context, i) {
                          final user = filtered[i];
                          return Dismissible(
                            key: ValueKey('user-${user.id}'),
                            direction: DismissDirection.endToStart,
                            background: const SizedBox.shrink(),
                            secondaryBackground: const _DeleteSwipeBackground(),
                            confirmDismiss: (_) =>
                                _confirmDelete(context, user.name),
                            onDismissed: (_) => _handleDelete(context, user),
                            // Derive color from user.id so the avatar stays
                            // the same whether or not a filter is active.
                            child: UserCard(
                              user: user,
                              colorIndex: user.id.hashCode.abs(),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UserDetailScreen(user: user),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Header
// ══════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final isSearching = provider.searchQuery.trim().isNotEmpty;
    final total = provider.users.length;
    final shown = provider.filteredUsers.length;

    final subtitle = isSearching
        ? '$shown of $total customer${total == 1 ? '' : 's'}'
        : '$total customer${total == 1 ? '' : 's'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mod Graphics', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Search field
// ══════════════════════════════════════════════════════════════════════

/// Stateful so it can own the TextEditingController, but the query state
/// itself lives in [UserProvider] — this field only writes to it.
class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Seed from the provider so the field stays populated across rebuilds
    // (e.g. when the user returns from the detail screen).
    final initial = context.read<UserProvider>().searchQuery;
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch only the query so the field re-syncs if something external clears
    // it (e.g. the "clear" button in the no-results state).
    final providerQuery = context.select<UserProvider, String>(
      (p) => p.searchQuery,
    );
    if (_controller.text != providerQuery) {
      _controller.value = TextEditingValue(
        text: providerQuery,
        selection: TextSelection.collapsed(offset: providerQuery.length),
      );
    }

    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      onChanged: (v) => context.read<UserProvider>().setSearchQuery(v),
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: 'Search by name',
        hintStyle: const TextStyle(
          fontSize: 13,
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: AppTheme.textMuted,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        suffixIcon: hasText
            ? IconButton(
                splashRadius: 18,
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () {
                  _controller.clear();
                  context.read<UserProvider>().clearSearch();
                  FocusScope.of(context).unfocus();
                },
              )
            : null,
        filled: true,
        fillColor: AppTheme.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Empty / error states
// ══════════════════════════════════════════════════════════════════════

/// Shown when the user has zero customers total.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              color: AppTheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No customers yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap the add button to create your first record.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Shown when there are users but the current filter excludes all of them.
class _NoMatchesState extends StatelessWidget {
  const _NoMatchesState({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              color: AppTheme.textSecondary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No users found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No names match "${query.trim()}".',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onClear, child: const Text('Clear search')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppTheme.danger),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Swipe-to-delete background
// ══════════════════════════════════════════════════════════════════════

/// Red panel revealed behind the card as it swipes left.
/// Icon and label are right-aligned so they appear to "come from" the
/// right edge as the card slides away.
class _DeleteSwipeBackground extends StatelessWidget {
  const _DeleteSwipeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.danger,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 20),
          SizedBox(width: 6),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
