import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aerend_customer/screens/common/orderHistory/order_history_dl.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

import '../../../utils/utils.dart';

class OrderHistoryDetail extends StatefulWidget {
  final OrderHistoryListItem orderDetail;

  const OrderHistoryDetail({super.key, required this.orderDetail});

  @override
  State<OrderHistoryDetail> createState() => _OrderHistoryDetailState();
}

class _OrderHistoryDetailState extends State<OrderHistoryDetail> {
  bool isEmpty = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScSaasThemeTokens.background,
      appBar: AppBar(
        backgroundColor: ScSaasThemeTokens.card,
        automaticallyImplyLeading: false,
        foregroundColor: ScSaasThemeTokens.text,
        toolbarHeight: 50,
        elevation: 0,
        title: Stack(
          children: [
            SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  languages.orderHistory,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 15,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScSaasThemeTokens.rowHover,
                  elevation: 2,
                  padding: const EdgeInsets.all(10),
                  shape: const CircleBorder(),
                ),
                child: SvgPicture.asset(
                  'assets/svgs/icons/back.svg',
                  height: 18,
                  width: 18,
                  colorFilter: const ColorFilter.mode(
                    ScSaasThemeTokens.text,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ScSaasThemeTokens.background,
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(deviceAverageSize * 0.0),
          ),
        ),
        child: ListView(
          children: [
            Text(
              '${widget.orderDetail.serviceDate} ${widget.orderDetail.serviceTime}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Text(
              widget.orderDetail.storeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Flexible(
                  child: Text(
                    'MW8H+2V8, Samarkand, Samarqand Region, Uzbekistan',
                    softWrap: true,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // TextButton(
                //   onPressed: () {},
                //   child: Container(
                //     padding:
                //         const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(8.0),
                //       color: Colors.red.withOpacity(0.1),
                //     ),
                //     child: const Text(
                //       'More Information',
                //       style: TextStyle(
                //         color: colorPrimary,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
                const Text(
                  '4,9 (12K ratings) ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.circle, size: 5),
                const Text(
                  ' \$\$\$\$\$ ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.circle, size: 5),
                const Text(
                  ' 1km ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.circle, size: 5),
                const Text(
                  ' 10min ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ScSaasThemeTokens.card,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: ScSaasThemeTokens.border.withOpacity(0.7),
                    spreadRadius: 0.1,
                    blurRadius: 10,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      const Text(
                        'Order number',
                        style: TextStyle(
                          fontSize: 15,
                          color: ScSaasThemeTokens.muted,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: ScSaasThemeTokens.rowHover,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          '#ffdrae334',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text(
                        'Order from',
                        style: TextStyle(
                          fontSize: 15,
                          color: ScSaasThemeTokens.muted,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Le St Andre Cafe',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text(
                        'Delivery address',
                        style: TextStyle(
                          fontSize: 15,
                          color: ScSaasThemeTokens.muted,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Lorem ipsum dolor sit a...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'More',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    'Order Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),
                  const Row(
                    children: [
                      Text(
                        '1x    ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cruch Rush Pizza',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 7),
                            Row(
                              children: [
                                Text(
                                  'Regular Cheese  ',
                                  style: TextStyle(
                                    color: ScSaasThemeTokens.muted,
                                  ),
                                ),
                                Icon(
                                  Icons.circle,
                                  color: ScSaasThemeTokens.muted,
                                  size: 5,
                                ),
                                Text(
                                  '  Medium',
                                  style: TextStyle(
                                    color: ScSaasThemeTokens.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$\$\$',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Row(
                    children: [
                      Text(
                        '2x    ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nasi Kandar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 7),
                            Row(
                              children: [
                                Text(
                                  'Curry Chicken  ',
                                  style: TextStyle(
                                    color: ScSaasThemeTokens.muted,
                                  ),
                                ),
                                Icon(
                                  Icons.circle,
                                  color: ScSaasThemeTokens.muted,
                                  size: 5,
                                ),
                                Text(
                                  '  Basmati Rice',
                                  style: TextStyle(
                                    color: ScSaasThemeTokens.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$\$\$',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 18,
                          color: ScSaasThemeTokens.muted,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '\$\$\$',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text(
                        'Delivery fee',
                        style: TextStyle(
                          fontSize: 18,
                          color: ScSaasThemeTokens.muted,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '\$\$\$',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text(
                        'Order fee',
                        style: TextStyle(
                          fontSize: 18,
                          color: ScSaasThemeTokens.muted,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '\$\$\$',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: ScSaasThemeTokens.card,
                  backgroundColor: ScSaasThemeTokens.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(languages.orderContactSupport),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
