import '../models/calendar_event_model.dart';
import '../models/email_model.dart';

/// Logo paths (no `assets/` prefix, avoids a double path on Flutter Web).
abstract final class BrandAssets {
  static const base = 'brands';

  static const gmail = '$base/gmail.png';
  static const outlook = '$base/outlook.png';
  static const yahoo = '$base/yahoo.png';
  static const apple = '$base/apple.png';
  static const proton = '$base/proton.png';
  static const imap = '$base/imap.png';
  static const google = '$base/google.png';
  static const microsoft = '$base/microsoft.png';
  static const googledocs = '$base/googledocs.png';
  static const googlepay = '$base/googlepay.png';
  static const googleCalendar = '$base/googlecalendar.png';
  static const outlookCalendar = '$base/outlook_calendar.png';
  static const appleCalendar = '$base/apple_calendar.png';
  static const microsoft365 = '$base/microsoft365.png';
  static const paperless = '$base/paperlessngx.png';
  static const nextcloud = '$base/nextcloud.png';

  /// Files currently present in the bundle (avoids console 404s).
  static const bundled = {
    gmail,
    proton,
    googleCalendar,
    googledocs,
    googlepay,
    paperless,
    nextcloud,
  };

  static String? ifBundled(String path) => bundled.contains(path) ? path : null;
}

extension MailProviderBrand on MailProvider {
  String? get logoAsset => BrandAssets.ifBundled(switch (this) {
        MailProvider.gmail => BrandAssets.gmail,
        MailProvider.outlook => BrandAssets.outlook,
        MailProvider.yahoo => BrandAssets.yahoo,
        MailProvider.apple => BrandAssets.apple,
        MailProvider.proton => BrandAssets.proton,
        MailProvider.imap => BrandAssets.imap,
      });
}

extension CalendarSourceBrand on CalendarSource {
  String? get logoAsset => switch (this) {
        CalendarSource.confidia => null,
        CalendarSource.google => BrandAssets.ifBundled(BrandAssets.googleCalendar),
        CalendarSource.outlook => BrandAssets.ifBundled(BrandAssets.outlookCalendar),
        CalendarSource.apple => BrandAssets.ifBundled(BrandAssets.appleCalendar),
        CalendarSource.microsoft365 => BrandAssets.ifBundled(BrandAssets.microsoft365),
      };
}
