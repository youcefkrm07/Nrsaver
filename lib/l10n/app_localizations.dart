import 'package:flutter/material.dart';

class L10n {
  static const supportedLocales = [Locale('en'), Locale('ar')];
}

class Strings {
  final Locale locale;
  const Strings(this.locale);

  static Strings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Strings(locale);
  }

  bool get isAr => locale.languageCode == 'ar';

  String get appTitle => isAr ? 'إدارة العملاء' : 'Client Manager';
  String get subtitle => isAr
      ? 'إدارة أرقام 4G والألياف الضوئية للعملاء'
      : 'Manage 4G Mobile and FIBRE numbers for your clients';

  String get name => isAr ? 'اسم العميل' : 'Client Name';
  String get enterName => isAr ? 'أدخل اسم العميل' : 'Enter client name';
  String get n4g => isAr ? 'رقم الموبايل 4G' : '4G Mobile Number';
  String get enter4g => isAr ? 'أدخل رقم الموبايل 4G' : 'Enter 4G mobile number';
  String get fibre => isAr ? 'رقم الألياف الضوئية' : 'FIBRE Number';
  String get enterFibre => isAr ? 'أدخل رقم الألياف الضوئية' : 'Enter FIBRE number';
  String get addClient => isAr ? 'إضافة عميل' : 'Add Client';
  String get searchHint => isAr
      ? 'البحث بالإسم أو رقم 4G أو رقم الألياف...'
      : 'Search by name, 4G number, or FIBRE number...';
  String get showingOne => isAr ? 'عرض' : 'Showing';
  String get ofClient => isAr ? 'عميل' : 'of client';
  String get edit => isAr ? 'تعديل' : 'Edit';
  String get delete => isAr ? 'حذف' : 'Delete';
}
