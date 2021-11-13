

import 'package:flutter/material.dart';

class EcgScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    Text(
      'Hello, ecg! How are you?',
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    throw UnimplementedError();
  }

}