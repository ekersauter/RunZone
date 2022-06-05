import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:slidable_button/slidable_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunZone',
      theme: ThemeData(
          primarySwatch: Colors.blue, scaffoldBackgroundColor: Colors.grey),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<_PositionItem> _positionItems = <_PositionItem>[];
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  TextToSpeech tts = TextToSpeech();

  final int _interval = 20;
  String _location = '';
  DateTime _displayTime = DateTime.now();
  double _displaySpeed = 0.0;
  double _min_per_km = 0.0;
  bool clicked = false;
  int timer = 0;

  void initState() {
    tts.setVolume(1);
    tts.speak('De startknop staat in het midden onderaan');
    _getLocationAccuracy();
    _askPermission();
    assert(_location == '');
  }

  Future<void> _askPermission() async {
    // ignore: unused_local_variable
    var permission = await GeolocatorPlatform.instance.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      // appBar: AppBar(
      // Here we take the value from the MyHomePage object that was created by
      // the App.build method, and use it to set our appbar title.
      // title: Text(widget.title),
      // ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 80,
                ),
                TextButton(
                    onPressed: () {
                      tts.speak(
                          'Hieronder staat een schuifknop voor de settings');
                    },
                    child: const Text('Settings button'))
              ],
            ),
            const Text('Slide this button to left or right.'),
            const SizedBox(height: 10.0),
            SlidableButton(
              height: 80,
              width: MediaQuery.of(context).size.width / 2,
              buttonWidth: 120.0,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              buttonColor: Theme.of(context).primaryColor,
              dismissible: false,
              label: const Center(child: Text('Slide Me')),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Left'),
                    Text('Right'),
                  ],
                ),
              ),
              onChanged: (position) {
                setState(() {
                  if (position == SlidableButtonPosition.right) {
                    tts.speak('De settings worden geopend');
                  } else {
                    tts.speak('De settings worden gesloten');
                  }
                });
              },
            ),
            const Text(
              'Current location data:',
            ),
            Text(
              '$_displayTime',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _location,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '$_displaySpeed',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _min_per_km.toStringAsFixed(2),
              style: Theme.of(context).textTheme.headline1,
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 60.0),
          child: Transform.scale(
              scale: 3,
              child: FloatingActionButton(
                onPressed: _startStream,
                tooltip: 'Increment',
                child: Icon((clicked != true)
                    ? Icons.start_rounded
                    : Icons.stop_circle_rounded),
              ))),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _getCurrentPosition() async {
    final position = await _geolocatorPlatform.getCurrentPosition();
    _updatePositionList(_PositionItemType.position, position.toString(),
        position.timestamp, position.speed);
  }

  Future<void> _startStream() async {
    setState(() {
      clicked = !clicked;
    });

    final Stream _myStream =
        Stream.periodic(const Duration(seconds: 10), (int count) {
      _getCurrentPosition();
    });

    if (clicked == true) {
      tts.speak('Gestart');
      _myStream.forEach((element) {});
    }

    if (clicked == false) {
      tts.speak('Je hebt de app gestopt');
      SystemNavigator.pop();
    }
  }

  void _updatePositionList(_PositionItemType type, String displayValue,
      DateTime? displayTime, double displaySpeed) {
    _positionItems
        .add(_PositionItem(type, displayValue, displayTime!, displaySpeed));
    setState(() {
      _location = displayValue;
      _displayTime = displayTime;
      _displaySpeed = displaySpeed;
      _min_per_km = displaySpeed != 0 ? ((1 / displaySpeed) / 0.06) : 0.0;
      timer += 10;
    });
    if (timer >= _interval) {
      // int i = 0;
      // double sumSpeed = 0;
      // double avarageSpeed = 0;
      // while (i <= (_interval / 10)) {
      //   sumSpeed += _positionItems[-i].displaySpeed;
      //   i++;
      // }
      // avarageSpeed = sumSpeed / i;
      // avarageSpeed = avarageSpeed != 0 ? ((1 / avarageSpeed) / 0.06) : 0.0;
      // print(avarageSpeed);
      print(_min_per_km);
      setState(() {
        timer = 0;
      });
      (_min_per_km > 0.0)
          ? tts.speak(
              _min_per_km.toStringAsFixed(2).replaceAll('.', ' minuten '))
          : '';
    }
  }

  void _getLocationAccuracy() async {
    final status = await _geolocatorPlatform.getLocationAccuracy();
    print(status);
    _handleLocationAccuracyStatus(status);
  }

  void _handleLocationAccuracyStatus(LocationAccuracyStatus status) {
    String locationAccuracyStatusValue;
    if (status == LocationAccuracyStatus.precise) {
      locationAccuracyStatusValue = 'Precise';
    } else if (status == LocationAccuracyStatus.reduced) {
      locationAccuracyStatusValue = 'Reduced';
    } else {
      locationAccuracyStatusValue = 'Unknown';
    }
    _updatePositionList(
        _PositionItemType.log,
        '$locationAccuracyStatusValue location accuracy granted.',
        DateTime.now(),
        0.0);
  }
}

enum _PositionItemType {
  log,
  position,
}

class _PositionItem {
  _PositionItem(
      this.type, this.displayValue, this.displayTime, this.displaySpeed);
  final _PositionItemType type;
  final String displayValue;
  final DateTime displayTime;
  final double displaySpeed;
}
