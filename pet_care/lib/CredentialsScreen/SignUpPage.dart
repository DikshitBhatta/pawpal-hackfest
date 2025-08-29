import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Removed for MVP
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_care/DataBase.dart';
import 'package:pet_care/firestore_service.dart';
import 'package:pet_care/CredentialsScreen/LoginPage.dart';
import 'package:pet_care/HomePage/HomeScreen.dart';
import 'package:pet_care/utils/app_icons.dart';
import 'package:pet_care/uihelper.dart';
import 'package:pet_care/services/image_compression_service.dart';

class SignUpForm extends StatefulWidget {
  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  double borderRadius = 15;
  File? pickedImage;

  showAlertBox() {
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
                leading: AppIcons.cameraIcon(),
                title: Text("Camera"),
              ),
              ListTile(
                onTap: () {
                  pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
                leading: AppIcons.galleryIcon(),
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
      
      // Show image info for user feedback
      final imageInfo = await ImageCompressionService.getImageInfo(tempImage);
      final sizeKB = imageInfo['sizeKB'] ?? 0;
      
      // Show a message about the image size
      if (sizeKB > 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 Profile image selected (${sizeKB}KB). Will be compressed for storage.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 Profile image selected (${sizeKB}KB). Ready for upload.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      setState(() {
        pickedImage = tempImage;
      });
    } catch (ex) {
      print("Error ${ex.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error selecting image: ${ex.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Convert image to base64 string
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);
      return base64String;
    } catch (e) {
      print("Error converting image to base64: $e");
      return null;
    }
  }

  signUP(userData) async {
    try {
      // Show loading indicator
      uiHelper.customAlertBox(() {}, context, "Creating Account...");
      
      // Convert image to base64 if user picked an image
      if (pickedImage != null) {
        String? base64Image = await convertImageToBase64(pickedImage!);
        if (base64Image != null) {
          userData["Pic"] = "data:image/png;base64,$base64Image";
        } else {
          userData["Pic"] = "assets/images/petPic.png"; // Fallback to default
        }
      } else {
        userData["Pic"] = "assets/images/petPic.png"; // Default placeholder
      }
      
      // Create Firebase Auth account
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: userData["Email"], password: userData["Password"])
          .then((value) async {
        
        Navigator.pop(context); // Close loading dialog
        
        // Use FirestoreService to create user document with default role
        bool userCreated = await FirestoreService.createUserDocument(userData);
        
        if (userCreated) {
          // Auto-login: Set user session and navigate to home
          var pref = await SharedPreferences.getInstance();
          pref.setString("userEmail", userData["Email"]);
          
          // Get complete user data for navigation
          Map<String,dynamic> completeUserData = await DataBase.readData("UserData", userData["Email"]);
          
          uiHelper.customAlertBox(() {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => petScreenDynamicDark(userData: completeUserData)));
          }, context, "Account Created Successfully! Welcome!");
        } else {
          return uiHelper.customAlertBox(() {}, context, "User Document Creation Failed");
        }
      });
    } on FirebaseAuthException catch (ex) {
      Navigator.pop(context); // Close any open dialogs
      String errorMessage;
      switch (ex.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered";
          break;
        case 'weak-password':
          errorMessage = "Password is too weak";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format";
          break;
        default:
          errorMessage = ex.message ?? "Signup failed";
      }
      return uiHelper.customAlertBox(() {}, context, errorMessage);
    } catch (e) {
      Navigator.pop(context); // Close any open dialogs
      return uiHelper.customAlertBox(() {}, context, "An error occurred during signup");
    }
  }

  // uploadImage function removed - not needed for MVP without Firebase Storage

  void submitForm() {
    // First validate the form
    if (!_SignupFormKey.currentState!.validate()) {
      uiHelper.customAlertBox(() {}, context, "Please correct the errors in the form");
      return;
    }

    // Get form values
    String email = EmailController.value.text.trim();
    String password = PasswordController.value.text;
    final RegExp emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final RegExp passwordRejex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$');
    final RegExp NameRejex = RegExp(r'\d');
  String Name = NameController.value.text.trim();
    String Email = EmailController.value.text.trim();
    String Password = PasswordController.value.text;
    String ConfirmPassword = ConfirmPasswordController.value.text;
    String City = CityController.value.text.trim();

    // Additional validations
  if (Name.isEmpty ||
    Email.isEmpty ||
    Password.isEmpty ||
    ConfirmPassword.isEmpty ||
    City.isEmpty) {
      uiHelper.customAlertBox(() {}, context, "Please Fill All Fields!");
      return;
    } else if (Name.contains(NameRejex)) {
      uiHelper.customAlertBox(
          () {}, context, "Name Not Valid. Must Not Contains Numbers!");
      return;
    } else if (!email.contains(emailRegex)) {
      uiHelper.customAlertBox(() {}, context, "Email Not Valid!");
      return;
    } else if (password != ConfirmPassword) {
      uiHelper.customAlertBox(
          () {}, context, "Password and Confirm Passwords Must be Same");
      return;
    } else if (!Password.contains(passwordRejex)) {
      uiHelper.customAlertBox(() {}, context,
          "Password Must Contains at Least One Lower Case, Upper Case, Digit, 8 Letters Length");
      return;
    } else if (City.contains(NameRejex)) {
      uiHelper.customAlertBox(
          () {}, context, "City Not Valid. Must Not Contains Numbers!");
      return;
    }
    // Image is now optional - we'll use a default placeholder
    // No need to check for image as we use a default one

    // If all validations pass, create user data and signup
    Map<String, dynamic> userData = {
      "Name": Name,
      "Email": Email,
      "Password": Password,
      "City": City,
      "DateOfBirth": DateOfBirthController,
      "Pic": "assets/images/petPic.png", // Will be updated in signUP method if image is picked
      "isVerified": false,
      "role": "user", // Default role for new users
      "LAT": 31.5607552, // Default coordinates for Lahore, Pakistan
      "LONG": 74.378948
    };

    // Call signup function
    signUP(userData);
  }

  // Image picking is now optional - no validation needed
  checkImagePicked() {
    // This function is kept for potential future use but no longer used in validation
    if (pickedImage == null) {
      return "PLease Pick your Image";
    } else {
      return null;
    }
  }

  String? nameValidator(value) {
    if (value.isEmpty) {
      return ("PLease Enter Name");
    }
    final RegExp NameRejex = RegExp(r'\d');
    if (value.contains(NameRejex)) {
      return ("Name Not Valid.Must Not Contains Numbers!");
    }
    return null;
  }

  // Phone number validation removed because phone number is no longer collected during signup

  String? emailValidator(value) {
    if (value.isEmpty) {
      return ("PLease Enter Email");
    }
    final RegExp emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!value.contains(emailRegex)) {
      return ("Email Not Valid!");
    }
    return null;
  }

  String? passwordValidator(value) {
    if (value.isEmpty) {
      return ("PLease Enter Password");
    }
    final RegExp passwordRejex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$');
    if (!value.contains(passwordRejex)) {
      return ("Password Must Contains at Least One Lower Case,Upper Case,Digit,8 Letters Length");
    }
    return null;
  }

  String? confirmPasswordValidator(value, ConfirmPassword) {
    if (value != ConfirmPassword) {
      return ("Password and Confirm Passwords Must be Same");
    }
    return null;
  }

  String? cityValidator(value) {
    if (value.isEmpty) {
      return ("PLease Enter City");
    }
    final RegExp NameRejex = RegExp(r'\d');
    if (value.contains(NameRejex)) {
      return ("City Not Valid.Must Not Contains Numbers!");
    }
    return null;
  }

  String? dateOfBirthValidator(value) {
    if (DateOfBirthController == "") {
      return ("PLease Enter Date of  birth");
    }

    return null; // Image is now optional, so no need to check
  }

  var NameController = TextEditingController();
  var EmailController = TextEditingController();
  var PasswordController = TextEditingController();
  var ConfirmPasswordController = TextEditingController();
  var CityController = TextEditingController();
  String DateOfBirthController = "";
  var PetController = TextEditingController();
  final GlobalKey<FormState> _SignupFormKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    DateTime date = DateTime(2024);

    return Scaffold(
      appBar: AppBar(
        title: Text("Pet Care"),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Color.fromRGBO(10, 101, 10, 0.2),
          child: Form(
            key: _SignupFormKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                      // color: Colors.grey,
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: showAlertBox,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: pickedImage != null
                              ? FileImage(pickedImage!)
                              : AssetImage('assets/images/petPic.png')
                                  as ImageProvider,
                          child: pickedImage == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey[700],
                                )
                              : null,
                        ),
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10,right: 10,bottom: 8),
                  child: TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: NameController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        label: Text("Name"),
                        prefixIcon: AppIcons.nameIcon(),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius))),
                    validator: (value) => nameValidator(value),
                  ),
                ),
                // Phone number field removed as it's no longer required
                Padding(
                  padding: const EdgeInsets.only(left: 10,right: 10,bottom: 8),
                  child: TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: EmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        label: Text("Email"),
                        prefixIcon: AppIcons.emailIcon(),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius))),
                    validator: (value) => emailValidator(value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10,right: 10,bottom: 8),
                  child: TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: PasswordController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        label: Text("Password"),
                        prefixIcon: AppIcons.passwordIcon(),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius))),
                    validator: (value) => passwordValidator(value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10,right: 10,bottom: 8),
                  child: TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: ConfirmPasswordController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        label: Text("Confirm Password"),
                        prefixIcon: AppIcons.passwordIcon(),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius))),
                    validator: (value) => confirmPasswordValidator(
                        value, PasswordController.text),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10,right: 10,bottom: 8),
                  child: TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: CityController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        label: Text("City"),
                        prefixIcon: Icon(Icons.location_city_outlined),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius))),
                    validator: (value) => cityValidator(value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10,right: 10,bottom: 8),
                  child: InkWell(
                    child: TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                          label: Text("Date of Birth : $DateOfBirthController"),
                          prefixIcon: Icon(Icons.date_range_outlined),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(borderRadius))),
                      validator: (value) => dateOfBirthValidator(value),
                    ),
                    onTap: () async {
                      DateTime? datePicked = await showDatePicker(
                          context: context,
                          // initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now());
                      if (datePicked != null) {
                        setState(() {
                          date = datePicked;
                          DateOfBirthController =
                              "${date.day}/${date.month}/${date.year}";
                          print("Time : $datePicked");
                        });
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10,right: 10,bottom: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      submitForm();
                    },
                    child: Text("SignUp", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Already Have an Account??",
                      style: TextStyle(fontSize: 16),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => Login()));
                        },
                        child: Text(
                          "LogIn",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ))
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
