import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/animations/animations.dart';
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
              final currency = ctrl.settings.currency;
              // Materialised HERE, inside the Obx body, exactly as the
              // dashboard does it (dashboard_view.dart). Reading `transactions`
              // only inside `itemBuilder` runs after the observer scope has
              // closed, so the transaction list was never registered as a
              // dependency of this Obx: spend stayed at 0 until the tab was
              // re-entered, which reads as "the save failed" on a money screen
              // (UI-02).
              final spentMinorByCategory = {
                for (final cat in list)
                  cat.id: ctrl.spentForCategoryMinor(cat.id)
              };

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined,
                          size: 64, color: context.semanticColors.textMuted),
                      const SizedBox(height: AppSpacing.m),
                      Text('No categories yet', style: AppFonts.h6),
                      const SizedBox(height: AppSpacing.s),
                      Text('Tap + to create your first budget category',
                          style: AppFonts.bodySmall.copyWith(
                              color: context.semanticColors.textMuted)),
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
                  final card = FadeSlideItem(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: CategoryCard(
                        category: cat,
                        spentMinor: spentMinorByCategory[cat.id] ?? 0,
                        currency: currency,
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

                  // The reserved bucket has no swipe-to-delete: it is where
                  // transactions go when their category is deleted, so the
                  // repository refuses to delete it. The affordance is absent
                  // rather than present-and-refusing (F-01 rule 4).
                  if (isReservedCategoryName(cat.name)) return card;

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
                          // Names the destination before the user confirms:
                          // "will not delete its transactions" left them
                          // wondering where the money went (F-01 rule 3).
                          content: Text('Delete "${cat.name}"? Its '
                              'transactions are kept — they move to '
                              '$kUncategorisedCategoryName.'),
                          actions: [
                            TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Cancel')),
                            // Error-coloured text, not a green FilledButton:
                            // green reads as "safe/go" everywhere else in this
                            // app (N9).
                            TextButton(
                                onPressed: () => Get.back(result: true),
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) => ctrl.deleteCategory(cat),
                    child: card,
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
