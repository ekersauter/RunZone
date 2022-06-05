import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_background/flutter_background.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Wakelock.enable();
  runApp(const MyApp());
}

/// Example [Widget] showing the functionalities of the geolocator plugin
class MyApp extends StatelessWidget {
  /// Creates a new GeolocatorWidget.
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunZone',
      theme: ThemeData(
          primarySwatch: Colors.blue, scaffoldBackgroundColor: Colors.grey),
      home: const MyHomePage(title: 'RunZone'),
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
  TextToSpeech tts = TextToSpeech();
  int speakCounter = 60;
  double stateMinPerKm = 0.0;
  String stateSpeakMinPerKm = 'Geen beweging gevonden';

  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final List<_PositionItem> _positionItems = <_PositionItem>[];
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  bool positionStreamStarted = false;
  final List noMovemend = [
    'Momenteel merk ik nog geen actie',
    'Na verplaatsing kan ik pas de snelheid uitzoeken',
    'Start of zet je opnieuw in gang'
  ];

  @override
  void initState() {
    super.initState();
    _toggleServiceStatusStream();
    tts.speak('De startknop staat rechts onderaan');
  }

  PopupMenuButton _createSettingsPopupActions() {
    return PopupMenuButton(
      elevation: 40,
      onSelected: (value) async {
        switch (value) {
          case 1:
            _getLocationAccuracy();
            break;
          case 2:
            _requestTemporaryFullAccuracy();
            break;
          case 3:
            _openAppSettings();
            break;
          case 4:
            _openLocationSettings();
            break;
          case 5:
            setState(_positionItems.clear);
            break;
          default:
            break;
        }
      },
      itemBuilder: (context) => [
        if (Platform.isIOS)
          const PopupMenuItem(
            child: Text("Get Location Accuracy"),
            value: 1,
          ),
        if (Platform.isIOS)
          const PopupMenuItem(
            child: Text("Request Temporary Full Accuracy"),
            value: 2,
          ),
        const PopupMenuItem(
          child: Text("Open App Settings"),
          value: 3,
        ),
        if (Platform.isAndroid || Platform.isWindows)
          const PopupMenuItem(
            child: Text("Open Location Settings"),
            value: 4,
          ),
        const PopupMenuItem(
          child: Text("Clear"),
          value: 5,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const sizedBox = SizedBox(
      height: 10,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Runzone'),
        actions: [_createSettingsPopupActions()],
      ),
      backgroundColor: Colors.grey,
      body: ListView.builder(
        itemCount: _positionItems.length,
        itemBuilder: (context, index) {
          final positionItem = _positionItems[index];
          if (positionItem.type == _PositionItemType.log) {
            _positionItems.length % speakCounter == 0
                ? tts.speak(stateSpeakMinPerKm)
                : '';
            return Text(
              index.toString() + ' ' + stateMinPerKm.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          } else {
            return Text(
              index.toString() + ' ' + stateMinPerKm.toString(),
              style: const TextStyle(color: Colors.white),
            );
          }
        },
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          sizedBox,
          FloatingActionButton(
            child: const Icon(Icons.back_hand_outlined),
            onPressed: _activeOnBackground,
          ),
          sizedBox,
          FloatingActionButton(
            child: const Icon(Icons.my_location),
            onPressed: _getCurrentPosition,
          ),
          sizedBox,
          FloatingActionButton(
            child: const Icon(Icons.bookmark),
            onPressed: _getLastKnownPosition,
          ),
          sizedBox,
          FloatingActionButton(
            child: (_positionStreamSubscription == null ||
                    _positionStreamSubscription!.isPaused)
                ? const Icon(Icons.play_arrow)
                : const Icon(Icons.pause),
            onPressed: () {
              positionStreamStarted = !positionStreamStarted;
              positionStreamStarted
                  ? tts.speak('Snelheidsmeting is gestart')
                  : tts.speak('Snelheidsmeting is gestopt');
              _toggleListening();
            },
            tooltip: (_positionStreamSubscription == null)
                ? 'Start position updates'
                : _positionStreamSubscription!.isPaused
                    ? 'Resume'
                    : 'Pause',
            backgroundColor: _determineButtonColor(),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handlePermission();

    if (!hasPermission) {
      return;
    }

    final position = await _geolocatorPlatform.getCurrentPosition();

    _updatePositionList(
        _PositionItemType.position, position.toString(), position.speed);
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      _updatePositionList(
          _PositionItemType.log, _kLocationServicesDisabledMessage, 0.0);

      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _updatePositionList(
            _PositionItemType.log, _kPermissionDeniedMessage, 0.0);

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _updatePositionList(
          _PositionItemType.log, _kPermissionDeniedForeverMessage, 0.0);

      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    _updatePositionList(_PositionItemType.log, _kPermissionGrantedMessage, 0.0);
    return true;
  }

  void _updatePositionList(
      _PositionItemType type, String displayValue, double displaySpeed) {
    _positionItems.add(_PositionItem(type, displayValue, displaySpeed));
    double currentMinPerKmSpeed =
        displaySpeed > 0.4 ? ((1 / displaySpeed) / 0.06) : 0.0;
    setState(() {
      stateMinPerKm = currentMinPerKmSpeed;
      stateSpeakMinPerKm =
          currentMinPerKmSpeed.toStringAsFixed(2).replaceAll('.', ' minuten ');
    });
  }

  bool _isListening() => !(_positionStreamSubscription == null ||
      _positionStreamSubscription!.isPaused);

  Color _determineButtonColor() {
    return _isListening() ? Colors.green : Colors.red;
  }

  void _toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription == null) {
      final serviceStatusStream = _geolocatorPlatform.getServiceStatusStream();
      _serviceStatusStreamSubscription =
          serviceStatusStream.handleError((error) {
        _serviceStatusStreamSubscription?.cancel();
        _serviceStatusStreamSubscription = null;
      }).listen((serviceStatus) {
        String serviceStatusValue;
        if (serviceStatus == ServiceStatus.enabled) {
          if (positionStreamStarted) {
            _toggleListening();
          }
          serviceStatusValue = 'enabled';
        } else {
          if (_positionStreamSubscription != null) {
            setState(() {
              _positionStreamSubscription?.cancel();
              _positionStreamSubscription = null;
              _updatePositionList(_PositionItemType.log,
                  'Position Stream has been canceled', 0.0);
            });
          }
          serviceStatusValue = 'disabled';
        }
        _updatePositionList(_PositionItemType.log,
            'Location service has been $serviceStatusValue', 0.0);
      });
    }
  }

  void _toggleListening() {
    if (_positionStreamSubscription == null) {
      final positionStream = _geolocatorPlatform.getPositionStream();
      _positionStreamSubscription = positionStream.handleError((error) {
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = null;
      }).listen((position) => _updatePositionList(
          _PositionItemType.position, position.toString(), position.speed));
      _positionStreamSubscription?.pause();
    }

    setState(() {
      if (_positionStreamSubscription == null) {
        return;
      }

      String statusDisplayValue;
      if (_positionStreamSubscription!.isPaused) {
        _positionStreamSubscription!.resume();
        statusDisplayValue = 'resumed';
      } else {
        _positionStreamSubscription!.pause();
        statusDisplayValue = 'paused';
      }

      _updatePositionList(_PositionItemType.log,
          'Listening for position updates $statusDisplayValue', 0.0);
    });
  }

  @override
  void dispose() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }

    super.dispose();
  }

  void _getLastKnownPosition() async {
    final position = await _geolocatorPlatform.getLastKnownPosition();
    if (position != null) {
      _updatePositionList(
          _PositionItemType.position, position.toString(), position.speed);
    } else {
      _updatePositionList(
          _PositionItemType.log, 'No last known position available', 0.0);
    }
  }

  void _getLocationAccuracy() async {
    final status = await _geolocatorPlatform.getLocationAccuracy();
    _handleLocationAccuracyStatus(status);
  }

  void _requestTemporaryFullAccuracy() async {
    final status = await _geolocatorPlatform.requestTemporaryFullAccuracy(
      purposeKey: "TemporaryPreciseAccuracy",
    );
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
    _updatePositionList(_PositionItemType.log,
        '$locationAccuracyStatusValue location accuracy granted.', 0.0);
  }

  void _openAppSettings() async {
    final opened = await _geolocatorPlatform.openAppSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Application Settings.';
    } else {
      displayValue = 'Error opening Application Settings.';
    }

    _updatePositionList(_PositionItemType.log, displayValue, 0.0);
  }

  void _openLocationSettings() async {
    final opened = await _geolocatorPlatform.openLocationSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Location Settings';
    } else {
      displayValue = 'Error opening Location Settings';
    }

    _updatePositionList(_PositionItemType.log, displayValue, 0.0);
  }

  Future<void> _activeOnBackground() async {
    const config = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Activate on background',
      notificationText:
          'Background notification for keeping the RunZone app running in the background',
      notificationIcon: AndroidResource(name: 'background_icon'),
      notificationImportance: AndroidNotificationImportance.Default,
      enableWifiLock: true,
    );
    var hasPermissions = await FlutterBackground.hasPermissions;
    final backgroundInit =
        await FlutterBackground.initialize(androidConfig: config);
    if (hasPermissions) {
      if (backgroundInit) {
        final backgroundExecution =
            await FlutterBackground.enableBackgroundExecution();
        print(backgroundExecution);
      }
    }
  }
}

enum _PositionItemType {
  log,
  position,
}

class _PositionItem {
  _PositionItem(this.type, this.displayValue, this.displaySpeed);

  final _PositionItemType type;
  final String displayValue;
  final double displaySpeed;
}
