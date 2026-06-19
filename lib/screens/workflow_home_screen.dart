import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/workflow_models.dart';
import '../providers/workflow_provider.dart';

class WorkflowHomeScreen extends StatefulWidget {
  const WorkflowHomeScreen({super.key});

  @override
  State<WorkflowHomeScreen> createState() => _WorkflowHomeScreenState();
}

class _WorkflowHomeScreenState extends State<WorkflowHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [_CustomerPortal(), _AdminWorkspace()];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Customer',
          ),
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

class _CustomerPortal extends StatelessWidget {
  const _CustomerPortal();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkflowProvider>();
    final latest = provider.orders.first;
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _ScreenHeader()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: _ActionBand(
              title: 'Start a print order',
              subtitle: 'Share product details, colors, quantity, and address.',
              icon: Icons.add_business_outlined,
              buttonLabel: 'New request',
              onPressed: () => _openRequestSheet(context),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Track order',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TrackingPanel(order: latest),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: Text(
              'Recent requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        SliverList.separated(
          itemCount: provider.orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                index == provider.orders.length - 1 ? 24 : 0,
              ),
              child: _OrderCard(order: provider.orders[index]),
            );
          },
        ),
      ],
    );
  }

  void _openRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RequestSheet(),
    );
  }
}

class _AdminWorkspace extends StatelessWidget {
  const _AdminWorkspace();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkflowProvider>();
    return DefaultTabController(
      length: 4,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          const SliverToBoxAdapter(child: _ScreenHeader(admin: true)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: _KpiGrid(provider: provider),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeaderDelegate(
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Orders'),
                  Tab(text: 'Production'),
                  Tab(text: 'Inventory'),
                  Tab(text: 'Messages'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _OrdersTab(orders: provider.activeOrders),
            const _ProductionTab(),
            _InventoryTab(items: provider.inventory),
            _MessagesTab(messages: provider.messages),
          ],
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({this.admin = false});

  final bool admin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.print_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin ? 'Operations' : 'Own Business',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  admin
                      ? 'Orders, production, inventory, delivery'
                      : 'Design, print, and delivery in one place',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class _ActionBand extends StatelessWidget {
  const _ActionBand({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.onInkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _TrackingPanel extends StatelessWidget {
  const _TrackingPanel({required this.order});

  final WorkflowOrder order;

  @override
  Widget build(BuildContext context) {
    final statuses = RequestStatus.values
        .where((s) => s != RequestStatus.draft)
        .toList();
    final activeIndex = statuses.indexOf(order.status).clamp(0, statuses.length);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.id, style: Theme.of(context).textTheme.titleMedium),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.product} / ${order.quantity} pcs / due ${_date(order.dueDate)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: order.progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 66,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = statuses[index];
                final active = index <= activeIndex;
                return _StepPill(status: status, active: active);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.status, required this.active});

  final RequestStatus status;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? AppTheme.primarySoft : AppTheme.inputFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status.icon,
            size: 18,
            color: active ? AppTheme.primary : AppTheme.textSecondary,
          ),
          const Spacer(),
          Text(
            status.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.provider});

  final WorkflowProvider provider;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.sizeOf(context).width > 620 ? 4 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _KpiTile('Active', provider.activeOrders.length.toString(), Icons.receipt_long),
        _KpiTile('Designs', provider.pendingDesigns.toString(), Icons.draw_outlined),
        _KpiTile('Production', provider.inProduction.toString(), Icons.precision_manufacturing_outlined),
        _KpiTile('Receivable', _money(provider.receivables), Icons.payments_outlined),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.orders});

  final List<WorkflowOrder> orders;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _OrderCard(order: orders[index], admin: true),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.admin = false});

  final WorkflowOrder order;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.customerName} / ${order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${order.product}, ${order.material}, ${order.size}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            order.designBrief,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Meta(icon: Icons.inventory_2_outlined, label: '${order.quantity} pcs'),
              _Meta(icon: Icons.event_outlined, label: _date(order.dueDate)),
              Expanded(child: _Meta(icon: Icons.person_outline, label: order.assignee)),
            ],
          ),
          if (admin) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<WorkflowProvider>().advanceOrder(order.id),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Advance'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductionTab extends StatelessWidget {
  const _ProductionTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkflowProvider>();
    final stages = ProductionStage.values;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final stage = stages[index];
        final orders = provider.ordersForStage(stage);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(stage.label, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text('${orders.length}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              if (orders.isEmpty)
                const Text('No jobs in this stage.', style: TextStyle(color: AppTheme.textSecondary))
              else
                ...orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ProductionJob(order: order),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductionJob extends StatelessWidget {
  const _ProductionJob({required this.order});

  final WorkflowOrder order;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.id, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${order.product} / ${order.quantity} pcs',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 90,
              child: LinearProgressIndicator(
                value: order.progress,
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _panelDecoration(),
          child: Row(
            children: [
              Icon(
                item.needsReorder ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: item.needsReorder ? AppTheme.warning : AppTheme.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Reorder at ${_qty(item.reorderPoint)} ${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${_qty(item.stock)} ${item.unit}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessagesTab extends StatefulWidget {
  const _MessagesTab({required this.messages});

  final List<TeamMessage> messages;

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: widget.messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final message = widget.messages[index];
              return Align(
                alignment: message.isCustomer ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 310),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isCustomer ? AppTheme.surface : AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.sender, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(message.text),
                      const SizedBox(height: 6),
                      Text(_time(message.time), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Message customer or team'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () {
                  context.read<WorkflowProvider>().sendMessage(_controller.text);
                  _controller.clear();
                },
                icon: const Icon(Icons.send),
                tooltip: 'Send',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet();

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'New Customer');
  final _phone = TextEditingController(text: '+92 ');
  final _quantity = TextEditingController(text: '500');
  final _colors = TextEditingController();
  final _brief = TextEditingController();
  final _address = TextEditingController();
  ProductOption? _product;
  String? _material;
  String? _size;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _quantity.dispose();
    _colors.dispose();
    _brief.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkflowProvider>();
    _product ??= provider.products.first;
    _material ??= _product!.materials.first;
    _size ??= _product!.sizes.first;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('New design request', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TextInput(controller: _name, label: 'Customer name'),
              _TextInput(controller: _phone, label: 'Phone number', keyboardType: TextInputType.phone),
              DropdownButtonFormField<ProductOption>(
                value: _product,
                decoration: const InputDecoration(labelText: 'Product'),
                items: provider.products
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _product = value;
                    _material = value.materials.first;
                    _size = value.sizes.first;
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _material,
                      decoration: const InputDecoration(labelText: 'Material'),
                      items: _product!.materials
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (value) => setState(() => _material = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _size,
                      decoration: const InputDecoration(labelText: 'Size'),
                      items: _product!.sizes
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _size = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _TextInput(controller: _quantity, label: 'Quantity', keyboardType: TextInputType.number),
              _TextInput(controller: _colors, label: 'Colors'),
              _TextInput(controller: _brief, label: 'Design brief', maxLines: 3),
              _TextInput(controller: _address, label: 'Delivery address', maxLines: 2),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    provider.createOrder(
                      customerName: _name.text.trim(),
                      phoneNumber: _phone.text.trim(),
                      product: _product!,
                      quantity: int.tryParse(_quantity.text.trim()) ?? 1,
                      material: _material!,
                      size: _size!,
                      colors: _colors.text.trim(),
                      designBrief: _brief.text.trim(),
                      deliveryAddress: _address.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Submit request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabHeaderDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: AppTheme.background,
      child: Align(alignment: Alignment.centerLeft, child: tabBar),
    );
  }

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) => false;
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppTheme.border),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0A111827),
        blurRadius: 14,
        offset: Offset(0, 6),
      ),
    ],
  );
}

String _date(DateTime date) => DateFormat('MMM d').format(date);

String _time(DateTime date) => DateFormat('h:mm a').format(date);

String _money(double value) {
  final formatted = NumberFormat.compactCurrency(symbol: 'Rs ', decimalDigits: 0).format(value);
  return formatted;
}

String _qty(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
