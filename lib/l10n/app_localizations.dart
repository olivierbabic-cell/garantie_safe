import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @test_key.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test_key;

  /// No description provided for @test_umlaut.
  ///
  /// In en, this message translates to:
  /// **'Umlaut test (English - no special chars)'**
  String get test_umlaut;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GarantieSafe'**
  String get appTitle;

  /// No description provided for @onb_welcome_headline.
  ///
  /// In en, this message translates to:
  /// **'Keep all your warranties in view – secure, private, under your control.'**
  String get onb_welcome_headline;

  /// No description provided for @onb_welcome_hint.
  ///
  /// In en, this message translates to:
  /// **'Note: For warranty cases always scan the entire receipt.'**
  String get onb_welcome_hint;

  /// No description provided for @onb_lets_go.
  ///
  /// In en, this message translates to:
  /// **'Let’s go'**
  String get onb_lets_go;

  /// No description provided for @onb_start_fresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get onb_start_fresh;

  /// No description provided for @onb_restore_backup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get onb_restore_backup;

  /// No description provided for @onb_restore_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Restore cancelled'**
  String get onb_restore_cancelled;

  /// No description provided for @onb_restore_failed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get onb_restore_failed;

  /// No description provided for @storage_title.
  ///
  /// In en, this message translates to:
  /// **'Choose storage location'**
  String get storage_title;

  /// No description provided for @storage_question.
  ///
  /// In en, this message translates to:
  /// **'Where should your data be stored?'**
  String get storage_question;

  /// No description provided for @storage_local.
  ///
  /// In en, this message translates to:
  /// **'Only on this device'**
  String get storage_local;

  /// No description provided for @storage_cloud.
  ///
  /// In en, this message translates to:
  /// **'In your cloud (Google Drive)'**
  String get storage_cloud;

  /// No description provided for @storage_footer.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in settings.'**
  String get storage_footer;

  /// No description provided for @payments_title.
  ///
  /// In en, this message translates to:
  /// **'Select payment methods'**
  String get payments_title;

  /// No description provided for @payments_intro.
  ///
  /// In en, this message translates to:
  /// **'Which payment methods do you usually use? This speeds up capturing new receipts.'**
  String get payments_intro;

  /// No description provided for @payments_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get payments_save;

  /// No description provided for @pm_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get pm_cash;

  /// No description provided for @pm_debit_card.
  ///
  /// In en, this message translates to:
  /// **'Debit card'**
  String get pm_debit_card;

  /// No description provided for @pm_credit_card.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get pm_credit_card;

  /// No description provided for @pm_visa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get pm_visa;

  /// No description provided for @pm_mastercard.
  ///
  /// In en, this message translates to:
  /// **'Mastercard'**
  String get pm_mastercard;

  /// No description provided for @pm_american_express.
  ///
  /// In en, this message translates to:
  /// **'American Express'**
  String get pm_american_express;

  /// No description provided for @pm_maestro.
  ///
  /// In en, this message translates to:
  /// **'Maestro'**
  String get pm_maestro;

  /// No description provided for @pm_apple_pay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get pm_apple_pay;

  /// No description provided for @pm_google_pay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get pm_google_pay;

  /// No description provided for @pm_samsung_pay.
  ///
  /// In en, this message translates to:
  /// **'Samsung Pay'**
  String get pm_samsung_pay;

  /// No description provided for @pm_paypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get pm_paypal;

  /// No description provided for @pm_twint.
  ///
  /// In en, this message translates to:
  /// **'Twint'**
  String get pm_twint;

  /// No description provided for @pm_klarna.
  ///
  /// In en, this message translates to:
  /// **'Klarna / Buy now pay later'**
  String get pm_klarna;

  /// No description provided for @pm_gift_card_voucher.
  ///
  /// In en, this message translates to:
  /// **'Gift card / Voucher'**
  String get pm_gift_card_voucher;

  /// No description provided for @pm_bank_transfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get pm_bank_transfer;

  /// No description provided for @pm_venmo.
  ///
  /// In en, this message translates to:
  /// **'Venmo'**
  String get pm_venmo;

  /// No description provided for @pm_cash_app.
  ///
  /// In en, this message translates to:
  /// **'Cash App'**
  String get pm_cash_app;

  /// No description provided for @pm_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get pm_other;

  /// No description provided for @pm_debit.
  ///
  /// In en, this message translates to:
  /// **'EC / Maestro / Debit card'**
  String get pm_debit;

  /// No description provided for @pm_credit.
  ///
  /// In en, this message translates to:
  /// **'Credit card (Visa/Mastercard/Amex)'**
  String get pm_credit;

  /// No description provided for @pm_applepay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get pm_applepay;

  /// No description provided for @pm_googlepay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get pm_googlepay;

  /// No description provided for @pm_invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice / Klarna'**
  String get pm_invoice;

  /// No description provided for @pm_giftcard.
  ///
  /// In en, this message translates to:
  /// **'Gift card / voucher'**
  String get pm_giftcard;

  /// No description provided for @pm_financing.
  ///
  /// In en, this message translates to:
  /// **'Financing / installments'**
  String get pm_financing;

  /// No description provided for @snack_saved_prefix.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get snack_saved_prefix;

  /// No description provided for @setup_hub_title.
  ///
  /// In en, this message translates to:
  /// **'Setup & Preferences'**
  String get setup_hub_title;

  /// No description provided for @setup_hub_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your app settings'**
  String get setup_hub_subtitle;

  /// No description provided for @setup_hub_note.
  ///
  /// In en, this message translates to:
  /// **'Each section can be changed independently anytime.'**
  String get setup_hub_note;

  /// No description provided for @setup_hub_card_title.
  ///
  /// In en, this message translates to:
  /// **'Setup & Preferences'**
  String get setup_hub_card_title;

  /// No description provided for @setup_hub_card_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure backup, notifications, payments & security'**
  String get setup_hub_card_subtitle;

  /// No description provided for @setup_backup_title.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get setup_backup_title;

  /// No description provided for @setup_backup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups in secure storage'**
  String get setup_backup_subtitle;

  /// No description provided for @setup_notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get setup_notifications_title;

  /// No description provided for @setup_notifications_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Warranty expiry reminders'**
  String get setup_notifications_subtitle;

  /// No description provided for @setup_payment_methods_title.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get setup_payment_methods_title;

  /// No description provided for @setup_payment_methods_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick options for adding items'**
  String get setup_payment_methods_subtitle;

  /// No description provided for @setup_security_title.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get setup_security_title;

  /// No description provided for @setup_security_subtitle.
  ///
  /// In en, this message translates to:
  /// **'App lock with device biometrics'**
  String get setup_security_subtitle;

  /// No description provided for @notif_title.
  ///
  /// In en, this message translates to:
  /// **'Reminders & notifications'**
  String get notif_title;

  /// No description provided for @notif_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get notif_enable;

  /// No description provided for @notif_enable_sub.
  ///
  /// In en, this message translates to:
  /// **'Warranty expirations, service intervals, etc.'**
  String get notif_enable_sub;

  /// No description provided for @notif_lead.
  ///
  /// In en, this message translates to:
  /// **'Lead time before expiry'**
  String get notif_lead;

  /// No description provided for @notif_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly digest'**
  String get notif_weekly;

  /// No description provided for @notif_weekly_sub.
  ///
  /// In en, this message translates to:
  /// **'A weekly overview of due warranties'**
  String get notif_weekly_sub;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @notif_note.
  ///
  /// In en, this message translates to:
  /// **'Push notifications will be set up later. This page only stores your preferences.'**
  String get notif_note;

  /// No description provided for @notif_saved.
  ///
  /// In en, this message translates to:
  /// **'Notification settings saved'**
  String get notif_saved;

  /// No description provided for @security_title.
  ///
  /// In en, this message translates to:
  /// **'Choose security option'**
  String get security_title;

  /// No description provided for @security_question.
  ///
  /// In en, this message translates to:
  /// **'How would you like to protect the app?'**
  String get security_question;

  /// No description provided for @security_pin.
  ///
  /// In en, this message translates to:
  /// **'PIN protection'**
  String get security_pin;

  /// No description provided for @security_bio.
  ///
  /// In en, this message translates to:
  /// **'Biometrics (Face/Touch)'**
  String get security_bio;

  /// No description provided for @security_none.
  ///
  /// In en, this message translates to:
  /// **'No protection'**
  String get security_none;

  /// No description provided for @security_footer.
  ///
  /// In en, this message translates to:
  /// **'You can change this setting later.'**
  String get security_footer;

  /// No description provided for @pin_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get pin_dialog_title;

  /// No description provided for @pin_label.
  ///
  /// In en, this message translates to:
  /// **'PIN (4 digits)'**
  String get pin_label;

  /// No description provided for @pin_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter 4 digits'**
  String get pin_invalid;

  /// No description provided for @pin_saved.
  ///
  /// In en, this message translates to:
  /// **'PIN saved'**
  String get pin_saved;

  /// No description provided for @bio_enabled.
  ///
  /// In en, this message translates to:
  /// **'Biometrics enabled'**
  String get bio_enabled;

  /// No description provided for @bio_error.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get bio_error;

  /// No description provided for @none_enabled.
  ///
  /// In en, this message translates to:
  /// **'Protection disabled'**
  String get none_enabled;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @not_set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get not_set;

  /// No description provided for @field_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get field_required;

  /// No description provided for @category_required.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get category_required;

  /// No description provided for @save_failed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get save_failed;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Garantie Safe'**
  String get home_title;

  /// No description provided for @home_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep track of all your warranties'**
  String get home_subtitle;

  /// No description provided for @home_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get home_welcome;

  /// No description provided for @home_restart_onboarding.
  ///
  /// In en, this message translates to:
  /// **'Restart onboarding'**
  String get home_restart_onboarding;

  /// No description provided for @home_add_card_title.
  ///
  /// In en, this message translates to:
  /// **'Add New Receipt'**
  String get home_add_card_title;

  /// No description provided for @home_add_card_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a receipt or add manually'**
  String get home_add_card_subtitle;

  /// No description provided for @home_scan_button.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get home_scan_button;

  /// No description provided for @home_manual_button.
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get home_manual_button;

  /// No description provided for @home_items_section_title.
  ///
  /// In en, this message translates to:
  /// **'Your Receipts'**
  String get home_items_section_title;

  /// No description provided for @home_items_empty.
  ///
  /// In en, this message translates to:
  /// **'No receipts yet'**
  String get home_items_empty;

  /// No description provided for @home_items_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first receipt to get started'**
  String get home_items_empty_subtitle;

  /// No description provided for @home_scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get home_scan;

  /// No description provided for @home_import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get home_import;

  /// No description provided for @home_receipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get home_receipts;

  /// No description provided for @home_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get home_settings;

  /// No description provided for @home_status_active_items.
  ///
  /// In en, this message translates to:
  /// **'{count} active items'**
  String home_status_active_items(int count);

  /// No description provided for @home_status_expiring_soon.
  ///
  /// In en, this message translates to:
  /// **'{count} expiring soon'**
  String home_status_expiring_soon(int count);

  /// No description provided for @home_status_all_good.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get home_status_all_good;

  /// No description provided for @import_source_title.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import_source_title;

  /// No description provided for @import_source_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a source'**
  String get import_source_subtitle;

  /// No description provided for @import_photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get import_photo;

  /// No description provided for @import_photo_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery'**
  String get import_photo_subtitle;

  /// No description provided for @import_pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get import_pdf;

  /// No description provided for @import_pdf_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF document'**
  String get import_pdf_subtitle;

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_intro.
  ///
  /// In en, this message translates to:
  /// **'Choose which events you want to be notified about'**
  String get notifications_intro;

  /// No description provided for @notifications_reminders.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get notifications_reminders;

  /// No description provided for @notifications_reminders_sub.
  ///
  /// In en, this message translates to:
  /// **'Get a reminder when a warranty is about to expire'**
  String get notifications_reminders_sub;

  /// No description provided for @notifications_expiring.
  ///
  /// In en, this message translates to:
  /// **'Expiration alerts'**
  String get notifications_expiring;

  /// No description provided for @notifications_expiring_sub.
  ///
  /// In en, this message translates to:
  /// **'Be notified before a warranty or receipt expires'**
  String get notifications_expiring_sub;

  /// No description provided for @notifications_summary.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get notifications_summary;

  /// No description provided for @notifications_summary_sub.
  ///
  /// In en, this message translates to:
  /// **'Receive a weekly overview of your warranties'**
  String get notifications_summary_sub;

  /// No description provided for @notifications_finish.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get notifications_finish;

  /// No description provided for @notif_warranty_expiring_soon_title.
  ///
  /// In en, this message translates to:
  /// **'Warranty expiring soon'**
  String get notif_warranty_expiring_soon_title;

  /// No description provided for @notif_warranty_expires_today_title.
  ///
  /// In en, this message translates to:
  /// **'Warranty expires today'**
  String get notif_warranty_expires_today_title;

  /// No description provided for @notif_warranty_expires_in_days_body.
  ///
  /// In en, this message translates to:
  /// **'{itemTitle} expires in {days} days.'**
  String notif_warranty_expires_in_days_body(String itemTitle, int days);

  /// No description provided for @notif_warranty_expires_today_body.
  ///
  /// In en, this message translates to:
  /// **'{itemTitle} expires today.'**
  String notif_warranty_expires_today_body(String itemTitle);

  /// No description provided for @notifications_summary_time_title.
  ///
  /// In en, this message translates to:
  /// **'Summary time'**
  String get notifications_summary_time_title;

  /// No description provided for @notifications_lead_title.
  ///
  /// In en, this message translates to:
  /// **'Lead time (days)'**
  String get notifications_lead_title;

  /// No description provided for @notifications_lead_sub.
  ///
  /// In en, this message translates to:
  /// **'How many days in advance should we remind you?'**
  String get notifications_lead_sub;

  /// No description provided for @notifications_time_title.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get notifications_time_title;

  /// No description provided for @notifications_summary_day_title.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary day'**
  String get notifications_summary_day_title;

  /// No description provided for @weekday_mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekday_mon;

  /// No description provided for @weekday_tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekday_tue;

  /// No description provided for @weekday_wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekday_wed;

  /// No description provided for @weekday_thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekday_thu;

  /// No description provided for @weekday_fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekday_fri;

  /// No description provided for @weekday_sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekday_sat;

  /// No description provided for @weekday_sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekday_sun;

  /// No description provided for @security_device_lock.
  ///
  /// In en, this message translates to:
  /// **'Device lock (Face/Touch/Code)'**
  String get security_device_lock;

  /// No description provided for @security_device_lock_hint.
  ///
  /// In en, this message translates to:
  /// **'Uses your phone’s existing device lock.'**
  String get security_device_lock_hint;

  /// No description provided for @device_lock_reason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate with Face/Touch or device passcode.'**
  String get device_lock_reason;

  /// No description provided for @device_lock_enabled.
  ///
  /// In en, this message translates to:
  /// **'Device lock enabled'**
  String get device_lock_enabled;

  /// No description provided for @device_lock_error.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get device_lock_error;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_section_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settings_section_preferences;

  /// No description provided for @settings_section_backup_security.
  ///
  /// In en, this message translates to:
  /// **'Backup & Security'**
  String get settings_section_backup_security;

  /// No description provided for @settings_section_data_storage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get settings_section_data_storage;

  /// No description provided for @settings_section_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_section_about;

  /// No description provided for @settings_section_developer.
  ///
  /// In en, this message translates to:
  /// **'Developer Options'**
  String get settings_section_developer;

  /// No description provided for @settings_section_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settings_section_general;

  /// No description provided for @settings_section_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_section_notifications;

  /// No description provided for @settings_section_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settings_section_security;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_appearance_sub.
  ///
  /// In en, this message translates to:
  /// **'Theme and display settings'**
  String get settings_appearance_sub;

  /// No description provided for @settings_payment_methods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get settings_payment_methods;

  /// No description provided for @settings_payment_methods_sub.
  ///
  /// In en, this message translates to:
  /// **'Manage saved payment methods'**
  String get settings_payment_methods_sub;

  /// No description provided for @settings_app_lock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get settings_app_lock;

  /// No description provided for @settings_app_lock_sub.
  ///
  /// In en, this message translates to:
  /// **'Secure your app with biometric authentication'**
  String get settings_app_lock_sub;

  /// No description provided for @settings_app_version.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settings_app_version;

  /// No description provided for @settings_dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settings_dark_mode;

  /// No description provided for @settings_dark_mode_sub.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark theme'**
  String get settings_dark_mode_sub;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get settings_notifications;

  /// No description provided for @settings_notifications_sub.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable app notifications'**
  String get settings_notifications_sub;

  /// No description provided for @settings_restart_onboarding.
  ///
  /// In en, this message translates to:
  /// **'Restart onboarding'**
  String get settings_restart_onboarding;

  /// No description provided for @settings_restart_onboarding_sub.
  ///
  /// In en, this message translates to:
  /// **'Repeat the introduction and setup process'**
  String get settings_restart_onboarding_sub;

  /// No description provided for @settings_restart_done.
  ///
  /// In en, this message translates to:
  /// **'Onboarding reset. Restart the app to see changes.'**
  String get settings_restart_done;

  /// No description provided for @settings_language_sub.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language (or System).'**
  String get settings_language_sub;

  /// No description provided for @settings_language_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_language_system;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @language_auto.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get language_auto;

  /// No description provided for @language_de.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get language_de;

  /// No description provided for @language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_en;

  /// No description provided for @items_title.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get items_title;

  /// No description provided for @items_empty.
  ///
  /// In en, this message translates to:
  /// **'No items yet.\nAdd one using the + button.'**
  String get items_empty;

  /// No description provided for @items_merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get items_merchant;

  /// No description provided for @items_purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get items_purchase;

  /// No description provided for @items_expiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get items_expiry;

  /// No description provided for @items_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get items_add;

  /// No description provided for @items_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get items_saved;

  /// No description provided for @items_deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get items_deleted;

  /// No description provided for @items_updated.
  ///
  /// In en, this message translates to:
  /// **'Receipt updated'**
  String get items_updated;

  /// No description provided for @items_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit receipt'**
  String get items_edit_title;

  /// No description provided for @items_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit receipt'**
  String get items_edit;

  /// No description provided for @items_name.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get items_name;

  /// No description provided for @items_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee machine, TV, Drill'**
  String get items_name_hint;

  /// No description provided for @items_merchant_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. MediaMarkt Zug'**
  String get items_merchant_hint;

  /// No description provided for @items_pick_purchase_date.
  ///
  /// In en, this message translates to:
  /// **'Pick purchase date'**
  String get items_pick_purchase_date;

  /// No description provided for @items_pick_expiry_date.
  ///
  /// In en, this message translates to:
  /// **'Pick expiry date'**
  String get items_pick_expiry_date;

  /// No description provided for @items_payment_method.
  ///
  /// In en, this message translates to:
  /// **'Payment method (optional)'**
  String get items_payment_method;

  /// No description provided for @items_payment_method_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. credit card, Twint, …'**
  String get items_payment_method_hint;

  /// No description provided for @items_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get items_category;

  /// No description provided for @items_category_hint.
  ///
  /// In en, this message translates to:
  /// **'Select one'**
  String get items_category_hint;

  /// No description provided for @attachment_required.
  ///
  /// In en, this message translates to:
  /// **'A receipt or document is required.'**
  String get attachment_required;

  /// No description provided for @warranty_years.
  ///
  /// In en, this message translates to:
  /// **'Warranty (years)'**
  String get warranty_years;

  /// No description provided for @years_suffix.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years_suffix;

  /// No description provided for @custom_expiry.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get custom_expiry;

  /// No description provided for @warranty_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get warranty_custom;

  /// No description provided for @warranty_custom_years.
  ///
  /// In en, this message translates to:
  /// **'Custom warranty (years)'**
  String get warranty_custom_years;

  /// No description provided for @warranty_custom_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Enter custom warranty duration'**
  String get warranty_custom_dialog_title;

  /// No description provided for @warranty_custom_dialog_hint.
  ///
  /// In en, this message translates to:
  /// **'Number of years (1-10)'**
  String get warranty_custom_dialog_hint;

  /// No description provided for @warranty_custom_error_min.
  ///
  /// In en, this message translates to:
  /// **'Minimum 1 year'**
  String get warranty_custom_error_min;

  /// No description provided for @warranty_custom_error_max.
  ///
  /// In en, this message translates to:
  /// **'Maximum 10 years'**
  String get warranty_custom_error_max;

  /// No description provided for @warranty_custom_error_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get warranty_custom_error_invalid;

  /// No description provided for @expiry_date_required.
  ///
  /// In en, this message translates to:
  /// **'Please set warranty duration or expiry date'**
  String get expiry_date_required;

  /// No description provided for @item_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get item_notes;

  /// No description provided for @item_notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Repair IDs, serial numbers, seller, remarks …'**
  String get item_notes_hint;

  /// No description provided for @scan_title.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan_title;

  /// No description provided for @scan_placeholder.
  ///
  /// In en, this message translates to:
  /// **'The scanner/OCR view will appear here later.'**
  String get scan_placeholder;

  /// No description provided for @pin_setup_title.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get pin_setup_title;

  /// No description provided for @pin_setup_intro.
  ///
  /// In en, this message translates to:
  /// **'Please set a 4-digit PIN and confirm it.'**
  String get pin_setup_intro;

  /// No description provided for @pin_label_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get pin_label_confirm;

  /// No description provided for @pin_mismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pin_mismatch;

  /// No description provided for @attach_receipt_photo.
  ///
  /// In en, this message translates to:
  /// **'Add receipt photo'**
  String get attach_receipt_photo;

  /// No description provided for @receipt_photo_title.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get receipt_photo_title;

  /// No description provided for @receipt_photo_missing.
  ///
  /// In en, this message translates to:
  /// **'Receipt image not found.'**
  String get receipt_photo_missing;

  /// No description provided for @photo_replace.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get photo_replace;

  /// No description provided for @photo_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photo_remove;

  /// No description provided for @photo_remove_title.
  ///
  /// In en, this message translates to:
  /// **'Remove photo?'**
  String get photo_remove_title;

  /// No description provided for @photo_remove_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to remove the photo?'**
  String get photo_remove_confirm;

  /// No description provided for @image_attached.
  ///
  /// In en, this message translates to:
  /// **'Image attached'**
  String get image_attached;

  /// No description provided for @attach_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attach_camera;

  /// No description provided for @attach_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get attach_gallery;

  /// No description provided for @attach_file.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get attach_file;

  /// No description provided for @attach_file_pdf.
  ///
  /// In en, this message translates to:
  /// **'Choose file or PDF'**
  String get attach_file_pdf;

  /// No description provided for @attachments_title.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachments_title;

  /// No description provided for @attachment_add.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get attachment_add;

  /// No description provided for @attachment_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attachment_camera;

  /// No description provided for @attachment_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get attachment_gallery;

  /// No description provided for @attachment_remove_title.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment?'**
  String get attachment_remove_title;

  /// No description provided for @attachment_remove_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to remove the attachment?'**
  String get attachment_remove_confirm;

  /// No description provided for @pdf_attached.
  ///
  /// In en, this message translates to:
  /// **'PDF attached'**
  String get pdf_attached;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save_item_first.
  ///
  /// In en, this message translates to:
  /// **'Save the item first to add attachments'**
  String get save_item_first;

  /// No description provided for @no_attachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet'**
  String get no_attachments;

  /// No description provided for @attachment_added.
  ///
  /// In en, this message translates to:
  /// **'Attachment added'**
  String get attachment_added;

  /// No description provided for @attachment_deleted.
  ///
  /// In en, this message translates to:
  /// **'Attachment deleted'**
  String get attachment_deleted;

  /// No description provided for @delete_attachment_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this attachment?'**
  String get delete_attachment_confirm;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get delete_title;

  /// No description provided for @delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete receipt?'**
  String get delete_confirm_title;

  /// No description provided for @delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this receipt?'**
  String get delete_confirm;

  /// No description provided for @delete_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this item? This action cannot be undone.'**
  String get delete_confirm_body;

  /// No description provided for @delete_confirm_receipt.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this receipt? This cannot be undone.'**
  String get delete_confirm_receipt;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @restart_onboarding_title.
  ///
  /// In en, this message translates to:
  /// **'Restart onboarding?'**
  String get restart_onboarding_title;

  /// No description provided for @restart_onboarding_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to reset and restart the onboarding?'**
  String get restart_onboarding_confirm;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @cat_not_set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get cat_not_set;

  /// No description provided for @cat_electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get cat_electronics;

  /// No description provided for @cat_household.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get cat_household;

  /// No description provided for @cat_vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get cat_vehicle;

  /// No description provided for @cat_tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get cat_tools;

  /// No description provided for @cat_clothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get cat_clothing;

  /// No description provided for @cat_services.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get cat_services;

  /// No description provided for @cat_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cat_other;

  /// No description provided for @filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filter_all;

  /// No description provided for @filter_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filter_active;

  /// No description provided for @filter_due_soon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get filter_due_soon;

  /// No description provided for @filter_expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get filter_expired;

  /// No description provided for @filter_category_label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filter_category_label;

  /// No description provided for @filter_category_all.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get filter_category_all;

  /// No description provided for @status_expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get status_expired;

  /// No description provided for @status_no_warranty.
  ///
  /// In en, this message translates to:
  /// **'No warranty'**
  String get status_no_warranty;

  /// No description provided for @status_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get status_today;

  /// No description provided for @status_month_left.
  ///
  /// In en, this message translates to:
  /// **'1 month left'**
  String get status_month_left;

  /// No description provided for @status_months_left.
  ///
  /// In en, this message translates to:
  /// **'{months} months left'**
  String status_months_left(int months);

  /// No description provided for @status_year_left.
  ///
  /// In en, this message translates to:
  /// **'1 year left'**
  String get status_year_left;

  /// No description provided for @status_years_left.
  ///
  /// In en, this message translates to:
  /// **'{years} years left'**
  String status_years_left(int years);

  /// No description provided for @status_years_months_left.
  ///
  /// In en, this message translates to:
  /// **'{years} years {months} months left'**
  String status_years_months_left(int years, int months);

  /// No description provided for @status_expired_recently.
  ///
  /// In en, this message translates to:
  /// **'Expired recently'**
  String get status_expired_recently;

  /// No description provided for @status_expired_year_ago.
  ///
  /// In en, this message translates to:
  /// **'Expired 1 year ago'**
  String get status_expired_year_ago;

  /// No description provided for @status_expired_years_ago.
  ///
  /// In en, this message translates to:
  /// **'Expired {years} years ago'**
  String status_expired_years_ago(int years);

  /// No description provided for @status_in_day.
  ///
  /// In en, this message translates to:
  /// **'In 1 day'**
  String get status_in_day;

  /// No description provided for @status_in_days.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String status_in_days(int days);

  /// No description provided for @status_in_month.
  ///
  /// In en, this message translates to:
  /// **'In 1 month'**
  String get status_in_month;

  /// No description provided for @status_in_months.
  ///
  /// In en, this message translates to:
  /// **'In {months} months'**
  String status_in_months(int months);

  /// No description provided for @status_in_year.
  ///
  /// In en, this message translates to:
  /// **'In 1 year'**
  String get status_in_year;

  /// No description provided for @status_in_years.
  ///
  /// In en, this message translates to:
  /// **'In {years} years'**
  String status_in_years(int years);

  /// No description provided for @status_in_years_months.
  ///
  /// In en, this message translates to:
  /// **'In {years} years {months} months'**
  String status_in_years_months(int years, int months);

  /// No description provided for @status_ago_day.
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get status_ago_day;

  /// No description provided for @status_ago_days.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String status_ago_days(int days);

  /// No description provided for @load_failed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get load_failed;

  /// No description provided for @filter_soon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get filter_soon;

  /// No description provided for @status_expires_today.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get status_expires_today;

  /// No description provided for @status_expiring_in_days.
  ///
  /// In en, this message translates to:
  /// **'Expiring in {days} days'**
  String status_expiring_in_days(Object days);

  /// No description provided for @status_expiring_in_day.
  ///
  /// In en, this message translates to:
  /// **'Expiring in 1 day'**
  String get status_expiring_in_day;

  /// No description provided for @status_expired_days_ago.
  ///
  /// In en, this message translates to:
  /// **'Expired {days} days ago'**
  String status_expired_days_ago(Object days);

  /// No description provided for @status_expired_day_ago.
  ///
  /// In en, this message translates to:
  /// **'Expired 1 day ago'**
  String get status_expired_day_ago;

  /// No description provided for @use_warranty_duration.
  ///
  /// In en, this message translates to:
  /// **'Use warranty duration instead'**
  String get use_warranty_duration;

  /// No description provided for @no_receipt_warning.
  ///
  /// In en, this message translates to:
  /// **'No receipt attached'**
  String get no_receipt_warning;

  /// No description provided for @no_receipt_indicator.
  ///
  /// In en, this message translates to:
  /// **'No receipt'**
  String get no_receipt_indicator;

  /// No description provided for @merchant_label.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant_label;

  /// No description provided for @category_label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category_label;

  /// No description provided for @purchase_date_label.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get purchase_date_label;

  /// No description provided for @expiry_date_label.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiry_date_label;

  /// No description provided for @payment_method_label.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get payment_method_label;

  /// No description provided for @payment_methods_title.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get payment_methods_title;

  /// No description provided for @payment_methods_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your payment methods'**
  String get payment_methods_subtitle;

  /// No description provided for @payment_methods_add.
  ///
  /// In en, this message translates to:
  /// **'Add payment method'**
  String get payment_methods_add;

  /// No description provided for @payment_methods_add_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'New payment method'**
  String get payment_methods_add_dialog_title;

  /// No description provided for @payment_methods_add_dialog_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter method name'**
  String get payment_methods_add_dialog_hint;

  /// No description provided for @payment_methods_add_dialog_save.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get payment_methods_add_dialog_save;

  /// No description provided for @payment_methods_edit_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Edit payment method'**
  String get payment_methods_edit_dialog_title;

  /// No description provided for @payment_methods_edit_dialog_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get payment_methods_edit_dialog_save;

  /// No description provided for @payment_methods_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete payment method?'**
  String get payment_methods_delete_confirm_title;

  /// No description provided for @payment_methods_delete_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get payment_methods_delete_confirm_message;

  /// No description provided for @payment_methods_delete_confirm_ok.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get payment_methods_delete_confirm_ok;

  /// No description provided for @payment_methods_cannot_delete_message.
  ///
  /// In en, this message translates to:
  /// **'This method is used by {count} items. It has been archived instead.'**
  String payment_methods_cannot_delete_message(Object count);

  /// No description provided for @payment_methods_archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get payment_methods_archived;

  /// No description provided for @payment_methods_archived_edit_hint.
  ///
  /// In en, this message translates to:
  /// **'Currently selected (archived)'**
  String get payment_methods_archived_edit_hint;

  /// No description provided for @payment_methods_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get payment_methods_disabled;

  /// No description provided for @payment_methods_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get payment_methods_enabled;

  /// No description provided for @payment_methods_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get payment_methods_custom;

  /// No description provided for @payment_methods_builtin.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get payment_methods_builtin;

  /// No description provided for @payment_methods_empty.
  ///
  /// In en, this message translates to:
  /// **'No payment methods configured'**
  String get payment_methods_empty;

  /// No description provided for @payment_methods_section_enabled.
  ///
  /// In en, this message translates to:
  /// **'Active methods'**
  String get payment_methods_section_enabled;

  /// No description provided for @payment_methods_section_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled methods'**
  String get payment_methods_section_disabled;

  /// No description provided for @payment_methods_section_archived.
  ///
  /// In en, this message translates to:
  /// **'Archived methods'**
  String get payment_methods_section_archived;

  /// No description provided for @payment_methods_empty_notice.
  ///
  /// In en, this message translates to:
  /// **'No payment methods configured. Set them up first.'**
  String get payment_methods_empty_notice;

  /// No description provided for @payment_methods_configure.
  ///
  /// In en, this message translates to:
  /// **'Configure payment methods'**
  String get payment_methods_configure;

  /// No description provided for @empty_all_title.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get empty_all_title;

  /// No description provided for @empty_all_hint.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any items yet.'**
  String get empty_all_hint;

  /// No description provided for @empty_soon_title.
  ///
  /// In en, this message translates to:
  /// **'Nothing expiring soon'**
  String get empty_soon_title;

  /// No description provided for @empty_soon_hint.
  ///
  /// In en, this message translates to:
  /// **'No warranties are expiring soon.'**
  String get empty_soon_hint;

  /// No description provided for @empty_expired_title.
  ///
  /// In en, this message translates to:
  /// **'No expired items'**
  String get empty_expired_title;

  /// No description provided for @empty_expired_hint.
  ///
  /// In en, this message translates to:
  /// **'There are no expired warranties.'**
  String get empty_expired_hint;

  /// No description provided for @error_generic_title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error_generic_title;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @backup_title.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backup_title;

  /// No description provided for @backup_now.
  ///
  /// In en, this message translates to:
  /// **'Backup now'**
  String get backup_now;

  /// No description provided for @backup_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get backup_restore;

  /// No description provided for @backup_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto backup'**
  String get backup_auto;

  /// No description provided for @backup_frequency.
  ///
  /// In en, this message translates to:
  /// **'Backup frequency'**
  String get backup_frequency;

  /// No description provided for @backup_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get backup_weekly;

  /// No description provided for @backup_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get backup_monthly;

  /// No description provided for @backup_location.
  ///
  /// In en, this message translates to:
  /// **'Backup location'**
  String get backup_location;

  /// No description provided for @backup_location_not_set.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get backup_location_not_set;

  /// No description provided for @backup_location_required.
  ///
  /// In en, this message translates to:
  /// **'Backup location is required'**
  String get backup_location_required;

  /// No description provided for @backup_last_backup.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get backup_last_backup;

  /// No description provided for @backup_never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get backup_never;

  /// No description provided for @backup_time_just_now.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get backup_time_just_now;

  /// No description provided for @backup_time_minutes_ago.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String backup_time_minutes_ago(int minutes);

  /// No description provided for @backup_time_hours_ago.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String backup_time_hours_ago(int hours);

  /// No description provided for @backup_time_days_ago.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String backup_time_days_ago(int days);

  /// No description provided for @backup_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Creating backup...'**
  String get backup_in_progress;

  /// No description provided for @backup_success.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backup_success;

  /// No description provided for @backup_failed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backup_failed;

  /// No description provided for @backup_restore_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get backup_restore_confirm_title;

  /// No description provided for @backup_restore_confirm.
  ///
  /// In en, this message translates to:
  /// **'This will overwrite all current data. Continue?'**
  String get backup_restore_confirm;

  /// No description provided for @backup_restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring backup...'**
  String get backup_restoring;

  /// No description provided for @backup_restore_success.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully. Please restart the app.'**
  String get backup_restore_success;

  /// No description provided for @backup_restore_failed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get backup_restore_failed;

  /// No description provided for @backup_select_location.
  ///
  /// In en, this message translates to:
  /// **'Select backup folder'**
  String get backup_select_location;

  /// No description provided for @backup_select_file.
  ///
  /// In en, this message translates to:
  /// **'Select backup file'**
  String get backup_select_file;

  /// No description provided for @backup_save_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Save Backup'**
  String get backup_save_dialog_title;

  /// No description provided for @backup_required_title.
  ///
  /// In en, this message translates to:
  /// **'Backup required'**
  String get backup_required_title;

  /// No description provided for @backup_required_body.
  ///
  /// In en, this message translates to:
  /// **'Backup is required to protect your receipts and attachments. Please select a backup location.'**
  String get backup_required_body;

  /// No description provided for @backup_no_server_info.
  ///
  /// In en, this message translates to:
  /// **'We do NOT have servers. Your data is stored only on your device and in the backup location you choose.'**
  String get backup_no_server_info;

  /// No description provided for @backup_share.
  ///
  /// In en, this message translates to:
  /// **'Share backup file'**
  String get backup_share;

  /// No description provided for @backupExportReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Export reminder'**
  String get backupExportReminderTitle;

  /// No description provided for @backupExportReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Consider exporting a backup to keep a safe copy outside the app.'**
  String get backupExportReminderMessage;

  /// No description provided for @backupExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get backupExportButton;

  /// No description provided for @trash_title.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash_title;

  /// No description provided for @trash_empty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trash_empty;

  /// No description provided for @trash_deleted_on.
  ///
  /// In en, this message translates to:
  /// **'Deleted on'**
  String get trash_deleted_on;

  /// No description provided for @trash_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get trash_restore;

  /// No description provided for @trash_delete_permanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get trash_delete_permanently;

  /// No description provided for @trash_restore_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Restore item?'**
  String get trash_restore_confirm_title;

  /// No description provided for @trash_restore_confirm.
  ///
  /// In en, this message translates to:
  /// **'This will restore the item to your warranties list.'**
  String get trash_restore_confirm;

  /// No description provided for @trash_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get trash_delete_confirm_title;

  /// No description provided for @trash_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the item and all attachments. This cannot be undone!'**
  String get trash_delete_confirm;

  /// No description provided for @trash_restored.
  ///
  /// In en, this message translates to:
  /// **'Item restored'**
  String get trash_restored;

  /// No description provided for @trash_deleted.
  ///
  /// In en, this message translates to:
  /// **'Item permanently deleted'**
  String get trash_deleted;

  /// No description provided for @trash_purge_old.
  ///
  /// In en, this message translates to:
  /// **'Auto-cleanup ran: {count} old items purged'**
  String trash_purge_old(Object count);

  /// No description provided for @scan_choose_source.
  ///
  /// In en, this message translates to:
  /// **'Choose source'**
  String get scan_choose_source;

  /// No description provided for @scan_choose_source_sub.
  ///
  /// In en, this message translates to:
  /// **'Select how you want to add your receipt:'**
  String get scan_choose_source_sub;

  /// No description provided for @scan_take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get scan_take_photo;

  /// No description provided for @scan_take_photo_sub.
  ///
  /// In en, this message translates to:
  /// **'Use camera to capture receipt'**
  String get scan_take_photo_sub;

  /// No description provided for @scan_upload_receipt.
  ///
  /// In en, this message translates to:
  /// **'Upload Receipt'**
  String get scan_upload_receipt;

  /// No description provided for @scan_upload_receipt_sub.
  ///
  /// In en, this message translates to:
  /// **'Select from Files, Downloads, Drive, etc.'**
  String get scan_upload_receipt_sub;

  /// No description provided for @scan_how_it_works.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get scan_how_it_works;

  /// No description provided for @scan_how_it_works_steps.
  ///
  /// In en, this message translates to:
  /// **'1. Take a photo or select a file (image/PDF)\n2. Text will be extracted automatically\n3. Review and edit the detected details\n4. Save your warranty'**
  String get scan_how_it_works_steps;

  /// No description provided for @scan_extracting_text.
  ///
  /// In en, this message translates to:
  /// **'Extracting text...'**
  String get scan_extracting_text;

  /// No description provided for @scan_extracting_wait.
  ///
  /// In en, this message translates to:
  /// **'This may take a few moments'**
  String get scan_extracting_wait;

  /// No description provided for @scan_file_access_error.
  ///
  /// In en, this message translates to:
  /// **'Could not access the selected file'**
  String get scan_file_access_error;

  /// No description provided for @scan_unsupported_file_type.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type: {extension}'**
  String scan_unsupported_file_type(String extension);

  /// No description provided for @scan_ocr_failed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read this receipt clearly. Please enter the details manually.'**
  String get scan_ocr_failed;

  /// No description provided for @scan_review_title.
  ///
  /// In en, this message translates to:
  /// **'Receipt Scanned'**
  String get scan_review_title;

  /// No description provided for @scan_review_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please review the detected details before saving:'**
  String get scan_review_subtitle;

  /// No description provided for @scan_review_merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get scan_review_merchant;

  /// No description provided for @scan_review_purchase_date.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get scan_review_purchase_date;

  /// No description provided for @scan_review_attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get scan_review_attachment;

  /// No description provided for @scan_review_files_attached.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) attached'**
  String scan_review_files_attached(int count);

  /// No description provided for @scan_review_attached.
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get scan_review_attached;

  /// No description provided for @scan_attachment_failed_title.
  ///
  /// In en, this message translates to:
  /// **'Receipt Attached'**
  String get scan_attachment_failed_title;

  /// No description provided for @scan_attachment_failed_message.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read this receipt clearly. The file has been attached, but please enter the details manually.'**
  String get scan_attachment_failed_message;

  /// No description provided for @scan_success.
  ///
  /// In en, this message translates to:
  /// **'Receipt scanned and attached successfully'**
  String get scan_success;

  /// No description provided for @multi_item_choice_title.
  ///
  /// In en, this message translates to:
  /// **'How many items?'**
  String get multi_item_choice_title;

  /// No description provided for @multi_item_choice_subtitle.
  ///
  /// In en, this message translates to:
  /// **'One receipt can be used for multiple warranty items'**
  String get multi_item_choice_subtitle;

  /// No description provided for @multi_item_create_one.
  ///
  /// In en, this message translates to:
  /// **'Create one item'**
  String get multi_item_create_one;

  /// No description provided for @multi_item_create_multiple.
  ///
  /// In en, this message translates to:
  /// **'Create multiple items'**
  String get multi_item_create_multiple;

  /// No description provided for @multi_item_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Create Multiple Items'**
  String get multi_item_screen_title;

  /// No description provided for @multi_item_shared_section.
  ///
  /// In en, this message translates to:
  /// **'Shared Receipt Data'**
  String get multi_item_shared_section;

  /// No description provided for @multi_item_shared_info.
  ///
  /// In en, this message translates to:
  /// **'Merchant, purchase date and receipt are reused for all items. Only product-specific details need to be entered.'**
  String get multi_item_shared_info;

  /// No description provided for @multi_item_items_section.
  ///
  /// In en, this message translates to:
  /// **'Warranty Items'**
  String get multi_item_items_section;

  /// No description provided for @multi_item_item_number.
  ///
  /// In en, this message translates to:
  /// **'Item {number}'**
  String multi_item_item_number(int number);

  /// No description provided for @multi_item_add_another.
  ///
  /// In en, this message translates to:
  /// **'Add another item'**
  String get multi_item_add_another;

  /// No description provided for @multi_item_create_button.
  ///
  /// In en, this message translates to:
  /// **'Create {count} {count, plural, =1{item} other{items}}'**
  String multi_item_create_button(int count);

  /// No description provided for @multi_item_validation_error.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields for each item'**
  String get multi_item_validation_error;

  /// No description provided for @multi_item_success.
  ///
  /// In en, this message translates to:
  /// **'{count} items created successfully'**
  String multi_item_success(int count);

  /// No description provided for @multi_item_add_from_receipt.
  ///
  /// In en, this message translates to:
  /// **'Add another product from this receipt'**
  String get multi_item_add_from_receipt;

  /// No description provided for @multi_item_add_from_receipt_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Reuse merchant and purchase date'**
  String get multi_item_add_from_receipt_subtitle;

  /// No description provided for @add_entry_title.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get add_entry_title;

  /// No description provided for @add_upload_image_pdf.
  ///
  /// In en, this message translates to:
  /// **'Upload image or PDF'**
  String get add_upload_image_pdf;

  /// No description provided for @add_manually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get add_manually;

  /// No description provided for @scan_button.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan_button;

  /// No description provided for @scan_button_camera.
  ///
  /// In en, this message translates to:
  /// **'Scan with camera'**
  String get scan_button_camera;

  /// No description provided for @snapshot_section_recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get snapshot_section_recommended;

  /// No description provided for @snapshot_section_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent backups'**
  String get snapshot_section_recent;

  /// No description provided for @snapshot_section_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily backups'**
  String get snapshot_section_daily;

  /// No description provided for @snapshot_section_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly backups'**
  String get snapshot_section_weekly;

  /// No description provided for @snapshot_section_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly backups'**
  String get snapshot_section_monthly;

  /// No description provided for @snapshot_current_state.
  ///
  /// In en, this message translates to:
  /// **'Current state'**
  String get snapshot_current_state;

  /// No description provided for @snapshot_empty_label.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get snapshot_empty_label;

  /// No description provided for @premium_upgrade_title.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get premium_upgrade_title;

  /// No description provided for @premium_limit_reached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the free limit'**
  String get premium_limit_reached;

  /// No description provided for @premium_free_limit_info.
  ///
  /// In en, this message translates to:
  /// **'The free version allows up to {count} active items.'**
  String premium_free_limit_info(int count);

  /// No description provided for @premium_unlock_title.
  ///
  /// In en, this message translates to:
  /// **'Premium Lifetime Unlock'**
  String get premium_unlock_title;

  /// No description provided for @premium_feature_unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited items'**
  String get premium_feature_unlimited;

  /// No description provided for @premium_feature_lifetime.
  ///
  /// In en, this message translates to:
  /// **'One-time payment, yours forever'**
  String get premium_feature_lifetime;

  /// No description provided for @premium_feature_no_subscription.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions or recurring fees'**
  String get premium_feature_no_subscription;

  /// No description provided for @premium_feature_offline.
  ///
  /// In en, this message translates to:
  /// **'Works completely offline'**
  String get premium_feature_offline;

  /// No description provided for @premium_price.
  ///
  /// In en, this message translates to:
  /// **'Only {price}'**
  String premium_price(String price);

  /// No description provided for @premium_upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get premium_upgrade;

  /// No description provided for @premium_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get premium_restore;

  /// No description provided for @premium_not_now.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get premium_not_now;

  /// No description provided for @premium_purchase_initiated.
  ///
  /// In en, this message translates to:
  /// **'Purchase initiated...'**
  String get premium_purchase_initiated;

  /// No description provided for @premium_purchase_failed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get premium_purchase_failed;

  /// No description provided for @premium_purchase_error.
  ///
  /// In en, this message translates to:
  /// **'Purchase error'**
  String get premium_purchase_error;

  /// No description provided for @premium_restored.
  ///
  /// In en, this message translates to:
  /// **'Premium restored successfully!'**
  String get premium_restored;

  /// No description provided for @premium_no_purchase_found.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found'**
  String get premium_no_purchase_found;

  /// No description provided for @premium_restore_error.
  ///
  /// In en, this message translates to:
  /// **'Restore error'**
  String get premium_restore_error;

  /// No description provided for @premium_status_free.
  ///
  /// In en, this message translates to:
  /// **'Free ({current}/{max} items)'**
  String premium_status_free(int current, int max);

  /// No description provided for @premium_status_premium.
  ///
  /// In en, this message translates to:
  /// **'Premium (Unlimited)'**
  String get premium_status_premium;

  /// No description provided for @premium_card_title.
  ///
  /// In en, this message translates to:
  /// **'Premium Status'**
  String get premium_card_title;

  /// No description provided for @premium_card_subtitle_free.
  ///
  /// In en, this message translates to:
  /// **'You are using the free version'**
  String get premium_card_subtitle_free;

  /// No description provided for @premium_card_subtitle_premium.
  ///
  /// In en, this message translates to:
  /// **'You have Premium access'**
  String get premium_card_subtitle_premium;

  /// No description provided for @premium_buy_lifetime.
  ///
  /// In en, this message translates to:
  /// **'Buy Lifetime Unlock'**
  String get premium_buy_lifetime;

  /// No description provided for @premium_unlocked_via.
  ///
  /// In en, this message translates to:
  /// **'Unlocked via {source}'**
  String premium_unlocked_via(String source);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @error_with_details.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String error_with_details(String details);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @continue_button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_button;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @restore_button.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore_button;

  /// No description provided for @backup_snapshot_failed.
  ///
  /// In en, this message translates to:
  /// **'Snapshot failed: {error}'**
  String backup_snapshot_failed(String error);

  /// No description provided for @backup_select_valid_file.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid backup file (.gsbackup)'**
  String get backup_select_valid_file;

  /// No description provided for @backup_restore_completed.
  ///
  /// In en, this message translates to:
  /// **'Restore Completed'**
  String get backup_restore_completed;

  /// No description provided for @backup_restore_failed_details.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String backup_restore_failed_details(String error);

  /// No description provided for @backup_exported_successfully.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully'**
  String get backup_exported_successfully;

  /// No description provided for @backupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export: {error}'**
  String backupExportFailed(String error);

  /// No description provided for @backup_cloud_exported.
  ///
  /// In en, this message translates to:
  /// **'Backup exported to cloud successfully'**
  String get backup_cloud_exported;

  /// No description provided for @backup_cloud_export_failed.
  ///
  /// In en, this message translates to:
  /// **'Cloud export failed: {error}'**
  String backup_cloud_export_failed(String error);

  /// No description provided for @backup_disable_cloud_title.
  ///
  /// In en, this message translates to:
  /// **'Disable Cloud Backup?'**
  String get backup_disable_cloud_title;

  /// No description provided for @backup_disable_cloud_message.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup will no longer be automatic. You can still manually export backups.'**
  String get backup_disable_cloud_message;

  /// No description provided for @backup_cloud_title.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get backup_cloud_title;

  /// No description provided for @backup_cloud_message.
  ///
  /// In en, this message translates to:
  /// **'When cloud backup is enabled, every time you create a backup, it will also be exported so you can save it to your cloud storage (Google Drive, iCloud Drive, etc.).\n\nTap \"Export to Cloud\" to save the backup to your preferred location.'**
  String get backup_cloud_message;

  /// No description provided for @backup_device_settings_info.
  ///
  /// In en, this message translates to:
  /// **'Please open your device Settings app and navigate to Backup settings.\n\nAndroid: Settings > System > Backup\niOS: Settings > [Your Name] > iCloud > iCloud Backup'**
  String get backup_device_settings_info;

  /// No description provided for @backup_time_min_ago.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String backup_time_min_ago(int minutes);

  /// No description provided for @backup_snapshot_count_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get backup_snapshot_count_none;

  /// No description provided for @backup_snapshot_count_daily.
  ///
  /// In en, this message translates to:
  /// **'{count} daily'**
  String backup_snapshot_count_daily(int count);

  /// No description provided for @backup_snapshot_count_weekly.
  ///
  /// In en, this message translates to:
  /// **'{count} weekly'**
  String backup_snapshot_count_weekly(int count);

  /// No description provided for @backup_snapshot_count_monthly.
  ///
  /// In en, this message translates to:
  /// **'{count} monthly'**
  String backup_snapshot_count_monthly(int count);

  /// No description provided for @backup_snapshot_count_total.
  ///
  /// In en, this message translates to:
  /// **'{total} available'**
  String backup_snapshot_count_total(int total);

  /// No description provided for @backup_status_header.
  ///
  /// In en, this message translates to:
  /// **'Backup Status'**
  String get backup_status_header;

  /// No description provided for @backup_last_backup_label.
  ///
  /// In en, this message translates to:
  /// **'Last successful backup:'**
  String get backup_last_backup_label;

  /// No description provided for @backup_snapshots_available_label.
  ///
  /// In en, this message translates to:
  /// **'Snapshots available:'**
  String get backup_snapshots_available_label;

  /// No description provided for @backup_next_scheduled_label.
  ///
  /// In en, this message translates to:
  /// **'Next backup scheduled:'**
  String get backup_next_scheduled_label;

  /// No description provided for @backup_status_label.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get backup_status_label;

  /// No description provided for @backup_status_up_to_date.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get backup_status_up_to_date;

  /// No description provided for @backup_last_error.
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String backup_last_error(String error);

  /// No description provided for @backup_cloud_outdated_title.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup Outdated'**
  String get backup_cloud_outdated_title;

  /// No description provided for @backup_cloud_outdated_message.
  ///
  /// In en, this message translates to:
  /// **'Your last internal backup is more recent than your last cloud export. Consider exporting to cloud again for complete protection.'**
  String get backup_cloud_outdated_message;

  /// No description provided for @backup_export_to_cloud_now.
  ///
  /// In en, this message translates to:
  /// **'Export to Cloud Now'**
  String get backup_export_to_cloud_now;

  /// No description provided for @backup_internal_protection_title.
  ///
  /// In en, this message translates to:
  /// **'Internal Backup Protection'**
  String get backup_internal_protection_title;

  /// No description provided for @backup_internal_protection_message.
  ///
  /// In en, this message translates to:
  /// **'Internal backups protect against accidental changes inside the app. Multiple snapshots (daily, weekly, monthly) are maintained for recovery. Stored securely in app-private storage.'**
  String get backup_internal_protection_message;

  /// No description provided for @backup_device_protection_title.
  ///
  /// In en, this message translates to:
  /// **'Device Backup Protection'**
  String get backup_device_protection_title;

  /// No description provided for @backup_device_protection_message.
  ///
  /// In en, this message translates to:
  /// **'Your data is included in device backup (Google Backup on Android, iCloud on iOS). This protects against device loss, uninstall, and moving to a new phone. Data is restored automatically when setting up a new device.'**
  String get backup_device_protection_message;

  /// No description provided for @backup_external_protection_title.
  ///
  /// In en, this message translates to:
  /// **'External Backup (Optional)'**
  String get backup_external_protection_title;

  /// No description provided for @backup_external_protection_message.
  ///
  /// In en, this message translates to:
  /// **'For extra security, export backup files manually and save to cloud storage (Google Drive, iCloud Drive, Dropbox, etc.) or external devices. Recommended for critical data.'**
  String get backup_external_protection_message;

  /// No description provided for @backup_create_update_now.
  ///
  /// In en, this message translates to:
  /// **'Create/update backup immediately'**
  String get backup_create_update_now;

  /// No description provided for @backup_export_to_cloud_storage.
  ///
  /// In en, this message translates to:
  /// **'Export backup file to cloud storage, email, or external device'**
  String get backup_export_to_cloud_storage;

  /// No description provided for @backup_export_tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Save exported backups to Google Drive, iCloud Drive, or Dropbox for maximum protection.'**
  String get backup_export_tip;

  /// No description provided for @backup_cloud_section_header.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get backup_cloud_section_header;

  /// No description provided for @backup_auto_export_prompt.
  ///
  /// In en, this message translates to:
  /// **'Automatically prompt to export backups to your cloud storage'**
  String get backup_auto_export_prompt;

  /// No description provided for @backup_cloud_export_status.
  ///
  /// In en, this message translates to:
  /// **'Cloud Export Status'**
  String get backup_cloud_export_status;

  /// No description provided for @backup_last_cloud_export.
  ///
  /// In en, this message translates to:
  /// **'Last cloud export:'**
  String get backup_last_cloud_export;

  /// No description provided for @backup_export_to_cloud_button.
  ///
  /// In en, this message translates to:
  /// **'Export to Cloud'**
  String get backup_export_to_cloud_button;

  /// No description provided for @backup_export_to_cloud_help.
  ///
  /// In en, this message translates to:
  /// **'Save backup to Google Drive, iCloud Drive, or another cloud service'**
  String get backup_export_to_cloud_help;

  /// No description provided for @backup_device_section_header.
  ///
  /// In en, this message translates to:
  /// **'Device Backup'**
  String get backup_device_section_header;

  /// No description provided for @backup_device_may_protect.
  ///
  /// In en, this message translates to:
  /// **'Your phone may also protect app data'**
  String get backup_device_may_protect;

  /// No description provided for @backup_device_protection_info.
  ///
  /// In en, this message translates to:
  /// **'Your device backup (iCloud on iOS, Google Backup on Android) may include app data. This provides additional protection when setting up a new device.'**
  String get backup_device_protection_info;

  /// No description provided for @backup_open_device_settings.
  ///
  /// In en, this message translates to:
  /// **'Open Device Backup Settings'**
  String get backup_open_device_settings;

  /// No description provided for @backup_restore_section_header.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backup_restore_section_header;

  /// No description provided for @backup_restore_from_backup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get backup_restore_from_backup;

  /// No description provided for @backup_restore_from_storage.
  ///
  /// In en, this message translates to:
  /// **'Restore from the backup in app storage'**
  String get backup_restore_from_storage;

  /// No description provided for @backup_no_internal_backup.
  ///
  /// In en, this message translates to:
  /// **'No internal backup available'**
  String get backup_no_internal_backup;

  /// No description provided for @backup_restore_from_file.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get backup_restore_from_file;

  /// No description provided for @backup_restore_from_file_help.
  ///
  /// In en, this message translates to:
  /// **'Select a backup file from your device or cloud storage'**
  String get backup_restore_from_file_help;

  /// No description provided for @backup_health_protected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get backup_health_protected;

  /// No description provided for @backup_health_partial.
  ///
  /// In en, this message translates to:
  /// **'Partial Protection'**
  String get backup_health_partial;

  /// No description provided for @backup_health_full_message.
  ///
  /// In en, this message translates to:
  /// **'Your data is fully protected with internal snapshots and device backup'**
  String get backup_health_full_message;

  /// No description provided for @backup_health_partial_message.
  ///
  /// In en, this message translates to:
  /// **'Internal backups are active, but cloud export is recommended for maximum protection'**
  String get backup_health_partial_message;

  /// No description provided for @backupStatusSafe.
  ///
  /// In en, this message translates to:
  /// **'Your data is safe'**
  String get backupStatusSafe;

  /// No description provided for @backupStatusNeedsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup recommended'**
  String get backupStatusNeedsBackup;

  /// No description provided for @backupLastBackupLabel.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get backupLastBackupLabel;

  /// No description provided for @backupActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Actions'**
  String get backupActionsTitle;

  /// No description provided for @backupCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get backupCloudTitle;

  /// No description provided for @backupCloudDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically save backups to your cloud storage'**
  String get backupCloudDescription;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreTitle;

  /// No description provided for @backupCloudSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup Cloud Backup'**
  String get backupCloudSetup;

  /// No description provided for @backupCloudSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder where backups will be automatically saved'**
  String get backupCloudSetupDescription;

  /// No description provided for @backupCloudConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup active'**
  String get backupCloudConfigured;

  /// No description provided for @backupCloudFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup folder'**
  String get backupCloudFolderLabel;

  /// No description provided for @backupCloudLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last cloud backup'**
  String get backupCloudLastBackup;

  /// No description provided for @backupCloudChangeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change Folder'**
  String get backupCloudChangeFolder;

  /// No description provided for @backupCloudDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable Cloud Backup'**
  String get backupCloudDisable;

  /// No description provided for @backupCloudSetupError.
  ///
  /// In en, this message translates to:
  /// **'Failed to setup cloud backup'**
  String get backupCloudSetupError;

  /// No description provided for @backupCloudAccessError.
  ///
  /// In en, this message translates to:
  /// **'Cannot access folder. Please choose a different folder.'**
  String get backupCloudAccessError;

  /// No description provided for @backupCloudBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup to Cloud Now'**
  String get backupCloudBackupNow;

  /// No description provided for @backupCloudBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to cloud folder'**
  String get backupCloudBackupSuccess;

  /// No description provided for @backupCloudBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup failed'**
  String get backupCloudBackupFailed;

  /// No description provided for @backupCloudDisableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disable automatic cloud backup? Your existing backup files will not be deleted.'**
  String get backupCloudDisableConfirm;

  /// No description provided for @backupCloudAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic Cloud Backup'**
  String get backupCloudAutomatic;

  /// No description provided for @backup_setup_title.
  ///
  /// In en, this message translates to:
  /// **'Backup Setup'**
  String get backup_setup_title;

  /// No description provided for @backup_choose_title.
  ///
  /// In en, this message translates to:
  /// **'Choose Backup'**
  String get backup_choose_title;

  /// No description provided for @backup_no_backups_title.
  ///
  /// In en, this message translates to:
  /// **'No backups available'**
  String get backup_no_backups_title;

  /// No description provided for @backup_no_backups_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Backups are created automatically'**
  String get backup_no_backups_subtitle;

  /// No description provided for @backup_restore_title.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get backup_restore_title;

  /// No description provided for @backup_restored_count.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} warranties successfully'**
  String backup_restored_count(int count);

  /// No description provided for @backup_restore_success_message.
  ///
  /// In en, this message translates to:
  /// **'Your data has been restored successfully.'**
  String get backup_restore_success_message;

  /// No description provided for @backup_restored_items.
  ///
  /// In en, this message translates to:
  /// **'Restored: {count} warranties'**
  String backup_restored_items(int count);

  /// No description provided for @backup_restoring_wait.
  ///
  /// In en, this message translates to:
  /// **'This may take a few moments'**
  String get backup_restoring_wait;

  /// No description provided for @backup_contents_header.
  ///
  /// In en, this message translates to:
  /// **'Backup Contents'**
  String get backup_contents_header;

  /// No description provided for @backup_info_warranties.
  ///
  /// In en, this message translates to:
  /// **'Warranties'**
  String get backup_info_warranties;

  /// No description provided for @backup_info_attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get backup_info_attachments;

  /// No description provided for @backup_info_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get backup_info_size;

  /// No description provided for @backup_info_app_version.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get backup_info_app_version;

  /// No description provided for @backup_info_backup_type.
  ///
  /// In en, this message translates to:
  /// **'Backup Type'**
  String get backup_info_backup_type;

  /// No description provided for @backup_type_automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get backup_type_automatic;

  /// No description provided for @backup_type_manual.
  ///
  /// In en, this message translates to:
  /// **'Manual backup'**
  String get backup_type_manual;

  /// No description provided for @backup_legacy_format.
  ///
  /// In en, this message translates to:
  /// **'Legacy backup format - item count unavailable'**
  String get backup_legacy_format;

  /// No description provided for @backup_warning_header.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get backup_warning_header;

  /// No description provided for @backup_before_restore_header.
  ///
  /// In en, this message translates to:
  /// **'Before You Restore'**
  String get backup_before_restore_header;

  /// No description provided for @backup_restore_warning.
  ///
  /// In en, this message translates to:
  /// **'Restoring this backup will replace all current data. Any items, attachments, or settings added after this backup was created will be lost. This action cannot be undone.'**
  String get backup_restore_warning;

  /// No description provided for @backup_restore_this_backup.
  ///
  /// In en, this message translates to:
  /// **'Restore This Backup'**
  String get backup_restore_this_backup;

  /// No description provided for @backup_badge_recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get backup_badge_recommended;

  /// No description provided for @backup_badge_empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get backup_badge_empty;

  /// No description provided for @settings_debug_premium_override.
  ///
  /// In en, this message translates to:
  /// **'Debug Premium Override'**
  String get settings_debug_premium_override;

  /// No description provided for @settings_debug_no_override.
  ///
  /// In en, this message translates to:
  /// **'No override (using real state)'**
  String get settings_debug_no_override;

  /// No description provided for @settings_debug_forced_premium.
  ///
  /// In en, this message translates to:
  /// **'Forced: Premium'**
  String get settings_debug_forced_premium;

  /// No description provided for @settings_debug_forced_free.
  ///
  /// In en, this message translates to:
  /// **'Forced: Free'**
  String get settings_debug_forced_free;

  /// No description provided for @settings_force_free.
  ///
  /// In en, this message translates to:
  /// **'Force Free'**
  String get settings_force_free;

  /// No description provided for @settings_real_state.
  ///
  /// In en, this message translates to:
  /// **'Real State'**
  String get settings_real_state;

  /// No description provided for @settings_force_premium.
  ///
  /// In en, this message translates to:
  /// **'Force Premium'**
  String get settings_force_premium;

  /// No description provided for @language_name_de.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get language_name_de;

  /// No description provided for @language_name_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_name_en;

  /// No description provided for @security_no_device_lock.
  ///
  /// In en, this message translates to:
  /// **'Please set up a PIN, password, or biometric lock on your device first.'**
  String get security_no_device_lock;

  /// No description provided for @security_lock_enabled.
  ///
  /// In en, this message translates to:
  /// **'App lock enabled - you\'ll need to authenticate when opening'**
  String get security_lock_enabled;

  /// No description provided for @security_lock_disabled.
  ///
  /// In en, this message translates to:
  /// **'App lock disabled'**
  String get security_lock_disabled;

  /// No description provided for @security_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security_screen_title;

  /// No description provided for @security_protect_with_lock.
  ///
  /// In en, this message translates to:
  /// **'Protect app with device lock'**
  String get security_protect_with_lock;

  /// No description provided for @security_requires_biometric.
  ///
  /// In en, this message translates to:
  /// **'Requires biometric or PIN to open the app'**
  String get security_requires_biometric;

  /// No description provided for @security_no_lock_configured.
  ///
  /// In en, this message translates to:
  /// **'Device has no secure lock configured'**
  String get security_no_lock_configured;

  /// No description provided for @security_enable_lock_info.
  ///
  /// In en, this message translates to:
  /// **'To use app lock, please enable a PIN, password, or biometric lock in your device settings.'**
  String get security_enable_lock_info;

  /// No description provided for @notifications_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_screen_title;

  /// No description provided for @notifications_enabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notifications_enabled;

  /// No description provided for @notifications_disabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notifications_disabled;

  /// No description provided for @notifications_local_info.
  ///
  /// In en, this message translates to:
  /// **'Notifications are scheduled locally on your device and work even when the app is closed.'**
  String get notifications_local_info;

  /// No description provided for @notifications_enable_reminders.
  ///
  /// In en, this message translates to:
  /// **'Enable warranty reminders'**
  String get notifications_enable_reminders;

  /// No description provided for @notifications_remind_before_expiry.
  ///
  /// In en, this message translates to:
  /// **'Get notified before warranties expire'**
  String get notifications_remind_before_expiry;

  /// No description provided for @notifications_reminder_schedule.
  ///
  /// In en, this message translates to:
  /// **'Reminder schedule (all at 09:00)'**
  String get notifications_reminder_schedule;

  /// No description provided for @notifications_30_days_before.
  ///
  /// In en, this message translates to:
  /// **'30 days before expiry'**
  String get notifications_30_days_before;

  /// No description provided for @notifications_7_days_before.
  ///
  /// In en, this message translates to:
  /// **'7 days before expiry'**
  String get notifications_7_days_before;

  /// No description provided for @notifications_on_expiry_day.
  ///
  /// In en, this message translates to:
  /// **'On expiry day'**
  String get notifications_on_expiry_day;

  /// No description provided for @notifications_system_permissions_note.
  ///
  /// In en, this message translates to:
  /// **'Note: System notification permissions must be enabled in your device settings for notifications to appear.'**
  String get notifications_system_permissions_note;

  /// No description provided for @trash_restore_all_title.
  ///
  /// In en, this message translates to:
  /// **'Restore All from Trash'**
  String get trash_restore_all_title;

  /// No description provided for @trash_restore_all_message.
  ///
  /// In en, this message translates to:
  /// **'Restore all {count} item(s) from trash?'**
  String trash_restore_all_message(int count);

  /// No description provided for @trash_restored_count.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} item(s) from trash'**
  String trash_restored_count(int count);

  /// No description provided for @trash_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Empty Trash'**
  String get trash_empty_title;

  /// No description provided for @trash_empty_message.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all {count} item(s) from trash?\n\nThis action cannot be undone.'**
  String trash_empty_message(int count);

  /// No description provided for @trash_empty_button.
  ///
  /// In en, this message translates to:
  /// **'Empty Trash'**
  String get trash_empty_button;

  /// No description provided for @trash_deleted_count.
  ///
  /// In en, this message translates to:
  /// **'Permanently deleted {count} item(s)'**
  String trash_deleted_count(int count);

  /// No description provided for @trash_restore_all.
  ///
  /// In en, this message translates to:
  /// **'Restore All'**
  String get trash_restore_all;

  /// No description provided for @trash_error_display.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String trash_error_display(String error);

  /// No description provided for @trash_items_kept_info.
  ///
  /// In en, this message translates to:
  /// **'Deleted items are kept for 180 days'**
  String get trash_items_kept_info;

  /// No description provided for @trash_auto_delete_info.
  ///
  /// In en, this message translates to:
  /// **'Items are kept for 180 days before automatic deletion'**
  String get trash_auto_delete_info;

  /// No description provided for @payments_error_loading.
  ///
  /// In en, this message translates to:
  /// **'Error loading payment methods: {error}'**
  String payments_error_loading(String error);

  /// No description provided for @item_could_not_open_file.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String item_could_not_open_file(String error);

  /// No description provided for @onboarding_restore_from_backup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get onboarding_restore_from_backup;

  /// No description provided for @onboarding_restore_from_file.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get onboarding_restore_from_file;

  /// No description provided for @safety_no_warranties_found.
  ///
  /// In en, this message translates to:
  /// **'No warranties found'**
  String get safety_no_warranties_found;

  /// No description provided for @warrantiesExpiringSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get warrantiesExpiringSoonTitle;

  /// No description provided for @warrantiesViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get warrantiesViewAll;

  /// No description provided for @backup_restore_warning_empty.
  ///
  /// In en, this message translates to:
  /// **'This backup contains 0 warranties. Restoring it will delete all your current warranties. Are you sure you want to restore this empty backup?'**
  String get backup_restore_warning_empty;

  /// No description provided for @backup_restore_warning_replace.
  ///
  /// In en, this message translates to:
  /// **'Your current app content will be replaced by this backup. This cannot be undone.'**
  String get backup_restore_warning_replace;

  /// No description provided for @receipt_validation_warning_title.
  ///
  /// In en, this message translates to:
  /// **'This document may be hard to read'**
  String get receipt_validation_warning_title;

  /// No description provided for @receipt_validation_warning_message.
  ///
  /// In en, this message translates to:
  /// **'If the document is not clearly readable, it may not be accepted for a warranty claim.'**
  String get receipt_validation_warning_message;

  /// No description provided for @receipt_validation_detected_info.
  ///
  /// In en, this message translates to:
  /// **'Detected Information:'**
  String get receipt_validation_detected_info;

  /// No description provided for @receipt_validation_words.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get receipt_validation_words;

  /// No description provided for @receipt_validation_lines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get receipt_validation_lines;

  /// No description provided for @receipt_validation_retake_photo.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get receipt_validation_retake_photo;

  /// No description provided for @receipt_validation_choose_another.
  ///
  /// In en, this message translates to:
  /// **'Choose Another File'**
  String get receipt_validation_choose_another;

  /// No description provided for @receipt_validation_use_anyway.
  ///
  /// In en, this message translates to:
  /// **'Use Anyway'**
  String get receipt_validation_use_anyway;

  /// No description provided for @receipt_validation_warning_insufficient_text.
  ///
  /// In en, this message translates to:
  /// **'This receipt has limited readable text. The photo quality may not be sufficient for warranty claims at some stores.'**
  String get receipt_validation_warning_insufficient_text;

  /// No description provided for @receipt_validation_warning_missing_date.
  ///
  /// In en, this message translates to:
  /// **'The purchase date could not be detected automatically. Make sure the date is clearly visible in the photo.'**
  String get receipt_validation_warning_missing_date;

  /// No description provided for @receipt_validation_warning_missing_merchant.
  ///
  /// In en, this message translates to:
  /// **'The merchant/store name could not be detected. Ensure the store name is visible in the photo.'**
  String get receipt_validation_warning_missing_merchant;

  /// No description provided for @receipt_validation_warning_poor_quality.
  ///
  /// In en, this message translates to:
  /// **'The receipt structure appears incomplete. Make sure the entire receipt is visible and in focus.'**
  String get receipt_validation_warning_poor_quality;

  /// No description provided for @receipt_validation_warning_too_small.
  ///
  /// In en, this message translates to:
  /// **'The receipt appears small or far away in the photo. It may be difficult for a store to read. Try taking a closer photo.'**
  String get receipt_validation_warning_too_small;

  /// No description provided for @receipt_validation_warning_blurry.
  ///
  /// In en, this message translates to:
  /// **'The photo appears slightly blurry. Check that the text is clearly readable before continuing.'**
  String get receipt_validation_warning_blurry;

  /// No description provided for @receipt_validation_warning_few_lines.
  ///
  /// In en, this message translates to:
  /// **'Only a few lines of text were detected. The receipt may be incomplete or partially cut off.'**
  String get receipt_validation_warning_few_lines;

  /// No description provided for @receipt_validation_warning_general.
  ///
  /// In en, this message translates to:
  /// **'The receipt quality may not be optimal for warranty purposes. Please review the photo carefully.'**
  String get receipt_validation_warning_general;

  /// No description provided for @receipt_validation_reject_title.
  ///
  /// In en, this message translates to:
  /// **'Document Not Readable'**
  String get receipt_validation_reject_title;

  /// No description provided for @receipt_validation_reject_message.
  ///
  /// In en, this message translates to:
  /// **'This image contains no readable text. Please take a clearer photo.'**
  String get receipt_validation_reject_message;

  /// No description provided for @receipt_validation_reject_reason.
  ///
  /// In en, this message translates to:
  /// **'Problem detected:'**
  String get receipt_validation_reject_reason;

  /// No description provided for @receipt_validation_reject_critically_insufficient.
  ///
  /// In en, this message translates to:
  /// **'Almost no text could be detected. The receipt is too blurry, dark, or cut off.'**
  String get receipt_validation_reject_critically_insufficient;

  /// No description provided for @receipt_validation_reject_too_small.
  ///
  /// In en, this message translates to:
  /// **'The receipt is too small or far away in the photo. Please take a closer photo where the receipt fills most of the frame.'**
  String get receipt_validation_reject_too_small;

  /// No description provided for @receipt_validation_reject_blurry.
  ///
  /// In en, this message translates to:
  /// **'The photo is too blurry to read. Hold the camera steady and ensure the receipt is in focus before taking the photo.'**
  String get receipt_validation_reject_blurry;

  /// No description provided for @receipt_validation_reject_few_lines.
  ///
  /// In en, this message translates to:
  /// **'Too few lines detected - the receipt appears incomplete. Make sure the entire receipt is visible in the photo.'**
  String get receipt_validation_reject_few_lines;

  /// No description provided for @receipt_validation_reject_general.
  ///
  /// In en, this message translates to:
  /// **'The receipt quality is too poor to be useful for warranty claims.'**
  String get receipt_validation_reject_general;

  /// No description provided for @receipt_validation_tips_title.
  ///
  /// In en, this message translates to:
  /// **'Tips for better receipt photos:'**
  String get receipt_validation_tips_title;

  /// No description provided for @receipt_validation_tip_lighting.
  ///
  /// In en, this message translates to:
  /// **'Ensure good lighting without glare or shadows'**
  String get receipt_validation_tip_lighting;

  /// No description provided for @receipt_validation_tip_focus.
  ///
  /// In en, this message translates to:
  /// **'Hold the camera steady and wait for the receipt to be in focus'**
  String get receipt_validation_tip_focus;

  /// No description provided for @receipt_validation_tip_flat.
  ///
  /// In en, this message translates to:
  /// **'Place the receipt on a flat surface'**
  String get receipt_validation_tip_flat;

  /// No description provided for @receipt_validation_tip_complete.
  ///
  /// In en, this message translates to:
  /// **'Capture the entire receipt from top to bottom'**
  String get receipt_validation_tip_complete;

  /// No description provided for @backup_recommended_contents.
  ///
  /// In en, this message translates to:
  /// **'✓ This backup is recommended based on its contents.'**
  String get backup_recommended_contents;

  /// No description provided for @trash_restore_from_trash.
  ///
  /// In en, this message translates to:
  /// **'Restore from Trash'**
  String get trash_restore_from_trash;

  /// No description provided for @backup_restore_backup_button.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get backup_restore_backup_button;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
