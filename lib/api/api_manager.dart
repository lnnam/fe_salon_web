//import 'package:salonappweb/api/customBackend/custom_backend.dart';
//import 'package:salonappweb/api/firebase/firebase_helper.dart';
//import 'package:salonappweb/api/local/local_data.dart';
import 'package:salonappweb/api/http/http.dart';


/// Uncomment these if you want to remove firebase and add local data:
// var apiManager = LocalData();

/// Uncomment these if you want to remove firebase and add your own custom backend:
// var apiManager = CustomBackend();

/// Remove these lines if you want to remove firebase and add your own custom backend:
//var apiManager = FireStoreUtils();

var apiManager = MyHttp();
