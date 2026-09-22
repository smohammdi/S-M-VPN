import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart' as m;
import 'package:provider/provider.dart';
import 'package:sm_vpn/services/v2ray_service.dart';
import 'package:sm_vpn/models/subscription.dart';
import 'package:sm_vpn/theme/app_theme.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<Subscription> _subscriptions = [];
  Subscription? _suggestedSubscription;
  bool _isLoading = true;
  bool _isSuggestedActive = false;

  static const Color _success = Color(0xFF10B981);
  static const Color _danger = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initializeSuggestedSubscription();
    _loadSubscriptions();
  }

  void _initializeSuggestedSubscription() {
    _suggestedSubscription = Subscription(
      id: 'suggested_cloudflare_plus',
      name: 'Suggested - CloudflarePlus',
      url: 'https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/refs/heads/main/proxy',
      lastUpdate: DateTime.now(),
      configCount: 0,
    );
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
    });

    final service = Provider.of<V2RayService>(context, listen: false);
    final subs = await service.loadSubscriptions();

    final hasSuggested = subs.any((sub) => sub.id == 'suggested_cloudflare_plus');
    if (hasSuggested) {
      _isSuggestedActive = true;
    }

    setState(() {
      _subscriptions = subs;
      _isLoading = false;
    });
  }

  Color _secondaryText(BuildContext context) {
    return FluentTheme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Subscriptions', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        commandBar: FilledButton(
          onPressed: () {
            HapticFeedback.lightImpact().ignore();
            _showAddSubscriptionDialog();
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(m.Symbols.add_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                'Add Subscription',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      content: _isLoading
          ? const Center(child: ProgressRing())
          : Directionality(
              textDirection: Directionality.of(context),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, AppTheme.bottomNavHeight),
                children: [
                  if (!_isSuggestedActive && _suggestedSubscription != null) ...[
                    _buildListSectionHeader(
                      context,
                      icon: m.Symbols.new_releases_rounded,
                      title: 'Suggested Subscription',
                    ),
                    _buildSuggestedSubscriptionCard(_suggestedSubscription!),
                    const SizedBox(height: 20),
                  ],
                  if (_subscriptions.isNotEmpty) ...[
                    _buildListSectionHeader(
                      context,
                      icon: m.Symbols.subscriptions_rounded,
                      title: 'My Subscriptions (${_subscriptions.length})',
                    ),
                    ..._subscriptions.asMap().entries.map(
                          (entry) => _buildSubscriptionCard(entry.value, entry.key),
                        ),
                  ],
                  if (_subscriptions.isEmpty && _isSuggestedActive)
                    _buildEmptyState(context),
                ],
              ),
            ),
    );
  }

  Widget _buildListSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: AppTheme.primary, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedSubscriptionCard(Subscription subscription) {
    return _EntranceAnimation(
      index: 0,
      child: Container(
        margin: AppTheme.cardMargin,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.10),
              AppTheme.secondary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(m.Symbols.cloud_download_rounded, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Free CloudflarePlus servers',
                    style: TextStyle(fontSize: 13, color: _secondaryText(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact().ignore();
                _activateSuggestedSubscription(subscription);
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m.Symbols.add_rounded, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Activate',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Subscription subscription, int index) {
    // Display-only status derived from data: a subscription holding no
    // servers is shown as inactive. No logic is changed.
    final bool isActive = subscription.configCount > 0;
    final Color statusColor = isActive ? _success : _secondaryText(context);

    return _EntranceAnimation(
      index: index,
      child: Container(
        margin: AppTheme.cardMargin,
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.neoCardDecoration(
          borderRadius: 24,
          brightness: FluentTheme.of(context).brightness,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(m.Symbols.cloud_rounded, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Updated ${_formatDate(subscription.lastUpdate)}',
                        style: TextStyle(fontSize: 13, color: _secondaryText(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(m.Symbols.dns_rounded, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${subscription.configCount} servers',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact().ignore();
                        _updateSubscription(subscription);
                      },
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(AppTheme.primary),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(m.Symbols.refresh_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Update',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact().ignore();
                        _deleteSubscription(subscription);
                      },
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(_danger),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(m.Symbols.delete_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.14),
                    AppTheme.secondary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Center(
                child: Icon(
                  m.Symbols.cloud_off_rounded,
                  size: 64,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No subscriptions yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Add a subscription link to get started with automatic server lists.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: _secondaryText(context)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact().ignore();
                  _showAddSubscriptionDialog();
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(AppTheme.primary),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(m.Symbols.add_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add Subscription',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _showAddSubscriptionDialog() async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Add Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextBox(
              controller: nameController,
              placeholder: 'My Subscription',
            ),
            const SizedBox(height: 20),
            const Text(
              'URL',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextBox(
              controller: urlController,
              placeholder: 'https://...',
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty || urlController.text.isEmpty) {
                return;
              }

              Navigator.pop(context);

              final service = Provider.of<V2RayService>(context, listen: false);

              try {
                final configs = await service.parseSubscriptionUrl(urlController.text);

                final existingConfigs = await service.loadConfigs();
                final allConfigs = [...existingConfigs, ...configs];
                await service.saveConfigs(allConfigs);

                final subscription = Subscription(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  url: urlController.text,
                  lastUpdate: DateTime.now(),
                  configCount: configs.length,
                );

                _subscriptions.add(subscription);
                await service.saveSubscriptions(_subscriptions);
                await _loadSubscriptions();

                if (mounted) {
                  await displayInfoBar(
                    context,
                    builder: (context, close) {
                      return InfoBar(
                        title: const Text('Success'),
                        content: Text('Added ${configs.length} servers'),
                        severity: InfoBarSeverity.success,
                      );
                    },
                    duration: const Duration(seconds: 3),
                  );
                }
              } catch (e) {
                if (mounted) {
                  await displayInfoBar(
                    context,
                    builder: (context, close) {
                      return InfoBar(
                        title: const Text('Error'),
                        content: Text(e.toString()),
                        severity: InfoBarSeverity.error,
                      );
                    },
                    duration: const Duration(seconds: 3),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _activateSuggestedSubscription(Subscription subscription) async {
    final service = Provider.of<V2RayService>(context, listen: false);

    try {
      final configs = await service.parseSubscriptionUrl(subscription.url);

      final existingConfigs = await service.loadConfigs();
      final allConfigs = [...existingConfigs, ...configs];
      await service.saveConfigs(allConfigs);

      final activatedSub = subscription.copyWith(
        lastUpdate: DateTime.now(),
        configCount: configs.length,
      );

      _subscriptions.add(activatedSub);
      await service.saveSubscriptions(_subscriptions);

      setState(() {
        _isSuggestedActive = true;
      });

      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Subscription Activated'),
              content: Text('Added ${configs.length} servers'),
              severity: InfoBarSeverity.success,
            );
          },
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Activation Failed'),
              content: Text(e.toString()),
              severity: InfoBarSeverity.error,
            );
          },
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _updateSubscription(Subscription subscription) async {
    final service = Provider.of<V2RayService>(context, listen: false);

    try {
      final configs = await service.parseSubscriptionUrl(subscription.url);

      final existingConfigs = await service.loadConfigs();
      final filteredConfigs = existingConfigs.where((config) {
        return !configs.any((newConfig) => newConfig.fullConfig == config.fullConfig);
      }).toList();

      final allConfigs = [...filteredConfigs, ...configs];
      await service.saveConfigs(allConfigs);

      final updatedSub = subscription.copyWith(
        lastUpdate: DateTime.now(),
        configCount: configs.length,
      );

      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = updatedSub;
      }

      await service.saveSubscriptions(_subscriptions);
      await _loadSubscriptions();

      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Updated'),
              content: Text('Updated ${configs.length} servers'),
              severity: InfoBarSeverity.success,
            );
          },
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Error'),
              content: Text(e.toString()),
              severity: InfoBarSeverity.error,
            );
          },
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _deleteSubscription(Subscription subscription) async {
    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Subscription'),
        content: Text('Are you sure you want to delete "${subscription.name}"?'),
        actions: [
          Button(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              _subscriptions.removeWhere((s) => s.id == subscription.id);

              final service = Provider.of<V2RayService>(context, listen: false);
              await service.saveSubscriptions(_subscriptions);
              await _loadSubscriptions();

              if (mounted) {
                await displayInfoBar(
                  context,
                  builder: (context, close) {
                    return const InfoBar(
                      title: Text('Deleted'),
                      severity: InfoBarSeverity.info,
                    );
                  },
                  duration: const Duration(seconds: 2),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Soft fade + slide entrance for subscription cards.
class _EntranceAnimation extends StatelessWidget {
  const _EntranceAnimation({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
