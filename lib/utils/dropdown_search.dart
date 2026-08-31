import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:aerend_customer/commonView/load_image_with_placeholder.dart';
import 'package:aerend_customer/constant/colors.dart';
import 'package:aerend_customer/googleApi/google_api_repo.dart';

class DropdownSearch extends StatefulWidget {
  final TextEditingController? textController;
  final String country;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final TextStyle? dropdownTextStyle;
  final IconData? suffixIcon;
  final double? dropdownHeight;
  final Color? dropdownBgColor;
  final InputBorder? textFieldBorder;
  final EdgeInsetsGeometry? contentPadding;
  final Function(LatLng latLng) updateLatLng;

  const DropdownSearch(
      {super.key,
      required this.textController,
      required this.country,
      this.hintText,
      this.hintStyle,
      this.style,
      this.dropdownTextStyle,
      this.suffixIcon,
      this.dropdownHeight,
      this.dropdownBgColor,
      this.textFieldBorder,
      this.contentPadding,
      required this.updateLatLng});

  @override
  State<DropdownSearch> createState() => DropdownSearchState();
}

class DropdownSearchState extends State<DropdownSearch> {
  bool _isTapped = false;
  List _filteredList = [];
  final List<String> items = [];

  @override
  initState() {
    _filteredList = items;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ///Text Field
        TextFormField(
          controller: widget.textController,
          onChanged: (val) async {
            final response = await GoogleApiRepo().getAddressListFromKeyword(
                widget.textController!.text, widget.country);
            List predictions = response["predictions"];
            List addressList = predictions
                .map((item) => {
                      "description": item["description"],
                      "name":
                          item["structured_formatting"]["main_text"] as String,
                      "place_id": item["place_id"]
                    })
                .toList();
            setState(() {
              _filteredList = addressList;
            });
          },
          validator: (val) => val!.isEmpty ? 'Field can\'t empty' : null,
          style: widget.style ??
              TextStyle(color: Colors.grey.shade800, fontSize: 16.0),
          onTap: () => setState(() => _isTapped = true),
          decoration: InputDecoration(
              filled: true,
              fillColor: colorWhite,
              border: widget.textFieldBorder ?? const UnderlineInputBorder(),
              hintText: widget.hintText ?? "Write here...",
              hintStyle: widget.hintStyle ??
                  const TextStyle(fontSize: 16.0, color: Colors.grey),
              // suffixIcon:
              //     Icon(widget.suffixIcon ?? Icons.expand_more, size: 25),
              contentPadding: widget.contentPadding ??
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              isDense: true,
              suffixIconConstraints:
                  BoxConstraints.loose(MediaQuery.of(context).size),
              suffix: InkWell(
                  onTap: () {
                    widget.textController!.clear();
                    setState(() => _filteredList = items);
                  },
                  child: const Icon(Icons.clear, color: Colors.grey))),
        ),

        ///Dropdown Items
        _isTapped && _filteredList.isNotEmpty
            ? Container(
                height: widget.dropdownHeight ?? 150.0,
                color: widget.dropdownBgColor ?? Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView.builder(
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () async {
                        widget.textController!.text =
                            _filteredList[index]["description"];
                        final response = await GoogleApiRepo()
                            .getPlaceNameFormID(
                                _filteredList[index]["place_id"]);
                        double lat =
                            response["result"]["geometry"]["location"]!["lat"];
                        double lng =
                            response["result"]["geometry"]["location"]!["lng"];
                        setState(() {
                          widget.updateLatLng(LatLng(lat, lng));
                          _isTapped = !_isTapped;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const LoadImageSimple(
                              image: 'assets/images/location.png',
                              width: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _filteredList[index]['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorBlack,
                                    fontSize: 16.0,
                                  ),
                                ),
                                Text(
                                  _filteredList[index]['description'].length >
                                          43
                                      ? _filteredList[index]['description']
                                          .substring(0, 43)
                                      : _filteredList[index]['description'],
                                  style: const TextStyle(
                                    color: colorMainGray,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
