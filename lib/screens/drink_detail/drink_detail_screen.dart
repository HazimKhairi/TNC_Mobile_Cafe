import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/drink.dart';
import '../../providers/cart_provider.dart';

class DrinkDetailScreen extends StatefulWidget {
  final Drink drink;

  const DrinkDetailScreen({super.key, required this.drink});

  @override
  State<DrinkDetailScreen> createState() => _DrinkDetailScreenState();
}

class _DrinkDetailScreenState extends State<DrinkDetailScreen> {
  late DrinkSize _selectedSize;
  final Set<DrinkAddon> _selectedAddons = {};
  late String _selectedSugar;
  late String _selectedIce;
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.drink.sizes.isNotEmpty
        ? widget.drink.sizes.first
        : const DrinkSize(label: 'Regular', priceAdd: 0);
    _selectedSugar = widget.drink.sugarLevels.isNotEmpty
        ? widget.drink.sugarLevels[widget.drink.sugarLevels.length ~/ 2]
        : '100%';
    _selectedIce = widget.drink.iceLevels.isNotEmpty
        ? widget.drink.iceLevels[2 < widget.drink.iceLevels.length ? 2 : 0]
        : 'Normal';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double price = widget.drink.basePrice + _selectedSize.priceAdd;
    for (final addon in _selectedAddons) {
      price += addon.price;
    }
    return price * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final drink = widget.drink;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Image Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentBlue.withValues(alpha: 0.08),
                      AppColors.primaryBrand.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'drink_${drink.id}',
                    child: Text(
                      drink.imageEmoji,
                      style: const TextStyle(fontSize: 120),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                drink.name,
                                style: GoogleFonts.spectral(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                drink.description,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB800)),
                              const SizedBox(width: 4),
                              Text(
                                drink.rating.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Size Selection
                    if (drink.sizes.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionTitle(title: 'Size'),
                      const SizedBox(height: 12),
                      Row(
                        children: drink.sizes.map((size) {
                          final isSelected = _selectedSize == size;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: size != drink.sizes.last ? 10 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedSize = size),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentBlue
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accentBlue
                                          : AppColors.divider,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        size.label,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                      if (size.priceAdd > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '+RM${size.priceAdd.toStringAsFixed(0)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white.withValues(alpha: 0.8)
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Sugar Level
                    if (drink.sugarLevels.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionTitle(title: 'Sugar Level'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: drink.sugarLevels.map((level) {
                          final isSelected = _selectedSugar == level;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSugar = level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.accentBlue : AppColors.background,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected ? AppColors.accentBlue : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                level,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Ice Level
                    if (drink.iceLevels.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionTitle(title: 'Ice Level'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: drink.iceLevels.map((level) {
                          final isSelected = _selectedIce == level;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedIce = level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.accentBlue : AppColors.background,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected ? AppColors.accentBlue : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                level,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Add-ons
                    if (drink.addons.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionTitle(title: 'Add-ons'),
                      const SizedBox(height: 12),
                      ...drink.addons.map((addon) {
                        final isSelected = _selectedAddons.contains(addon);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedAddons.remove(addon);
                                } else {
                                  _selectedAddons.add(addon);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentBlue.withValues(alpha: 0.08)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.accentBlue : AppColors.divider,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.accentBlue : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      addon.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '+RM${addon.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],

                    // Special Instructions
                    const SizedBox(height: 28),
                    _SectionTitle(title: 'Special Instructions'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'e.g., Less sweet, extra hot...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Bar
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Quantity
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onTap: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$_quantity',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.add,
                    onTap: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Add to Cart Button
            Expanded(
              child: ElevatedButton(
                onPressed: () => _addToCart(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Add to Cart  RM${_totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    final cart = context.read<CartProvider>();
    cart.addItem(
      drink: widget.drink,
      size: _selectedSize,
      addons: _selectedAddons.toList(),
      sugarLevel: _selectedSugar,
      iceLevel: _selectedIce,
      specialInstructions: _notesController.text.isNotEmpty ? _notesController.text : null,
      quantity: _quantity,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              '${widget.drink.name} added to cart',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}
