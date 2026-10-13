import 'package:flutter/material.dart';

class IOSGroupedSection extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final EdgeInsets margin;

  const IOSGroupedSection({
    super.key,
    required this.children,
    this.title,
    this.margin = const EdgeInsets.symmetric(horizontal: 0),
  });

  @override
  Widget build(BuildContext context) {
    final validChildren = children
        .where((c) => c is! SizedBox || (c.height ?? 1) > 0)
        .toList();
    if (validChildren.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 16, bottom: 8),
            child: Text(
              title!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                letterSpacing: 0.8,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(validChildren.length, (index) {
              return Column(
                children: [
                  validChildren[index],
                  if (index < validChildren.length - 1)
                    Container(
                      margin: const EdgeInsets.only(left: 56),
                      height: 0.5,
                      color: const Color(0xFFE5E7EA),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
