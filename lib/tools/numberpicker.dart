import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class IntegerPicker extends StatefulWidget {
  final int value;
  const IntegerPicker({Key? key, this.value = 60}) : super(key: key);

  @override
  __IntegerPickerState createState() => __IntegerPickerState();
}

class __IntegerPickerState extends State<IntegerPicker> {
  int _currentIntValue = 10;
  int _currentHorizontalIntValue = 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        Text('Default', style: Theme.of(context).textTheme.headline6),
        NumberPicker(
          value: _currentIntValue,
          minValue: 0,
          maxValue: 100,
          step: 10,
          haptics: true,
          onChanged: (value) => setState(() => _currentIntValue = value),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => setState(() {
                final newValue = _currentIntValue - 10;
                _currentIntValue = newValue.clamp(0, 100);
              }),
            ),
            Text('Current int value: $_currentIntValue'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() {
                final newValue = _currentIntValue + 20;
                _currentIntValue = newValue.clamp(0, 100);
              }),
            ),
          ],
        ),
        const Divider(color: Colors.grey, height: 32),
        const SizedBox(height: 16),
        Text('Horizontal', style: Theme.of(context).textTheme.headline6),
        NumberPicker(
          value: _currentHorizontalIntValue,
          minValue: 0,
          maxValue: 100,
          step: 10,
          itemHeight: 100,
          axis: Axis.horizontal,
          onChanged: (value) =>
              setState(() => _currentHorizontalIntValue = value),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black26),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => setState(() {
                final newValue = _currentHorizontalIntValue - 10;
                _currentHorizontalIntValue = newValue.clamp(0, 100);
              }),
            ),
            Text('Current horizontal int value: $_currentHorizontalIntValue'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() {
                final newValue = _currentHorizontalIntValue + 20;
                _currentHorizontalIntValue = newValue.clamp(0, 100);
              }),
            ),
          ],
        ),
      ],
    );
  }
}
