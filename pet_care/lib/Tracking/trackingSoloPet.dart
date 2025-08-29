import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pet_care/utils/image_utils.dart';
import 'package:geocoding/geocoding.dart';

class trackingPetSolo extends StatefulWidget {

  final Map<String,dynamic> petData;
  final String email;
  const trackingPetSolo({super.key,required this.petData,required this.email});

  @override
  State<trackingPetSolo> createState() => _trackingPetSoloState();
}

class _trackingPetSoloState extends State<trackingPetSolo> {

  String title = "", subtitle = "";
  String address = "Loading address...";
  
  // Additional variables for detailed pet info
  String petBreed = "Mixed Breed";
  String petAge = "Unknown"; 
  String petWeight = "Unknown";
  String petDescription = "No description available";

  LatLng pos = LatLng(31.5607552, 74.378948);

  final Completer<GoogleMapController> _MapController =
  Completer<GoogleMapController>();

  List<Marker> _marker = <Marker>[];

  String picPath = "https://firebasestorage.googleapis.com/v0/b/petpick-8250c.appspot.com/o/PetPics%2F2ytt5qm8zpkl?alt=media&token=598ba9b9-36a9-448b-a690-e8f03508e8ac";

  Uint8List? markerImage;

  @override
  void initState() {
    super.initState();
    // Initialize with fixed data from addPetFormDark - no continuous location tracking
    setData();
    customMarkerImages();
    customMarkerBytes();
    // Removed getLocationUpdates() and fetchLocation() - use fixed location only
  }

  // Function to get readable address from coordinates (one-time, no setState)
  Future<void> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}".replaceAll(RegExp(r'^, |, $'), '');
        
        // Update subtitle with the resolved address once (no setState to prevent refreshes)
        if (mounted) {
        setState(() {
            if (widget.petData["oneLine"] != null && widget.petData["oneLine"].toString().isNotEmpty) {
              subtitle = widget.petData["oneLine"];
            } else {
              subtitle = "$petBreed • $address";
            }
          });
        }
      }
    } catch (e) {
      print("Error getting address: $e");
      address = "Address unavailable";
    }
  }

  setData(){
    title = widget.petData["Name"] ?? "Unknown Pet";
    
    // Extract detailed pet information
    petBreed = widget.petData["Breed"] ?? "Mixed Breed";
    petAge = widget.petData["Age"] ?? "Unknown";
    petWeight = widget.petData["Weight"] ?? "Unknown";
    petDescription = widget.petData["oneLine"] ?? "No description available";
    
    // Add null checks for LAT and LONG with default coordinates
    double lat = widget.petData["LAT"]?.toDouble() ?? 31.5607552; // Default to Lahore, Pakistan
    double lng = widget.petData["LONG"]?.toDouble() ?? 74.378948;
    pos = LatLng(lat, lng);
    
    // Get readable address for pet's location (one-time)
    getAddressFromCoordinates(lat, lng);
    
    // Improved subtitle with fallback to breed and location info
    if (widget.petData["oneLine"] != null && widget.petData["oneLine"].toString().isNotEmpty) {
      subtitle = widget.petData["oneLine"];
    } else {
      // Create a more informative subtitle with breed and location
      subtitle = "$petBreed • Getting location...";
    }
    
    picPath = widget.petData["Photo"] ?? "https://firebasestorage.googleapis.com/v0/b/petpick-8250c.appspot.com/o/PetPics%2F2ytt5qm8zpkl?alt=media&token=598ba9b9-36a9-448b-a690-e8f03508e8ac";
  }

  // Function to show detailed pet information dialog
  void _showPetInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(picPath),
              radius: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '$title Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Name', title),
                _buildDetailRow('Breed', petBreed),
                _buildDetailRow('Age', petAge),
                _buildDetailRow('Weight', petWeight),
                _buildDetailRow('Description', petDescription),
                _buildDetailRow('Current Location', address),
                if (widget.petData['Category'] != null)
                  _buildDetailRow('Species', widget.petData['Category']),
                if (widget.petData['activityLevel'] != null)
                  _buildDetailRow('Activity Level', widget.petData['activityLevel']),
                if (widget.petData['DateOfBirth'] != null)
                  _buildDetailRow('Date of Birth', widget.petData['DateOfBirth']),
                if (widget.petData['allergies'] != null && (widget.petData['allergies'] as List).isNotEmpty)
                  _buildDetailRow('Allergies', (widget.petData['allergies'] as List).join(', ')),
                if (widget.petData['healthGoals'] != null && (widget.petData['healthGoals'] as List).isNotEmpty)
                  _buildDetailRow('Health Goals', (widget.petData['healthGoals'] as List).join(', ')),
                if (widget.petData['favorites'] != null && (widget.petData['favorites'] as List).isNotEmpty)
                  _buildDetailRow('Favorites', (widget.petData['favorites'] as List).join(', ')),
                if (widget.petData['healthNotes'] != null && widget.petData['healthNotes'].toString().isNotEmpty)
                  _buildDetailRow('Health Notes', widget.petData['healthNotes']),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> getBytesFromAssets(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return (await frameInfo.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void customMarkerBytes() async {
    final Uint8List markerIcon = await getBytesFromAssets(picPath, 100);
    _marker.add(Marker(
        markerId: MarkerId('01'),
        position: (pos),
        infoWindow: InfoWindow(
          title: "First Map API",
          snippet: "Snipped of API",
        ),
        icon: BitmapDescriptor.bytes(markerIcon)));
  }
  late BitmapDescriptor markerIcon;

  void customMarkerImages() async{

    markerIcon=BitmapDescriptor.defaultMarker;
    await BitmapDescriptor.asset(ImageConfiguration.empty, "assets/images/petPic.ico").then((icon) {

      markerIcon=icon;


    },);

  }

  Future<void> reFocus(LatLng position) async {
    final GoogleMapController controller = await _MapController.future;
    CameraPosition newCameraPostion =
    CameraPosition(target: position, zoom: 13);
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(newCameraPostion));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [

              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: IconButton(
                  onPressed: () {
                    _showPetInfoDialog();
                  },
                  icon: Icon(
                    Icons.info_outline,
                  ),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        Color.fromRGBO(10, 111, 112, 0.3)),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: IconButton(
                  onPressed: () {
                    reFocus(pos);
                  },
                  icon: Icon(
                    Icons.my_location,
                  ),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        Color.fromRGBO(10, 111, 112, 0.3)),
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  reFocus(pos);
                  // init();
                },
                icon: FaIcon(FontAwesomeIcons.amazonPay),
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        Color.fromRGBO(10, 111, 112, 0.3))),
              ),
            ],
          ),
        ),
        body: Container(
          // Todo Add Dynamic Data from Database
          child: Stack(children: [
            Container(
              // height: 720,
                color: Colors.blue,
                child: GoogleMap(
                  myLocationEnabled: false,
                  // myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  onMapCreated: (GoogleMapController controller) {
                    _MapController.complete(controller);
                  },
                  initialCameraPosition:
                  CameraPosition(target: pos, zoom: 15),
                  markers: {
                    Marker(
                      markerId: MarkerId("PetLocation"),
                      icon: markerIcon,
                      position: pos,
                      infoWindow: InfoWindow(
                        title: title,
                        snippet: subtitle,
                      ),
                    ),
                    // Marker(
                    //   markerId: MarkerId("Id2"),
                    //   position: LatLng(pos.latitude+0.03,pos.longitude),
                    //   infoWindow: InfoWindow(
                    //     title: title,
                    //     snippet: "Snipped of API2",
                    //   ),
                    // ),
                    // _marker[0]
                  },
                )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                // width: 400,
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      _showPetInfoDialog();
                    },
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(subtitle),
                      trailing: Icon(Icons.info_outline, color: Colors.blue),
                    leading: (picPath.isEmpty || picPath == "")  ?
                    CircleAvatar(
                      radius: 30,
                      child: Image.asset("assets/images/petPic.png"),
                      backgroundColor: Colors.white70,
                    ):
                    ImageUtils.buildPetAvatar(
                      imagePath: picPath,
                      radius: 30,
                      backgroundColor: Colors.white70,
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}