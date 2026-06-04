import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/animations/tilt_card.dart';
import '../../../core/animations/spring_scale_button.dart';
import '../../../core/constants/dummy_data.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['All', 'Coffee', 'Food', 'Snacks', 'Drinks', 'Desserts'];

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _selectedCategory == 'All' 
        ? DummyData.products 
        : DummyData.products.where((p) => p['category'] == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search menu...',
                border: InputBorder.none,
                filled: false,
              ),
              onChanged: (value) => setState(() {}),
            )
          : Text('Our Menu', style: Theme.of(context).textTheme.displaySmall),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchController.clear();
            }),
          ),
        ],
      ),
      body: Column(
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
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppTheme.accentColor : AppTheme.primaryColor.withOpacity(0.1)),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: AnimationLimiter(
                key: ValueKey<String>(_selectedCategory),
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 450),
                      columnCount: 2,
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildMenuItemCard(context, index, filteredProducts[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'menu_fab',
        onPressed: () => context.push('/menu/add'),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _confirmDeleteItem(BuildContext context, Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Remove "${product['name']}" from the menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      DummyData.removeProduct(product['id'] as String);
      setState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${product['name']}" removed from menu')),
        );
      }
    }
  }

  Widget _buildMenuItemCard(BuildContext context, int index, Map<String, dynamic> product) {
    final bool isSpecial = index % 3 == 0; // Simulate featured items

    return TiltCard(
      child: SpringScaleButton(
        onPressed: () => context.push('/menu/edit/${product['id']}'),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSpecial ? AppTheme.accentColor : AppTheme.primaryColor.withOpacity(0.05),
              width: isSpecial ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Hero(
                      tag: 'menu_image_${product['id']}',
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: product['color'].withOpacity(0.1),
                        ),
                        child: product.containsKey('imageUrl') 
                            ? (product['imageUrl'].startsWith('assets/')
                                ? Image.asset(product['imageUrl'], fit: BoxFit.cover)
                                : Image.network(
                                    product['imageUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(child: Icon(product['icon'], size: 40, color: product['color'])),
                                  ))
                            : Center(child: Icon(product['icon'], size: 40, color: product['color'])),
                      ),
                    ),
                    if (isSpecial)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(4)),
                          child: const Text('FEATURED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.white.withOpacity(0.95),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _confirmDeleteItem(context, product),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'], style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(product['category'], style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PKR ${product['price']}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.05), shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_right, size: 14, color: AppTheme.primaryColor),
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
  }
}


