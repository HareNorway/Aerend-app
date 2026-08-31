import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import 'vipps_bloc.dart';

class VippsIntegration extends StatefulWidget {
  const VippsIntegration({super.key});

  @override
  VippsIntegrationState createState() => VippsIntegrationState();
}

class VippsIntegrationState extends State<VippsIntegration> {
  VippsIntegrationBloc? _bloc;
  var textStyle =
      bodyText(fontSize: textSizeMediumBig, fontWeight: FontWeight.w500);

  double formSpacingVertical = deviceHeight * 0.025;

  @override
  void didChangeDependencies() {
    _bloc = VippsIntegrationBloc(context, this);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bloc!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorGray,
      body: _buildVippsIntegration(context),
    );
  }

  _buildVippsIntegration(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned(
                top: deviceHeight * 0.1,
                left: 30,
                right: 30,
                child: Column(
                  children: [
                    Center(
                      child: LoadImageSimple(
                        height: deviceHeight * 0.3,
                        image: 'assets/images/dialog_payment_img.png',
                      ),
                    ),
                    const Text(
                      'You have to verfy your payment method to use this app.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () => {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue with  ',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: bodyText(
                                textColor: colorWhite,
                                fontSize: 0.03,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Image.asset(
                              "assets/images/vipps_logo.png",
                              width: deviceAverageSize * 0.1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/google_standard_color.png",
                            width: deviceAverageSize * 0.04,
                          ),
                          Text(
                            ' Pay',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: bodyText(
                              fontSize: 0.05,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/apple_standard_color.png",
                            width: deviceAverageSize * 0.04,
                          ),
                          Text(
                            ' Pay',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: bodyText(
                              textColor: colorWhite,
                              fontSize: 0.05,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: deviceHeight * 0.2,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
