import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../googleApi/google_api_repo.dart';
import '../../../googleApi/place_model_dl.dart';
import '../../../googleApi/place_name_dl.dart';
import '../../../theme/design_scale.dart';
import '../../../theme/sc_saas_theme.dart';
import '../../../utils/utils.dart';
import '../../dugnad/dugnad_club_theme.dart';
import '../address_order_chrome.dart';
import 'add_new_address_repo.dart';
import 'manage_address_dl.dart';

/// Street line shown on address cards — never `flat_no` (`N/A`).
String addressDisplayTitle(AddressListItem address) {
  final line = address.address.trim();
  if (line.isNotEmpty) return line;
  return capitalize(address.type);
}

Future<LatLng> resolveAddressLatLng({
  required String line,
  Predictions? picked,
}) async {
  final google = GoogleApiRepo();
  final fromPicked = await _latLngFromPlaceId(google, picked?.placeId);
  if (fromPicked != null) return fromPicked;
  try {
    final model = PlaceModel.fromJson(
      await google.placeApiCall(line, prefGetLatLng()),
    );
    final firstId = model.predictions?.isNotEmpty == true
        ? model.predictions!.first.placeId
        : null;
    final fromFirst = await _latLngFromPlaceId(google, firstId);
    if (fromFirst != null) return fromFirst;
  } catch (_) {}
  final saved = prefGetLatLng();
  if (saved.latitude.abs() > 1e-7 || saved.longitude.abs() > 1e-7) {
    return saved;
  }
  return defaultLatLng;
}

Future<LatLng?> _latLngFromPlaceId(GoogleApiRepo google, String? placeId) async {
  if (placeId == null || placeId.isEmpty) return null;
  try {
    final named = PlaceName.fromJson(await google.getPlaceNameFormID(placeId));
    final loc = named.result?.geometry?.location;
    if (loc == null) return null;
    return LatLng(loc.lat ?? 0, loc.lng ?? 0);
  } catch (_) {
    return null;
  }
}

/// `flat_no` is required by the API; landmark is varchar(30) — send `N/A`.
Future<dynamic> saveDugnadAddressLine({
  required String line,
  Predictions? picked,
  int? editingId,
  String type = home,
}) async {
  final latLng = await resolveAddressLatLng(line: line, picked: picked);
  final repo = AddNewAddressRepo();
  final kind = type.trim().isEmpty ? home : type;
  if (editingId != null) {
    return repo.callEditAddressApi(editingId, line, kind, latLng, 'N/A', 'N/A');
  }
  return repo.callAddAddressApi(line, kind, latLng, 'N/A', 'N/A');
}

bool addressApiOk(dynamic response) =>
    response is Map && response['status'] == 1;

String addressApiMessage(BuildContext context, dynamic response) {
  if (response is Map) {
    return getApiMsg(
      context,
      response['message_code'],
      response['message']?.toString(),
    );
  }
  return languages.internetConnLostTitle;
}

/// Search + suggestions + Avbryt / Lagre — same form as Velg leveringsadresse.
class DugnadInlineAddressForm extends StatefulWidget {
  const DugnadInlineAddressForm({
    super.key,
    this.initialLine = '',
    this.editingId,
    this.addressType = home,
    required this.onCancel,
    required this.onSaved,
  });

  final String initialLine;
  final int? editingId;
  final String addressType;
  final VoidCallback onCancel;
  final Future<void> Function(dynamic response) onSaved;

  @override
  State<DugnadInlineAddressForm> createState() =>
      _DugnadInlineAddressFormState();
}

class _DugnadInlineAddressFormState extends State<DugnadInlineAddressForm> {
  final GoogleApiRepo _google = GoogleApiRepo();
  final TextEditingController _lineController = TextEditingController();
  final FocusNode _lineFocus = FocusNode();
  List<Predictions> _suggestions = [];
  bool _saving = false;
  Timer? _suggestDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLine.isNotEmpty) {
      _lineController.text = widget.initialLine;
    }
    _lineController.addListener(_onLineChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _lineFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _suggestDebounce?.cancel();
    _lineController.removeListener(_onLineChanged);
    _lineController.dispose();
    _lineFocus.dispose();
    super.dispose();
  }

  void _onLineChanged() {
    _suggestDebounce?.cancel();
    final q = _lineController.text.trim();
    if (q.length < 2) {
      setState(() {
        if (_suggestions.isNotEmpty) _suggestions = [];
      });
      return;
    }
    _suggestDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_fetchSuggestions(q));
    });
    setState(() {});
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final response = PlaceModel.fromJson(
        await _google.placeApiCall(query, prefGetLatLng()),
      );
      if (!mounted || _lineController.text.trim() != query) return;
      setState(
        () => _suggestions = (response.predictions ?? []).take(5).toList(),
      );
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    }
  }

  Future<void> _saveLine({Predictions? picked}) async {
    final line = (picked?.description ?? _lineController.text).trim();
    if (line.isEmpty || _saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      final response = await saveDugnadAddressLine(
        line: line,
        picked: picked,
        editingId: widget.editingId,
        type: widget.addressType,
      );
      if (!mounted) return;
      if (!addressApiOk(response)) {
        openSimpleSnackbar(addressApiMessage(context, response));
        return;
      }
      HapticFeedback.lightImpact();
      openSimpleSnackbar(languages.dugnadAddressSavedToast);
      await widget.onSaved(response);
    } catch (e) {
      if (mounted) openSimpleSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final valid = _lineController.text.trim().isNotEmpty && !_saving;
    return Container(
      padding: EdgeInsets.all(context.dp(13)),
      decoration: BoxDecoration(
        color: theme.primaryTint,
        borderRadius: BorderRadius.circular(context.dp(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _lineController,
            focusNode: _lineFocus,
            enabled: !_saving,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveLine(
              picked: _suggestions.isNotEmpty ? _suggestions.first : null,
            ),
            style: aoText(14.5, FontWeight.w600, color: theme.text),
            decoration: InputDecoration(
              hintText: languages.dugnadAddressSearchHint,
              hintStyle: aoText(14.5, FontWeight.w500, color: kAoGray400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.dp(14),
                vertical: context.dp(12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.dp(12)),
                borderSide:
                    const BorderSide(color: Colors.transparent, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.dp(12)),
                borderSide:
                    const BorderSide(color: Colors.transparent, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.dp(12)),
                borderSide: BorderSide(color: theme.primary, width: 1.5),
              ),
            ),
          ),
          if (_suggestions.isNotEmpty) ...[
            SizedBox(height: context.dp(9)),
            _suggestionList(theme),
          ],
          SizedBox(height: context.dp(10)),
          Row(
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _saving ? null : widget.onCancel,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.dp(16),
                      vertical: context.dp(11),
                    ),
                    child: Text(
                      languages.cancel,
                      style: aoText(
                        13.5,
                        FontWeight.w800,
                        color: theme.primaryHover,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.dp(9)),
              Expanded(
                child: Opacity(
                  opacity: valid ? 1 : 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: theme.shinyGradient,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: valid ? theme.shadowButton : null,
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: valid ? () => _saveLine() : null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: context.dp(11),
                            horizontal: context.dp(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_saving)
                                SizedBox(
                                  width: context.dp(16),
                                  height: context.dp(16),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.check_rounded,
                                  size: context.dp(16),
                                  color: Colors.white,
                                ),
                              SizedBox(width: context.dp(7)),
                              Text(
                                languages.saveAddress,
                                style: aoText(
                                  13.5,
                                  FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestionList(DugnadClubThemePalette theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.dp(13)),
        boxShadow: [
          BoxShadow(
            color: theme.text.withValues(alpha: 0.06),
            blurRadius: context.dp(2),
            offset: Offset(0, context.dp(1)),
          ),
          BoxShadow(
            color: theme.text.withValues(alpha: 0.22),
            blurRadius: context.dp(20),
            offset: Offset(0, context.dp(8)),
            spreadRadius: context.dp(-10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _suggestions.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: ScSaasThemeTokens.gray100),
            _suggestionRow(_suggestions[i], theme),
          ],
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              context.dp(13),
              context.dp(8),
              context.dp(13),
              context.dp(9),
            ),
            color: const Color(0xFFF7F6F9),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: context.dp(12),
                  color: kAoGray400,
                ),
                SizedBox(width: context.dp(5)),
                Text(
                  languages.dugnadAddressSuggestFoot,
                  style: aoText(
                    10.5,
                    FontWeight.w700,
                    letterSpacingEm: 0.03,
                    color: kAoGray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionRow(Predictions pred, DugnadClubThemePalette theme) {
    final full = pred.description ?? '';
    final street = pred.structuredFormatting?.mainText ?? full.split(',').first;
    final rest = pred.structuredFormatting?.secondaryText ??
        (full.contains(',') ? full.substring(full.indexOf(',') + 1).trim() : '');
    return InkWell(
      onTap: _saving ? null : () => _saveLine(picked: pred),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.dp(13),
          vertical: context.dp(11),
        ),
        child: Row(
          children: [
            Container(
              width: context.dp(30),
              height: context.dp(30),
              decoration: BoxDecoration(
                color: theme.primaryTint,
                borderRadius: BorderRadius.circular(context.dp(9)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.location_on_outlined,
                size: context.dp(15),
                color: theme.primaryHover,
              ),
            ),
            SizedBox(width: context.dp(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    street,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: aoText(
                      14,
                      FontWeight.w800,
                      letterSpacingEm: -0.01,
                      color: theme.text,
                    ),
                  ),
                  if (rest.isNotEmpty)
                    Text(
                      rest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aoText(
                        11.5,
                        FontWeight.w600,
                        color: ScSaasThemeTokens.gray500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.north_east_rounded,
              size: context.dp(15),
              color: const Color(0xFFD0CCD8),
            ),
          ],
        ),
      ),
    );
  }
}

class DugnadAddAddressCard extends StatelessWidget {
  const DugnadAddAddressCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.dp(18)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.dp(20)),
          border: Border.all(width: 1.5, color: const Color(0xFFE6DFF7)),
          boxShadow: ScSaasThemeTokens.shadowCard,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: context.dp(56),
              height: context.dp(56),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.primaryTint,
                borderRadius: BorderRadius.circular(context.dp(16)),
              ),
              child: Icon(
                Icons.add_rounded,
                size: context.dp(30),
                color: theme.primaryHover,
              ),
            ),
            SizedBox(width: context.dp(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languages.addAddress,
                    style: aoText(
                      16,
                      FontWeight.w800,
                      letterSpacingEm: -0.01,
                      color: theme.text,
                    ),
                  ),
                  SizedBox(height: context.dp(2)),
                  Text(
                    languages.dugnadAddressDeliverMultiple,
                    style: aoText(
                      12.5,
                      FontWeight.w600,
                      height: 1.35,
                      color: ScSaasThemeTokens.gray500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.dp(12)),
            Icon(
              Icons.chevron_right_rounded,
              size: context.dp(22),
              color: kAoGray400,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet-style address card. Checkout sheet shows a check when selected
/// and a trash icon otherwise. Leveringsadresse keeps edit/delete outside.
class DugnadAddressPickCard extends StatelessWidget {
  const DugnadAddressPickCard({
    super.key,
    required this.address,
    this.selected = false,
    this.enabled = true,
    this.showCheckWhenSelected = false,
    this.onTap,
    this.onDelete,
  });

  final AddressListItem address;
  final bool selected;
  final bool enabled;
  final bool showCheckWhenSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = context.dugnadTheme;
    final radius = BorderRadius.circular(context.dp(20));
    final trailing = _trailing(context, theme);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.all(context.dp(18)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(
              width: selected ? 2 : 1.5,
              color: selected ? theme.primaryHover : const Color(0x140E214A),
            ),
            boxShadow: ScSaasThemeTokens.shadowCard,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.dp(62),
                height: context.dp(62),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0FB),
                  borderRadius: BorderRadius.circular(context.dp(16)),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: context.dp(28),
                  color: theme.primaryHover,
                ),
              ),
              SizedBox(width: context.dp(16)),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        addressDisplayTitle(address),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: aoText(
                          15,
                          FontWeight.w800,
                          height: 1.25,
                          letterSpacingEm: -0.01,
                          color: theme.text,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      SizedBox(width: context.dp(10)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F0FB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          languages.dugnadAddressStandardBadge,
                          style: aoText(
                            10,
                            FontWeight.w800,
                            letterSpacingEm: 0.03,
                            color: const Color(0xFF4A628A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: context.dp(8)),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _trailing(BuildContext context, DugnadClubThemePalette theme) {
    if (showCheckWhenSelected && selected) {
      return Container(
        width: context.dp(38),
        height: context.dp(38),
        decoration: BoxDecoration(
          color: theme.primaryHover,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: context.dp(22),
        ),
      );
    }
    if (onDelete == null) return null;
    return IconButton(
      onPressed: enabled ? onDelete : null,
      splashRadius: 20,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: context.dp(38),
        height: context.dp(38),
      ),
      icon: Icon(
        Icons.delete_outline_rounded,
        color: kAoGray400,
        size: context.dp(22),
      ),
    );
  }
}
