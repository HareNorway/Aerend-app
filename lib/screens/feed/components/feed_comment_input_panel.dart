import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';

class FeedCommentInputPanel extends StatefulWidget {
  final String? avatarUrl;
  final String avatarLetter;
  final bool sending;
  final bool rateLimited;
  final bool autoFocus;
  final void Function(String text) onSubmit;

  const FeedCommentInputPanel({
    super.key,
    this.avatarUrl,
    this.avatarLetter = '?',
    this.sending = false,
    this.rateLimited = false,
    required this.onSubmit,
    this.autoFocus = false,
  });

  @override
  State<FeedCommentInputPanel> createState() => FeedCommentInputPanelState();
}

class FeedCommentInputPanelState extends State<FeedCommentInputPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  static const int _maxChars = 2000;
  static const int _counterThreshold = 1500;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void clear() {
    _controller.clear();
  }

  bool get _canSend {
    final text = _controller.text.trim();
    return text.isNotEmpty && !widget.sending && !widget.rateLimited;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final len = _controller.text.length;
    final showCounter = len > _counterThreshold;

    return Material(
      elevation: 8,
      color: scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCounter)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.comment_char_counter(len),
                      style: aeCaption(
                        color: len > _maxChars
                            ? ScSaasThemeTokens.danger
                            : ScSaasThemeTokens.muted,
                      ).copyWith(fontSize: 11),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: scheme.surfaceContainerHighest,
                      backgroundImage: widget.avatarUrl != null &&
                              widget.avatarUrl!.isNotEmpty
                          ? NetworkImage(widget.avatarUrl!)
                          : null,
                      child: widget.avatarUrl == null ||
                              widget.avatarUrl!.isEmpty
                          ? Text(
                              widget.avatarLetter,
                              style: const TextStyle(fontSize: 10),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const Key('feed_comment_input'),
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !widget.sending && !widget.rateLimited,
                        maxLines: 4,
                        minLines: 1,
                        maxLength: _maxChars,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                            null,
                        decoration: InputDecoration(
                          hintText: l10n.post_detail_comment_hint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: const Key('feed_comment_send_btn'),
                      onPressed: _canSend
                          ? () => widget.onSubmit(_controller.text.trim())
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: _canSend
                            ? ScSaasThemeTokens.primary
                            : scheme.surfaceContainerHighest,
                        foregroundColor:
                            _canSend ? Colors.white : scheme.outline,
                      ),
                      icon: widget.sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_upward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
