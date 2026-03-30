import 'package:flutter/widgets.dart';

class AppLanguage {
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('mr'));

  static void changeLocale(Locale locale) {
    localeNotifier.value = locale;
  }
}

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('mr'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Revolve Agro',
      'language': 'Language',
      'english': 'English',
      'marathi': 'Marathi',
      'grow_smarter_title': 'Grow smarter,\nharvest stronger.',
      'grow_smarter_subtitle':
          'Discover crop care products, place orders faster, and manage your farm purchases in one polished flow.',
      'trusted_products': 'Trusted Products',
      'easy_checkout': 'Easy Checkout',
      'continue': 'Continue',
      'browse_products_directly': 'Browse Products Directly',
      'choose_experience_title': 'Choose your\nexperience',
      'choose_experience_subtitle':
          'Farmers and admins get tailored dashboards, faster actions, and a smoother purchase journey.',
      'user_login': 'User Login',
      'admin_login': 'Admin Login',
      'user_login_subtitle': 'Browse products, manage your cart, and checkout with delivery details.',
      'admin_login_subtitle': 'Track incoming orders, customer addresses, and overall order activity.',
      'multilingual_support':
          'Available for multilingual agriculture support and faster team coordination.',
      'admin_workspace': 'Admin Workspace',
      'farmer_workspace': 'Farmer Workspace',
      'welcome_back': 'Welcome back',
      'create_your_account': 'Create your account',
      'login': 'Login',
      'sign_up': 'Sign Up',
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'email_address': 'Email Address',
      'password': 'Password',
      'login_hint': 'Use your registered email and password to continue.',
      'signup_hint': 'Your account will be used for orders, address saving, and faster checkout.',
      'continue_to_dashboard': 'Continue to Dashboard',
      'create_account': 'Create Account',
      'dont_have_account': "Don't have an account? Register now",
      'already_have_account': 'Already have an account? Login',
      'logout': 'Logout',
      'logout_confirm': 'Do you want to sign out from your account?',
      'cancel': 'Cancel',
      'logged_out': 'Logged out successfully',
      'fast_farm_delivery': 'Fast farm delivery',
      'smart_crop_title': 'Smart crop support\nfor every season',
      'smart_crop_subtitle':
          'Explore agricultural products curated for stronger roots, healthier plants, and smoother checkout.',
      'featured_products': 'Featured Products',
      'products_ready': 'products ready for quick ordering',
      'view_details': 'View Details',
      'payment_successful': 'Payment Successful',
      'payment_success_subtitle':
          'Your order has been placed successfully. Our team will review the delivery details and contact you shortly.',
      'next_step_delivery': 'Next step: delivery confirmation and team follow-up.',
      'back_to_marketplace': 'Back to Marketplace',
      'incoming_orders': 'Incoming Orders',
      'incoming_orders_subtitle':
          'Track customers, ordered products, and saved delivery addresses in one place.',
      'no_orders_found': 'No orders found yet.',
      'processing': 'Processing',
      'total_received': 'Total Received',
      'payment': 'Payment',
      'order_summary': 'Order Summary',
      'total_amount': 'Total Amount',
      'delivery': 'Delivery',
      'delivery_days': '3 - 4 Day',
      'delivery_address': 'Delivery Address',
      'add': 'Add',
      'change': 'Change',
      'add_address_before_payment': 'Add your address or current location before payment.',
      'current_location': 'Current Location',
      'saved_address': 'Saved Address',
      'pay_via_card': 'Pay via Card',
      'pay_now': 'Pay Now',
      'contact_seller': 'Contact Seller',
      'choose_delivery_location': 'Choose Delivery Location',
      'delivery_location_subtitle': 'Add the address where you want the order delivered.',
      'manual_address': 'Manual Address',
      'use_my_current_location': 'Use My Current Location',
      'fetching_location': 'Fetching Location...',
      'house_street_area': 'House / Street / Area',
      'landmark': 'Landmark',
      'city': 'City',
      'pincode': 'Pincode',
      'save_delivery_address': 'Save Delivery Address',
      'please_complete_address': 'Please complete the delivery address',
      'current_location_fetched': 'Current location fetched. You can save it now.',
      'enable_location_services': 'Please enable location services on your device',
      'location_permission_denied': 'Location permission was denied',
      'location_permission_denied_forever':
          'Location permission is permanently denied. Open app settings to enable it.',
      'settings': 'Settings',
      'could_not_fetch_location': 'Could not fetch current location',
      'add_delivery_address_first': 'Please add your delivery address first',
    },
    'mr': {
      'app_name': 'रिव्हॉल्व अॅग्रो',
      'language': 'भाषा',
      'english': 'इंग्रजी',
      'marathi': 'मराठी',
      'grow_smarter_title': 'अधिक शहाणपणाने वाढवा,\nअधिक मजबूत पीक घ्या.',
      'grow_smarter_subtitle':
          'पीक काळजी उत्पादने शोधा, ऑर्डर पटकन द्या आणि तुमची शेती खरेदी एकाच सुंदर प्रवाहात सांभाळा.',
      'trusted_products': 'विश्वसनीय उत्पादने',
      'easy_checkout': 'सोपे चेकआउट',
      'continue': 'पुढे जा',
      'browse_products_directly': 'थेट उत्पादने पाहा',
      'choose_experience_title': 'तुमचा\nअनुभव निवडा',
      'choose_experience_subtitle':
          'शेतकरी आणि अॅडमिन यांना वेगळे डॅशबोर्ड, जलद कृती आणि अधिक सुटसुटीत खरेदी अनुभव मिळतो.',
      'user_login': 'युजर लॉगिन',
      'admin_login': 'अॅडमिन लॉगिन',
      'user_login_subtitle': 'उत्पादने पाहा, कार्ट व्यवस्थापित करा आणि डिलिव्हरी तपशीलांसह चेकआउट करा.',
      'admin_login_subtitle': 'आलेले ऑर्डर्स, ग्राहक पत्ते आणि एकूण ऑर्डर क्रियाकलाप पहा.',
      'multilingual_support': 'बहुभाषिक शेती सहाय्य आणि जलद टीम समन्वयासाठी उपलब्ध.',
      'admin_workspace': 'अॅडमिन कार्यक्षेत्र',
      'farmer_workspace': 'शेतकरी कार्यक्षेत्र',
      'welcome_back': 'पुन्हा स्वागत आहे',
      'create_your_account': 'तुमचे खाते तयार करा',
      'login': 'लॉगिन',
      'sign_up': 'नोंदणी',
      'full_name': 'पूर्ण नाव',
      'phone_number': 'फोन नंबर',
      'email_address': 'ईमेल पत्ता',
      'password': 'पासवर्ड',
      'login_hint': 'पुढे जाण्यासाठी तुमचा नोंदणीकृत ईमेल आणि पासवर्ड वापरा.',
      'signup_hint': 'तुमचे खाते ऑर्डर, पत्ता जतन आणि जलद चेकआउटसाठी वापरले जाईल.',
      'continue_to_dashboard': 'डॅशबोर्डवर जा',
      'create_account': 'खाते तयार करा',
      'dont_have_account': 'खाते नाही? आत्ता नोंदणी करा',
      'already_have_account': 'आधीच खाते आहे? लॉगिन करा',
      'logout': 'लॉगआउट',
      'logout_confirm': 'तुम्हाला खात्यातून बाहेर पडायचे आहे का?',
      'cancel': 'रद्द करा',
      'logged_out': 'यशस्वीरित्या लॉगआउट झाले',
      'fast_farm_delivery': 'जलद शेत डिलिव्हरी',
      'smart_crop_title': 'प्रत्येक हंगामासाठी\nस्मार्ट पीक सहाय्य',
      'smart_crop_subtitle':
          'मजबूत मुळे, निरोगी रोपे आणि सोपे चेकआउट यासाठी निवडक शेती उत्पादने पाहा.',
      'featured_products': 'विशेष उत्पादने',
      'products_ready': 'उत्पादने झटपट ऑर्डरसाठी तयार',
      'view_details': 'तपशील पहा',
      'payment_successful': 'पेमेंट यशस्वी',
      'payment_success_subtitle':
          'तुमची ऑर्डर यशस्वीरित्या नोंदवली गेली आहे. आमची टीम डिलिव्हरी तपशील तपासून लवकरच संपर्क करेल.',
      'next_step_delivery': 'पुढील टप्पा: डिलिव्हरी पुष्टी आणि टीम संपर्क.',
      'back_to_marketplace': 'मार्केटप्लेसवर परत जा',
      'incoming_orders': 'आलेली ऑर्डर्स',
      'incoming_orders_subtitle':
          'ग्राहक, ऑर्डर केलेली उत्पादने आणि जतन केलेले डिलिव्हरी पत्ते एकाच ठिकाणी पहा.',
      'no_orders_found': 'अजून कोणतीही ऑर्डर नाही.',
      'processing': 'प्रक्रियेत',
      'total_received': 'एकूण प्राप्त',
      'payment': 'पेमेंट',
      'order_summary': 'ऑर्डर सारांश',
      'total_amount': 'एकूण रक्कम',
      'delivery': 'डिलिव्हरी',
      'delivery_days': '३ - ४ दिवस',
      'delivery_address': 'डिलिव्हरी पत्ता',
      'add': 'जोडा',
      'change': 'बदला',
      'add_address_before_payment': 'पेमेंटपूर्वी तुमचा पत्ता किंवा सद्य स्थान जोडा.',
      'current_location': 'सध्याचे स्थान',
      'saved_address': 'जतन केलेला पत्ता',
      'pay_via_card': 'कार्डद्वारे पेमेंट',
      'pay_now': 'आता पेमेंट करा',
      'contact_seller': 'विक्रेत्याशी संपर्क',
      'choose_delivery_location': 'डिलिव्हरी स्थान निवडा',
      'delivery_location_subtitle': 'तुमची ऑर्डर जिथे पोहोचवायची आहे तो पत्ता जोडा.',
      'manual_address': 'हस्तचलित पत्ता',
      'use_my_current_location': 'माझे सध्याचे स्थान वापरा',
      'fetching_location': 'स्थान घेत आहे...',
      'house_street_area': 'घर / रस्ता / परिसर',
      'landmark': 'ओळखचिन्ह',
      'city': 'शहर',
      'pincode': 'पिनकोड',
      'save_delivery_address': 'डिलिव्हरी पत्ता जतन करा',
      'please_complete_address': 'कृपया पूर्ण डिलिव्हरी पत्ता भरा',
      'current_location_fetched': 'सध्याचे स्थान मिळाले. आता जतन करा.',
      'enable_location_services': 'कृपया डिव्हाइसवरील स्थान सेवा सुरू करा',
      'location_permission_denied': 'स्थान परवानगी नाकारली गेली',
      'location_permission_denied_forever':
          'स्थान परवानगी कायमची नाकारली गेली आहे. सेटिंग्जमध्ये जाऊन ती सुरू करा.',
      'settings': 'सेटिंग्ज',
      'could_not_fetch_location': 'सध्याचे स्थान मिळवता आले नाही',
      'add_delivery_address_first': 'कृपया आधी डिलिव्हरी पत्ता जोडा',
    },
  };

  String text(String key) {
    final languageCode = locale.languageCode;
    return _localizedValues[languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'mr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
