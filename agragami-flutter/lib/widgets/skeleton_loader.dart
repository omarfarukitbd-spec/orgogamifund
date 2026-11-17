import 'package:flutter/material.dart';

/// ডেটা আসার সময় ঝাপসা বাক্স দেখাবে — ফাঁকা সাদা স্ক্রিন নয়।
class SkeletonLoader extends StatelessWidget {
  final double height;
  final double width;

  const SkeletonLoader({super.key, this.height = 16, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// কার্ডের জায়গায় ৩টা ঝাপসা কার্ড।
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: 160),
              SizedBox(height: 10),
              SkeletonLoader(width: 240),
            ],
          ),
        ),
      ),
    );
  }
}
