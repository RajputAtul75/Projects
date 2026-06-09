import 'package:flutter/material.dart';

class CurrencyConverterMaterialPage extends StatelessWidget {
  const CurrencyConverterMaterialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '0',
              style: TextStyle(
                fontSize: 55,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextField(
              style: TextStyle(
                color: Colors.blue,
              ),
              decoration: InputDecoration(
                hintText: 'Please Enter the amount in USD',
                hintStyle: TextStyle(
                  color : Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}