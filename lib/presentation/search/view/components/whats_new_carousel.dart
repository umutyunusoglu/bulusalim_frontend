import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/get_it_service_locators/get_it_init.dart';
import 'package:outnest/core/constants/theme/color_themes.dart';
import 'package:outnest/domain/services/remote_config_service.dart';

class WhatsNewItem {
  WhatsNewItem({required this.imageUrl});

  factory WhatsNewItem.fromJson(Map<String, dynamic> json) {
    return WhatsNewItem(
      imageUrl: (json['image_url'] as String? ?? '').trim(),
    );
  }
  final String imageUrl;
}

final whatsNewProvider = FutureProvider<List<WhatsNewItem>>((ref) async {
  try {
    final remoteConfig = getIt<RemoteConfigService>();
    final jsonStr = await remoteConfig.getValue<String>('whats_new_carousel');

    if (jsonStr.isEmpty || jsonStr == '[]') return [];

    final data = jsonDecode(jsonStr) as List<dynamic>;
    return data
        .map((e) => WhatsNewItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('❌ WhatsNew Error: $e');
    return [];
  }
});

class WhatsNewCarousel extends HookConsumerWidget {
  const WhatsNewCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(whatsNewProvider);
    final currentIndex = useState(0);

    return itemsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final contentWidth = MediaQuery.of(context).size.width - 32; // padding 16 each side
        final pageHeight = contentWidth * 3 / 4;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Symbols.local_fire_department,
                    color: AppColors.primaryColor,
                    size: 20,
                    weight: 600,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Ne Var Ne Yok',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: pageHeight,

              child: PageView.builder(
                itemCount: items.length,
                onPageChanged: (index) => currentIndex.value = index,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: item.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                fit: BoxFit.cover,
                              placeholder: (context, url) => ColoredBox(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => ColoredBox(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const ColoredBox(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            if (items.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: currentIndex.value == index
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
