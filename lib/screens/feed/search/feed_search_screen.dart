import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../components/feed_search_result_tile.dart';
import '../storeProfile/store_profile.dart';
import 'feed_search_bloc.dart';
import 'feed_search_event.dart';
import 'feed_search_state.dart';

class FeedSearchScreen extends StatefulWidget {
  const FeedSearchScreen({super.key, this.embedded = false});

  /// When true, renders without a back-button [AppBar] (used in [FeedShellScreen]).
  final bool embedded;

  @override
  State<FeedSearchScreen> createState() => _FeedSearchScreenState();
}

class _FeedSearchScreenState extends State<FeedSearchScreen> {
  FeedSearchBloc? _bloc;
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bloc == null) {
      _bloc = FeedSearchBloc(context, this);
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    _bloc?.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _bloc?.handleEvent(FeedSearchQueryChanged(value));
  }

  void _openStore(String storeId) {
    openScreen(context, StoreProfileScreen(storeId: storeId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = _bloc;
    if (bloc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: widget.embedded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _buildSearchField(l10n),
                ),
                Expanded(child: _buildResults(bloc, l10n)),
              ],
            )
          : Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: _buildSearchField(l10n),
              ),
              body: _buildResults(bloc, l10n),
            ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return TextField(
      controller: _queryController,
      focusNode: _focusNode,
      autofocus: !widget.embedded,
      textInputAction: TextInputAction.search,
      onChanged: _onQueryChanged,
      onSubmitted: (q) => _bloc?.handleEvent(FeedSearchSubmitted(q)),
      decoration: InputDecoration(
        hintText: l10n.search_stores_hint,
        prefixIcon: const Icon(Icons.search, color: ScSaasThemeTokens.muted),
        border: widget.embedded ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ScSaasThemeTokens.border),
        ) : InputBorder.none,
        enabledBorder: widget.embedded ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ScSaasThemeTokens.border),
        ) : InputBorder.none,
        focusedBorder: widget.embedded ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ScSaasThemeTokens.primary),
        ) : InputBorder.none,
        filled: widget.embedded,
        fillColor: ScSaasThemeTokens.card,
        contentPadding: widget.embedded
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : null,
        hintStyle: aeBody(color: ScSaasThemeTokens.muted).copyWith(fontSize: 16),
      ),
      style: aeBody(color: ScSaasThemeTokens.text).copyWith(fontSize: 16),
    );
  }

  Widget _buildResults(FeedSearchBloc bloc, AppLocalizations l10n) {
    return StreamBuilder<FeedSearchState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const FeedSearchInitial();

        if (state is FeedSearchLoading) {
          return const Center(
            child: CircularProgressIndicator(color: ScSaasThemeTokens.primary),
          );
        }

        if (state is FeedSearchError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: ScSaasThemeTokens.muted),
              ),
            ),
          );
        }

        if (state is FeedSearchEmpty) {
          return Center(
            child: Text(
              l10n.search_no_results,
              style: aeBody(color: ScSaasThemeTokens.muted),
            ),
          );
        }

        if (state is FeedSearchLoaded) {
          return ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: widget.embedded
                ? const EdgeInsets.only(top: 8)
                : EdgeInsets.zero,
            itemCount: state.results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final store = state.results[index];
              return FeedSearchResultTile(
                store: store,
                onTap: () => _openStore(store.id),
              );
            },
          );
        }

        if (widget.embedded && state is FeedSearchInitial) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.feed_explore_hint,
                textAlign: TextAlign.center,
                style: aeLabel(color: ScSaasThemeTokens.muted),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
