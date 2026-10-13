import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LiquidGlassScaffold extends StatelessWidget {
  final Widget child;
  final Color? backgroundColors;
  final String? title;
  final Widget? trailing;
  final Widget? leading;
  final bool useScrollView;
  final Future<void> Function()? onRefresh;
  final bool resizeToAvoidBottomInset;

  const LiquidGlassScaffold({
    super.key,
    required this.child,
    this.backgroundColors,
    this.title,
    this.trailing,
    this.leading,
    this.useScrollView = true,
    this.onRefresh,
    this.resizeToAvoidBottomInset = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColors ?? AppTheme.kBackgroundLight,
      navigationBar: title != null
          ? CupertinoNavigationBar(
              transitionBetweenRoutes: false,
              backgroundColor: (backgroundColors ?? AppTheme.kBackgroundLight)
                  .withValues(alpha: 0.8),
              border: null,
              leading:
                  leading ??
                  (Navigator.of(context).canPop()
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Icon(
                            CupertinoIcons.back,
                            color: AppTheme.kBrand,
                          ),
                        )
                      : null),
              middle: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title!,
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing: trailing,
              previousPageTitle: "Tr? v?",
            )
          : null,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: Colors.transparent,
          child: useScrollView
              ? CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    if (onRefresh != null)
                      CupertinoSliverRefreshControl(onRefresh: onRefresh),
                    SliverToBoxAdapter(child: child),
                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
                      ),
                    ),
                  ],
                )
              : child,
        ),
      ),
    );
  }
}
