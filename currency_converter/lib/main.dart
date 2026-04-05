import 'package:flutter/material.dart';

void main(){
  runApp(const MyApp());
}

//Types of widgets in terms of UI
//1. StatelessWidgets
//2. StateFullWidgest
//3. InheritedWidgets

// Types of Desing
// 1. Material Design :- By Google
// 2. Cupertino Design :- By Apple

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      home: Text('Hello World!!!'),
    );
  }
}