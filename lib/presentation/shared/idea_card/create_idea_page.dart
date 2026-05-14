// presentation/idea/view/create_idea_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:outnest/application/app_state/current_user_data_providers/current_user_identity_provider.dart';
import 'package:outnest/application/providers/idea_providers.dart';
import 'package:outnest/core/utils/debug/android_image_url_fixer.dart';
import 'package:outnest/domain/services/file_service.dart';

/// "Fikir Balonu" composer (screenshot 2).
///
/// Single-purpose page: 250-char input, a comments-enabled toggle,
/// and a send button in the header. No drafts, no media — keeps the
/// surface area small and the create flow snappy.
class CreateIdeaPage extends HookConsumerWidget {
  const CreateIdeaPage({super.key});

  static const _maxLength = 250;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final commentsEnabled = useState(true);
    final isSubmitting = useState(false);
    final length = useState(0);

    useEffect(() {
      void listener() => length.value = controller.text.characters.length;
      controller.addListener(listener);
      // Autofocus on open so the keyboard shows without an extra tap.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
      return () => controller.removeListener(listener);
    }, [controller]);

    final user = ref.watch(currentUserEntityProvider).requireValue;
    final canSubmit =
        length.value > 0 && length.value <= _maxLength && !isSubmitting.value;

    Future<void> submit() async {
      if (!canSubmit) return;
      isSubmitting.value = true;
      try {
        await ref
            .read(ideaRepositoryProvider)
            .createIdea(
              content: controller.text.trim(),
              commentsEnabled: commentsEnabled.value,
            );
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fikir gönderilemedi: $e')),
          );
        }
        isSubmitting.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Fikir Balonu',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
            fontSize: 17.sp,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: _SendButton(
              enabled: canSubmit,
              onTap: submit,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(url: user?.profileImageUrl),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLength: _maxLength,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_maxLength),
                        ],
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16.sp,
                          color: const Color(0xFF1A1A1A),
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ne düşünüyorsun?',
                          hintStyle: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16.sp,
                            color: const Color(0xFF8E8E93),
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          isCollapsed: true,
                          contentPadding: EdgeInsets.only(top: 10.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '${length.value}/$_maxLength',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 12.sp,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ),
              const Divider(height: 24, color: Color(0xFFEFEFEF)),
              Row(
                children: [
                  Icon(
                    Icons.add_box_outlined,
                    size: 20.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Yorumlar',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Switch.adaptive(
                    value: commentsEnabled.value,
                    onChanged: (v) => commentsEnabled.value = v,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty && url!.startsWith('http');
    return CircleAvatar(
      radius: 20.r,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: hasUrl
          ? CachedNetworkImageProvider(fixEmulatorUrl(url!))
          : AssetImage(FileService.defaultProfileImageUrl()) as ImageProvider,
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? const Color(0xFFFF6B4A) // turuncu/coral, screenshot 2 ile uyumlu
        : const Color(0xFFE5E5EA);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          Symbols.arrow_upward,
          color: Colors.white,
          size: 20.sp,
        ),
      ),
    );
  }
}
