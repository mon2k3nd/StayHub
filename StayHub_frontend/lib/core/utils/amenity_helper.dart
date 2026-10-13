import 'package:flutter/cupertino.dart';

class AmenityHelper {
  static IconData getIconForAmenity(String amenityCode) {
    switch (amenityCode.toUpperCase()) {
      case 'WIFI':
      case 'INTERNET':
        return CupertinoIcons.wifi;
      case 'AC':
      case 'AIR_CONDITIONING':
        return CupertinoIcons.snow;
      case 'PARKING':
      case 'FREE PARKING':
        return CupertinoIcons.car;
      case 'KITCHEN':
      case 'EQUIPPED KITCHEN':
        return CupertinoIcons.flame;
      case 'WASHING_MACHINE':
      case 'LAUNDRY':
        return CupertinoIcons.drop;
      case 'TV':
        return CupertinoIcons.tv;
      case 'FRIDGE':
      case 'REFRIGERATOR':
        return CupertinoIcons.thermometer_snowflake;
      case 'SECURITY':
      case 'CAMERA':
        return CupertinoIcons.video_camera;
      case 'ELEVATOR':
        return CupertinoIcons.arrow_up_arrow_down;
      case 'BALCONY':
        return CupertinoIcons.sun_max;
      default:
        return CupertinoIcons.check_mark_circled;
    }
  }

  /// Returns a premium 3D icon asset for the given amenity code.
  static String getAssetForAmenity(String amenityCode) {
    switch (amenityCode.toUpperCase()) {
      case 'WIFI':
      case 'INTERNET':
        return 'assets/images/features/iot_management.png';
      case 'AC':
      case 'AIR_CONDITIONING':
        return 'assets/images/features/utilities_dashboard.png';
      case 'PARKING':
      case 'FREE PARKING':
        return 'assets/images/features/multi_property.png';
      case 'KITCHEN':
      case 'EQUIPPED KITCHEN':
        return 'assets/images/features/local_services.png';
      case 'WASHING_MACHINE':
      case 'LAUNDRY':
        return 'assets/images/features/utilities_dashboard.png';
      case 'TV':
        return 'assets/images/features/community_board.png';
      case 'FRIDGE':
      case 'REFRIGERATOR':
        return 'assets/images/features/utilities_dashboard.png';
      case 'SECURITY':
      case 'CAMERA':
        return 'assets/images/features/biometric_auth.png';
      case 'ELEVATOR':
        return 'assets/images/features/multi_property.png';
      case 'BALCONY':
        return 'assets/images/features/feat_room.png';
      default:
        return 'assets/images/features/feat_room.png';
    }
  }

  static String getLabelForAmenity(String amenityCode) {
    switch (amenityCode.toUpperCase()) {
      case 'WIFI':
      case 'INTERNET':
        return 'Free Wi-Fi';
      case 'AC':
      case 'AIR_CONDITIONING':
        return 'Air Conditioning';
      case 'PARKING':
      case 'FREE PARKING':
        return 'Free parking';
      case 'KITCHEN':
      case 'EQUIPPED KITCHEN':
        return 'Equipped kitchen';
      case 'WASHING_MACHINE':
      case 'LAUNDRY':
        return 'Washing Machine';
      case 'TV':
        return 'Smart TV';
      case 'FRIDGE':
      case 'REFRIGERATOR':
        return 'Refrigerator';
      case 'SECURITY':
      case 'CAMERA':
        return 'Security Camera';
      case 'ELEVATOR':
        return 'Elevator';
      case 'BALCONY':
        return 'Balcony';
      default:
        if (amenityCode.isEmpty) return '';
        return amenityCode[0].toUpperCase() +
            amenityCode.substring(1).toLowerCase().replaceAll('_', ' ');
    }
  }
}
