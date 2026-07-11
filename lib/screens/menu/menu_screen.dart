import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/drink.dart';
import '../../providers/menu_provider.dart';
import '../drink_detail/drink_detail_screen.dart';
import '../notification/notification_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedTabIndex = 0;
  String _selectedSubFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Main tab groupings that map to one or more category IDs
  static const List<Map<String, dynamic>> _mainTabs = [
    {'label': 'All', 'icon': Icons.grid_view_outlined, 'categoryIds': <String>['all']},
    {'label': 'Coffee', 'icon': Icons.coffee_outlined, 'categoryIds': <String>['coffee']},
    {'label': 'Non-Coffee', 'icon': Icons.local_drink_outlined, 'categoryIds': <String>['matcha', 'tea']},
    {'label': 'Ice Blended', 'icon': Icons.icecream_outlined, 'categoryIds': <String>['ice_blended']},
    {'label': 'Soda', 'icon': Icons.local_bar_outlined, 'categoryIds': <String>['soda']},
    {'label': 'Hot Drink', 'icon': Icons.local_fire_department_outlined, 'categoryIds': <String>['hot_drink']},
  ];

  // Sub-filter chips per main tab
  static const Map<int, List<Map<String, String>>> _subFilters = {
    2: [
      {'id': 'all', 'label': 'All'},
      {'id': 'matcha', 'label': 'Matcha'},
      {'id': 'tea', 'label': 'Tea & Chocolate'},
    ],
  };

  List<Drink> _filteredDrinks(MenuProvider menu) {
    List<Drink> drinks;

    if (_selectedTabIndex == 0) {
      // "All" tab — show everything
      drinks = menu.getDrinksByCategory('all');
    } else {
      final tab = _mainTabs[_selectedTabIndex];
      final categoryIds = tab['categoryIds'] as List<String>;

      if (_selectedSubFilter != 'all') {
        // A specific sub-filter is selected
        drinks = menu.getDrinksByCategory(_selectedSubFilter);
      } else {
        // Combine drinks from all category IDs in this tab group
        drinks = categoryIds
            .expand((id) => menu.getDrinksByCategory(id))
            .toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      drinks = drinks
          .where(
            (d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    return drinks;
  }

  /// Smart square-crop for Cloudinary thumbnails so every drink fills the
  /// thumbnail consistently (auto-focuses on the subject, not the background).
  String _squareThumbUrl(String url) {
    if (!url.contains('res.cloudinary.com') || !url.contains('/upload/')) {
      return url;
    }
    return url.replaceFirst(
      '/upload/',
      '/upload/c_fill,g_auto,ar_1:1,w_200/',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final filtered = _filteredDrinks(menu);
    final subFilters = _subFilters[_selectedTabIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark green header with back arrow and trailing icon
          Container(
            color: AppColors.darkGreen,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
              child: Row(
                children: [
                  // Back arrow (only if can pop)
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  else
                    const SizedBox(width: 12),
                  // Center title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'The Native Cloud',
                          style: GoogleFonts.spectral(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gulalet, Matcha, Coffee & More',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trailing notification/lock icon
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Category TabBar
          Container(
            color: AppColors.surface,
            child: Row(
              children: List.generate(_mainTabs.length, (index) {
                final tab = _mainTabs[index];
                final isSelected = _selectedTabIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                        _selectedSubFilter = 'all';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.only(
                          top: 12, bottom: 8, left: 4, right: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? AppColors.primaryBrand
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab['icon'] as IconData,
                            size: 22,
                            color: isSelected
                                ? AppColors.primaryBrand
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              tab['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primaryBrand
                                    : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Sub-filter chips (only shown when there are sub-filters)
          if (subFilters != null && subFilters.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subFilters.length,
                  itemBuilder: (context, index) {
                    final filter = subFilters[index];
                    final isSelected = _selectedSubFilter == filter['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSubFilter = filter['id']!;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkGreen
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: AppColors.divider, width: 1),
                          ),
                          child: Text(
                            filter['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search drinks...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '${filtered.length} drinks found',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Drink List (changed from GridView to ListView)
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('\uD83D\uDD0D', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          'No drinks found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final drink = filtered[index];
                      return _MenuListItem(
                        drink: drink,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DrinkDetailScreen(drink: drink),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MenuListItem extends StatelessWidget {
  final Drink drink;
  final VoidCallback onTap;

  const _MenuListItem({required this.drink, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Row(
          children: [
            // Square thumbnail
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: drink.imageUrl != null && drink.imageUrl!.isNotEmpty
                    ? Image.network(
                        _squareThumbUrl(drink.imageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(drink.imageEmoji,
                              style: const TextStyle(fontSize: 32)),
                        ),
                      )
                    : Image(
                        image: AssetImage(
                          drink.imagePath ?? 'assets/images/menu/default-image.png',
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(drink.imageEmoji,
                              style: const TextStyle(fontSize: 32)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Name, category, price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drink.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    drink.categoryId,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'RM ${drink.basePrice.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ],
              ),
            ),
            // Green "+" button
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.darkGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
