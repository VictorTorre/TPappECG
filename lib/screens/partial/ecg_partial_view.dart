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
  final identifier = '7E1B542A';
  final Color colorLine = Colors.redAccent;

  final limitCount = 100;
  final points = <FlSpot>[];

  double xValue = 0;
  double step = 0.04;
  bool _firstTime = true;
  String _textState =
      "Active el Bluetooth y colóquese el dispositivo en el pecho para empezar por favor";
  List<int> joinedECGdata = <int>[];

  //late Timer timer;
  late final Polar polar;

  // List<int> testData = <int>[
  //   -198,
  //   -206,
  //   -203,
  //   -206,
  //   -215,
  //   -206,
  //   -201,
  //   -218,
  //   -218,
  //   -208,
  //   -225,
  //   -240,
  //   -227,
  //   -220,
  //   -215,
  //   -194,
  //   -184,
  //   -194,
  //   -196,
  //   -196,
  //   -191,
  //   -174,
  //   -169,
  //   -184,
  //   -196,
  //   -186,
  //   -152,
  //   -116,
  //   -101,
  //   -128,
  //   -155,
  //   -157,
  //   -150,
  //   -150,
  //   -150,
  //   -157,
  //   -189,
  //   -206,
  //   -186,
  //   -143,
  //   -9,
  //   264,
  //   417,
  //   106,
  //   -375,
  //   -446,
  //   -257,
  //   -225,
  //   -254,
  //   -227,
  //   -225,
  //   -240,
  //   -237,
  //   -249,
  //   -259,
  //   -252,
  //   -252,
  //   -254,
  //   -242,
  //   -225,
  //   -215,
  //   -210,
  //   -208,
  //   -206,
  //   -196,
  //   -184,
  //   -181,
  //   -198,
  //   -203,
  //   -184,
  //   -174,
  //   -172,
  //   -164
  // ];

  List<int> prepareECGdata() {
    return <int>[];
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
    // var dummyData = {
    //   'data': [40, 50, 50, 80],
    //   'read_date': '2021-11-04',
    //   'user': 1
    // };
    // print(dummyData['data'].toString());

    var currentDatetime = DateTime.now();
    var response = await topic.publishString(
        'Envío de datos del wearable con fecha de ' +
            DateFormat('dd-MM-yyyy:H:m:s').format(currentDatetime),
        attributes: {
          "data": joinedECGdata.toString(),
          'read_date': DateFormat('yyyy-MM-dd').format(currentDatetime),
          'user': '1'
        });

    print(response);
  }

  @override
  void initState() {
    super.initState();

    polar = Polar();
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

          while (points.length > limitCount) {
            points.removeAt(0);
          }

          joinedECGdata.addAll(e.samples);
          for (var i = 0; i < e.samples.length; i++) {
            points.add(FlSpot(xValue, e.samples[i] / 1000.0));
            xValue += step;
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
    //sentToGCloud();
    //timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
          points.isNotEmpty
              ? SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      minY: -1,
                      maxY: 1,
                      minX: points.first.x,
                      maxX: points.last.x,
                      lineTouchData: LineTouchData(enabled: false),
                      clipData: FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      lineBarsData: [
                        line(points),
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

  LineChartBarData line(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      colors: [colorLine.withOpacity(0), colorLine],
      colorStops: [0.1, 1.0],
      barWidth: 4,
      isCurved: false,
    );
  }

  @override
  void dispose() {
    //timer.cancel();
    super.dispose();
  }
}
