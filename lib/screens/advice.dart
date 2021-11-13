

import 'package:flutter/material.dart';

class AdviceScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    Text(
      'Hello, advice! How are you?',
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    throw UnimplementedError();
  }

}