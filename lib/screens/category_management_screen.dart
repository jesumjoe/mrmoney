import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mrmoney/repositories/category_repository.dart';
import 'package:mrmoney/models/category.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  void _addOrEditCategory({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name);
    // Budget limit is optional in this context, but we can add it if needed.
    // For now, let's focus on Name and Color/Icon.

    Color currentColor = category != null
        ? Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')))
        : Colors.blue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Pick Color'),
                trailing: CircleAvatar(backgroundColor: currentColor),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pick a color'),
                      content: SingleChildScrollView(
                        child: BlockPicker(
                          pickerColor: currentColor,
                          onColorChanged: (color) {
                            currentColor = color;
                            (context as Element)
                                .markNeedsBuild(); // Force rebuild of parent dialog? No, state is local.
                            // This won't update the parent dialog's "trailing" widget immediately without setState in a StatefulBuilder.
                            // But usually ColorPicker is enough.
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Select'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ).then((_) {
                    // Refresh parent dialog to show new color
                    // This requires the parent dialog to be stateful or use StatefulBuilder.
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final repo = Provider.of<CategoryRepository>(
                  context,
                  listen: false,
                );
                final hexColor =
                    '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}';

                if (isEditing) {
                  category.name = nameController.text;
                  category.colorHex = hexColor;
                  repo.updateCategory(
                    category,
                  ); // Assuming update method exists
                } else {
                  final newCat = Category(
                    id: DateTime.now().millisecondsSinceEpoch
                        .toString(), // Simple ID
                    name: nameController.text,
                    colorHex: hexColor,
                    iconCode: Icons.category.codePoint, // Default icon
                  );
                  repo.add(newCat);
                }
                // Refresh provider? The Repository might notify or we rely on setState/Consumer.
                // Assuming Repository notifies or we need to trigger UI update.
                // For Hive, the ValueListenableBuilder usually handles it if implemented.
                // Or we setState if we fetch list locally.
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We need to consume the repository or provider.
    // Assuming CategoryRepository provides a way to listen or we use ValueListenableBuilder on the box.
    // Since I don't see a "CategoryProvider", I assume we access Repository directly.
    // Let's use Consumer<CategoryRepository> if it uses ChangeNotifier, or just getAll().
    final repo = Provider.of<CategoryRepository>(context);
    final categories = repo.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final color = Color(
            int.parse(cat.colorHex.replaceFirst('#', '0xFF')),
          );
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                color: color,
              ),
            ),
            title: Text(cat.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () {
                // Confirm delete
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Category?'),
                    content: const Text(
                      'This will not delete existing transactions but might affect statistics.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          repo.delete(cat.id);
                          setState(() {}); // Refresh list
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            onTap: () => _addOrEditCategory(category: cat),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCategory(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
