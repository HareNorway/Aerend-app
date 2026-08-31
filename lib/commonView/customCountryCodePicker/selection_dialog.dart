import 'package:flutter/material.dart';
import 'package:aerend_customer/theme/sc_saas_theme.dart';

import 'country_code.dart';

/// selection dialog used for selection of the country code
class SelectionDialog extends StatefulWidget {
  final List<CountryCode> elements;
  final bool? showCountryOnly;
  final InputDecoration searchDecoration;
  final TextStyle? searchStyle;
  final TextStyle? textStyle;
  final BoxDecoration? boxDecoration;
  final WidgetBuilder? emptySearchBuilder;
  final bool? showFlag;
  final double flagWidth;
  final Decoration? flagDecoration;
  final Size? size;
  final bool hideSearch;
  final Icon? closeIcon;

  /// Background color of SelectionDialog
  final Color? backgroundColor;

  /// Boxshaow color of SelectionDialog that matches CountryCodePicker barrier color
  final Color? barrierColor;

  /// elements passed as favorite
  final List<CountryCode> favoriteElements;

  SelectionDialog(
    this.elements,
    this.favoriteElements, {
    super.key,
    this.showCountryOnly,
    this.emptySearchBuilder,
    InputDecoration searchDecoration = const InputDecoration(),
    this.searchStyle,
    this.textStyle,
    this.boxDecoration,
    this.showFlag,
    this.flagDecoration,
    this.flagWidth = 32,
    this.size,
    this.backgroundColor,
    this.barrierColor,
    this.hideSearch = false,
    this.closeIcon,
  }) : searchDecoration = searchDecoration.prefixIcon == null
           ? searchDecoration.copyWith(prefixIcon: const Icon(Icons.search))
           : searchDecoration;

  @override
  State<StatefulWidget> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  /// this is useful for filtering purpose
  late List<CountryCode> filteredElements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Container(
        clipBehavior: Clip.hardEdge,
        width: widget.size?.width ?? MediaQuery.of(context).size.width,
        height:
            widget.size?.height ?? MediaQuery.of(context).size.height * 0.85,
        decoration:
            widget.boxDecoration ??
            BoxDecoration(
              color:
                  widget.backgroundColor ??
                  (isDark ? theme.colorScheme.surface : ScSaasThemeTokens.card),
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              boxShadow: [
                BoxShadow(
                  color:
                      widget.barrierColor ??
                      (isDark
                          ? Colors.black.withOpacity(0.8)
                          : ScSaasThemeTokens.muted.withOpacity(0.4)),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              padding: const EdgeInsets.all(0),
              iconSize: 20,
              icon: Icon(
                widget.closeIcon?.icon ?? Icons.close,
                color: theme.iconTheme.color,
                size: widget.closeIcon?.size ?? 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            if (!widget.hideSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  style: widget.searchStyle ?? theme.textTheme.bodyMedium,
                  decoration: widget.searchDecoration,
                  onChanged: _filterElements,
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  widget.favoriteElements.isEmpty
                      ? const DecoratedBox(decoration: BoxDecoration())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...widget.favoriteElements.map(
                              (f) => SimpleDialogOption(
                                child: _buildOption(f),
                                onPressed: () {
                                  _selectItem(f);
                                },
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                  if (filteredElements.isEmpty)
                    _buildEmptySearchWidget(context)
                  else
                    ...filteredElements.map(
                      (e) => SimpleDialogOption(
                        child: _buildOption(e),
                        onPressed: () {
                          _selectItem(e);
                        },
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

  Widget _buildOption(CountryCode e) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseStyle = widget.textStyle ?? theme.textTheme.bodyMedium;
    final textStyle = isDark
        ? baseStyle?.copyWith(color: ScSaasThemeTokens.card)
        : baseStyle;

    return SizedBox(
      width: 400,
      child: Flex(
        direction: Axis.horizontal,
        children: <Widget>[
          if (widget.showFlag == true)
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(right: 16.0),
                decoration: widget.flagDecoration,
                clipBehavior: widget.flagDecoration == null
                    ? Clip.none
                    : Clip.hardEdge,
                child: e.flagUri == null
                    ? SizedBox(width: widget.flagWidth)
                    : Image.asset(
                        e.flagUri!,
                        width: widget.flagWidth,
                        errorBuilder: (_, __, ___) =>
                            SizedBox(width: widget.flagWidth),
                      ),
              ),
            ),
          Expanded(
            flex: 4,
            child: Text(
              widget.showCountryOnly == true
                  ? e.toCountryStringOnly()
                  : e.toLongString(),
              overflow: TextOverflow.fade,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchWidget(BuildContext context) {
    if (widget.emptySearchBuilder != null) {
      return widget.emptySearchBuilder!(context);
    }

    return const Center(child: Text('No country found'));
  }

  @override
  void initState() {
    filteredElements = widget.elements;
    super.initState();
  }

  void _filterElements(String s) {
    s = s.toUpperCase();
    setState(() {
      filteredElements = widget.elements
          .where(
            (e) =>
                e.code!.contains(s) ||
                e.dialCode!.contains(s) ||
                e.name!.toUpperCase().contains(s),
          )
          .toList();
    });
  }

  void _selectItem(CountryCode e) {
    Navigator.pop(context, e);
  }
}
