import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import 'package:polar_poc/screens/home.dart';


void main() {
  runApp(HomeScreen());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const identifier = '7E1B542A';

  late final Polar polar;
  List<String> logs = ['Service started'];

  @override
  void initState() {
    super.initState();

    polar = Polar();
    polar.deviceConnectingStream.listen((_) => plog('Device connecting'));
    polar.deviceConnectedStream.listen((_) => plog('Device connected'));

    polar.heartRateStream.listen((e) => plog('Heart rate: ${e.data.hr}'));
    polar.streamingFeaturesReadyStream.listen((e) {
      if (e.features.contains(DeviceStreamingFeature.ecg)) {
        polar
            .startEcgStreaming(e.identifier)
            .listen((e) => plog('ECG data: ${e.samples}'));
      }
    });

    polar.deviceDisconnectedStream.listen((_) => plog('Device disconnected'));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Polar POC'),
          actions: [
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                plog('Disconnecting from device: $identifier');
                polar.disconnectFromDevice(identifier);
              },
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                plog('Connecting to device: $identifier');
                polar.connectToDevice(identifier);
                plog('Log');
                plog(polar.batteryLevelStream.toString());
                logs.reversed.map((e) => Text(e)).toList();
              },
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.all(20),
          shrinkWrap: true,
          children: logs.reversed.map((e) => Text(e)).toList(),
        ),
      ),
    );
  }

  void plog(String log) {
    print(log);
    setState(() {
      logs.add(log);
    });
  }
}
