import 'package:flutter/material.dart';

import '../../../utils/utils.dart';

class Delivered extends StatefulWidget {
  final List? orderList;

  const Delivered({super.key, this.orderList});

  @override
  DeliveredState createState() => DeliveredState();
}

class DeliveredState extends State<Delivered> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorMainBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorMainBackground,
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        title: SizedBox(
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Center(
                child: Text(
                  'Delivered',
                  style: TextStyle(
                    color: colorBlack,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: ElevatedButton(
                  onPressed: () => {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorWhite,
                    elevation: 2,
                    padding: const EdgeInsets.all(11),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: colorBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const LoadImageSimple(
              image: 'assets/images/delivered.png',
              width: 223,
              height: 187,
            ),
            const SizedBox(height: 20),
            const Center(
              child: SizedBox(
                width: 300,
                child: Text(
                  'Your meal is delivered successfully. Enjoy your meal!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              height: 280,
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0.1,
                    blurRadius: 10,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order number',
                        style: TextStyle(color: colorMainGray),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          color: colorGray,
                        ),
                        child: const Text(
                          '#ffdrae334',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order from',
                        style: TextStyle(color: colorMainGray),
                      ),
                      Text(
                        'Le St Andre Cafe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery address',
                              style: TextStyle(color: colorMainGray),
                            ),
                            Text(
                              'Lorem ipsum dolor sit a...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 30,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(2),
                            ),
                            onPressed: () {},
                            child: const Text(
                              'More',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (include delivery cost)',
                        style: TextStyle(color: colorMainGray),
                      ),
                      Text(
                        '\$\$\$',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => {},
              child: const Text(
                'Share your order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}
