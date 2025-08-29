import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/AIScreen/AIMealPlanScreen.dart';
import 'package:pet_care/utils/image_utils.dart';

class PetDetailsWidget extends StatefulWidget {
  final Map<String, dynamic>? petData;

  PetDetailsWidget({super.key, required this.petData});

  @override
  State<PetDetailsWidget> createState() => _PetDetailsWidgetState();
}

class _PetDetailsWidgetState extends State<PetDetailsWidget> {
  
  // Helper function to calculate age from date of birth
  String calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null || dateOfBirth.isEmpty) return "Unknown";
    
    try {
      // Parse the date - assuming format like "DD/MM/YYYY" or similar
      List<String> dateParts = dateOfBirth.split('/');
      if (dateParts.length != 3) return "Invalid Date";
      
      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);
      
      DateTime birthDate = DateTime(year, month, day);
      DateTime now = DateTime.now();
      
      int ageYears = now.year - birthDate.year;
      int ageMonths = now.month - birthDate.month;
      
      if (ageMonths < 0) {
        ageYears--;
        ageMonths += 12;
      }
      
      if (ageYears > 0) {
        return ageMonths > 0 ? "$ageYears years, $ageMonths months" : "$ageYears years";
      } else {
        return ageMonths > 0 ? "$ageMonths months" : "Less than a month";
      }
    } catch (e) {
      return "Invalid Date";
    }
  }

  // Helper function to build detail cards for light theme
  Widget buildDetailCard(String title, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: Colors.teal.shade700,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pet Info Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(10),
                topLeft: Radius.circular(10),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pet Photo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ImageUtils.buildPetAvatar(
                    imagePath: widget.petData?["Photo"],
                    radius: 50,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet Name
                      Text(
                        widget.petData?["Name"] ?? "Unknown Pet",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      SizedBox(height: 4),
                      // Pet Type/Species
                      Row(
                        children: [
                          Icon(
                            Icons.pets,
                            color: Colors.teal.shade700,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            widget.petData?["Type"] ?? widget.petData?["Species"] ?? "Pet",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // One Line Description
                      if (widget.petData?["oneLine"] != null)
                        Text(
                          widget.petData!["oneLine"],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.teal.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Display selected pet details in a nice format
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: [
                  // Age Section
                  buildDetailCard(
                    "Age",
                    calculateAge(widget.petData?["DateOfBirth"]),
                    Icons.cake,
                  ),
                  
                  // Date of Birth Section
                  if (widget.petData?["DateOfBirth"] != null)
                    buildDetailCard(
                      "Date of Birth",
                      widget.petData!["DateOfBirth"].toString(),
                      Icons.calendar_today,
                    ),
                  
                  // Breed Section
                  if (widget.petData?["Breed"] != null)
                    buildDetailCard(
                      "Breed",
                      widget.petData!["Breed"].toString(),
                      Icons.pets,
                    ),
                  
                  // Weight Section
                  if (widget.petData?["Weight"] != null)
                    buildDetailCard(
                      "Weight",
                      "${widget.petData!["Weight"]} kg",
                      Icons.fitness_center,
                    ),
                  
                  // Activity Level Section
                  if (widget.petData?["ActivityLevel"] != null)
                    buildDetailCard(
                      "Activity Level",
                      widget.petData!["ActivityLevel"].toString(),
                      Icons.directions_run,
                    ),
                  
                  // Favorites Section
                  if (widget.petData?["Favorites"] != null)
                    buildDetailCard(
                      "Favorites",
                      widget.petData!["Favorites"].toString(),
                      Icons.favorite,
                    ),
                  
                  // Health Notes Section
                  if (widget.petData?["HealthNotes"] != null && widget.petData!["HealthNotes"].toString().isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.red.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(
                                  Icons.health_and_safety,
                                  color: Colors.red.shade700,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                "Health Notes",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              widget.petData!["HealthNotes"].toString(),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                // AI Meal Plan Button
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AIMealPlanScreen(petData: widget.petData!),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.auto_fix_high,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Generate AI Meal Plan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.green.shade600),
                      padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(vertical: 14.0)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ),
                // Edit Pet Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to pet edit form with existing data
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Edit Pet",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.teal.shade700),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16.0)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
