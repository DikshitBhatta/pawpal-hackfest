import 'dart:io';
import 'dart:math';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/HomePage/addPetFormDark2.dart';
import 'package:pet_care/widgets/step_progress_indicator.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';

// Custom input formatter for date formatting (MM/DD/YYYY)
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('/', '');
    
    // Limit to 8 digits (MMDDYYYY)
    if (text.length > 8) {
      text = text.substring(0, 8);
    }
    
    String formattedText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formattedText += '/';
      }
      formattedText += text[i];
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class addPetFormDark extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic>? petData;  // optional for edit
  const addPetFormDark({super.key, required this.userData, this.petData});

  @override
  State<addPetFormDark> createState() => _addPetFormDarkState();
}

class _addPetFormDarkState extends State<addPetFormDark> {
  bool showSpinner = false;
  LatLng? _current;

  DateTime date = DateTime.now();

  GlobalKey<FormState> petForm = GlobalKey<FormState>();
  TextEditingController petNameController = TextEditingController();
  TextEditingController oneLineController = TextEditingController();
  TextEditingController breedController = TextEditingController();
  TextEditingController dateOfBirthController = TextEditingController();
  String dropdownvalue = 'Select Breed'; // Default placeholder
  File? pickedImage;
  String selectedCategory = "Dog"; // Always Dog since this is a dog-only app
  bool isImageUpload = false,
      isDateOfBirthSelected = false;

  // Remove cat breeds since this is a dog-only app
  var dogValue = [
    'Select Breed', // Placeholder option
    'Labrador Retriever',
    'German Shepherd',
    'Golden Retriever',
    'Bulldog',
    'Beagle',
    'Poodle',
    'Siberian Husky',
    'Rottweiler',
    'Yorkshire Terrier',
    'Boxer',
    'Dachshund',
    'Pomeranian',
    'Australian Shepherd',
    'Border Collie',
    'Cocker Spaniel',
    'French Bulldog',
    'Chihuahua',
    'Mixed Breed'
  ];

  @override
  void initState() {
    // Format as MM/DD/YYYY
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    dateOfBirthController.text = "$month/$day/${date.year}";
    getLocationUpdates();
    super.initState();
  }

  allValuesFilled() {
    // Check if basic required fields are filled
    if (petNameController.text.trim().isEmpty) {
      showErrorSnackBar("Please enter your pet's name 🐕");
      return false;
    }

    // Check if description is filled
    if (oneLineController.text.trim().isEmpty) {
      showErrorSnackBar("Please enter a one-line description about your pet 📝");
      return false;
    }

    // Make breed mandatory (check if still default value)
    if (dropdownvalue == 'Select Breed') {
      showErrorSnackBar("Please select your pet's breed 🎯");
      return false;
    }

    // Make date of birth mandatory
    if (!isDateOfBirthSelected && dateOfBirthController.text.isEmpty) {
      showErrorSnackBar("Please select your pet's date of birth 📅");
      return false;
    }

    return true;
  }

  void showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Oops! 😅',
        message: message,
        contentType: ContentType.failure,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  showAlertBoxs() {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pic Image From"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () {
                  pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
                leading: Icon(Icons.camera_alt),
                title: Text("Camera"),
              ),
              ListTile(
                onTap: () {
                  pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
                leading: Icon(Icons.image),
                title: Text("Gallery"),
              )
            ],
          ),
        );
      },
    );
  }

  pickImage(ImageSource imageSource) async {
    try {
      final photo = await ImagePicker().pickImage(source: imageSource);
      if (photo == null) {
        return;
      }
      final tempImage = File(photo.path);
      setState(() {
        isImageUpload = true;
        pickedImage = tempImage;
      });
    } catch (ex) {
      print("Error ${ex.toString()}");
    }
  }

  Future<void> getLocationUpdates() async {
    Location _locationController = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGuranted;

    // Check if location service is enabled
    _serviceEnabled = await _locationController.serviceEnabled();
    
    // Enable location service if needed
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        _showErrorDialog("Location Service Not Available", 
          "Please enable location services in your device settings to continue.");
        return;
      }
    }

    // Check current permission status
    _permissionGuranted = await _locationController.hasPermission();

    // Only request permission if it's denied
    if (_permissionGuranted == PermissionStatus.denied) {
      // Request system permission directly (this will show the system dialog)
      _permissionGuranted = await _locationController.requestPermission();
      if (_permissionGuranted != PermissionStatus.granted) {
        _showErrorDialog("Location Permission Required", 
          "Location access is needed to provide personalized pet services. Please allow location access.");
        return;
      }
    }

    // Now start location listener only if we have permission
    if (_permissionGuranted == PermissionStatus.granted) {
      _locationController.onLocationChanged.listen((LocationData currentLocation) {
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          setState(() {
            _current = LatLng(currentLocation.latitude!, currentLocation.longitude!);
            print("Location : $_current");
          });
        }
      }).onError((error) {
        print("Location error: $error");
        _showErrorDialog("Location Not Accessible", 
          "Unable to access your location. Please check your device settings.");
      });
    } else {
      _showErrorDialog("Location Not Accessible", 
        "Unable to access your location. Please check your device settings.");
    }
  }

  // Custom error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Color(0xff352F44),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 30,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 16),
                
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TextColor,
                  ),
                ),
                SizedBox(height: 12),
                
                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: subTextColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  continueToNextPage() async {
    setState(() {
      showSpinner = true;
    });

    try {
      if (allValuesFilled()) {
        if (petForm.currentState!.validate()) {
                    // Prepare initial pet data to pass to next page
          Map<String, dynamic> petData = {
            "Email": widget.userData["Email"],
            "Name": petNameController.text,
            "Category": "Dog", // Always Dog since this is a dog-only app
            "Breed": dropdownvalue,
            "DateOfBirth": dateOfBirthController.text,
            "LAT": _current?.latitude,
            "LONG": _current?.longitude,
            "oneLine": oneLineController.text, // Add the description field
            // Add image reference for later upload
            "pickedImage": pickedImage,
          };

          setState(() {
            showSpinner = false;
          });

          // Navigate to the next page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => addPetFormDark2(
                userData: widget.userData,
                petData: petData,
              ),
            ),
          );
        } else {
          setState(() {
            showSpinner = false;
          });
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'Error!',
              message: 'Please Fill All The Details!',
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
      setState(() {
        showSpinner = false;
      });
    } catch (ex) {
      setState(() {
        showSpinner = false;
      });
      print(ex.toString());
    }
  }

  isNameFilled(value) {
    if (value == "") {
      return "Please Enter Pet Name";
    }
    return null;
  }

  isOneLineFilled(value) {
    if (value == "") {
      return "Please Enter One Line Description";
    }
    return null;
  }

  // Custom Date Picker Widget with Manual Entry
  Widget _buildCustomDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🎂 Date of Birth *",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateOfBirthController.text.isEmpty 
                              ? "Select date" 
                              : dateOfBirthController.text,
                            style: TextStyle(
                              fontSize: 16,
                              color: dateOfBirthController.text.isEmpty 
                                ? Colors.grey[600] 
                                : Colors.black87,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showEditDateDialog(),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showSystemDatePicker(),
                  icon: Icon(Icons.calendar_month, size: 18),
                  label: Text("Pick"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Show edit date dialog with automatic slash formatting
  void _showEditDateDialog() {
    TextEditingController tempController = TextEditingController();
    tempController.text = dateOfBirthController.text;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Color(0xff352F44),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Select date",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                
                // Display current date
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tempController.text.isEmpty 
                          ? "Fri, Aug 22" 
                          : _formatDisplayDate(tempController.text),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Focus on the text field below
                        },
                        child: Icon(
                          Icons.edit,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Manual entry field with auto-formatting
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: tempController,
                    inputFormatters: [
                      DateInputFormatter(),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: "Enter Date",
                      hintText: "MM/DD/YYYY",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      // Update the display as user types
                    },
                  ),
                ),
                SizedBox(height: 20),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_validateDate(tempController.text)) {
                          setState(() {
                            dateOfBirthController.text = tempController.text;
                            isDateOfBirthSelected = true;
                          });
                          Navigator.of(context).pop();
                        } else {
                          // Show error
                          showErrorSnackBar("Please enter a valid date in MM/DD/YYYY format");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show system date picker
  void _showSystemDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        date = pickedDate;
        isDateOfBirthSelected = true;
        // Format as MM/DD/YYYY
        String month = date.month.toString().padLeft(2, '0');
        String day = date.day.toString().padLeft(2, '0');
        dateOfBirthController.text = "$month/$day/${date.year}";
      });
    }
  }

  // Helper method to format date for display
  String _formatDisplayDate(String dateString) {
    if (dateString.isEmpty) return "Select date";
    
    try {
      List<String> parts = dateString.split('/');
      if (parts.length == 3) {
        int month = int.parse(parts[0]);
        int day = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        
        DateTime date = DateTime(year, month, day);
        List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        
        String weekday = weekdays[date.weekday - 1];
        String monthName = months[date.month - 1];
        
        return "$weekday, $monthName $day";
      }
    } catch (e) {
      // If parsing fails, return the original string
    }
    
    return dateString;
  }

  // Validate date format and value
  bool _validateDate(String value) {
    if (value.isEmpty) return false;
    
    // Basic date format validation
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
      return false;
    }
    
    // Additional date validity check
    try {
      List<String> parts = value.split('/');
      int month = int.parse(parts[0]);
      int day = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      if (year < 1990 || year > DateTime.now().year) return false;
      
      // Check if the date is valid
      DateTime birthDate = DateTime(year, month, day);
      if (birthDate.isAfter(DateTime.now())) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Pet",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: listTileColorSecond,
          ),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Stack(
          children: [
            PetBackgroundPattern(
              opacity: 0.8,
              symbolSize: 80.0,
              density: 0.3,
            ),
            Container(
          height: double.maxFinite,
          decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff2A2438).withOpacity(0.85), // Semi-transparent
                    Color(0xff77669E).withOpacity(0.85), // Semi-transparent
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: petForm,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Step Progress Indicator
                    StepProgressIndicator(
                      currentStep: 1,
                      totalSteps: 5,
                      stepLabels: [
                        'Basic Info',
                        'Details',
                        'Food Prefs',
                        'Physical',
                        'Health',
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        // var imagePicker = ImagePicker();
                        // var image = await imagePicker.pickImage(
                        //     source: ImageSource.gallery);
                        // if (image != null) {
                        //   setState(() {
                        //     pickedImage = File(image.path);
                        //     isImageUpload = true;
                        //   });
                        // }
                        showAlertBoxs();
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.teal,
                                width: 3.0,
                              ),
                            ),
                      child: CircleAvatar(
                        backgroundColor: buttonColor,
                        radius: 60,
                        backgroundImage:
                        pickedImage != null ? FileImage(pickedImage!) : null,
                        child: pickedImage == null
                                  ? ClipOval(
                                      child: Image.asset(
                                        'assets/images/placeholder.png',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                        )
                            : null,
                      ),
                    ),
                          if (pickedImage == null)
                            Positioned(
                              bottom: -10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.all(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "🐶 Add your pet's photo!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: petNameController,
                      validator: (value) => isNameFilled(value),
                      decoration: InputDecoration(
                        labelText: "🐾 Pet Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: oneLineController,
                      validator: (value) => isOneLineFilled(value),
                      decoration: InputDecoration(
                        labelText: "📝 One Line Description",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Remove category selection since this is a dog-only app
                    DropdownButtonFormField(
                      value: dropdownvalue,
                      onChanged: (newValue) {
                        setState(() {
                          dropdownvalue = newValue as String;
                        });
                      },
                      items: dogValue.map((String item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: "🐕 Dog Breed",
                        hintText: "Select your pet's breed *",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Custom Date Picker with Manual Entry
                    _buildCustomDatePicker(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: continueToNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appBarColor,
                        minimumSize: Size(220, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 18,
                              color: subTextColor
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: subTextColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}
