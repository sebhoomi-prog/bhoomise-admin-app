import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/util/unsplash_raster_url.dart';
import '../../../data/login_ui_config.dart';

/// Hero image — Figma login frame (`9:675`), asset URLs from [LoginUiConfig].
class FigmaLoginHeroBlock extends StatelessWidget {
  const FigmaLoginHeroBlock({
    super.key,
    required this.cfg,
    required this.brand,
  });

  final LoginUiConfig cfg;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
          color: DesignTokens.figmaSearchBarFill.withValues(alpha: 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          unsplashAsJpeg(cfg.heroImageUrl),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: brand,
              ),
            );
          },
          errorBuilder: (context, error, stack) {
            return Image.network(
              unsplashAsJpeg(cfg.heroImageUrlAlt),
              fit: BoxFit.cover,
              errorBuilder: (context, e, s) {
                return Container(
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.agriculture_rounded,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
