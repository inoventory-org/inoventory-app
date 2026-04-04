import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Constants {
  // static const inoventoryBackendUrl = "http://10.100.255.76:8080";
  // static const inoventoryBackendUrl = "http://localhost:8080";
  // static const inoventoryBackendUrl = "http://10.0.2.2:8080";
  static const appName = "inoventory";
  static const version = "0.0.1";
  // static const inoventoryBackendUrl = "https://www.inoventory.railabouni.fra.ics.inovex.io";
  static String inoventoryBackendUrl = dotenv.env["BACKEND_URL"]  ?? "https://inoventory.onrender.com";

  static const darkMode = true;
  static const openFoodFactsUserName = "inoventory";
  static String? supabaseRedirectUrl(bool isWeb) =>
      isWeb ? null : "com.railabouni.inoventory://login-callback";
}

abstract class Globals {
  static bool forceFetchProducts = false;
}
