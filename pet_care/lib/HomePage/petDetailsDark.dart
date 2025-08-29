import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/HomePage/petDetailsWidgetDark.dart';

class petDetailsDark extends StatefulWidget {
  final Map<String, dynamic> petData;
  final Map<String, dynamic>? userData;

  const petDetailsDark({super.key, required this.petData, this.userData});

  @override
  State<petDetailsDark> createState() => _petDetailsDarkState();
}

class _petDetailsDarkState extends State<petDetailsDark> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pet Details",
          style: TextStyle(color: TextColor),
        ),
        backgroundColor: appBarColor,
        elevation: 5,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: headingBackgroundColor),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
            child: PetDetailsWidgetDark(petData: widget.petData, userData: widget.userData),
        ),
      ),
    );
  }
}
