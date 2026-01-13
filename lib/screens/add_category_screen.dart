import 'package:flutter/material.dart';
import '../models/category_data.dart';

// Available icons for category selection
class IconOption {
  final String name;
  final IconData icon;

  const IconOption({required this.name, required this.icon});
}

// Available colors for category selection
class ColorOption {
  final String label;
  final Color color;

  const ColorOption({required this.label, required this.color});
}

// Predefined icons
const List<IconOption> availableIcons = [
  IconOption(name: 'Home', icon: Icons.home_outlined),
  IconOption(name: 'School', icon: Icons.school_outlined),
  IconOption(name: 'Heart', icon: Icons.favorite_border),
  IconOption(name: 'Spa', icon: Icons.spa_outlined),
  IconOption(name: 'Fitness', icon: Icons.fitness_center_outlined),
  IconOption(name: 'Sports', icon: Icons.sports_soccer_outlined),
  IconOption(name: 'Work', icon: Icons.work_outline),
  IconOption(name: 'Shopping', icon: Icons.shopping_bag_outlined),
  IconOption(name: 'Food', icon: Icons.restaurant_outlined),
  IconOption(name: 'Coffee', icon: Icons.coffee_outlined),
  IconOption(name: 'Car', icon: Icons.directions_car_outlined),
  IconOption(name: 'Flight', icon: Icons.flight_outlined),
  IconOption(name: 'Pet', icon: Icons.pets_outlined),
  IconOption(name: 'Music', icon: Icons.music_note_outlined),
  IconOption(name: 'Game', icon: Icons.sports_esports_outlined),
  IconOption(name: 'Movie', icon: Icons.movie_outlined),
  IconOption(name: 'Book', icon: Icons.menu_book_outlined),
  IconOption(name: 'Gift', icon: Icons.card_giftcard_outlined),
  IconOption(name: 'Star', icon: Icons.star_outline),
  IconOption(name: 'Phone', icon: Icons.phone_android_outlined),
];

// Predefined colors
const List<ColorOption> availableColors = [
  ColorOption(label: 'Blue', color: Color(0xFF5b7db1)),
  ColorOption(label: 'Orange', color: Color(0xFFff8c42)),
  ColorOption(label: 'Pink', color: Color(0xFFff6b9d)),
  ColorOption(label: 'Purple', color: Color(0xFFa855f7)),
  ColorOption(label: 'Teal', color: Color(0xFF4ecdc4)),
  ColorOption(label: 'Green', color: Color(0xFF10b981)),
  ColorOption(label: 'Red', color: Color(0xFFef4444)),
  ColorOption(label: 'Yellow', color: Color(0xFFf59e0b)),
];

class AddCategoryScreen extends StatefulWidget {
  final Function(CategoryData) onCategoryCreated;

  const AddCategoryScreen({
    super.key,
    required this.onCategoryCreated,
  });

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  IconOption _selectedIcon = availableIcons[0];
  ColorOption _selectedColor = availableColors[0];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_nameController.text.isEmpty) return;

    final newCategory = CategoryData(
      id: _nameController.text,
      label: _nameController.text,
      icon: _selectedIcon.icon,
      color: _selectedColor.color,
      tags: [], // Custom categories start with no tags
    );

    widget.onCategoryCreated(newCategory);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasName = _nameController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'New Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // Preview
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedColor.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    _selectedIcon.icon,
                    color: _selectedColor.color,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Name Input
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Gym, Travel, Gaming',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Icon Picker
                  Row(
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SELECT ICON',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final iconOption = availableIcons[index];
                      final isSelected = _selectedIcon.name == iconOption.name;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = iconOption),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _selectedColor.color.withOpacity(0.15)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF10b981).withOpacity(0.5)
                                  : Colors.white.withOpacity(0.05),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            iconOption.icon,
                            size: 24,
                            color: isSelected
                                ? _selectedColor.color
                                : Colors.grey[500],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Color Picker
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SELECT COLOR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: availableColors.length,
                    itemBuilder: (context, index) {
                      final colorOption = availableColors[index];
                      final isSelected = _selectedColor.label == colorOption.label;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = colorOption),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colorOption.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                colorOption.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: GestureDetector(
              onTap: hasName ? _handleSave : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: hasName
                      ? const Color(0xFF10b981)
                      : const Color(0xFF1e293b),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: hasName
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10b981).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: hasName ? Colors.white : Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check,
                      color: hasName ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
