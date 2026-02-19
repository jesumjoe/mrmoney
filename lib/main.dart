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
import 'package:mrmoney/screens/transactions_screen.dart';

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

  // Listen for Notification Taps
  notificationService.onNotificationTap.listen((payload) async {
    if (payload != null) {
      // Refresh Data first
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Show loading indicator or splash? Ideally we just wait.
        await Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).refresh();
        await Provider.of<BankAccountProvider>(
          context,
          listen: false,
        ).refresh();
      }

      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const TransactionsScreen()),
      );
    }
  });

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes to foreground
      Provider.of<TransactionProvider>(context, listen: false).refresh();
      Provider.of<BankAccountProvider>(context, listen: false).refresh();
    }
  }

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
          seedColor: NeoColors.primary,
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          iconTheme: IconThemeData(color: NeoColors.text, size: 24),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: NeoColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeoStyle.radius),
            borderSide: const BorderSide(color: NeoColors.border, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeoStyle.radius),
            borderSide: const BorderSide(color: NeoColors.border, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeoStyle.radius),
            borderSide: const BorderSide(color: NeoColors.primary, width: 1.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeoStyle.radius),
            borderSide: const BorderSide(color: NeoColors.error, width: 1.0),
          ),
          hintStyle: GoogleFonts.inter(color: NeoColors.textSecondary),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
