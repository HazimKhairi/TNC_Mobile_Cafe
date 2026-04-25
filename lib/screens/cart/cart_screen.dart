import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/linen_background.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../auth/login_screen.dart';
import '../order/order_confirmation_screen.dart';
import '../payment/qr_payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LinenBackground(
        child: SafeArea(
          child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            if (cart.isEmpty) {
              return _EmptyCart();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Cart',
                        style: GoogleFonts.spectral(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showClearDialog(context, cart),
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Text(
                    '${cart.itemCount} item${cart.itemCount != 1 ? 's' : ''} in cart',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                // Cart Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => cart.removeItem(item.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Emoji avatar
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceAlt,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Image(
                                    image: AssetImage(
                                      item.drink.imagePath ?? 'assets/images/menu/default-image.png',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.drink.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.customizationSummary,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'RM${item.totalPrice.toStringAsFixed(0)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.goldAccent,
                                            ),
                                          ),
                                          // Quantity controls
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.background,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                _SmallButton(
                                                  icon: Icons.remove,
                                                  onTap: () =>
                                                      cart.updateQuantity(
                                                        item.id,
                                                        item.quantity - 1,
                                                      ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                      ),
                                                  child: Text(
                                                    '${item.quantity}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                _SmallButton(
                                                  icon: Icons.add,
                                                  onTap: () =>
                                                      cart.updateQuantity(
                                                        item.id,
                                                        item.quantity + 1,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Summary & Checkout
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    MediaQuery.of(context).padding.bottom + 100,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Subtotal',
                        value: 'RM${cart.totalAmount.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(label: 'Service Fee', value: 'RM10'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      _SummaryRow(
                        label: 'Total',
                        value:
                            'RM${(cart.totalAmount + 10).toStringAsFixed(0)}',
                        isBold: true,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _checkout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBrand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Place Order',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Cart?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove all items?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
            },
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkout(BuildContext context) async {
    final auth = context.read<AuthProvider>();

    // Require login before checkout
    if (!auth.isLoggedIn) {
      final loggedIn = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen(returnResult: true)));
      if (loggedIn != true || !context.mounted) return;
    }

    if (!context.mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _OrderTypeSheet(),
    );
    if (result == null || !context.mounted) return;

    final cart = context.read<CartProvider>();
    final totalAmount = cart.totalAmount + 10;

    // QR Payment step (with simulation)
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QrPaymentScreen(
          amount: totalAmount,
          orderType: result['orderType'] as String,
          tableNumber: result['tableNumber'] as int?,
        ),
      ),
    );
    if (paid != true || !context.mounted) return;

    final orderProvider = context.read<OrderProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;

    final order = await orderProvider.placeOrder(
      cart.items,
      totalAmount,
      userId: currentUser?.uid,
      customerName: currentUser?.displayName,
      orderType: result['orderType'] as String,
      tableNumber: result['tableNumber'] as int?,
    );

    if (!context.mounted) return;
    cart.clear();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: GoogleFonts.spectral(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some delicious drinks!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.primaryBrand : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}

class _OrderTypeSheet extends StatefulWidget {
  const _OrderTypeSheet();

  @override
  State<_OrderTypeSheet> createState() => _OrderTypeSheetState();
}

class _OrderTypeSheetState extends State<_OrderTypeSheet> {
  String _orderType = 'dine_in';
  final _tableController = TextEditingController();
  String? _tableError;

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_orderType == 'dine_in') {
      final table = int.tryParse(_tableController.text.trim());
      if (table == null || table < 1) {
        setState(() => _tableError = 'Enter a valid table number');
        return;
      }
      Navigator.pop(context, {'orderType': 'dine_in', 'tableNumber': table});
    } else {
      Navigator.pop(context, {'orderType': 'takeaway', 'tableNumber': null});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Order Type',
            style: GoogleFonts.spectral(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How would you like your order?',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Dine-in option
          _OrderTypeOption(
            icon: Icons.restaurant_rounded,
            label: 'Dine-in',
            subtitle: 'Enjoy at the café',
            isSelected: _orderType == 'dine_in',
            onTap: () => setState(() => _orderType = 'dine_in'),
          ),
          const SizedBox(height: 10),

          // Table number (visible only for dine-in)
          if (_orderType == 'dine_in') ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 14),
              child: TextFormField(
                controller: _tableController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Table number',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.table_bar_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  errorText: _tableError,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primaryBrand,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_tableError != null) setState(() => _tableError = null);
                },
              ),
            ),
          ],

          // Takeaway option
          _OrderTypeOption(
            icon: Icons.takeout_dining_rounded,
            label: 'Takeaway',
            subtitle: 'Pack and go',
            isSelected: _orderType == 'takeaway',
            onTap: () => setState(() => _orderType = 'takeaway'),
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirm & Place Order',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrderTypeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBrand.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryBrand : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBrand.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryBrand
                    : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryBrand
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? AppColors.primaryBrand
                  : AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
