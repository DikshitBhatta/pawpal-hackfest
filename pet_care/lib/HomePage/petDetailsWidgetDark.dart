import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/utils/image_utils.dart';
import 'package:pet_care/AIScreen/AIMealPlanScreen.dart';
import 'package:pet_care/HomePage/EditPetForm.dart';

class PetDetailsWidgetDark extends StatefulWidget {
  final Map<String, dynamic>? petData;
  final Map<String, dynamic>? userData;

  PetDetailsWidgetDark({super.key, required this.petData, this.userData});

  @override
  State<PetDetailsWidgetDark> createState() => _PetDetailsWidgetDarkState();
}

class _PetDetailsWidgetDarkState extends State<PetDetailsWidgetDark> {
  
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

  // Helper function to build detail cards
  Widget buildDetailCard(String title, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: listTileColorSecond,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
              color: Colors.teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: Colors.teal,
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
                    color: subHeadingColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: subTextColor,
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
        gradient: backgroundColor,
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
              gradient: BackgroundOverlayColorReverse,
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
                  child: ImageUtils.buildProfileAvatar(
                    imagePath: widget.petData?["Photo"],
                    radius: 50,
                    backgroundColor: Colors.white70,
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
                          color: TextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      // Pet Type/Species
                      Row(
                        children: [
                          Icon(
                            Icons.pets,
                            color: Colors.teal,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            widget.petData?["Category"] ?? "Pet",
                            style: TextStyle(
                              fontSize: 16,
                              color: TextColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Breed Information - Show here as requested
                      if (widget.petData?["Breed"] != null)
                        Row(
                          children: [
                            Icon(
                              Icons.bookmark,
                              color: Colors.orange,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              widget.petData!["Breed"].toString(),
                              style: TextStyle(
                                fontSize: 16,
                                color: TextColor.withOpacity(0.8),
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
                            color: TextColor.withOpacity(0.7),
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
                  
                  // Weight Section
                  if (widget.petData?["weight"] != null)
                    buildDetailCard(
                      "Weight",
                      "${widget.petData!["weight"]} ${widget.petData?["weightUnit"] ?? "kg"}",
                      Icons.fitness_center,
                    ),
                  
                  // Activity Level Section
                  if (widget.petData?["activityLevel"] != null)
                    buildDetailCard(
                      "Activity Level",
                      widget.petData!["activityLevel"].toString(),
                      Icons.directions_run,
                    ),
                  
                  // Health Goals Section
                  if (widget.petData?["healthGoals"] != null && (widget.petData!["healthGoals"] as List).isNotEmpty)
                    buildDetailCard(
                      "Health Goals",
                      (widget.petData!["healthGoals"] as List).join(", "),
                      Icons.health_and_safety,
                    ),
                  
                  // Custom Health Goal Section
                  if (widget.petData?["customHealthGoal"] != null && widget.petData!["customHealthGoal"].toString().isNotEmpty)
                    buildDetailCard(
                      "Custom Health Goal",
                      widget.petData!["customHealthGoal"].toString(),
                      Icons.assignment,
                    ),
                  
                  // Favorites Section
                  if (widget.petData?["favorites"] != null && (widget.petData!["favorites"] as List).isNotEmpty)
                    buildDetailCard(
                      "Favorite Foods",
                      (widget.petData!["favorites"] as List).join(", "),
                      Icons.favorite,
                    ),
                  
                  // Allergies Section
                  if (widget.petData?["allergies"] != null && (widget.petData!["allergies"] as List).isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: listTileColorSecond,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
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
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Allergies",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: subHeadingColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  (widget.petData!["allergies"] as List).join(", "),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Health Notes Section
                  if (widget.petData?["healthNotes"] != null && widget.petData!["healthNotes"].toString().isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: listTileColorSecond,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
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
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(
                                  Icons.medical_information,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                "Health Notes",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: subHeadingColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              widget.petData!["healthNotes"].toString(),
                              style: TextStyle(
                                fontSize: 15,
                                color: subTextColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Poop Status Section
                  if (widget.petData?["poopDescription"] != null)
                    buildDetailCard(
                      "Poop Status",
                      widget.petData!["poopDescription"].toString(),
                      Icons.pets,
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
                      "AI Meal Plan",
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
                    onPressed: () async {
                      if (widget.petData != null && widget.userData != null) {
                        // Navigate to edit form with existing data
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPetForm(
                              userData: widget.userData!,
                              petData: widget.petData!,
                            ),
                          ),
                        );
                        
                        // If pet data was updated, refresh the current screen
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            // Update the local pet data with the returned data
                            widget.petData!.addAll(result);
                          });
                        }
                      } else {
                        // Show error if userData is not available
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Unable to edit pet. User data not available.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
                      backgroundColor: MaterialStateProperty.all(buttonColor),
                      padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(vertical: 16.0)),
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
