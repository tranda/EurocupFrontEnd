class AppVersion {
  static const String major = '0';
  static const String minor = '6';
  static const String patch = '7';

  static String get version => '$major.$minor.$patch';

  static String increaseVersion({bool major = false, bool minor = false}) {
    if (major) {
      return 'Update AppVersion.major in lib/config/app_version.dart';
    } else if (minor) {
      return 'Update AppVersion.minor in lib/config/app_version.dart';
    } else {
      return 'Update AppVersion.patch in lib/config/app_version.dart';
    }
  }
}