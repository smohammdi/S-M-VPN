import 'package:fluent_ui/fluent_ui.dart';
import 'package:sm_vpn/l10n/app_strings.dart';
import 'package:sm_vpn/widgets/subscriptions_tab.dart';

/// Standalone subscriptions page. Its content lives in
/// [SubscriptionsTab] so the Servers screen tab and this page share
/// one implementation with no duplication.
class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text(S.of(context, 'subs_title'),
            style:
                const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
      content: const SubscriptionsTab(),
    );
  }
}
