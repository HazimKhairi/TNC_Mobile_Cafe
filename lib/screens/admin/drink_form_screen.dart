import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/drink.dart';
import '../../providers/menu_provider.dart';
import '../../services/cloudinary_service.dart';

class DrinkFormScreen extends StatefulWidget {
  final Drink? drink;

  const DrinkFormScreen({super.key, this.drink});

  @override
  State<DrinkFormScreen> createState() => _DrinkFormScreenState();
}

class _DrinkFormScreenState extends State<DrinkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _emojiController = TextEditingController();
  final _ratingController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final _cloudinary = CloudinaryService();
  final _picker = ImagePicker();

  String? _selectedCategoryId;
  bool _isFeatured = false;
  bool _isSaving = false;
  bool _isUploading = false;

  List<DrinkSize> _sizes = [];
  List<DrinkAddon> _addons = [];
  List<String> _sugarLevels = ['0%', '25%', '50%', '75%', '100%'];
  List<String> _iceLevels = ['No Ice', 'Less Ice', 'Normal', 'Extra Ice'];

  bool get _isEditing => widget.drink != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final d = widget.drink!;
      _nameController.text = d.name;
      _descController.text = d.description;
      _priceController.text = d.basePrice.toStringAsFixed(2);
      _emojiController.text = d.imageEmoji;
      _ratingController.text = d.rating.toString();
      _imageUrlController.text = d.imageUrl ?? '';
      _selectedCategoryId = d.categoryId;
      _isFeatured = d.isFeatured;
      _sizes = List.from(d.sizes);
      _addons = List.from(d.addons);
      _sugarLevels = List.from(d.sugarLevels);
      _iceLevels = List.from(d.iceLevels);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _emojiController.dispose();
    _ratingController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final categories = menuProvider.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          _isEditing ? 'Edit Drink' : 'Add Drink',
          style: GoogleFonts.spectral(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image preview
            _buildImagePreview(),
            const SizedBox(height: 12),

            // Upload button + Image URL field
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _imageUrlController,
                    label: 'Image URL (optional)',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUpload,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_rounded,
                            size: 20, color: Colors.white),
                    label: Text(
                      _isUploading ? 'Uploading' : 'Upload',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Basic info
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: 'Drink Name',
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descController,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Base Price (RM)',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _ratingController,
                    label: 'Rating (0-5)',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _emojiController,
                    label: 'Emoji Icon',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(categories),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSwitchTile('Featured Drink', _isFeatured, (v) {
              setState(() => _isFeatured = v);
            }),

            const SizedBox(height: 24),

            // Sizes
            _buildSectionTitle('Sizes'),
            const SizedBox(height: 12),
            ..._sizes.asMap().entries.map((e) => _SizeRow(
                  key: ValueKey('size_${e.key}_${_sizes.length}'),
                  initial: e.value,
                  onChanged: (v) => _sizes[e.key] = v,
                  onRemove: () => setState(() => _sizes.removeAt(e.key)),
                )),
            _buildAddButton('Add Size', () {
              setState(() => _sizes.add(const DrinkSize(label: '', priceAdd: 0)));
            }),

            const SizedBox(height: 24),

            // Addons
            _buildSectionTitle('Add-ons'),
            const SizedBox(height: 12),
            ..._addons.asMap().entries.map((e) => _AddonRow(
                  key: ValueKey('addon_${e.key}_${_addons.length}'),
                  initial: e.value,
                  onChanged: (v) => _addons[e.key] = v,
                  onRemove: () => setState(() => _addons.removeAt(e.key)),
                )),
            _buildAddButton('Add Add-on', () {
              setState(
                  () => _addons.add(const DrinkAddon(name: '', price: 0)));
            }),

            const SizedBox(height: 24),

            // Sugar Levels
            _buildSectionTitle('Sugar Levels'),
            const SizedBox(height: 12),
            _buildChipList(_sugarLevels, (newList) {
              setState(() => _sugarLevels = newList);
            }),

            const SizedBox(height: 24),

            // Ice Levels
            _buildSectionTitle('Ice Levels'),
            const SizedBox(height: 12),
            _buildChipList(_iceLevels, (newList) {
              setState(() => _iceLevels = newList);
            }),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'Update Drink' : 'Add Drink',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final url = _imageUrlController.text.trim();
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(
                    icon: Icons.broken_image_rounded,
                    text: 'Invalid image URL'),
              ),
            )
          : _imagePlaceholder(
              icon: Icons.image_outlined, text: 'Enter image URL below'),
    );
  }

  Widget _imagePlaceholder({required IconData icon, required String text}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        Text(
          text,
          style:
              GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
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
          borderSide: const BorderSide(color: AppColors.accentBlue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown(List<DrinkCategory> categories) {
    // Guard against a categoryId that no longer exists in the loaded list
    // (e.g. category was deleted) — Flutter asserts if the dropdown's value
    // doesn't match exactly one item.
    final validValue = categories.any((c) => c.id == _selectedCategoryId)
        ? _selectedCategoryId
        : null;
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: categories
          .map((c) => DropdownMenuItem(
                value: c.id,
                child: Text('${c.icon} ${c.name}',
                    style: GoogleFonts.inter(fontSize: 14)),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategoryId = v),
      validator: (v) => v == null ? 'Select a category' : null,
    );
  }

  Widget _buildSwitchTile(
      String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textPrimary)),
        value: value,
        activeColor: AppColors.accentBlue,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(label, style: GoogleFonts.inter(fontSize: 13)),
    );
  }

  Widget _buildChipList(
      List<String> items, ValueChanged<List<String>> onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...items.map((item) => Chip(
              label: Text(item, style: GoogleFonts.inter(fontSize: 13)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                final newList = List<String>.from(items)..remove(item);
                onChanged(newList);
              },
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.divider),
              ),
            )),
        ActionChip(
          label: Text('+ Add',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.accentBlue)),
          backgroundColor: AppColors.accentBlue.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onPressed: () => _showAddItemDialog(items, onChanged),
        ),
      ],
    );
  }

  void _showAddItemDialog(
      List<String> items, ValueChanged<List<String>> onChanged) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Item',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter value',
            hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onChanged([...items, controller.text]);
              }
              Navigator.pop(ctx);
            },
            child: Text('Add',
                style: GoogleFonts.inter(
                    color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final url = await _cloudinary.uploadImage(File(picked.path));
      if (mounted) {
        setState(() {
          _imageUrlController.text = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final menuProvider = context.read<MenuProvider>();
      final imageUrl = _imageUrlController.text.trim();

      final drink = Drink(
        id: _isEditing ? widget.drink!.id : '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        basePrice: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
        imageEmoji: _emojiController.text.trim(),
        imagePath: _isEditing ? widget.drink!.imagePath : null,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        sizes: _sizes.where((s) => s.label.isNotEmpty).toList(),
        addons: _addons.where((a) => a.name.isNotEmpty).toList(),
        sugarLevels: _sugarLevels,
        iceLevels: _iceLevels,
        isFeatured: _isFeatured,
        rating: double.tryParse(_ratingController.text) ?? 4.5,
      );

      if (_isEditing) {
        await menuProvider.updateDrink(drink);
      } else {
        await menuProvider.addDrink(drink);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditing
                  ? '${drink.name} updated!'
                  : '${drink.name} added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ── Size row (stateful so the controllers persist across rebuilds) ──

class _SizeRow extends StatefulWidget {
  final DrinkSize initial;
  final ValueChanged<DrinkSize> onChanged;
  final VoidCallback onRemove;

  const _SizeRow({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_SizeRow> createState() => _SizeRowState();
}

class _SizeRowState extends State<_SizeRow> {
  late final TextEditingController _label;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.initial.label);
    _price =
        TextEditingController(text: widget.initial.priceAdd.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _label.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(DrinkSize(
      label: _label.text,
      priceAdd: double.tryParse(_price.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _label,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Size label',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => _emit(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: '+RM',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => _emit(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.error, size: 22),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

// ── Addon row (stateful, controllers persist) ──

class _AddonRow extends StatefulWidget {
  final DrinkAddon initial;
  final ValueChanged<DrinkAddon> onChanged;
  final VoidCallback onRemove;

  const _AddonRow({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_AddonRow> createState() => _AddonRowState();
}

class _AddonRowState extends State<_AddonRow> {
  late final TextEditingController _name;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.name);
    _price =
        TextEditingController(text: widget.initial.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(DrinkAddon(
      name: _name.text,
      price: double.tryParse(_price.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _name,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add-on name',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => _emit(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'RM',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.divider)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => _emit(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.error, size: 22),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
