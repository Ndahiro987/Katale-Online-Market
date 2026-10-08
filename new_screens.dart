}

// ===========================================================================
// Contact us
// ===========================================================================

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await SupabaseClientProvider.instance
          .from('contact_messages')
          .insert({
            'user_id': currentUserId,
            'name': _name.text.trim(),
            'email': _email.text.trim(),
            'subject': _subject.text.trim(),
            'message': _message.text.trim(),
          });
      if (context.mounted) {
        showKataleMessage(context, 'Message sent. We will reply within 24 hours.');
        _name.clear();
        _email.clear();
        _subject.clear();
        _message.clear();
      }
    } catch (e) {
      if (context.mounted) showKataleError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return KataleScreen(
      title: 'Contact us',
      child: ListView(
        padding: const EdgeInsets.all(KataleSpace.gutter),
        children: [
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KataleInput(
                  controller: _name,
                  hint: 'Your name',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: KataleSpace.sm),
                KataleInput(
                  controller: _email,
                  hint: 'Email address',
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: KataleSpace.sm),
                KataleInput(
                  controller: _subject,
                  hint: 'Subject',
                ),
                const SizedBox(height: KataleSpace.sm),
                KataleInput(
                  controller: _message,
                  hint: 'How can we help?',
                  maxLines: 6,
                ),
                const SizedBox(height: KataleSpace.lg),
                KataleButton(
                  label: 'Send message',
                  icon: Icons.send_rounded,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Report scam alert
// ===========================================================================

class ReportScamScreen extends ConsumerStatefulWidget {
  const ReportScamScreen({super.key, required this.reportedUserId, this.reportId});

  final String reportedUserId;
  final String? reportId;

  @override
  ConsumerState<ReportScamScreen> createState() => _ReportScamScreenState();
}

class _ReportScamScreenState extends ConsumerState<ReportScamScreen> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final reason = _reason.text.trim();
    if (reason.length < 8) {
      showKataleError(context, 'Please give at least 8 characters.');
      return;
    }
    setState(() => _busy = true);
    try {
      await BuyerRepo.reportScam(
        reportedUserId: widget.reportedUserId,
        reason: reason,
        reportId: widget.reportId,
      );
      if (context.mounted) {
        showKataleMessage(context, 'Report submitted. Thank you.');
        context.pop();
      }
    } catch (e) {
      if (context.mounted) showKataleError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return KataleScreen(
      title: 'Report scam alert',
      child: ListView(
        padding: const EdgeInsets.all(KataleSpace.gutter),
        children: [
          NoteBar(
            message:
                'Seven reports against one account triggers an automatic review. '
                'False reports are themselves a violation.',
            icon: Icons.shield_rounded,
            tone: KataleTagTone.warning,
          ),
          const SizedBox(height: KataleSpace.xl),
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KataleInput(
                  controller: _reason,
                  hint: 'Describe what happened (minimum 8 characters)',
                  maxLines: 5,
                ),
                const SizedBox(height: KataleSpace.lg),
                KataleButton(
                  label: 'Submit report',
                  icon: Icons.warning_rounded,
                  tone: KataleTone.danger,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Account deletion
// ===========================================================================

class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  bool _busy = false;

  Future<void> _requestDeletion() async {
    final ok = await confirm(
      context,
      title: 'Request account deletion?',
      message:
          'Your account will be scheduled for permanent deletion in 14 days. '
          'You can cancel this request within that period.',
      confirmLabel: 'Request deletion',
    );
    if (!ok || !context.mounted) return;
    setState(() => _busy = true);
    try {
      await AuthRepo.requestAccountDeletion();
      if (context.mounted) {
        showKataleMessage(context, 'Deletion requested. You have 14 days to cancel.');
        ref.invalidate(sessionProvider);
      }
    } catch (e) {
      if (context.mounted) showKataleError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelDeletion() async {
    final ok = await confirm(
      context,
      title: 'Cancel deletion?',
      message: 'Your account will remain active.',
      confirmLabel: 'Cancel deletion',
    );
    if (!ok || !context.mounted) return;
    setState(() => _busy = true);
    try {
      await AuthRepo.cancelAccountDeletion();
      if (context.mounted) {
        showKataleMessage(context, 'Deletion cancelled.');
        ref.invalidate(sessionProvider);
      }
    } catch (e) {
      if (context.mounted) showKataleError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final profile = session.publicProfile;
    final hasPending = profile?.hasPendingDeletion ?? false;

    return KataleScreen(
      title: 'Account deletion',
      child: ListView(
        padding: const EdgeInsets.all(KataleSpace.gutter),
        children: [
          if (hasPending) ...[
            NoteBar(
              message:
                  'Your account is scheduled for deletion on '
                  '${profile!.permanentDeleteAt!.toLocal().toString().split(' ')[0]}. '
                  'All your data will be permanently removed.',
              icon: Icons.warning_rounded,
              tone: KataleTagTone.danger,
            ),
            const SizedBox(height: KataleSpace.lg),
            KataleButton(
              label: 'Cancel deletion request',
              icon: Icons.cancel_rounded,
              tone: KataleTone.secondary,
              onPressed: _busy ? null : _cancelDeletion,
            ),
          ] else ...[
            NoteBar(
              message:
                  'This action cannot be undone. All your listings, reviews, and '
                  'messages will be permanently deleted.',
              icon: Icons.delete_forever_rounded,
              tone: KataleTagTone.danger,
            ),
            const SizedBox(height: KataleSpace.xl),
            KataleButton(
              label: 'Request account deletion',
              icon: Icons.delete_forever_rounded,
              tone: KataleTone.danger,
              onPressed: _busy ? null : _requestDeletion,
            ),
          ],
        ],
      ),
    );
  }
