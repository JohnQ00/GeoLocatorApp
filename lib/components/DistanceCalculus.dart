import 'package:geolocation_app/models/Attraction.dart';
import 'dart:math' as Math;

Attraction getDistance(Attraction attraction, double user_latitude, double user_longitude){
  double R = 6371e3; // metros
  double a1 = user_latitude * 0.01745;
  double a2 = attraction.latitude * 0.01745;
  double dt =
      (attraction.latitude - user_latitude) * 0.01745;
  double dk =
      (attraction.longitude - user_longitude) * 0.01745;

  double a =
      Math.sin(dt / 2) * Math.sin(dt / 2) +
          Math.cos(a1) * Math.cos(a2) * Math.sin(dk / 2) * Math.sin(dk / 2);

  double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  attraction.distance = R * c;

  //Converting to kilometers
  if (attraction.distance > 1000) {
    attraction.distance = attraction.distance / 1000;
    attraction.distance = double.parse(attraction.distance.toStringAsFixed(1));
    attraction.unit = "Km";
  } else {
    attraction.distance = double.parse(attraction.distance.toStringAsFixed(0));
    attraction.unit = "m";
  }

  return attraction;
}