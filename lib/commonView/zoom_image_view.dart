import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constant/constant.dart';

class ZoomImageView extends StatelessWidget {
  final String image;

  const ZoomImageView({super.key, required this.image});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black54,
        body: Builder(
          builder: (context) => Stack(
            children: [
              Hero(
                createRectTween: (Rect? begin, Rect? end) {
                  return MaterialRectCenterArcTween(begin: begin, end: end);
                },
                tag: image,
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(image),
                  backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                  minScale: PhotoViewComputedScale.contained,
                  filterQuality: FilterQuality.high,
                ),
              ),
              SafeArea(
                child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Container(
                        width: deviceAverageSize * 0.055,
                        height: deviceAverageSize * 0.055,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorTransBlack,
                        ),
                        padding: EdgeInsets.all(deviceAverageSize * 0.005),
                        margin: EdgeInsetsDirectional.only(top: deviceAverageSize * 0.02, end: deviceAverageSize * 0.02),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: deviceAverageSize * 0.045,
                          color: colorWhite,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
}
