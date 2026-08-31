import 'package:flutter/material.dart';

import '../../dugnad/dugnad_club_theme.dart';
import '../../dugnad/widgets/dugnad_rise_in.dart';
import '../../dugnad/widgets/dugnad_subpage_shell.dart';
import '../consent/consent_legal_docs.dart';
import 'account_widgets.dart';
import 'settings_design_kit.dart';

/// Legal document shell — `.tk-head` header over a club-themed page with the
/// copy in a single white shadow-card (LegalDocScreen language).
class _LegalDocScreen extends StatelessWidget {
  const _LegalDocScreen({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: DugnadFixedTypography(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountTkHead(
                title: title,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  // .ae-body { padding: 0 18px 120px }
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  child: DugnadRiseIn(
                    delay: const Duration(milliseconds: 120),
                    child: DgDocCard(children: children),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    const doc = kConsentPrivacyDoc;
    final children = <Widget>[];
    var firstHeading = true;
    for (final block in doc.blocks) {
      if (block.h != null) {
        children.add(_h(context, block.h!, top: firstHeading ? 0 : 20));
        firstHeading = false;
      }
      if (block.p != null) {
        children.add(_p(block.p!));
      }
      if (block.list != null) {
        for (final item in block.list!) {
          children.add(_bullet(context, item));
        }
      }
    }
    return _LegalDocScreen(title: doc.title, children: children);
  }
}

/// Document heading — 17/800/-0.01em club text.
Widget _h(BuildContext context, String text, {double top = 20}) => Padding(
      padding: EdgeInsets.only(top: top, bottom: 6),
      child: Text(text, style: dgDocHeading(context)),
    );

/// Document paragraph — 13.5/600, lh 1.55, gray-700.
Widget _p(String text, {double top = 0}) => Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Text(text, style: dgDocBody()),
    );

/// Bulleted item — 4px club-primary dot plus paragraph type.
Widget _bullet(BuildContext context, String text) {
  final theme = context.dugnadTheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 2, right: 12),
          child: SizedBox(
            width: 4,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Expanded(child: Text(text, style: dgDocBody())),
      ],
    ),
  );
}

class TermsOfService extends StatefulWidget {
  const TermsOfService({super.key});

  @override
  State<TermsOfService> createState() => _TermsOfServiceState();
}

class _TermsOfServiceState extends State<TermsOfService> {
  @override
  Widget build(BuildContext context) {
    return _LegalDocScreen(
      title: 'Terms Of Service',
      children: [
        _h(context, 'Welcome to Reen Dugnad!', top: 0),
        _p(
          'These terms and conditions outline the rules and regulations for the use of Reen Dugnad\'s mobile application and delivery services.',
        ),
        _p(
          'By accessing this mobile application, we assume you accept these terms and conditions. Do not continue to use Reen Dugnad if you do not agree to take all of the terms and conditions stated on this page.',
        ),
        _p(
          'The following terminology applies to these Terms and Conditions, Privacy Statement, and Disclaimer Notice and all Agreements: "Client," "You," and "Your" refers to you, the person accessing this mobile application and accepting the Company\'s terms and conditions. "The Company," "Ourselves," "We," "Our," and "Us," refers to our Company. "Party," "Parties," or "Us," refers to both the Client and ourselves, or either the Client or ourselves. All terms refer to the offer, acceptance, and consideration of payment necessary to undertake the process of our assistance to the Client in the most appropriate manner for the express purpose of meeting the \'s needs in respect of the provision of the \'s stated services, in accordance with and subject to, prevailing law.',
        ),
        _h(context, 'License'),
        _p(
          'Unless otherwise stated, Reen Dugnad and/or its licensors own the intellectual property rights for all material on Reen Dugnad. All intellectual property rights are reserved. You may access this from Reen Dugnad for your own personal use subjected to restrictions set in these terms and conditions.',
        ),
        _h(context, 'You must not:'),
        _bullet(context, 'Republish material from Reen Dugnad'),
        _bullet(context, 'Sell, rent, or sub-license material from Reen Dugnad'),
        _bullet(context, 'Reproduce, duplicate, or copy material from Reen Dugnad'),
        _bullet(context, 'Redistribute content from Reen Dugnad'),
        _h(context, 'This Agreement shall begin on Reen Dugnad:'),
        _p(
          'Parts of this mobile application offer an opportunity for users to post and exchange opinions and information in certain areas of the website. Reen Dugnad does not filter, edit, publish, or review Comments prior to their presence on the mobile application. Comments do not reflect the views and opinions of Reen Dugnad, its agents, and/or affiliates.',
        ),
      ],
    );
  }
}

class AvaibilityStatement extends StatefulWidget {
  const AvaibilityStatement({super.key});

  @override
  State<AvaibilityStatement> createState() => _AvaibilityStatementState();
}

class _AvaibilityStatementState extends State<AvaibilityStatement> {
  @override
  Widget build(BuildContext context) {
    return _LegalDocScreen(
      title: 'Avaibility Statement',
      children: [
        _h(context, 'Updated 02 April 2024', top: 0),
        _p(
          'At Reen Dugnad, we strive to maintain optimal availability of our services to ensure a seamless experience for our users. While we endeavor to provide uninterrupted access to our mobile application and delivery services, occasional downtime may occur due to maintenance, updates, or unforeseen technical issues.',
        ),
        _p(
          'We are committed to promptly addressing any issues that may arise and restoring full functionality as quickly as possible. Our team works tirelessly to minimize disruptions and maximize uptime, ensuring that you can rely on Reen Dugnad whenever you need us.',
        ),
        _p(
          'Should you encounter any difficulties accessing our services, please don\'t hesitate to contact our support team for assistance. Your satisfaction is our priority, and we appreciate your understanding and patience as we work to deliver the best possible experience to you.',
        ),
      ],
    );
  }
}
