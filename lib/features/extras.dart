import '../core/shared.dart';
import '../core/config/app_config.dart';
import 'auth/auth_provider.dart';
import 'auth/auth_models.dart';

final mockSupportReceiptsProvider =
    StateProvider<List<({String reference, String topic, String subject})>>(
      (ref) => [],
    );
final mockGiftPreviewsProvider =
    StateProvider<List<({double amount, String name, String message})>>(
      (ref) => [],
    );

class MockVisitReceipts extends ConsumerWidget {
  const MockVisitReceipts({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = ref.watch(mockSupportReceiptsProvider);
    final gifts = ref.watch(mockGiftPreviewsProvider);
    if (support.isEmpty && gifts.isEmpty) return const SizedBox.shrink();
    return DemoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading(
            'Your local mock receipts',
            subtitle:
                'Saved only for this visit. Not real requests, credit or purchases.',
          ),
          for (final receipt in support.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${receipt.reference} · ${receipt.topic}\n${receipt.subject}',
                style: AppTypography.body,
              ),
            ),
          for (final gift in gifts.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Mock gift preview · ${currency(gift.amount)} · For ${gift.name}\n${gift.message}',
                style: AppTypography.body,
              ),
            ),
        ],
      ),
    );
  }
}

class AccountSessionActions extends ConsumerStatefulWidget {
  const AccountSessionActions({super.key});
  @override
  ConsumerState<AccountSessionActions> createState() =>
      _AccountSessionActionsState();
}

class _AccountSessionActionsState extends ConsumerState<AccountSessionActions> {
  bool _busy = false;
  String? _error;

  Future<void> _signOut() async {
    if (_busy || ref.read(authProvider).isLoading) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!ref.read(appConfigProvider).useMocks) {
        throw const AuthException(
          'Only mock authentication is available here.',
        );
      }
      await ref.read(authProvider.notifier).signOut();
      if (!mounted) return;
      final session = ref.read(authProvider);
      if (session is AsyncData<AuthUser?> && session.value == null) {
        ref.read(demoDisplayNameProvider.notifier).state = 'Experience seeker';
      } else {
        throw const AuthException(
          'Sign-out could not be confirmed. Please retry.',
        );
      }
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not finish mock sign-out. Please retry; visit data is unchanged.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthUser?>>(authProvider, (previous, next) {
      if (next is AsyncData<AuthUser?>) {
        ref.read(demoDisplayNameProvider.notifier).state =
            next.value?.name ?? 'Experience seeker';
      }
    });
    final session = ref.watch(authProvider);
    final signedIn = session.asData?.value != null;
    final pending = _busy || session.isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending) const LinearProgressIndicator(color: gold),
        DemoPillButton(
          label: signedIn || session.hasError
              ? 'Sign out of mock session →'
              : 'Mock sign in →',
          onPressed: pending
              ? null
              : signedIn || session.hasError
              ? _signOut
              : () => context.push('/login'),
        ),
        if (_error != null) Text(_error!, style: const TextStyle(color: gold)),
        const Text(
          'Mock identity only. Visit preferences, favourites and reservations remain after sign-out.',
          style: AppTypography.small,
        ),
      ],
    );
  }
}

final _clubOperationProvider = StateProvider<AsyncValue<void>>(
  (ref) => const AsyncData(null),
);

final _clubMemberProvider = StateProvider<bool>((ref) => false);
final _clubPointsProvider = StateProvider<int>((ref) => 120);
final _claimedRewardsProvider = StateProvider<Set<int>>((ref) => {});

/// Shared presentation for the session-only account demos.
class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      color: bg,
      child: SafeArea(
        child: PageContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class DemoPanel extends StatelessWidget {
  const DemoPanel({super.key, required this.child, this.goldBorder = false});
  final Widget child;
  final bool goldBorder;
  @override
  Widget build(BuildContext context) => Material(
    color: surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: goldBorder ? gold : border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: const EdgeInsets.all(24), child: child),
  );
}

class DemoHero extends StatelessWidget {
  const DemoHero({
    super.key,
    required this.label,
    required this.title,
    required this.subtitle,
    this.image = '',
    this.height = 380,
  });
  final String label, title, subtitle, image;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // درون کلاس DemoHero، اولین فرزند Stack را به این صورت تغییر دهید:
          if (image.isNotEmpty)
            EventImage(image, height: height, width: double.infinity)
          else
            SizedBox(height: height, width: double.infinity),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.imageOverlay),
          ),
          // ... ادامه کد بدون تغییر
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.imageOverlay),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg.withValues(alpha: .15), bg.withValues(alpha: .95)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'event',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: '.',
                        style: TextStyle(color: gold),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(),
                Text(label, style: AppTypography.label),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTypography.heroTitle.copyWith(
                    fontSize: 28,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class DemoPillButton extends StatelessWidget {
  const DemoPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: gold,
      foregroundColor: AppColors.onPrimary,
      minimumSize: const Size.fromHeight(48),
      shape: const StadiumBorder(),
    ),
    child: loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: gold),
          )
        : Text(label, textAlign: TextAlign.center, style: AppTypography.button),
  );
}

String? demoRequired(String? value) => value == null || value.trim().isEmpty
    ? 'Please complete this field.'
    : null;
String? demoEmail(String? value) =>
    value == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? 'Enter a valid example email address.'
    : null;

class DemoField extends StatelessWidget {
  const DemoField({
    super.key,
    required this.controller,
    required this.label,
    this.validator = demoRequired,
    this.maxLines = 1,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.onChanged,
    this.enabled = true,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: obscure,
      enableSuggestions: !obscure,
      autocorrect: !obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        errorMaxLines: 3,
        filled: true,
        fillColor: AppColors.backgroundDarker,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class DemoColumns extends StatelessWidget {
  const DemoColumns({super.key, required this.left, required this.right});
  final Widget left, right;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 680) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: 24), right],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 24),
          Expanded(child: right),
        ],
      );
    },
  );
}

class ClubScreen extends ConsumerWidget {
  const ClubScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(_clubMemberProvider);
    final points = ref.watch(_clubPointsProvider);
    final claimed = ref.watch(_claimedRewardsProvider);
    final operation = ref.watch(_clubOperationProvider);
    Future<void> updateClub(int? reward) async {
      if (ref.read(_clubOperationProvider).isLoading) return;
      ref.read(_clubOperationProvider.notifier).state = const AsyncLoading();
      // Capture notifiers before awaiting so disposal never requires a WidgetRef.
      final status = ref.read(_clubOperationProvider.notifier);
      try {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!context.mounted) return;
        if (reward == null) {
          ref.read(_clubMemberProvider.notifier).state = !ref.read(
            _clubMemberProvider,
          );
        } else {
          final current = ref.read(_claimedRewardsProvider);
          final balance = ref.read(_clubPointsProvider);
          if (!ref.read(_clubMemberProvider) ||
              current.contains(reward) ||
              balance < reward)
            return;
          ref.read(_claimedRewardsProvider.notifier).state = {
            ...current,
            reward,
          };
          ref.read(_clubPointsProvider.notifier).state = balance - reward;
        }
      } catch (error, stack) {
        if (status.mounted) status.state = AsyncError(error, stack);
      } finally {
        if (status.mounted && status.state.isLoading)
          status.state = const AsyncData(null);
      }
    }

    return DemoPage(
      children: [
        const DemoHero(
          label: 'EVENT CLUB',
          title: 'Good plans. A little extra.',
          subtitle: 'A preview of a club made for experience seekers.',
        ),
        const SizedBox(height: 24),
        DemoColumns(
          left: DemoPanel(
            goldBorder: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, color: gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        member ? 'DEMO MEMBER' : 'YOUR INVITATION',
                        style: AppTypography.label,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '$points',
                  style: AppTypography.priceLarge.copyWith(
                    fontSize: 48,
                    color: gold,
                  ),
                ),
                const Text('Session mock points', style: AppTypography.body),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (points / 300).clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                    color: gold,
                    backgroundColor: AppColors.surfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '100 · First discovery     200 · More moments     300 · Extraordinary',
                  style: AppTypography.small,
                ),
                const SizedBox(height: 24),
                DemoPillButton(
                  label: member ? 'Leave demo club →' : 'Join the demo club →',
                  loading: operation.isLoading,
                  onPressed: operation.isLoading
                      ? null
                      : () => updateClub(null),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Demo only. Membership and points last for this session. No real rewards or benefits are issued.',
                  style: AppTypography.small,
                ),
              ],
            ),
          ),
          right: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeading('Little extras, big possibilities'),
              if (operation.hasError)
                const Text(
                  'Mock update failed. Retry the join or claim action; no real reward was issued.',
                  style: AppTypography.small,
                ),
              for (final reward in const [
                (100, 'First discovery', 'A sample £5 experience perk'),
                (200, 'More moments', 'A sample priority-access perk'),
                (300, 'Extraordinary', 'A sample special-experience perk'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DemoPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${reward.$1} MOCK POINTS',
                          style: AppTypography.label,
                        ),
                        const SizedBox(height: 12),
                        Text(reward.$2, style: AppTypography.cardTitle),
                        const SizedBox(height: 8),
                        Text(reward.$3, style: AppTypography.body),
                        const SizedBox(height: 16),
                        DemoPillButton(
                          label: claimed.contains(reward.$1)
                              ? 'Claimed in this demo'
                              : 'Claim sample reward →',
                          onPressed:
                              operation.isLoading ||
                                  !member ||
                                  points < reward.$1 ||
                                  claimed.contains(reward.$1)
                              ? null
                              : () => updateClub(reward.$1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class GiftCardsScreen extends ConsumerStatefulWidget {
  const GiftCardsScreen({super.key});
  @override
  ConsumerState<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends ConsumerState<GiftCardsScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  final _custom = TextEditingController();
  int? _amount = 50;
  bool _confirmed = false;
  AsyncValue<void> _operation = const AsyncData(null);
  ({double amount, String name, String message})? _preview;

  Future<void> _submitGift() async {
    if (!mounted || _operation.isLoading || _confirmed) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    final preview = (
      amount: _value,
      name: _name.text.trim(),
      message: _message.text.trim(),
    );
    FocusScope.of(context).unfocus();
    setState(() => _operation = const AsyncLoading());
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      ref.read(mockGiftPreviewsProvider.notifier).state = [
        ...ref.read(mockGiftPreviewsProvider),
        preview,
      ];
      for (final controller in [_name, _email, _message, _custom]) {
        controller.clear();
      }
      setState(() {
        _preview = preview;
        _amount = 50;
        _confirmed = true;
        _operation = const AsyncData(null);
      });
    } catch (error, stack) {
      if (mounted) setState(() => _operation = AsyncError(error, stack));
    }
  }

  double get _value {
    final value = _amount?.toDouble() ?? double.tryParse(_custom.text) ?? 0;
    return value.isFinite ? value.clamp(0.0, 300.0).toDouble() : 0;
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _message, _custom]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    children: [
      const DemoHero(
        label: 'GIVE A GOOD PLAN',
        title: 'More than a gift. A memory.',
        subtitle: 'Make a sample gift card for someone extraordinary.',
      ),
      const SizedBox(height: 24),
      DemoColumns(
        left: DemoPanel(
          goldBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.card_giftcard, color: gold, size: 40),
              const SizedBox(height: 24),
              const Text('EVENT GIFT CARD', style: AppTypography.label),
              const SizedBox(height: 16),
              Text(
                currency(_confirmed ? _preview!.amount : _value),
                style: AppTypography.priceLarge.copyWith(
                  fontSize: 44,
                  color: gold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _confirmed
                    ? 'For ${_preview!.name}'
                    : _name.text.trim().isEmpty
                    ? 'For someone special'
                    : 'For ${_name.text.trim()}',
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: 12),
              Text(
                _confirmed
                    ? (_preview!.message.isEmpty
                          ? 'A little something to look forward to.'
                          : _preview!.message)
                    : _message.text.trim().isEmpty
                    ? 'A little something to look forward to.'
                    : _message.text.trim(),
                style: AppTypography.body,
              ),
              const SizedBox(height: 32),
              const Text(
                'SAMPLE PREVIEW · NOT REDEEMABLE',
                style: AppTypography.label,
              ),
            ],
          ),
        ),
        right: _confirmed
            ? DemoPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: gold,
                      size: 48,
                    ),
                    const SizedBox(height: 20),
                    const SectionHeading(
                      'Your mock gift is ready',
                      subtitle:
                          'Nothing was charged, emailed or issued. This sample cannot be redeemed.',
                    ),
                    Text(
                      '${currency(_preview!.amount)} · For ${_preview!.name}',
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 24),
                    DemoPillButton(
                      label: 'Create another sample →',
                      onPressed: () => setState(() {
                        _confirmed = false;
                        _preview = null;
                      }),
                    ),
                  ],
                ),
              )
            : DemoPanel(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeading(
                        'Make it personal',
                        subtitle:
                            'Use example details only. Nothing is transmitted.',
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final amount in [25, 50, 100, null])
                            ChoiceChip(
                              label: Text(
                                amount == null ? 'Custom' : '£$amount',
                              ),
                              selected: _amount == amount,
                              selectedColor: AppColors.primarySurface,
                              side: BorderSide(
                                color: _amount == amount ? gold : border,
                              ),
                              onSelected: _operation.isLoading
                                  ? null
                                  : (_) => setState(() => _amount = amount),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_amount == null)
                        DemoField(
                          controller: _custom,
                          enabled: !_operation.isLoading,
                          label: 'Amount (£5–£300)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (text) {
                            final value = double.tryParse(text ?? '');
                            return value == null ||
                                    !value.isFinite ||
                                    value < 5 ||
                                    value > 300 ||
                                    (value * 100 - (value * 100).round())
                                            .abs() >
                                        .00001
                                ? 'Enter £5–£300, with up to two decimal places.'
                                : null;
                          },
                        ),
                      DemoField(
                        controller: _name,
                        enabled: !_operation.isLoading,
                        label: 'Recipient name',
                        onChanged: (_) => setState(() {}),
                      ),
                      DemoField(
                        controller: _email,
                        enabled: !_operation.isLoading,
                        label: 'Recipient example email',
                        validator: demoEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      DemoField(
                        controller: _message,
                        enabled: !_operation.isLoading,
                        label: 'Your message (optional)',
                        maxLines: 3,
                        validator: null,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_operation.hasError)
                        const Text(
                          'Could not save the mock preview. Please retry.',
                          style: AppTypography.small,
                        ),
                      DemoPillButton(
                        label: _operation.hasError
                            ? 'Retry mock gift →'
                            : 'Create mock gift →',
                        loading: _operation.isLoading,
                        onPressed: _operation.isLoading ? null : _submitGift,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Demo only. No payment, delivery, real credit or redemption. Previews are kept only during this visit; the example email is not saved.',
                        style: AppTypography.small,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ],
  );
}

class SupportRequestScreen extends ConsumerStatefulWidget {
  const SupportRequestScreen({super.key});
  @override
  ConsumerState<SupportRequestScreen> createState() =>
      _SupportRequestScreenState();
}

class _SupportRequestScreenState extends ConsumerState<SupportRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _topic = 'Booking';
  bool _submitted = false;
  AsyncValue<void> _operation = const AsyncData(null);
  String? _receipt;

  Future<void> _submitSupport() async {
    if (!mounted || _operation.isLoading || _submitted) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    final topic = _topic;
    final subject = _subject.text.trim();
    FocusScope.of(context).unfocus();
    setState(() => _operation = const AsyncLoading());
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      final receipts = ref.read(mockSupportReceiptsProvider);
      final reference = 'MOCK-SUPPORT-${receipts.length + 1}';
      ref.read(mockSupportReceiptsProvider.notifier).state = [
        ...receipts,
        (reference: reference, topic: topic, subject: subject),
      ];
      _subject.clear();
      _message.clear();
      setState(() {
        _receipt = reference;
        _submitted = true;
        _topic = 'Booking';
        _operation = const AsyncData(null);
      });
    } catch (error, stack) {
      if (mounted) setState(() => _operation = AsyncError(error, stack));
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    children: [
      const DemoHero(
        label: 'A LITTLE HELP',
        title: 'Good plans, fewer questions.',
        subtitle: 'Preview a support request. No messages leave this device.',
      ),
      const SizedBox(height: 24),
      DemoColumns(
        left: const DemoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.chat_bubble_outline, size: 36, color: gold),
              SizedBox(height: 20),
              SectionHeading(
                'We’re here in spirit',
                subtitle:
                    'This mock form lets you explore the support experience. Live support, case tracking and replies are not available.',
              ),
              Text(
                'Please use fictional details. There is no need to enter an email, booking reference or other personal information.',
                style: AppTypography.body,
              ),
            ],
          ),
        ),
        right: DemoPanel(
          child: _submitted
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: gold,
                      size: 48,
                    ),
                    const SizedBox(height: 20),
                    const SectionHeading(
                      'Mock request complete',
                      subtitle:
                          'This was not sent. No support case was created and no reply will arrive.',
                    ),
                    Text(
                      'Local sample receipt: $_receipt',
                      style: AppTypography.small,
                    ),
                    DemoPillButton(
                      label: 'Back to help →',
                      onPressed: () => context.go('/profile/help'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _submitted = false),
                      child: const Text('Try another mock request →'),
                    ),
                  ],
                )
              : Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeading('What can we help with?'),
                      DropdownButtonFormField<String>(
                        initialValue: _topic,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Topic'),
                        items:
                            [
                                  'Booking',
                                  'Account',
                                  'Gift cards',
                                  'Club & rewards',
                                  'Other',
                                ]
                                .map(
                                  (topic) => DropdownMenuItem(
                                    value: topic,
                                    child: Text(topic),
                                  ),
                                )
                                .toList(),
                        onChanged: _operation.isLoading
                            ? null
                            : (value) =>
                                  setState(() => _topic = value ?? 'Booking'),
                      ),
                      const SizedBox(height: 20),
                      DemoField(
                        controller: _subject,
                        label: 'Subject',
                        enabled: !_operation.isLoading,
                      ),
                      DemoField(
                        controller: _message,
                        enabled: !_operation.isLoading,
                        label: 'Message',
                        maxLines: 5,
                        validator: (value) => (value?.trim().length ?? 0) < 10
                            ? 'Add at least 10 characters for this mock request.'
                            : null,
                      ),
                      if (_operation.hasError)
                        const Text(
                          'Could not save a local mock receipt. Please retry.',
                          style: AppTypography.small,
                        ),
                      DemoPillButton(
                        label: _operation.hasError
                            ? 'Retry mock submission →'
                            : 'Preview mock submission →',
                        loading: _operation.isLoading,
                        onPressed: _operation.isLoading ? null : _submitSupport,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Demo only. No transmission, actual submission or support response.',
                        style: AppTypography.small,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    ],
  );
}
