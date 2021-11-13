

import 'package:flutter/material.dart';

class DeviceScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    Text(
      'Hello, device! How are you?',
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    throw UnimplementedError();
  }

}