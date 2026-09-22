import 'package:flutter/material.dart';

/// The customer's delivery code, and who is bringing the order
/// (Order Ops §11; Kunde design delivery-code card + ID-kort).
///
/// The card appears on its own, unprompted, when the order needs a code — a
/// customer should not have to hunt for it while a courier waits at the door.
/// It says *why* the code is there, because an unexplained extra step reads as
/// friction, and an explained one reads as care.
class DeliveryCodeCard extends StatelessWidget {
  const DeliveryCodeCard({
    super.key,
    required this.pin,
    required this.reasonCopy,
    this.qrPayload,
  });

  /// Four digits the customer reads out or the courier types.
  final String pin;

  /// Server-provided explanation (value, age-restricted, own choice, …).
  final String reasonCopy;

  final String? qrPayload;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('ops-delivery-code-card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Kode ved levering',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(reasonCopy, key: const Key('ops-delivery-code-reason')),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Text(
                  // Spaced so it can be read aloud at a door without stumbling.
                  pin.split('').join(' '),
                  key: const Key('ops-delivery-code-pin'),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                if (qrPayload != null)
                  Container(
                    key: const Key('ops-delivery-code-qr'),
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('QR', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Vis koden til budet. Denne leveringen kan ikke settes igjen ved døren.',
              key: Key('ops-delivery-code-no-leave-at-door'),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// The courier's ID card, visible from tracking before they arrive.
///
/// Someone is about to knock on your door; being able to see who, in advance,
/// costs us nothing and is worth a lot at 22:00.
class CourierIdCard extends StatelessWidget {
  const CourierIdCard({
    super.key,
    required this.courierName,
    this.photoUrl,
    this.verifiedOn,
    this.vehicle,
  });

  final String courierName;
  final String? photoUrl;

  /// When BankID verification was completed.
  final DateTime? verifiedOn;

  final String? vehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('ops-courier-id-card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              key: const Key('ops-courier-avatar'),
              radius: 24,
              backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
              child: photoUrl == null ? const Icon(Icons.person_outline) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    courierName,
                    key: const Key('ops-courier-name'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  if (vehicle != null)
                    Text(vehicle!, key: const Key('ops-courier-vehicle')),
                  if (verifiedOn != null)
                    Text(
                      'Identitet bekreftet ${verifiedOn!.year}',
                      key: const Key('ops-courier-verified'),
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
