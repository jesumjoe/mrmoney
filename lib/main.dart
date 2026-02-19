import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mrmoney/services/hive_service.dart';
import 'package:mrmoney/services/notification_service.dart';
import 'package:mrmoney/services/sms_background_service.dart';
import 'package:mrmoney/utils/globals.dart';
import 'package:mrmoney/repositories/bank_account_repository.dart';
import 'package:mrmoney/repositories/transaction_repository.dart';
import 'package:mrmoney/repositories/category_repository.dart';
import 'package:mrmoney/providers/bank_account_provider.dart';
import 'package:mrmoney/repositories/friend_loan_repository.dart';
import 'package:mrmoney/providers/friend_provider.dart';
import 'package:mrmoney/theme/neo_style.dart';
import 'package:mrmoney/providers/transaction_provider.dart';
import 'package:mrmoney/providers/settings_provider.dart';
import 'package:mrmoney/providers/budget_provider.dart';
import 'package:mrmoney/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService.init();

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Initialize repositories
  final bankAccountRepo = BankAccountRepository();
  final transactionRepo = TransactionRepository();
  final categoryRepo = CategoryRepository();
  final friendLoanRepo = FriendLoanRepository();

  // Init default categories if needed
  categoryRepo.initDefaultCategories();

  // Init SMS Listener
  final smsService = SmsBackgroundService();
  await smsService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => BankAccountProvider(bankAccountRepo),
        ),
        ChangeNotifierProvider(create: (_) => FriendProvider(friendLoanRepo)),
        ChangeNotifierProxyProvider<BankAccountProvider, TransactionProvider>(
          create: (context) => TransactionProvider(
            transactionRepo,
            Provider.of<BankAccountProvider>(context, listen: false),
          ),
          update: (context, bankAccountProvider, previous) {
            final provider =
                previous ??
                TransactionProvider(transactionRepo, bankAccountProvider);
            provider.updateAccountProvider(bankAccountProvider);
            return provider;
          },
        ),
        Provider<CategoryRepository>.value(value: categoryRepo),
        ChangeNotifierProvider(create: (_) => BudgetProvider(categoryRepo)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final settings = Provider.of<SettingsProvider>(context); // Theme is now strict light

    return MaterialApp(
      title: 'Mr. Money',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Strict Light Mode
      theme: ThemeData(
        scaffoldBackgroundColor: NeoColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NeoColors.border,
          primary: NeoColors.primary,
          secondary: NeoColors.secondary,
          surface: NeoColors.surface,
          onSurface: NeoColors.text,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: NeoColors.text,
          displayColor: NeoColors.text,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: NeoColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
          iconTheme: IconThemeData(color: NeoColors.text, size: 24),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeoStyle.radius),
            borderSide: const BorderSide(
              color: NeoColors.border,
              width: NeoStyle.borderWidth,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeoStyle.radius),
            borderSide: const BorderSide(
              color: NeoColors.border,
              width: NeoStyle.borderWidth,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeoStyle.radius),
            borderSide: const BorderSide(
              color: NeoColors.primary,
              width: NeoStyle.borderWidth,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeoStyle.radius),
            borderSide: const BorderSide(
              color: NeoColors.error,
              width: NeoStyle.borderWidth,
            ),
          ),
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade600),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
