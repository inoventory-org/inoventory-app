import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Secrets {
  static String get supabaseUrl => dotenv.env["SUPABASE_URL"] ?? "";
  static String get supabasePublishableKey =>
      dotenv.env["SUPABASE_PUBLISHABLE_KEY"] ?? dotenv.env["SUPABASE_ANON_KEY"] ?? "";
  static String get openFoodFactsToken => dotenv.env["OPEN_FOOD_FACTS_TOKEN"] ?? "";
}
