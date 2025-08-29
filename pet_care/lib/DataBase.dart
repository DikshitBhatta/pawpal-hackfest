// import 'package:firebase_storage/firebase_storage.dart'; // Removed for MVP

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_care/services/image_compression_service.dart';

class DataBase {
  static Future<Map<String, dynamic>> readData(
      String collection, String email) async {
    var db = FirebaseFirestore.instance;
    final docRef = db.collection(collection).doc(email);
    Map<String, dynamic> userData = {
      "Name": "",
      "Email": email,
      "isVerified": false,
      "Pic": "assets/images/petPic.png", // Default placeholder
      "role": "user", // Default role
      "LAT": 31.5607552, // Default coordinates for Lahore, Pakistan
      "LONG": 74.378948
    };

    try {
      final snapshot = await docRef.get();
      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> fetchedData = snapshot.data() as Map<String, dynamic>;
        // Ensure all required fields exist with default values if missing
        userData["Name"] = fetchedData["Name"] ?? "";
        userData["Email"] = fetchedData["Email"] ?? email;
        userData["isVerified"] = fetchedData["isVerified"] ?? false;
  // phone number removed from user data; keep other fields
        userData["Pic"] = fetchedData["Pic"] ?? "assets/images/profile_placeholder.png";
        userData["Password"] = fetchedData["Password"] ?? "";
        userData["City"] = fetchedData["City"] ?? "";
        userData["DateOfBirth"] = fetchedData["DateOfBirth"] ?? "";
        userData["role"] = fetchedData["role"] ?? "user"; // Default role
        // Add default coordinates for tracking functionality
        userData["LAT"] = fetchedData["LAT"] ?? 31.5607552; // Default to Lahore, Pakistan
        userData["LONG"] = fetchedData["LONG"] ?? 74.378948;
      } else {
        print('Document does not exist for email: $email');
      }
    } catch (error) {
      print('Error fetching document: $error');
      // Return default userData on error
    }

    return userData;
  }

  static readAllData() async {
    var db = FirebaseFirestore.instance;
    print("Data Read");
    await db.collection("UserData").get().then((event) {
      for (var doc in event.docs) {
        print("${doc.id} => ${doc.data()["Email"]}");
      }
    });
  }

  static readRemainderData(petId) async {
    var db = FirebaseFirestore.instance;
    print("Data Read");
    var data=[];
    await db.collection(petId).get().then((event) {
      for (var doc in event.docs) {
        print("${doc.id} => ${doc.data()["Email"]}");
        data.add({
          "Email":doc.data()["Email"],
          "title":doc.data()["title"],
          "Details":doc.data()["Details"],
          "Time":doc.data()["Time"],
          "Date":doc.data()["Date"],
          "isSilent":doc.data()["isSilent"],
        });
      }
    });
    return data;
  }

  static Future<dynamic> saveUserData(collection, userData) async {
    try {
      var db = FirebaseFirestore.instance;

      await db
          .collection(collection)
          .doc(userData["Email"])
          .set(userData, SetOptions(merge: false))
          .then((value) => print("Written Successfully"))
          .onError((e, _) => print("Error writing document: $e"));

      return true;
    } on FirebaseAuthException catch (ex) {
      return ex.code.toString();
    }
  }

  static Future<dynamic> saveMessageData(collection, userData) async {
    try {
      var db = FirebaseFirestore.instance;

      await db
          .collection(collection)
          .doc()
          .set(userData, SetOptions(merge: false))
          .then((value) => print("Written Successfully"))
          .onError((e, _) => print("Error writing document: $e"));

      return true;
    } on FirebaseAuthException catch (ex) {
      return ex.code.toString();
    }
  }

  static Future<bool> updateUserData(collection, userid, updatedData) async {
    bool returnValue = false;

    var db = FirebaseFirestore.instance;
    final userDocument = db.collection(collection).doc(userid);
    
    try {
      await userDocument.update(updatedData);
      returnValue = true;
      print("UserData updated successfully for $userid");
    } catch (e) {
      print("Error updating document: $e");
      returnValue = false;
    }

    print("Updated Data: $updatedData for $userid, Success: $returnValue");
    return returnValue;
  }

  static Future<dynamic>? deleteUserData(collection, userID) {
    var db = FirebaseFirestore.instance;

    db.collection(collection).doc(userID).delete().then(
          (doc) => print("Document deleted"),
          onError: (e) => print("Error updating document $e"),
        );

    return null;
  }

  static Future<dynamic>? deleteCollection(collection) async{
    CollectionReference collectionRef = FirebaseFirestore.instance.collection(collection);
    QuerySnapshot querySnapshot = await collectionRef.get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    print('Collection deleted');

    return null;
  }


  static Future<dynamic>? deleteSpecificField(collection, userID, deletedData) {
    var db = FirebaseFirestore.instance;

    final updates = <String, dynamic>{
      deletedData: FieldValue.delete(),
    };

    db.collection(collection).doc(userID).update(updates).then(
          (doc) => print("Document deleted"),
          onError: (e) => print("Error updating document $e"),
        );

    return null;
  }

  // Firebase Storage methods removed for MVP - using placeholder images instead
  // If needed in future, these can be re-implemented with proper Firebase Storage setup
  
  // Updated uploadImage method to compress and store images as base64 in Firestore
  static Future<String?> uploadImage(String email, String collection, dynamic pickedImage) async {
    try {
      if (pickedImage == null) {
        print("No image provided for upload");
        return null;
      }
      
      File imageFile;
      if (pickedImage is File) {
        imageFile = pickedImage;
      } else {
        print("Invalid image type provided");
        return null;
      }
      
      // Show image info for debugging
      final imageInfo = await ImageCompressionService.getImageInfo(imageFile);
      print("Original image info: $imageInfo");
      
      // Compress the image to base64 string under 1MB
      String? compressedBase64 = await ImageCompressionService.compressImageForFirestore(imageFile);
      
      if (compressedBase64 == null) {
        print("Failed to compress image for Firestore storage");
        return null;
      }
      
      // Store the compressed base64 image in Firestore
      try {
        var db = FirebaseFirestore.instance;
        String documentId = "${email}_${collection}_${DateTime.now().millisecondsSinceEpoch}";
        
        await db.collection('images').doc(documentId).set({
          'email': email,
          'collection': collection,
          'imageData': compressedBase64,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
        
        print("Image successfully stored in Firestore with document ID: $documentId");
        
        // Return the document ID as the image reference
        return documentId;
        
      } catch (firestoreError) {
        print("Error storing image in Firestore: $firestoreError");
        return null;
      }
      
    } catch (e) {
      print("Error in uploadImage: $e");
      return null;
    }
  }
  
  // Method to retrieve image from Firestore
  static Future<String?> getImageBase64(String imageId) async {
    try {
      var db = FirebaseFirestore.instance;
      final docSnapshot = await db.collection('images').doc(imageId).get();
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return data['imageData'] as String?;
      }
      
      return null;
    } catch (e) {
      print("Error retrieving image: $e");
      return null;
    }
  }
}