import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aerend_customer/screens/common/addCard/add_card.dart';

import '../../../utils/utils.dart';

class PaymentMethod extends StatefulWidget {
  const PaymentMethod({super.key});

  @override
  State<PaymentMethod> createState() => _PaymentMethodState();
}

class _PaymentMethodState extends State<PaymentMethod> {
  bool isEmpty = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : colorBlack,
        toolbarHeight: 80,
        elevation: 0,
        title: Stack(
          children: [
            const SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 24,
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
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    elevation: 2,
                    padding: const EdgeInsets.all(10),
                    shape: const CircleBorder()),
                child: SvgPicture.asset(
                  'assets/svgs/icons/back.svg',
                  height: 18,
                  width: 18,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
                ),
              ),
            )
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : colorBlack,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  SvgPicture.asset('assets/svgs/mastercard.svg', width: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Card ***118',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => openScreenWithResult(context, const AddCard()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : colorBlack,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add New Card',
                    style: TextStyle(fontSize: 16, color: colorMainLightGray),
                  ),
                  Icon(Icons.add, color: colorMainLightGray, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
