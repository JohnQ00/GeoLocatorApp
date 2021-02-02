
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:geolocation_app/models/PositionItem.dart';
import 'package:geolocation_app/models/Attraction.dart';
import 'package:geolocation_app/components/DistanceCalculus.dart';

class App extends StatefulWidget {
  @override
  GeoLocation_homepage createState() => GeoLocation_homepage();
}

class GeoLocation_homepage extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter GeoLocation Application',
      theme: new ThemeData(primaryColor: Colors.blueAccent),
      home: Home(title: 'GeoLocator'),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);
  final String title;
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final List<PositionItem> locations = <PositionItem>[];
  StreamSubscription<Position> streamSubscription;
  bool trackLocation = false;
  bool attractionCoordinatesActive = false;
  double distanceToUser;
  Attraction attraction = new Attraction();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  Position location;

  @override
  void initState() {
    super.initState();
    getPermission();
    trackLocation = false;
  }

  void getPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    checkGPS();

    if (permission == LocationPermission.deniedForever){
      return Future.error('Location permissions are permanently disabled. Please, enable them to use the app.');
    }

    else if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse){
        return Future.error('Location permissions are denied (actual value: $permission).');
      }
    }
  }

  void getLocations(){
    if (trackLocation){
      setState(() => trackLocation = false);
      streamSubscription.cancel();
      streamSubscription = null;
    } else {
      setState(() => trackLocation = true);

      streamSubscription = Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: 1),
      ).listen((result) {
        final location = result;
        setState(() {
          if (attraction.longitude != null && attraction.latitude != null) {
            attraction = getDistance(attraction, location.longitude, location.latitude);
          }
          locations.add(PositionItem(location.longitude, location.latitude, attraction.distance, attraction.unit));
        });
      });
      
      streamSubscription.onDone(() => setState(() {
        trackLocation = false;
      }));
    }
  }

  checkGPS() async {
    final result = await Geolocator.isLocationServiceEnabled();
    if (result == true){
      print("Success");
    } else {
      print("Fail");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'titleFont',
                fontWeight: FontWeight.bold,
                fontSize: 26),
          ),
          centerTitle: true,
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 5.0),
              child: FlatButton(
                onPressed: () async {
                  getLocations();
                },
                child: Icon(
                  Icons.add_location,
                  semanticLabel: 'Press this button to start the tracking of your localization. Press after the start to stop the tracking.',
                  color: Colors.white,
                  size: 26.0,
                ),
                shape: CircleBorder(
                  side: BorderSide(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.topCenter,
              margin: EdgeInsets.all(10.0),
              height: 175.0,
              width: 500.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
                boxShadow: [BoxShadow(
                  color: Colors.grey.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Insert the attraction coordinates: ',
                    semanticsLabel: 'Insert the desired coordinates. This card contains two input boxes and a button.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'textFont'
                    ),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      contentPadding:EdgeInsets.fromLTRB(10, 0, 10, 0),
                      hintText: 'Latitude',
                      hintStyle: TextStyle(
                        fontFamily: 'textFont',
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    controller: latitudeController,
                    validator: (input) {
                      return input.contains(',') ? 'Use the dot, please' : null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      contentPadding:EdgeInsets.fromLTRB(10,0,10,0),
                      hintText: 'Longitude',
                      hintStyle: TextStyle(
                        fontFamily: 'textFont',
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    controller: longitudeController,
                    validator: (input) {
                      return input.contains(',') ? 'Use the dot, please' : null;
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.all(5.0),
                    child: FlatButton(
                      color: Colors.blueAccent,
                      onPressed: () {
                        attractionCoordinatesActive = true;
                        attraction.longitude = double.parse(longitudeController.text);
                        attraction.latitude = double.parse(latitudeController.text);
                      },
                      child: Text(
                        'Set the coordinates',
                        semanticsLabel: 'Press this button and set the coordinates wrote above.',
                        style: TextStyle(
                          fontFamily: 'textFont',
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(10.0),
                scrollDirection: Axis.vertical,
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final locationItem = locations[index];

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.location_on_rounded,
                      ),
                      title: Text(
                        'This is your coordinate:',
                        style: TextStyle(
                          fontFamily: 'textFont',
                        ),
                      ),
                      subtitle: Text(
                        locationItem.displayLatitudeValue.toString() + ', ' + locationItem.displayLongitudeValue.toString(),
                        style: TextStyle(
                          fontFamily: 'textFont',
                        ),
                      ),
                      trailing: Text(
                        locationItem.distance.toString() + ' ' + locationItem.unit,
                        style: TextStyle(
                          fontFamily: 'textFont',
                        ),
                      ),
                    ),
                  );
                },
                shrinkWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}