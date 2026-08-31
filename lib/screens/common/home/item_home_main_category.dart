import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/utils.dart';
import 'home_dl.dart';

class ItemHomeMainCategory extends StatelessWidget {
  final ServicesItem servicesItem;
  final double? radius;

  const ItemHomeMainCategory(
      {super.key, required this.servicesItem, this.radius});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: deviceWidth * 0.2,
          width: deviceWidth * 0.25,
          padding: EdgeInsets.all(deviceWidth * 0.05),
          decoration: BoxDecoration(
              color: colorWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 3,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFAFAFA), width: 2)),
          child: SvgPicture.network(
            servicesItem.serviceCategoryIcon,
            alignment: Alignment.center,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: deviceWidth * 0.2,
          child: Text(servicesItem.serviceCategoryName,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}
