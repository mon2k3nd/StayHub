import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/providers/feature_flag_provider.dart';
import 'dart:async' show unawaited;

class AdminFeatureTogglesScreen extends ConsumerWidget {
  const AdminFeatureTogglesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagProvider);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text(
              'Feature Toggles',
              style: TextStyle(color: CupertinoColors.black),
            ),
            backgroundColor: Color(0x00000000),
            border: null,
          ),
          SliverToBoxAdapter(
            child: flags.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 12),
                          child: Text(
                            'SYSTEM FLAGS',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...flags.keys.map((key) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GlassContainer(
                              blur: 15,
                              color: const Color(0x66FFFFFF),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            flags[key] == true
                                                ? 'Active - System Wide'
                                                : 'Disabled - System Wide',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: flags[key] == true
                                                  ? CupertinoColors.activeGreen
                                                  : CupertinoColors.systemRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    CupertinoSwitch(
                                      value: flags[key] ?? false,
                                      onChanged: (val) {
                                        unawaited(
                                          ref
                                              .read(
                                                featureFlagProvider.notifier,
                                              )
                                              .toggleFlag(key, val),
                                        );
                                      },
                                      activeTrackColor:
                                          CupertinoColors.activeGreen,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 100), // spacing for bottom nav
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
