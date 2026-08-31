import 'dart:async';

import 'package:flutter/material.dart';

import '../../../blocs/bloc.dart';
import '../../../exceptions/feed/feed_api_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../../networking/feed/feed_repo.dart';
import 'feed_search_event.dart';
import 'feed_search_state.dart';

class FeedSearchBloc extends Bloc {
  FeedSearchBloc(
    this.context,
    this.state, {
    FeedRepo? repo,
  }) : _repo = repo ?? FeedRepo() {
    _stateSubject.add(const FeedSearchInitial());
  }

  final BuildContext context;
  final State state;
  final FeedRepo _repo;

  static const Duration _debounceDuration = Duration(milliseconds: 350);
  static const int _minQueryLength = 2;

  final _stateSubject = BehaviorSubject<FeedSearchState>.seeded(
    const FeedSearchInitial(),
  );

  Stream<FeedSearchState> get stateStream => _stateSubject.stream;
  FeedSearchState get currentState => _stateSubject.value;

  Timer? _debounce;
  String _lastQuery = '';
  int _requestId = 0;

  void handleEvent(FeedSearchEvent event) {
    switch (event) {
      case FeedSearchQueryChanged(:final query):
        _onQueryChanged(query);
      case FeedSearchSubmitted(:final query):
        _runSearch(query.trim(), immediate: true);
    }
  }

  void _onQueryChanged(String query) {
    final trimmed = query.trim();
    _debounce?.cancel();
    if (trimmed.length < _minQueryLength) {
      _lastQuery = trimmed;
      _emit(const FeedSearchInitial());
      return;
    }
    _debounce = Timer(_debounceDuration, () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query, {bool immediate = false}) async {
    if (!immediate) {
      if (query != _lastQuery && _debounce?.isActive == true) {
        // superseded
      }
    }
    if (query.length < _minQueryLength) {
      _emit(const FeedSearchInitial());
      return;
    }
    if (query == _lastQuery && currentState is FeedSearchLoaded) return;

    _lastQuery = query;
    final id = ++_requestId;
    _emit(const FeedSearchLoading());

    try {
      final results = await _repo.searchStores(query, limit: 20);
      if (!state.mounted || id != _requestId) return;
      if (results.isEmpty) {
        _emit(FeedSearchEmpty(query));
      } else {
        _emit(FeedSearchLoaded(results: results, query: query));
      }
    } catch (e) {
      if (!state.mounted || id != _requestId) return;
      _emit(FeedSearchError(_messageForError(e)));
    }
  }

  String _messageForError(Object e) {
    if (e is FeedApiException) return e.message;
    return AppLocalizations.of(context)!.feed_error_generic;
  }

  void _emit(FeedSearchState next) {
    if (!_stateSubject.isClosed) _stateSubject.add(next);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _stateSubject.close();
  }
}
