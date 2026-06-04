import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/constants/dummy_data.dart';
import '../../auth/domain/auth_providers.dart';

class OrderTakingScreen extends ConsumerStatefulWidget {
  final String? prefilledCustomerName;
  const OrderTakingScreen({super.key, this.prefilledCustomerName});

  @override
  ConsumerState<OrderTakingScreen> createState() => _OrderTakingScreenState();
}

class _OrderTakingScreenState extends ConsumerState<OrderTakingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _cartItems = {}; // id -> quantity
  bool _isPlacingOrder = false;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Coffee', 'Food', 'Snacks', 'Drinks', 'Desserts'];
  String _selectedPayment = 'Cash';
  final List<Map<String, dynamic>> _paymentMethods = [
    {'label': 'Cash', 'icon': Icons.payments_rounded, 'color': Color(0xFF27AE60)},
    {'label': 'Card', 'icon': Icons.credit_card_rounded, 'color': Color(0xFF3498DB)},
    {'label': 'EasyPaisa', 'icon': Icons.phone_android_rounded, 'color': Color(0xFF2ECC71)},
    {'label': 'JazzCash', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFFE74C3C)},
  ];
  final TextEditingController _customerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.prefilledCustomerName != null) {
      _customerNameController.text = widget.prefilledCustomerName!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  void _addToCart(String itemId) {
    setState(() {
      _cartItems[itemId] = (_cartItems[itemId] ?? 0) + 1;
    });
  }

  void _removeFromCart(String itemId) {
    setState(() {
      if (_cartItems.containsKey(itemId)) {
        if (_cartItems[itemId]! > 1) {
          _cartItems[itemId] = _cartItems[itemId]! - 1;
        } else {
          _cartItems.remove(itemId);
        }
      }
    });
  }

  void _deleteFromCart(String itemId) {
    setState(() {
      _cartItems.remove(itemId);
    });
  }

  double _calculateSubtotal() {
    double total = 0;
    _cartItems.forEach((id, qty) {
      final product = DummyData.products.firstWhere((p) => p['id'] == id);
      final price = product['price'] as int;
      total += price * qty;
    });
    return total;
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) return;

    final nameController = TextEditingController(text: _customerNameController.text);
    final now = DateTime.now();
    final timeStr = _formatTime(now);
    final dateStr = _formatDate(now);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Confirm Order Details',
                    style: GoogleFonts.ebGaramond(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Verify the customer name and exact timestamp before final placement.',
                style: GoogleFonts.hankenGrotesk(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // Time Stamp details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLACEMENT TIMESTAMP',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateStr at $timeStr',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Customer Name input field
              TextField(
                controller: nameController,
                autofocus: true,
                style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'CUSTOMER NAME',
                  labelStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  hintText: 'Enter name (e.g. Hassan)',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _customerNameController.text = nameController.text;
                        Navigator.pop(ctx, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Confirm & Place'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;
    _executeOrderPlacement();
  }

  Future<void> _executeOrderPlacement() async {
    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final subtotal = _calculateSubtotal();
      final tax = subtotal * 0.05;
      final total = subtotal + tax;

      final userProfile = ref.read(userProfileProvider).value;
      final staffId = userProfile?['id'] as String? ?? 'staff-offline';

      final itemsList = _cartItems.entries.map((e) {
        final product = DummyData.products.firstWhere((p) => p['id'] == e.key);
        return {
          'id': product['id'],
          'name': product['name'],
          'price': product['price'],
          'quantity': e.value,
        };
      }).toList();

      final orderRepo = ref.read(orderRepositoryProvider);
      final orderId = await orderRepo.createOrder(
        staffId: staffId,
        subtotal: subtotal,
        tax: tax,
        total: total,
        paymentMethod: _selectedPayment,
        items: itemsList,
        notes: _customerNameController.text.trim().isEmpty ? 'Guest' : _customerNameController.text.trim(),
      );

      if (!mounted) return;

      // Show Success Animation — auto dismiss after 1.5s then navigate
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (dialogContext, value, child) {
              return Transform.scale(
                scale: value,
                child: AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 80),
                      const SizedBox(height: 16),
                      Text('Order Placed!', style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }

      // Wait for animation then dismiss dialog and navigate to receipt
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
        context.go('/orders/$orderId/receipt'); // go() works correctly inside StatefulShellRoute
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Order'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Menu'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Cart'),
                  if (_cartItems.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _cartItems.values.fold(0, (a, b) => a + b).toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          _buildCartTab(),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    final theme = Theme.of(context);
    final filteredProducts = _selectedCategory == 'All' 
        ? DummyData.products 
        : DummyData.products.where((p) => p['category'] == _selectedCategory).toList();

    return Column(
      children: [
        // Category Chips
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    category,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                  checkmarkColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              final itemId = product['id'];
              final qty = _cartItems[itemId] ?? 0;
              final accentColor = theme.colorScheme.secondary;

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: (product['color'] as Color).withOpacity(0.08),
                        ),
                        child: product.containsKey('imageUrl')
                          ? (product['imageUrl'].startsWith('assets/')
                              ? Image.asset(
                                  product['imageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(product['icon'], size: 40, color: product['color']),
                                  ),
                                )
                              : Image.network(
                                  product['imageUrl'],
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: (product['color'] as Color),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(product['icon'], size: 40, color: product['color']),
                                  ),
                                ))
                          : Center(
                              child: Icon(product['icon'], size: 40, color: product['color']),
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PKR ${product['price']}',
                            style: GoogleFonts.hankenGrotesk(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (qty == 0)
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _addToCart(itemId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Icon(Icons.add_rounded, size: 20),
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _qtyButton(Icons.remove_rounded, () => _removeFromCart(itemId), theme),
                                Text(
                                  '$qty',
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                _qtyButton(Icons.add_rounded, () => _addToCart(itemId), theme),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildCartTab() {
    final theme = Theme.of(context);
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://lottie.host/17eb6bd4-1cde-47cc-ae90-c23f2b6e1546/1i1n8fQoK3.json',
              height: 200,
              errorBuilder: (context, error, stack) => Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => _tabController.animateTo(0),
                child: const Text('Browse Menu'),
              ),
            ),
          ],
        ),
      );
    }

    final subtotal = _calculateSubtotal();
    final tax = subtotal * 0.05;
    final total = subtotal + tax;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final itemId = _cartItems.keys.elementAt(index);
              final qty = _cartItems[itemId]!;
              final product = DummyData.products.firstWhere((p) => p['id'] == itemId);
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: (product['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(product['icon'], color: product['color'], size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('$qty x PKR ${product['price']}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text(
                      'PKR ${qty * product['price']}',
                      style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                      tooltip: 'Remove item',
                      onPressed: () => _deleteFromCart(itemId),
                    ),
                  ],
                ),
              );
            },
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Customer Name Input ──────────────────────
              TextField(
                controller: _customerNameController,
                style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'CUSTOMER NAME',
                  labelStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  hintText: 'Enter name (e.g. Ali)',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              // ── Payment Method Selector ──────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PAYMENT METHOD',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _paymentMethods.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    final isSelected = _selectedPayment == method['label'];
                    final color = method['color'] as Color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPayment = method['label']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : color.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(method['icon'] as IconData,
                                size: 15,
                                color: isSelected ? Colors.white : color),
                            const SizedBox(width: 6),
                            Text(
                              method['label'],
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              // ── Summary ───────────────────────────────────────
              _summaryRow('Subtotal', 'PKR $subtotal', theme),
              const SizedBox(height: 12),
              _summaryRow('Tax (5%)', 'PKR ${tax.toStringAsFixed(2)}', theme),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    'PKR ${total.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text('Place Order • $_selectedPayment',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _summaryRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
