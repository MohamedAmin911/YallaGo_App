import 'package:flutter_dotenv/flutter_dotenv.dart';

class KapiKeys {
  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? "";
  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? "";
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";
  static String get stripeSecretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? "";
  static String get googeleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "";
  static String get payMobApiKey => dotenv.env['PAYMOB_API_KEY'] ?? "";
  static String get payMobIntegrationId =>
      dotenv.env['PAYMOB_INTEGRATION_ID'] ?? "";

  static String get pipedreamApiKey => dotenv.env['PIPEDREAM_API_KEY'] ?? "";
}
