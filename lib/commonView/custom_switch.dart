import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  final bool value;
  final double width;
  final double radius;
  final Color activeColor;
  final Color disableColor;
  final Color thumbColor;
  final double thumbSize;
  final EdgeInsets innerPadding;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({
    super.key,
    this.value = false,
    required this.onChanged,
    required this.width,
    required this.radius,
    required this.activeColor,
    required this.disableColor,
    required this.thumbColor,
    required this.innerPadding,
    required this.thumbSize,
  });

  @override
  State createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  Alignment switchControlAlignment = Alignment.centerLeft;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: widget.value ? widget.activeColor : widget.disableColor,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
          curve: Curves.decelerate,
          child: Padding(
            padding: widget.innerPadding,
            child: Container(
              width: widget.thumbSize,
              height: widget.thumbSize,
              decoration: BoxDecoration(
                color: widget.thumbColor,
                borderRadius: BorderRadius.circular(widget.thumbSize / 2),
              ),
            ),
          ),
        ),
      ),
      onTap: () {
        widget.onChanged(!widget.value);
      },
    );
  }
}
