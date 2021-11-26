import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gcloud/pubsub.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;
import 'package:polar/polar.dart';
import 'package:intl/intl.dart';

class EcgPartialView extends StatefulWidget {
  EcgPartialView({Key? key}) : super(key: key);

  @override
  _EcgPartialView createState() => _EcgPartialView();
}

class _EcgPartialView extends State<EcgPartialView> {
  final _limitCount = 100;
  final _points = <FlSpot>[];
  double _xValue = 0;
  double _step = 0.04;
  bool _firstTime = true;
  final Color _colorLine = Colors.redAccent;

  Polar polar = Polar();

  static const identifier = '7E1B542A';
  String _textState =
      "Active el Bluetooth y colóquese el dispositivo en el pecho para empezar por favor";
  bool _startECG = false;
  List<int> _joinedECGdata = <int>[];

  void startECG() {
    polar.deviceConnectingStream.listen((_) => setState(() {
          _textState = "Conectando";
        }));
    polar.deviceConnectedStream.listen((_) => setState(() {
          _textState = "Conectado!";
        }));
    var currentTimestamp = 0;
    polar.streamingFeaturesReadyStream.listen((e) {
      if (e.features.contains(DeviceStreamingFeature.ecg)) {
        polar.startEcgStreaming(e.identifier).listen((e) {
          if (_firstTime) {
            currentTimestamp = e.timeStamp;
            _firstTime = false;
          }

          while (_points.length > _limitCount) {
            _points.removeAt(0);
          }

          _joinedECGdata.addAll(e.samples);
          for (var i = 0; i < e.samples.length; i++) {
            _points.add(FlSpot(_xValue, e.samples[i] / 1000.0));
            _xValue += _step;
          }

          if ((e.timeStamp - currentTimestamp) / 1000000000 >= 60) {
            // 1 minuto
            polar.disconnectFromDevice(identifier);
          }

          setState(() {
            print('ECG data: ${e.samples}');
          });
        });
      }
    });
    polar.deviceDisconnectedStream.listen((_) {
      sentToGCloud();
      setState(() {
        _textState = "Desconectado";
      });
    });
    polar.connectToDevice(identifier);
    setState(() {
      _startECG = true;
    });
  }

  void sentToGCloud() async {
    // Read the service account credentials from the file.
    var jsonCredentials =
        await rootBundle.loadString('assets/jsoncredentials_dev_pub.json');
    ;
    var credentials =
        new auth.ServiceAccountCredentials.fromJson(jsonCredentials);

    // Get an HTTP authenticated client using the service account credentials.
    var client = await auth.clientViaServiceAccount(credentials, PubSub.SCOPES);

    // Instantiate objects to access Cloud Datastore, Cloud Storage
    // and Cloud Pub/Sub APIs.
    var pubsub = new PubSub(client, 'systemheart');
    var topic =
        await pubsub.lookupTopic('projects/systemheart/topics/lectureECG');

    var currentDatetime = DateTime.now();
    await topic.publishString(_joinedECGdata.toString(), attributes: {
      'read_date': DateFormat('dd-MM-yyyy:H:m:s').format(currentDatetime),
      'user': '1'
    });
  }

  LineChartBarData line() {
    return LineChartBarData(
      spots: _points,
      dotData: FlDotData(
        show: false,
      ),
      colors: [_colorLine.withOpacity(0), _colorLine],
      colorStops: [0.1, 1.0],
      barWidth: 4,
      isCurved: false,
    );
  }

  @override
  void initState() {
    super.initState();
    //startECG();
  }

  @override
  Widget build(BuildContext context) {
    return !_startECG
        ? Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                      child: Text("Captura de Datos del Electrocardiograma")),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("1. Permanecer en Reposo"),
                      Text("2. No mover el dispositivo durante la prueba"),
                      Text(
                          "3. Los datos proporcionados serán enviados en su Centro de Salud"),
                      Text("4. Los resultados serán visibles en el Hospital")
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    width: 100,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(2.0)),
                    child: TextButton(
                      onPressed: () => startECG(),
                      child: Text(
                        "Empezar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _textState,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                _points.isNotEmpty
                    ? SizedBox(
                        height: 300,
                        child: LineChart(
                          LineChartData(
                            minY: -1,
                            maxY: 1,
                            minX: _points.first.x,
                            maxX: _points.last.x,
                            lineTouchData: LineTouchData(enabled: false),
                            clipData: FlClipData.all(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                            ),
                            lineBarsData: [
                              line(),
                            ],
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container()
              ],
            ),
          );
  }

  @override
  void dispose() {
    polar.disconnectFromDevice(identifier);
    super.dispose();
  }
}
