import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class CardSkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const CardSkeletonList({super.key, this.count = 4, this.itemHeight = 100});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) {
        return SkeletonLoader(
          width: double.infinity,
          height: itemHeight,
          margin: const EdgeInsets.only(bottom: 16),
        );
      },
    );
  }
}
