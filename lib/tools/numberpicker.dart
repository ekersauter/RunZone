import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class IntegerPicker extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final int step;
  final double itemHeight;
  final Axis axis;
  final Function callbackFunction;
  const IntegerPicker(
      {Key? key,
      required this.value,
      this.minValue = 10,
      this.maxValue = 600,
      this.step = 10,
      this.itemHeight = 100,
      this.axis = Axis.horizontal,
      required this.callbackFunction})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return NumberPicker(
      value: value,
      minValue: minValue,
      maxValue: maxValue,
      step: step,
      itemHeight: itemHeight,
      axis: Axis.horizontal,
      onChanged: (value) {
        callbackFunction(value);
      },
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
    );
  }
}
