import 'package:flutter/foundation.dart';

class User with ChangeNotifier {
  String email;

  String username;

  String salonkey;

  String salonname;

  UserSettings settings;

  bool active;

  String userkey;

  String profilephoto;

  bool selected = false;

  String token;

 // String appIdentifier = 'Flutter Instachatty ${Platform.operatingSystem}';

  String appIdentifier = '';


  User(
      {this.email = '',
      this.username = '',
      this.salonkey = '',
      this.salonname = '',
      this.active = false,
      lastOnlineTimestamp,
      settings,
      this.token = '',
      this.userkey = '',
      this.profilephoto = ''})
      : settings = settings ?? UserSettings();

  factory User.fromJson(Map<String, dynamic> parsedJson) {
    return User(
        token: parsedJson['token'] ?? '',
        salonkey: parsedJson['salonkey'] ?? '',
        salonname: parsedJson['salonname'] ?? '',
        userkey: parsedJson['userkey'] ?? '',
        username: parsedJson['username'] ?? '',
        active: parsedJson['active'] ?? false,
        lastOnlineTimestamp: parsedJson['lastOnlineTimestamp'],
        settings: parsedJson.containsKey('settings')
            ? UserSettings.fromJson(parsedJson['settings'])
            : UserSettings(),
        profilephoto: parsedJson['profilephoto'] ?? '');
  }

  factory User.fromPayload(Map<String, dynamic> parsedJson) {
    return User(
        token: parsedJson['token'] ?? '',
        salonkey: parsedJson['salonkey'] ?? '',
        salonname: parsedJson['salonname'] ?? '',
        userkey: parsedJson['userkey'] ?? '',
        username: parsedJson['username'] ?? '',
        active: parsedJson['active'] ?? false,
        settings: parsedJson.containsKey('settings')
            ? UserSettings.fromJson(parsedJson['settings'])
            : UserSettings(),
        profilephoto: parsedJson['profilephoto'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'username': username,
      'salonkey': salonkey,
      'salonname': salonname,
      'settings': settings.toJson(),
      'active': active,
      'profilephoto': profilephoto,
      'appIdentifier': appIdentifier
    };
  }

  Map<String, dynamic> toPayload() {
    return {
      'token': token,
      'username': username,
      'salonkey': salonkey,
      'salonname': salonname,
      'settings': settings.toJson(),
      'active': active,
      'profilephoto': profilephoto,
      'appIdentifier': appIdentifier
    };
  }
}

class UserSettings {
  bool allowPushNotifications;

  UserSettings({this.allowPushNotifications = true});

  factory UserSettings.fromJson(Map<dynamic, dynamic> parsedJson) {
    return UserSettings(
        allowPushNotifications: parsedJson['allowPushNotifications'] ?? true);
  }

  Map<String, dynamic> toJson() {
    return {'allowPushNotifications': allowPushNotifications};
  }
}
