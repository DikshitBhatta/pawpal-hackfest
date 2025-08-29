import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/rendering.dart';
import 'package:pet_care/HomePage/AccountSettingsPage.dart';
import 'package:flutter/widgets.dart';
import 'package:pet_care/ColorsScheme.dart';
import 'package:pet_care/CredentialsScreen/LoginPage.dart';
import 'package:pet_care/HomePage/addPetFormDark.dart';
// import 'package:pet_care/CredentialsScreen/phoneAuthentication.dart';
import 'package:pet_care/utils/image_utils.dart';
import 'package:pet_care/utils/app_icons.dart';
import 'package:pet_care/HomePage/petDetailsDark.dart';
import 'package:pet_care/widgets/notification_debug_widget.dart';
import 'package:pet_care/Tracking/trackingSoloPet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:pet_care/Subscription/SubscriptionHomeWidget.dart';
import 'package:pet_care/widgets/delivery_tracking_bar.dart';
import 'package:pet_care/widgets/pet_background_pattern.dart';

class petScreenDynamicDark extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>>? prefetchedSubscriptions;
  final List<Map<String, dynamic>>? prefetchedOrders;
  final List<Map<String, dynamic>>? prefetchedPets;

  const petScreenDynamicDark({
    Key? key, 
    required this.userData,
    this.prefetchedSubscriptions,
    this.prefetchedOrders,
    this.prefetchedPets,
  }) : super(key: key);

  @override
  _petScreenDynamicDarkState createState() => _petScreenDynamicDarkState();
}

class _petScreenDynamicDarkState extends State<petScreenDynamicDark> {
  // Commented out Our Services section
  /*
  var picsPath = [
    // "assets/images/HomeScreenPics/Tracking.png",
    "assets/images/HomeScreenPics/Doctor.png",
    "assets/images/Community.png",
    "assets/images/HomeScreenPics/Shop.png"
  ];
  var texts = [
    // "Pet Track",
    "Pet Doctor", "Pet Community", "Pet Shop"];
  var pages = [];
  */
  @override
  void initState() {
    /*
    pages = [
      gptScreenDark(),
      // gptScreen(),
      CommunityScreenDark(userData: widget.userData),
      shopping()
    ];
    */
    // TODO: implement initState
    super.initState();
  }

  deletePet(petID) async {
    try {
      // Delete pet from the old direct collection structure
      await FirebaseFirestore.instance
          .collection(widget.userData["Email"])
          .doc(petID)
          .delete();
      
      print("Pet document deleted successfully");
      return true;
    } catch (ex) {
      print("Error deleting pet: $ex");
      return false;
    }
  }

  Widget _buildBackgroundPattern() {
    return PetBackgroundPattern(
      opacity: 0.25,
      symbolSize: 50.0,
      density: 0.8,
      usePositioned: true, // Use internal Positioned.fill to avoid nesting
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: backgroundColor),
          child: Stack(
            children: [
              // Background pattern overlay
              _buildBackgroundPattern(),
              SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Container(
                      height: 120, // Fixed height for the header
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 6.0, top: 15.0, bottom: 8),
                        child: SimpleShadow(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Container(
                                height: 97,
                                decoration: BoxDecoration(
                                    gradient: titleBackgroundColor,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 9.0),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AccountSettingsPage(userData: widget.userData),
                                            ),
                                          );
                                        },
                                        child: ImageUtils.buildProfileAvatar(
                                          imagePath: widget.userData["Pic"],
                                          radius: 30,
                                          backgroundColor: Colors.white70,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 8.0, right: 8.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Hi ${widget.userData["Name"] ?? "User"}",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: TextColor),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              Text(
                                                "Welcome Back 👋",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: TextColor),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: appBarColor,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Commented out OTP verification section
                                      /*
                                      Flexible(
                                        child: IconButton(
                                          padding: EdgeInsets.all(1.0),
                                          constraints: BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          disabledColor: Colors.blueGrey.shade600,
                                          icon:
                                              widget.userData["isVerified"] == true
                                                  ? Icon(
                                                      Icons
                                                          .published_with_changes_outlined,
                                                      color: Colors.grey.shade400,
                                                      size: 14,
                                                    )
                                                  : Icon(
                                                      Icons.unpublished_outlined,
                                                      color: Colors.grey.shade400,
                                                      size: 14,
                                                    ),
                                          onPressed:
                                              widget.userData["isVerified"] == false
                                                  ? () {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                PhoneAuthentication(
                                                              userData:
                                                                  widget.userData,
                                                            ),
                                                          ));
                                                    }
                                                  : null,
                                        ),
                                      ),
                                      */
                                      SizedBox(width: 18),
                                      Flexible(
                                        child: Center(
                                          child: IconButton(
                                            padding: EdgeInsets.all(1.0),
                                            constraints: BoxConstraints(
                                              minWidth: 18,
                                              minHeight: 18,
                                            ),
                                            onPressed: () async {
                                              _showLogoutConfirmation();
                                            },
                                            icon: Icon(
                                              Icons.logout_rounded,
                                              color: AppIcons.disabledIconColor,
                                              size: 25,
                                            )),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Commented out Our Services section
                  /*
                  Expanded(
                      flex: 6,
                      child: Container(
                        width: double.maxFinite,
                        decoration: BoxDecoration(
                            gradient: BackgroundOverlayColor,
                            borderRadius: BorderRadius.circular(0)),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: headingBackgroundColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 11),
                                  child: Text(
                                    "Our Services",
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 20,
                                      color: TextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: picsPath.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 15.0, bottom: 15.0, left: 22.0),
                                      child: SimpleShadow(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        pages[index]));
                                          },
                                          child: Container(
                                            width: 140,
                                            height: 120,
                                            constraints: BoxConstraints(
                                              maxWidth: 140,
                                              maxHeight: 120,
                                              minHeight: 100,
                                              minWidth: 120,
                                            ),
                                            decoration: BoxDecoration(
                                                gradient: cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Flexible(
                                                  child: Container(
                                                    height: 60,
                                                    width: 60,
                                                    child: Image.asset(
                                                        picsPath[index],
                                                        fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
                                                  child: Text(
                                                    texts[index],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  */
                  // Subscription Widget Section
                  Container(
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      gradient: BackgroundOverlayColor,
                    ),
                    child: Stack(
                      children: [
                        PetBackgroundPattern(
                          opacity: 0.15,
                          symbolSize: 40.0,
                          density: 0.5,
                        ),
                        SubscriptionHomeWidget(
                          userData: widget.userData,
                          prefetchedSubscriptions: widget.prefetchedSubscriptions,
                        ),
                      ],
                    ),
                  ),
                  // Delivery Tracking Bar Section
                  Container(
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      gradient: BackgroundOverlayColor,
                    ),
                    child: Stack(
                      children: [
                        PetBackgroundPattern(
                         opacity: 0.10,
                          symbolSize: 40.0,
                          density: 0.5,
                        ),
                        DeliveryTrackingBar(
                          userId: widget.userData["Email"] ?? "",
                          prefetchedOrders: widget.prefetchedOrders,
                        ),
                      ],
                    ),
                  ),
                  // Delivery Animation Section
                  // Container(
                  //   width: double.maxFinite,
                  //   height: 120,
                  //   decoration: BoxDecoration(
                  //     gradient: BackgroundOverlayColor,
                  //   ),
                  //   child: Lottie.asset(
                  //     'assets/Animations/Loadingbar.json',
                  //     fit: BoxFit.fill,
                  //     repeat: true,
                  //     animate: true,
                  //   ),
                  // ),
                  Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6.0, bottom: 80.0), // Extra bottom padding for the fixed button
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: BackgroundOverlayColor,
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(6),
                                topLeft: Radius.circular(6),
                                bottomRight: Radius.circular(3),
                                bottomLeft: Radius.circular(3))),
                        child: Stack(
                          children: [
                            PetBackgroundPattern(
                              opacity: 0.15,
                              symbolSize: 40.0,
                              density: 0.5,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7, bottom: 7),
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: headingBackgroundColor),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 11),
                                  child: Text(
                                    "Your Pets",
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 20,
                                      color: TextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: _buildPetsSection(),
                            ),
                          ],
                        ),
                        ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ), // This closes the SingleChildScrollView
            Positioned(
              bottom: 7,
              left: 0,
              // left: MediaQuery.of(context).size.width * 0.02,
              right: 0,
              // right: MediaQuery.of(context).size.width * 0.02,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    // backgroundColor: Color.fromRGBO(128, 213, 196, 0.6),
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: Size(10, 40)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          addPetFormDark(userData: widget.userData),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(
                    'Add Pet',
                    style: TextStyle(
                        fontSize: headingSize,
                        fontWeight: FontWeight.w500,
                        color: TextColor),
                  ),
                ),
              ),
            ),
          ], // This closes the Stack children
        ), // This closes the Stack
      ), // This closes the body Container
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Navigate to notification debug screen
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => const NotificationDebugWidget(),
      //       ),
      //     );
      //   },
      //   backgroundColor: Colors.purple,
      //   child: const Icon(Icons.notifications, color: Colors.white),
      //   tooltip: 'Test Notifications',
      // ),
    ), // This closes the Scaffold
  ); // This closes the SafeArea
  }

  Widget _buildPetsSection() {
    // Always use StreamBuilder for real-time updates
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(widget.userData["Email"])
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        // Use prefetched data while waiting for stream or if stream has no data yet
        List<Map<String, dynamic>> petsToShow = [];
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          // Use real-time data from stream
          petsToShow = snapshot.data!.docs
              .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
              .toList();
        } else if (widget.prefetchedPets != null && widget.prefetchedPets!.isNotEmpty) {
          // Use prefetched data if stream is still loading or empty
          petsToShow = widget.prefetchedPets!;
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          // Only show loading if no prefetched data is available
          return Center(
            child: Lottie.asset(
              'assets/Animations/AnimalcareLoading.json',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          );
        }
        
        // Show empty state if no pets available
        if (petsToShow.isEmpty) {
          return Center(
            child: BlurryContainer(
              color: buttonColor,
              child: Container(
                width: RenderErrorBox.minimumWidth * 1.3,
                height: RenderErrorBox.minimumWidth / 1.6,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "No Pet Added Yet !!!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        
        var petData = petsToShow;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80.0),
          itemCount: petData.length,
          itemBuilder: (context, index) {
            var pet = petData[index];
            String petId = pet['id'] ?? '';
            
            return Dismissible(
              key: Key(petId),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          AppIcons.warningIcon(
                            color: Colors.orange,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text('Delete Pet?'),
                        ],
                      ),
                      content: Text(
                        'Are you sure you want to delete ${pet["Name"]}? This action cannot be undone.',
                        style: TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) async {
                bool success = await deletePet(petId);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Done! 🐾 ${pet["Name"]} removed safely! 💙'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('😔 Oops! Couldn\'t remove ${pet["Name"]}. Please try again! 🔄'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              background: Container(
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcons.deleteIcon(
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: 8.0,
                  left: 12.0,
                  right: 12.0
                ),
                child: SimpleShadow(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: index % 2 != 0
                          ? listTileColor
                          : listTileColorSecond
                    ),
                    child: ListTile(
                      titleTextStyle: TextStyle(
                        fontSize: 22,
                        color: Colors.teal.shade700
                      ),
                      subtitleTextStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.black45
                      ),
                      leading: ImageUtils.buildPetAvatar(
                        imagePath: pet["Photo"],
                        radius: 30,
                      ),
                      title: Text(
                        pet["Name"] ?? "Unknown",
                        style: TextStyle(color: TextColor),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        pet["Breed"] ?? "Unknown Breed",
                        style: TextStyle(color: TextColor),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      trailing: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 50),
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => trackingPetSolo(
                                  petData: pet,
                                  email: widget.userData["Email"]
                                ),
                              )
                            );
                          },
                          child: Image.asset(
                            "assets/images/HomeScreenPics/Tracking.png",
                            height: 35,
                            width: 35,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 8
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => petDetailsDark(
                              petData: pet,
                              userData: widget.userData
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                
                // Perform logout
                var pref = await SharedPreferences.getInstance();
                pref.remove("userEmail");
                pref.remove("messageList");
                await FirebaseAuth.instance.signOut();
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Login())
                );
              },
            ),
          ],
        );
      },
    );
  }
}
