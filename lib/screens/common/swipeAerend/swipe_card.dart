import 'package:flutter/material.dart';
import '../../../utils/utils.dart';

import 'swipe_aerend_dl.dart';

class SwipeCard extends StatelessWidget {
  final SwipeCardModel candidate;

  const SwipeCard({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: LoadImageSimple(
            width: deviceHeight * 0.65,
            height: deviceHeight * 0.65,
            image: candidate.productImage,
            imageFit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: LoadImageSimple(
                        image: candidate.storeLogo, height: 35, width: 35),
                  ),
                  // const SizedBox(width: 10),
                  // Text(
                  //   candidate.storeName,
                  //   style: const TextStyle(
                  //     fontSize: 26,
                  //     color: colorWhite,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 13),
                    child: Text(languages.open,
                        style: const TextStyle(fontSize: 16, color: colorWhite)),
                  ),
                ],
              ),
              // const Spacer(),
              // Text(
              //   candidate.productName,
              //   style: const TextStyle(
              //     fontSize: 30,
              //     color: colorWhite,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // Text(candidate.description,
              //     style: const TextStyle(color: colorWhite)),
            ],
          ),
        )
      ],
    );
  }
}
