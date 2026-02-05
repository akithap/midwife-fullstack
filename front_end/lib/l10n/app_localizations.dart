import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

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
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rakawaranaya'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Midwifery Care\nat Your Fingertips'**
  String get appSubtitle;

  /// No description provided for @midwifeLogin.
  ///
  /// In en, this message translates to:
  /// **'Midwife Login'**
  String get midwifeLogin;

  /// No description provided for @motherLogin.
  ///
  /// In en, this message translates to:
  /// **'Mother Login'**
  String get motherLogin;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get sinhala;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed. Please check your credentials.'**
  String get loginFailed;

  /// No description provided for @midwifePortalLogin.
  ///
  /// In en, this message translates to:
  /// **'Midwife Portal Login'**
  String get midwifePortalLogin;

  /// No description provided for @motherPortalLogin.
  ///
  /// In en, this message translates to:
  /// **'Mother Portal Login'**
  String get motherPortalLogin;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @nicNumber.
  ///
  /// In en, this message translates to:
  /// **'NIC Number'**
  String get nicNumber;

  /// No description provided for @loginAsMidwife.
  ///
  /// In en, this message translates to:
  /// **'Login as Midwife'**
  String get loginAsMidwife;

  /// No description provided for @loginAsMother.
  ///
  /// In en, this message translates to:
  /// **'Login as Mother'**
  String get loginAsMother;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @newMessages.
  ///
  /// In en, this message translates to:
  /// **'New Messages'**
  String get newMessages;

  /// No description provided for @fromMidwife.
  ///
  /// In en, this message translates to:
  /// **'From Midwife'**
  String get fromMidwife;

  /// No description provided for @noNewMessages.
  ///
  /// In en, this message translates to:
  /// **'No new messages'**
  String get noNewMessages;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @upcomingAppointment.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointment'**
  String get upcomingAppointment;

  /// No description provided for @nextAppointmentOn.
  ///
  /// In en, this message translates to:
  /// **'You have your next appointment on'**
  String get nextAppointmentOn;

  /// No description provided for @dailyWisdom.
  ///
  /// In en, this message translates to:
  /// **'Daily Wisdom'**
  String get dailyWisdom;

  /// No description provided for @myHealth.
  ///
  /// In en, this message translates to:
  /// **'My Health'**
  String get myHealth;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @welcomeMother.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeMother(String name);

  /// No description provided for @trackPregnancyJourney.
  ///
  /// In en, this message translates to:
  /// **'Track your pregnancy journey.'**
  String get trackPregnancyJourney;

  /// No description provided for @myRecords.
  ///
  /// In en, this message translates to:
  /// **'My Records'**
  String get myRecords;

  /// No description provided for @myHealthFile.
  ///
  /// In en, this message translates to:
  /// **'My Health File'**
  String get myHealthFile;

  /// No description provided for @viewMedicalHistory.
  ///
  /// In en, this message translates to:
  /// **'View complete medical history'**
  String get viewMedicalHistory;

  /// No description provided for @upcomingMeetings.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Meetings'**
  String get upcomingMeetings;

  /// No description provided for @viewScheduledAppointments.
  ///
  /// In en, this message translates to:
  /// **'View scheduled appointments'**
  String get viewScheduledAppointments;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// No description provided for @contactMidwife.
  ///
  /// In en, this message translates to:
  /// **'Contact Midwife'**
  String get contactMidwife;

  /// No description provided for @failedToConnectMidwife.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to Midwife'**
  String get failedToConnectMidwife;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get confirmed;

  /// No description provided for @errorLoadingMeetings.
  ///
  /// In en, this message translates to:
  /// **'Error loading meetings'**
  String get errorLoadingMeetings;

  /// No description provided for @noUpcomingMeetings.
  ///
  /// In en, this message translates to:
  /// **'No upcoming meetings scheduled.'**
  String get noUpcomingMeetings;

  /// No description provided for @noScheduledMeetings.
  ///
  /// In en, this message translates to:
  /// **'No scheduled meetings found.'**
  String get noScheduledMeetings;

  /// No description provided for @healthFile.
  ///
  /// In en, this message translates to:
  /// **'Health File'**
  String get healthFile;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @ancLog.
  ///
  /// In en, this message translates to:
  /// **'ANC Log'**
  String get ancLog;

  /// No description provided for @pncLog.
  ///
  /// In en, this message translates to:
  /// **'PNC Log'**
  String get pncLog;

  /// No description provided for @charts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// No description provided for @noRegistrationRecord.
  ///
  /// In en, this message translates to:
  /// **'No Pregnancy Registration Record Found'**
  String get noRegistrationRecord;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @occupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupation;

  /// No description provided for @husband.
  ///
  /// In en, this message translates to:
  /// **'Husband'**
  String get husband;

  /// No description provided for @obstetricHistory.
  ///
  /// In en, this message translates to:
  /// **'Obstetric History'**
  String get obstetricHistory;

  /// No description provided for @gravidity.
  ///
  /// In en, this message translates to:
  /// **'Gravidity'**
  String get gravidity;

  /// No description provided for @parity.
  ///
  /// In en, this message translates to:
  /// **'Parity'**
  String get parity;

  /// No description provided for @livingChildren.
  ///
  /// In en, this message translates to:
  /// **'Living Children'**
  String get livingChildren;

  /// No description provided for @youngestChild.
  ///
  /// In en, this message translates to:
  /// **'Youngest Child'**
  String get youngestChild;

  /// No description provided for @currentPregnancy.
  ///
  /// In en, this message translates to:
  /// **'Current Pregnancy'**
  String get currentPregnancy;

  /// No description provided for @lrmp.
  ///
  /// In en, this message translates to:
  /// **'LMP'**
  String get lrmp;

  /// No description provided for @edd.
  ///
  /// In en, this message translates to:
  /// **'EDD'**
  String get edd;

  /// No description provided for @poaAtReg.
  ///
  /// In en, this message translates to:
  /// **'POA at Reg'**
  String get poaAtReg;

  /// No description provided for @bmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroup;

  /// No description provided for @riskFactors.
  ///
  /// In en, this message translates to:
  /// **'Risk Factors'**
  String get riskFactors;

  /// No description provided for @riskAge.
  ///
  /// In en, this message translates to:
  /// **'Age < 20 or > 35'**
  String get riskAge;

  /// No description provided for @riskGrandMultipara.
  ///
  /// In en, this message translates to:
  /// **'• Grand Multipara (>5)'**
  String get riskGrandMultipara;

  /// No description provided for @riskBirthInterval.
  ///
  /// In en, this message translates to:
  /// **'Birth Interval < 1yr'**
  String get riskBirthInterval;

  /// No description provided for @riskDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get riskDiabetes;

  /// No description provided for @riskMalaria.
  ///
  /// In en, this message translates to:
  /// **'Malaria'**
  String get riskMalaria;

  /// No description provided for @riskHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart Disease'**
  String get riskHeart;

  /// No description provided for @riskRenal.
  ///
  /// In en, this message translates to:
  /// **'Renal Disease'**
  String get riskRenal;

  /// No description provided for @riskOther.
  ///
  /// In en, this message translates to:
  /// **'• Other'**
  String get riskOther;

  /// No description provided for @noneRecorded.
  ///
  /// In en, this message translates to:
  /// **'None Recorded'**
  String get noneRecorded;

  /// No description provided for @noAncVisits.
  ///
  /// In en, this message translates to:
  /// **'No ANC Visits Recorded Yet'**
  String get noAncVisits;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @poa.
  ///
  /// In en, this message translates to:
  /// **'POA'**
  String get poa;

  /// No description provided for @bp.
  ///
  /// In en, this message translates to:
  /// **'BP'**
  String get bp;

  /// No description provided for @fundalHeight.
  ///
  /// In en, this message translates to:
  /// **'Fundal H'**
  String get fundalHeight;

  /// No description provided for @lie.
  ///
  /// In en, this message translates to:
  /// **'Lie'**
  String get lie;

  /// No description provided for @fhs.
  ///
  /// In en, this message translates to:
  /// **'FHS'**
  String get fhs;

  /// No description provided for @urine.
  ///
  /// In en, this message translates to:
  /// **'Urine'**
  String get urine;

  /// No description provided for @edema.
  ///
  /// In en, this message translates to:
  /// **'Edema'**
  String get edema;

  /// No description provided for @noPncVisits.
  ///
  /// In en, this message translates to:
  /// **'No PNC Visits Recorded Yet'**
  String get noPncVisits;

  /// No description provided for @temp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get temp;

  /// No description provided for @infection.
  ///
  /// In en, this message translates to:
  /// **'Infection'**
  String get infection;

  /// No description provided for @lochia.
  ///
  /// In en, this message translates to:
  /// **'Lochia'**
  String get lochia;

  /// No description provided for @babyColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get babyColor;

  /// No description provided for @cord.
  ///
  /// In en, this message translates to:
  /// **'Cord'**
  String get cord;

  /// No description provided for @feeding.
  ///
  /// In en, this message translates to:
  /// **'Feeding'**
  String get feeding;

  /// No description provided for @hospitalRef.
  ///
  /// In en, this message translates to:
  /// **'Hospital Ref'**
  String get hospitalRef;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @weightGainChartComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Weight Gain Chart Coming Soon'**
  String get weightGainChartComingSoon;

  /// No description provided for @sayHello.
  ///
  /// In en, this message translates to:
  /// **'Say Hello! 👋'**
  String get sayHello;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSend;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @minSixChars.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters'**
  String get minSixChars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'UPDATE PASSWORD'**
  String get updatePassword;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password Changed Successfully!'**
  String get passwordChangedSuccess;

  /// No description provided for @incorrectOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Failed: Incorrect Old Password'**
  String get incorrectOldPassword;

  /// No description provided for @myPregnancyRecords.
  ///
  /// In en, this message translates to:
  /// **'My Pregnancy Records'**
  String get myPregnancyRecords;

  /// No description provided for @noRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No records found.'**
  String get noRecordsFound;

  /// No description provided for @recordNumber.
  ///
  /// In en, this message translates to:
  /// **'Record #'**
  String get recordNumber;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @myAntenatalPlan.
  ///
  /// In en, this message translates to:
  /// **'My Antenatal Plan'**
  String get myAntenatalPlan;

  /// No description provided for @noPlanFound.
  ///
  /// In en, this message translates to:
  /// **'No plan found.'**
  String get noPlanFound;

  /// No description provided for @nextClinicVisit.
  ///
  /// In en, this message translates to:
  /// **'Next Clinic Visit'**
  String get nextClinicVisit;

  /// No description provided for @notScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not Scheduled'**
  String get notScheduled;

  /// No description provided for @classesAttended.
  ///
  /// In en, this message translates to:
  /// **'Classes Attended'**
  String get classesAttended;

  /// No description provided for @firstTrimester.
  ///
  /// In en, this message translates to:
  /// **'1st Trimester'**
  String get firstTrimester;

  /// No description provided for @secondTrimester.
  ///
  /// In en, this message translates to:
  /// **'2nd Trimester'**
  String get secondTrimester;

  /// No description provided for @thirdTrimester.
  ///
  /// In en, this message translates to:
  /// **'3rd Trimester'**
  String get thirdTrimester;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @mohOffice.
  ///
  /// In en, this message translates to:
  /// **'MOH Office'**
  String get mohOffice;

  /// No description provided for @phmPhone.
  ///
  /// In en, this message translates to:
  /// **'PHM Phone'**
  String get phmPhone;

  /// No description provided for @notYetAttended.
  ///
  /// In en, this message translates to:
  /// **'Not yet attended'**
  String get notYetAttended;

  /// No description provided for @myDeliveryRecords.
  ///
  /// In en, this message translates to:
  /// **'My Delivery Records'**
  String get myDeliveryRecords;

  /// No description provided for @deliveryNumber.
  ///
  /// In en, this message translates to:
  /// **'Delivery #'**
  String get deliveryNumber;

  /// No description provided for @deliveryMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get deliveryMode;

  /// No description provided for @birthWeight.
  ///
  /// In en, this message translates to:
  /// **'Birth Weight'**
  String get birthWeight;

  /// No description provided for @abnormalities.
  ///
  /// In en, this message translates to:
  /// **'Abnormalities'**
  String get abnormalities;

  /// No description provided for @dischargeDate.
  ///
  /// In en, this message translates to:
  /// **'Discharge Date'**
  String get dischargeDate;

  /// No description provided for @specialNotes.
  ///
  /// In en, this message translates to:
  /// **'Special Notes'**
  String get specialNotes;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @midwifeStaff.
  ///
  /// In en, this message translates to:
  /// **'Midwife Staff'**
  String get midwifeStaff;

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// No description provided for @visitsDone.
  ///
  /// In en, this message translates to:
  /// **'Visits Done'**
  String get visitsDone;

  /// No description provided for @keepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up!'**
  String get keepItUp;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get upNext;

  /// No description provided for @nextVisit.
  ///
  /// In en, this message translates to:
  /// **'Next Visit'**
  String get nextVisit;

  /// No description provided for @noUpcomingVisits.
  ///
  /// In en, this message translates to:
  /// **'No upcoming visits'**
  String get noUpcomingVisits;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @riskLevels.
  ///
  /// In en, this message translates to:
  /// **'Risk Levels'**
  String get riskLevels;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @dailyWisdomFor.
  ///
  /// In en, this message translates to:
  /// **'Daily Wisdom for {name}'**
  String dailyWisdomFor(String name);

  /// No description provided for @enjoyYourDay.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your day, {name}!'**
  String enjoyYourDay(String name);

  /// No description provided for @myMidwife.
  ///
  /// In en, this message translates to:
  /// **'My Midwife'**
  String get myMidwife;

  /// No description provided for @newMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'New Message from Midwife'**
  String get newMessageTitle;

  /// No description provided for @newMessageBody.
  ///
  /// In en, this message translates to:
  /// **'You have {count} unread messages.'**
  String newMessageBody(int count);

  /// No description provided for @risk5thPreg.
  ///
  /// In en, this message translates to:
  /// **'5th Pregnancy or more'**
  String get risk5thPreg;

  /// No description provided for @riskHistoryPPH.
  ///
  /// In en, this message translates to:
  /// **'History of PPH'**
  String get riskHistoryPPH;

  /// No description provided for @upcomingApptTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointment'**
  String get upcomingApptTitle;

  /// No description provided for @upcomingApptBody.
  ///
  /// In en, this message translates to:
  /// **'You have your next appointment on {date}'**
  String upcomingApptBody(String date);

  /// No description provided for @regFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration (H 512)'**
  String get regFormTitle;

  /// No description provided for @editRegFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit H 512 Record'**
  String get editRegFormTitle;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Registration & Admin'**
  String get step1Title;

  /// No description provided for @regDate.
  ///
  /// In en, this message translates to:
  /// **'Reg Date'**
  String get regDate;

  /// No description provided for @regNo.
  ///
  /// In en, this message translates to:
  /// **'Reg No'**
  String get regNo;

  /// No description provided for @familyRegNo.
  ///
  /// In en, this message translates to:
  /// **'Family Reg No'**
  String get familyRegNo;

  /// No description provided for @loadingMOH.
  ///
  /// In en, this message translates to:
  /// **'Loading MOH Offices...'**
  String get loadingMOH;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @healthDistrict.
  ///
  /// In en, this message translates to:
  /// **'Health District'**
  String get healthDistrict;

  /// No description provided for @mohArea.
  ///
  /// In en, this message translates to:
  /// **'MOH Area'**
  String get mohArea;

  /// No description provided for @phiArea.
  ///
  /// In en, this message translates to:
  /// **'PHI Area'**
  String get phiArea;

  /// No description provided for @gnDivision.
  ///
  /// In en, this message translates to:
  /// **'Gramaniladhari Division'**
  String get gnDivision;

  /// No description provided for @distanceToClinic.
  ///
  /// In en, this message translates to:
  /// **'Distance to Clinic (km)'**
  String get distanceToClinic;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Personal Info (Mother & Husband)'**
  String get step2Title;

  /// No description provided for @motherLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother:'**
  String get motherLabel;

  /// No description provided for @husbandLabel.
  ///
  /// In en, this message translates to:
  /// **'Husband:'**
  String get husbandLabel;

  /// No description provided for @educationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education Level'**
  String get educationLevel;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Vitals & Medical History'**
  String get step3Title;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @bmiAuto.
  ///
  /// In en, this message translates to:
  /// **'BMI (Auto)'**
  String get bmiAuto;

  /// No description provided for @consanguineousMarriage.
  ///
  /// In en, this message translates to:
  /// **'Consanguineous Marriage?'**
  String get consanguineousMarriage;

  /// No description provided for @rubellaImmunization.
  ///
  /// In en, this message translates to:
  /// **'Rubella Immunization?'**
  String get rubellaImmunization;

  /// No description provided for @prePregnancyScreening.
  ///
  /// In en, this message translates to:
  /// **'Pre-Pregnancy Screening?'**
  String get prePregnancyScreening;

  /// No description provided for @folicAcidTaken.
  ///
  /// In en, this message translates to:
  /// **'Folic Acid Taken?'**
  String get folicAcidTaken;

  /// No description provided for @subfertilityHistory.
  ///
  /// In en, this message translates to:
  /// **'History of Subfertility?'**
  String get subfertilityHistory;

  /// No description provided for @step4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Family & Obstetric History'**
  String get step4Title;

  /// No description provided for @familyHistory.
  ///
  /// In en, this message translates to:
  /// **'Family History'**
  String get familyHistory;

  /// No description provided for @hypertension.
  ///
  /// In en, this message translates to:
  /// **'Hypertension'**
  String get hypertension;

  /// No description provided for @twins.
  ///
  /// In en, this message translates to:
  /// **'Twins'**
  String get twins;

  /// No description provided for @pastPregnancies.
  ///
  /// In en, this message translates to:
  /// **'Past Pregnancies'**
  String get pastPregnancies;

  /// No description provided for @addPastPregnancy.
  ///
  /// In en, this message translates to:
  /// **'Add Past Pregnancy ({order})'**
  String addPastPregnancy(String order);

  /// No description provided for @noPastPregnancies.
  ///
  /// In en, this message translates to:
  /// **'No past pregnancies added.'**
  String get noPastPregnancies;

  /// No description provided for @outcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get outcome;

  /// No description provided for @modeOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Mode of Delivery'**
  String get modeOfDelivery;

  /// No description provided for @ageIfAlive.
  ///
  /// In en, this message translates to:
  /// **'Age if Alive'**
  String get ageIfAlive;

  /// No description provided for @liveBirth.
  ///
  /// In en, this message translates to:
  /// **'Live Birth'**
  String get liveBirth;

  /// No description provided for @stillBirth.
  ///
  /// In en, this message translates to:
  /// **'Still Birth'**
  String get stillBirth;

  /// No description provided for @abortion.
  ///
  /// In en, this message translates to:
  /// **'Abortion'**
  String get abortion;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @lscs.
  ///
  /// In en, this message translates to:
  /// **'LSCS'**
  String get lscs;

  /// No description provided for @forceps.
  ///
  /// In en, this message translates to:
  /// **'Forceps'**
  String get forceps;

  /// No description provided for @vacuum.
  ///
  /// In en, this message translates to:
  /// **'Vacuum'**
  String get vacuum;

  /// No description provided for @step5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Dating (LMP & EDD)'**
  String get step5Title;

  /// No description provided for @usCorrectedEdd.
  ///
  /// In en, this message translates to:
  /// **'US Corrected EDD'**
  String get usCorrectedEdd;

  /// No description provided for @step6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Risk Assessment'**
  String get step6Title;

  /// No description provided for @recordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Record Updated Successfully!'**
  String get recordUpdated;

  /// No description provided for @poaReg.
  ///
  /// In en, this message translates to:
  /// **'POA at Registration'**
  String get poaReg;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @birthWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Birth Weight (kg)'**
  String get birthWeightKg;

  /// No description provided for @diabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get diabetes;

  /// No description provided for @ancTitle.
  ///
  /// In en, this message translates to:
  /// **'ANC Visit Record'**
  String get ancTitle;

  /// No description provided for @ancSaved.
  ///
  /// In en, this message translates to:
  /// **'ANC Record Saved Successfully!'**
  String get ancSaved;

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSaving(String error);

  /// No description provided for @fillVitals.
  ///
  /// In en, this message translates to:
  /// **'Please fill mandatory vitals (Weight, BP)'**
  String get fillVitals;

  /// No description provided for @clinicalVitals.
  ///
  /// In en, this message translates to:
  /// **'Clinical Vitals'**
  String get clinicalVitals;

  /// No description provided for @healthEducation.
  ///
  /// In en, this message translates to:
  /// **'Health Education & Counsel'**
  String get healthEducation;

  /// No description provided for @poaWeeks.
  ///
  /// In en, this message translates to:
  /// **'POA (Weeks)'**
  String get poaWeeks;

  /// No description provided for @fundalHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Fundal Height (cm)'**
  String get fundalHeightCm;

  /// No description provided for @bpSystolic.
  ///
  /// In en, this message translates to:
  /// **'BP Systolic'**
  String get bpSystolic;

  /// No description provided for @bpDiastolic.
  ///
  /// In en, this message translates to:
  /// **'BP Diastolic'**
  String get bpDiastolic;

  /// No description provided for @pallor.
  ///
  /// In en, this message translates to:
  /// **'Pallor'**
  String get pallor;

  /// No description provided for @oedema.
  ///
  /// In en, this message translates to:
  /// **'Oedema'**
  String get oedema;

  /// No description provided for @fetalLie.
  ///
  /// In en, this message translates to:
  /// **'Fetal Lie'**
  String get fetalLie;

  /// No description provided for @fetalHeart.
  ///
  /// In en, this message translates to:
  /// **'Fetal Heart Sound'**
  String get fetalHeart;

  /// No description provided for @fetalMove.
  ///
  /// In en, this message translates to:
  /// **'Fetal Movement'**
  String get fetalMove;

  /// No description provided for @urineTest.
  ///
  /// In en, this message translates to:
  /// **'Urine Test'**
  String get urineTest;

  /// No description provided for @urineSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get urineSugar;

  /// No description provided for @urineAlbumin.
  ///
  /// In en, this message translates to:
  /// **'Albumin'**
  String get urineAlbumin;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @cephalic.
  ///
  /// In en, this message translates to:
  /// **'Cephalic'**
  String get cephalic;

  /// No description provided for @breech.
  ///
  /// In en, this message translates to:
  /// **'Breech'**
  String get breech;

  /// No description provided for @transverse.
  ///
  /// In en, this message translates to:
  /// **'Transverse'**
  String get transverse;

  /// No description provided for @oblique.
  ///
  /// In en, this message translates to:
  /// **'Oblique'**
  String get oblique;

  /// No description provided for @notHeard.
  ///
  /// In en, this message translates to:
  /// **'Not Heard'**
  String get notHeard;

  /// No description provided for @reduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get reduced;

  /// No description provided for @neg.
  ///
  /// In en, this message translates to:
  /// **'Neg'**
  String get neg;

  /// No description provided for @counselIron.
  ///
  /// In en, this message translates to:
  /// **'Given Iron/Calcium/Vitamins?'**
  String get counselIron;

  /// No description provided for @counselNutri.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Advised'**
  String get counselNutri;

  /// No description provided for @counselDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger Signs Explained'**
  String get counselDanger;

  /// No description provided for @counselFamily.
  ///
  /// In en, this message translates to:
  /// **'Family Planning Discussed'**
  String get counselFamily;

  /// No description provided for @counselBreast.
  ///
  /// In en, this message translates to:
  /// **'Breastfeeding Advised'**
  String get counselBreast;

  /// No description provided for @counselDeliv.
  ///
  /// In en, this message translates to:
  /// **'Delivery Plan Discussed'**
  String get counselDeliv;

  /// No description provided for @counselEmerg.
  ///
  /// In en, this message translates to:
  /// **'Emergency Prep Discussed'**
  String get counselEmerg;

  /// No description provided for @counselPost.
  ///
  /// In en, this message translates to:
  /// **'Postnatal Care Advised (Last Trimester)'**
  String get counselPost;

  /// No description provided for @saveRecord.
  ///
  /// In en, this message translates to:
  /// **'Save Record'**
  String get saveRecord;

  /// No description provided for @pncTitle.
  ///
  /// In en, this message translates to:
  /// **'PNC Visit Record'**
  String get pncTitle;

  /// No description provided for @pncSaved.
  ///
  /// In en, this message translates to:
  /// **'PNC Record Saved Successfully!'**
  String get pncSaved;

  /// No description provided for @motherCondition.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s Condition'**
  String get motherCondition;

  /// No description provided for @babyCondition.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s Condition'**
  String get babyCondition;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature (°C)'**
  String get temperature;

  /// No description provided for @breastCondition.
  ///
  /// In en, this message translates to:
  /// **'Breast Condition'**
  String get breastCondition;

  /// No description provided for @uterusInvolution.
  ///
  /// In en, this message translates to:
  /// **'Uterus Involution'**
  String get uterusInvolution;

  /// No description provided for @lochiaCharacter.
  ///
  /// In en, this message translates to:
  /// **'Lochia Character'**
  String get lochiaCharacter;

  /// No description provided for @lochiaSmell.
  ///
  /// In en, this message translates to:
  /// **'Lochia Smell'**
  String get lochiaSmell;

  /// No description provided for @perineumInfection.
  ///
  /// In en, this message translates to:
  /// **'Perineum Infection (Gaping)?'**
  String get perineumInfection;

  /// No description provided for @fissureInfection.
  ///
  /// In en, this message translates to:
  /// **'C-Section/Episiotomy Infection?'**
  String get fissureInfection;

  /// No description provided for @vitaminA.
  ///
  /// In en, this message translates to:
  /// **'Vitamin A Mega Dose Given?'**
  String get vitaminA;

  /// No description provided for @familyPlanning.
  ///
  /// In en, this message translates to:
  /// **'Family Planning Method'**
  String get familyPlanning;

  /// No description provided for @referHospital.
  ///
  /// In en, this message translates to:
  /// **'Refer to Hospital?'**
  String get referHospital;

  /// No description provided for @babyWeight.
  ///
  /// In en, this message translates to:
  /// **'Baby Weight (kg)'**
  String get babyWeight;

  /// No description provided for @cordStatus.
  ///
  /// In en, this message translates to:
  /// **'Cord Status'**
  String get cordStatus;

  /// No description provided for @breastfeeding.
  ///
  /// In en, this message translates to:
  /// **'Breastfeeding'**
  String get breastfeeding;

  /// No description provided for @stoolPassage.
  ///
  /// In en, this message translates to:
  /// **'Stool Passage'**
  String get stoolPassage;

  /// No description provided for @cracked.
  ///
  /// In en, this message translates to:
  /// **'Cracked'**
  String get cracked;

  /// No description provided for @engorged.
  ///
  /// In en, this message translates to:
  /// **'Engorged'**
  String get engorged;

  /// No description provided for @infected.
  ///
  /// In en, this message translates to:
  /// **'Infected'**
  String get infected;

  /// No description provided for @contracted.
  ///
  /// In en, this message translates to:
  /// **'Contracted'**
  String get contracted;

  /// No description provided for @boggy.
  ///
  /// In en, this message translates to:
  /// **'Boggy'**
  String get boggy;

  /// No description provided for @subInvolution.
  ///
  /// In en, this message translates to:
  /// **'Sub-involution'**
  String get subInvolution;

  /// No description provided for @measurable.
  ///
  /// In en, this message translates to:
  /// **'Measurable'**
  String get measurable;

  /// No description provided for @excessive.
  ///
  /// In en, this message translates to:
  /// **'Excessive'**
  String get excessive;

  /// No description provided for @foul.
  ///
  /// In en, this message translates to:
  /// **'Foul'**
  String get foul;

  /// No description provided for @pale.
  ///
  /// In en, this message translates to:
  /// **'Pale'**
  String get pale;

  /// No description provided for @icteric.
  ///
  /// In en, this message translates to:
  /// **'Icteric (Yellow)'**
  String get icteric;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @bleeding.
  ///
  /// In en, this message translates to:
  /// **'Bleeding'**
  String get bleeding;

  /// No description provided for @pus.
  ///
  /// In en, this message translates to:
  /// **'Infected/Pus'**
  String get pus;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @goodSucking.
  ///
  /// In en, this message translates to:
  /// **'Good Sucking'**
  String get goodSucking;

  /// No description provided for @poorSucking.
  ///
  /// In en, this message translates to:
  /// **'Poor Sucking'**
  String get poorSucking;

  /// No description provided for @notEstablishing.
  ///
  /// In en, this message translates to:
  /// **'Not Establishing'**
  String get notEstablishing;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @notPassed.
  ///
  /// In en, this message translates to:
  /// **'Not Passed'**
  String get notPassed;

  /// No description provided for @delayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get delayed;

  /// No description provided for @pill.
  ///
  /// In en, this message translates to:
  /// **'Pill'**
  String get pill;

  /// No description provided for @implant.
  ///
  /// In en, this message translates to:
  /// **'Implant'**
  String get implant;

  /// No description provided for @lrt.
  ///
  /// In en, this message translates to:
  /// **'LRT'**
  String get lrt;

  /// No description provided for @injection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get injection;

  /// No description provided for @condom.
  ///
  /// In en, this message translates to:
  /// **'Condom'**
  String get condom;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get pink;

  /// No description provided for @white.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get white;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @clinicallyAnemic.
  ///
  /// In en, this message translates to:
  /// **'Clinically Anemic'**
  String get clinicallyAnemic;

  /// No description provided for @riskManagement.
  ///
  /// In en, this message translates to:
  /// **'Risk Management'**
  String get riskManagement;

  /// No description provided for @priorityActions.
  ///
  /// In en, this message translates to:
  /// **'Priority Actions'**
  String get priorityActions;

  /// No description provided for @riskGroups.
  ///
  /// In en, this message translates to:
  /// **'Risk Groups'**
  String get riskGroups;

  /// No description provided for @sensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get sensitive;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @silentRiskDetector.
  ///
  /// In en, this message translates to:
  /// **'Silent Risk Detector (>30 Days Overdue)'**
  String get silentRiskDetector;

  /// No description provided for @noDefaulters.
  ///
  /// In en, this message translates to:
  /// **'No defaulters found!'**
  String get noDefaulters;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @overdueDays.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {days} Days\nLast Seen: {date}'**
  String overdueDays(Object days, Object date);

  /// No description provided for @upcomingDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Deliveries (Next 30 Days)'**
  String get upcomingDeliveries;

  /// No description provided for @noDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No upcoming deliveries.'**
  String get noDeliveries;

  /// No description provided for @eddHighRisk.
  ///
  /// In en, this message translates to:
  /// **'EDD: {date}\nRisk: High'**
  String eddHighRisk(Object date);

  /// No description provided for @filterByRisk.
  ///
  /// In en, this message translates to:
  /// **'Filter by Risk Factor'**
  String get filterByRisk;

  /// No description provided for @noMothersFound.
  ///
  /// In en, this message translates to:
  /// **'No mothers found'**
  String get noMothersFound;

  /// No description provided for @highRiskCases.
  ///
  /// In en, this message translates to:
  /// **'High Risk Cases'**
  String get highRiskCases;

  /// No description provided for @diabetesWatch.
  ///
  /// In en, this message translates to:
  /// **'Diabetes Watch'**
  String get diabetesWatch;

  /// No description provided for @midwifeMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Midwife Field Map'**
  String get midwifeMapTitle;

  /// No description provided for @refreshMap.
  ///
  /// In en, this message translates to:
  /// **'Refresh Map Data'**
  String get refreshMap;

  /// No description provided for @searchMother.
  ///
  /// In en, this message translates to:
  /// **'Search mother by name...'**
  String get searchMother;

  /// No description provided for @todaysVisits.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Visits'**
  String get todaysVisits;

  /// No description provided for @eligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible'**
  String get eligible;

  /// No description provided for @postnatal.
  ///
  /// In en, this message translates to:
  /// **'Postnatal'**
  String get postnatal;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @unmappedWarning.
  ///
  /// In en, this message translates to:
  /// **'{count} mothers hidden (no location data)'**
  String unmappedWarning(int count);

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @riskLevel.
  ///
  /// In en, this message translates to:
  /// **'Risk Level'**
  String get riskLevel;

  /// No description provided for @viewHealthFile.
  ///
  /// In en, this message translates to:
  /// **'View Health File'**
  String get viewHealthFile;

  /// No description provided for @dailyVisits.
  ///
  /// In en, this message translates to:
  /// **'Daily Visits'**
  String get dailyVisits;

  /// No description provided for @noVisitsToday.
  ///
  /// In en, this message translates to:
  /// **'No visits scheduled for today!'**
  String get noVisitsToday;

  /// No description provided for @visitCompleted.
  ///
  /// In en, this message translates to:
  /// **'Visit Marked as Completed!'**
  String get visitCompleted;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completedStatus;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'MARK AS COMPLETED'**
  String get markAsCompleted;

  /// No description provided for @selectMother.
  ///
  /// In en, this message translates to:
  /// **'Select Mother'**
  String get selectMother;

  /// No description provided for @searchByNameOrNic.
  ///
  /// In en, this message translates to:
  /// **'Search by Name or NIC'**
  String get searchByNameOrNic;

  /// No description provided for @registeredMothers.
  ///
  /// In en, this message translates to:
  /// **'Registered Mothers'**
  String get registeredMothers;

  /// No description provided for @midwifeProfile.
  ///
  /// In en, this message translates to:
  /// **'Midwife Profile'**
  String get midwifeProfile;

  /// No description provided for @allHighRisk.
  ///
  /// In en, this message translates to:
  /// **'All High Risk'**
  String get allHighRisk;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @pregnancyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Registered Successfully!'**
  String get pregnancyRegistered;

  /// No description provided for @registerNewMother.
  ///
  /// In en, this message translates to:
  /// **'Register New Mother'**
  String get registerNewMother;

  /// No description provided for @editMotherDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Mother Details'**
  String get editMotherDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @contactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get contactNumber;

  /// No description provided for @temporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary Password'**
  String get temporaryPassword;

  /// No description provided for @registerMother.
  ///
  /// In en, this message translates to:
  /// **'Register Mother'**
  String get registerMother;

  /// No description provided for @updateDetails.
  ///
  /// In en, this message translates to:
  /// **'Update Details'**
  String get updateDetails;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services disabled.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permanently denied.'**
  String get locationPermanentlyDenied;

  /// No description provided for @pinCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Pin Current Location'**
  String get pinCurrentLocation;

  /// No description provided for @errorGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location.'**
  String get errorGettingLocation;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get gettingLocation;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @motherRegistered.
  ///
  /// In en, this message translates to:
  /// **'Mother registered!'**
  String get motherRegistered;

  /// No description provided for @motherUpdated.
  ///
  /// In en, this message translates to:
  /// **'Mother updated!'**
  String get motherUpdated;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed. Please check inputs.'**
  String get operationFailed;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nicRequired.
  ///
  /// In en, this message translates to:
  /// **'NIC is required'**
  String get nicRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @carePlan.
  ///
  /// In en, this message translates to:
  /// **'Care Plan'**
  String get carePlan;

  /// No description provided for @startPregnancyPlan.
  ///
  /// In en, this message translates to:
  /// **'Start Pregnancy Plan'**
  String get startPregnancyPlan;

  /// No description provided for @reportDelivery.
  ///
  /// In en, this message translates to:
  /// **'Report Delivery (Start PNC)'**
  String get reportDelivery;

  /// No description provided for @careTimeline.
  ///
  /// In en, this message translates to:
  /// **'Care Timeline'**
  String get careTimeline;

  /// No description provided for @addVisit.
  ///
  /// In en, this message translates to:
  /// **'Add Visit'**
  String get addVisit;

  /// No description provided for @deleteVisitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Visit?'**
  String get deleteVisitTitle;

  /// No description provided for @deleteVisitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this visit?'**
  String get deleteVisitConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @editVisitDate.
  ///
  /// In en, this message translates to:
  /// **'Edit Visit Date'**
  String get editVisitDate;

  /// No description provided for @ideal.
  ///
  /// In en, this message translates to:
  /// **'IDEAL'**
  String get ideal;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'SELECT DATE'**
  String get selectDate;

  /// No description provided for @enterDate.
  ///
  /// In en, this message translates to:
  /// **'Enter Date'**
  String get enterDate;

  /// No description provided for @lateVisitWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: Late Visit ⚠️'**
  String get lateVisitWarning;

  /// No description provided for @lateVisitMessage.
  ///
  /// In en, this message translates to:
  /// **'This date is more than 2 weeks after the recommended Week {week} target.\n\nProceed anyway?'**
  String lateVisitMessage(String week);

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @addExtraVisit.
  ///
  /// In en, this message translates to:
  /// **'Add Extra Visit'**
  String get addExtraVisit;

  /// No description provided for @homeVisit.
  ///
  /// In en, this message translates to:
  /// **'Home Visit'**
  String get homeVisit;

  /// No description provided for @clinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get clinic;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @notesReason.
  ///
  /// In en, this message translates to:
  /// **'Notes / Reason'**
  String get notesReason;

  /// No description provided for @dateMismatch.
  ///
  /// In en, this message translates to:
  /// **'Date Mismatch 📅'**
  String get dateMismatch;

  /// No description provided for @dateMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'This visit is scheduled for {scheduledDate}, but today is {today}.\n\nVisits can only be completed on the scheduled day.'**
  String dateMismatchBody(String scheduledDate, String today);

  /// No description provided for @rescheduleComplete.
  ///
  /// In en, this message translates to:
  /// **'Reschedule to Today & Complete'**
  String get rescheduleComplete;

  /// No description provided for @pregnancyRegistrationComplete.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Registration Complete!'**
  String get pregnancyRegistrationComplete;

  /// No description provided for @deliveryReported.
  ///
  /// In en, this message translates to:
  /// **'Delivery Reported! PNC Schedule Generated.'**
  String get deliveryReported;

  /// No description provided for @failedReportDelivery.
  ///
  /// In en, this message translates to:
  /// **'Failed to report delivery.'**
  String get failedReportDelivery;

  /// No description provided for @pregnant.
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get pregnant;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @scheduledVisit.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Visit'**
  String get scheduledVisit;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get riskHigh;

  /// No description provided for @riskModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get riskModerate;

  /// No description provided for @riskLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get riskLow;

  /// No description provided for @routineCheckup.
  ///
  /// In en, this message translates to:
  /// **'Routine Checkup'**
  String get routineCheckup;

  /// No description provided for @pnc.
  ///
  /// In en, this message translates to:
  /// **'PNC'**
  String get pnc;

  /// No description provided for @anc.
  ///
  /// In en, this message translates to:
  /// **'ANC'**
  String get anc;

  /// No description provided for @ancVisit.
  ///
  /// In en, this message translates to:
  /// **'ANC Visit'**
  String get ancVisit;

  /// No description provided for @pncVisitDay.
  ///
  /// In en, this message translates to:
  /// **'PNC Visit {visit} (Day {day})'**
  String pncVisitDay(String visit, String day);

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @itemsPending.
  ///
  /// In en, this message translates to:
  /// **'{count} items pending'**
  String itemsPending(int count);

  /// No description provided for @allRecordsSynced.
  ///
  /// In en, this message translates to:
  /// **'All records synced!'**
  String get allRecordsSynced;

  /// No description provided for @genericMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get genericMother;
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
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
