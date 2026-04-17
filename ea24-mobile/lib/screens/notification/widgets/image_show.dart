import 'package:flutter/material.dart';

import '../../../custom/useful_elements.dart';

class ImageShow extends StatelessWidget {
  final String notificationShowType;
  final String image;

  const ImageShow(
      {super.key, required this.notificationShowType, required this.image});

  @override
  Widget build(BuildContext context) {
    if (notificationShowType == 'only_text') {
      return SizedBox.shrink();
    }

    if (notificationShowType == 'design_1') {
      return Container(
        child: UsefulElements.roundImageWithPlaceholder(
            elevation: 1,
            borderWidth: 0,
            url: image,
            width: 38.0,
            height: 40.0,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(0)),
      );
    }
    if (notificationShowType == 'design_2') {
      return Container(
        child: UsefulElements.roundImageWithPlaceholder(
            elevation: 1,
            borderWidth: 0,
            url: image,
            width: 38.0,
            height: 40.0,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8)),
      );
    }
    if (notificationShowType == 'design_3') {
      return Container(
        child: UsefulElements.roundImageWithPlaceholder(
            elevation: 1,
            borderWidth: 0,
            url: image,
            width: 38.0,
            height: 40.0,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(116)),
      );
    }

    return Container();
  }
}
