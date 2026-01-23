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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @pm_twint.
  ///
  /// In en, this message translates to:
  /// **'Twint'**
  String get pm_twint;

  /// No description provided for @pm_paypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get pm_paypal;

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

  /// No description provided for @pm_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get pm_other;

  /// No description provided for @snack_saved_prefix.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get snack_saved_prefix;

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
  /// **'Title'**
  String get items_name;

  /// No description provided for @items_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. iPhone 15 Pro'**
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

  /// No description provided for @status_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get status_today;

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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
