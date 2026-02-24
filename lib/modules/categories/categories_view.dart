import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../routes/app_routes.dart';
import 'categories_controller.dart';
import 'widgets/category_card.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CategoriesController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Categories', style: AppFonts.h6),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed(AppRoutes.categoryForm),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.m, AppSpacing.s, AppSpacing.m, AppSpacing.xs),
            child: Obx(() => TextField(
                  onChanged: (v) => ctrl.searchQuery.value = v,
                  controller: ctrl.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: ctrl.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              ctrl.searchController.clear();
                              ctrl.searchQuery.value = '';
                            },
                          )
                        : null,
                  ),
                )),
          ),
          Expanded(
            child: Obx(() {
              final list = ctrl.filtered;
              final sym = ctrl.settings.currencySymbol.value;

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.category_outlined,
                          size: 64, color: AppColors.textMuted),
                      const SizedBox(height: AppSpacing.m),
                      Text('No categories yet', style: AppFonts.h6),
                      const SizedBox(height: AppSpacing.s),
                      Text('Tap + to create your first budget category',
                          style: AppFonts.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: AppSpacing.l),
                      FilledButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.categoryForm),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Category'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.m),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final cat = list[i];
                  return Dismissible(
                    key: Key(cat.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.l),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                      ),
                      child:
                          const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Category'),
                          content: Text(
                              'Delete "${cat.name}"? This will not delete its transactions.'),
                          actions: [
                            TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Cancel')),
                            FilledButton(
                                onPressed: () => Get.back(result: true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) => ctrl.deleteCategory(cat),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: CategoryCard(
                        category: cat,
                        spent: ctrl.spentForCategory(cat.id),
                        currencySymbol: sym,
                        onTap: () => Get.toNamed(
                          AppRoutes.transactions,
                          arguments: {
                            'categoryId': cat.id,
                            'categoryName': cat.name
                          },
                        ),
                        onEdit: () => Get.toNamed(
                          AppRoutes.categoryForm,
                          arguments: cat,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
