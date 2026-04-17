import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_state.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/parent/viewmodels/feed_view_model.dart';
import 'features/parent/viewmodels/suivi_view_model.dart';
import 'features/parent/viewmodels/homework_view_model.dart';
import 'features/parent/viewmodels/payment_view_model.dart';
import 'features/parent/viewmodels/chat_view_model.dart';
import 'features/parent/viewmodels/location_view_model.dart';
import 'features/parent/viewmodels/event_view_model.dart';
import 'features/common/viewmodels/notification_view_model.dart';
import 'features/common/viewmodels/profile_view_model.dart';
import 'features/parent/viewmodels/dashboard_view_model.dart';
import 'features/parent/viewmodels/behavior_view_model.dart';
import 'features/parent/viewmodels/calendar_view_model.dart';
import 'features/parent/viewmodels/security_view_model.dart';
import 'features/parent/viewmodels/timetable_view_model.dart';
import 'core/services/notification_service.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('ar', null);
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => FeedViewModel()),
        ChangeNotifierProvider(create: (_) => SuiviViewModel()),
        ChangeNotifierProvider(create: (_) => HomeworkViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        ChangeNotifierProvider<ChatViewModel>(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => LocationViewModel()),
        ChangeNotifierProvider(create: (_) => EventViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(
          create: (context) => ProfileViewModel(
            Provider.of<AppState>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => BehaviorViewModel()),
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
        ChangeNotifierProvider(create: (_) => SecurityViewModel()),
        ChangeNotifierProvider(create: (_) => TimetableViewModel()),
      ],
      child: const IkenasApp(),
    ),
  );

  // Init after runApp so the Android Activity is ready for permission dialogs
  NotificationService.instance.init().catchError(
    (e) => debugPrint('[Main] NotificationService init failed: $e'),
  );
}

class IkenasApp extends StatelessWidget {
  const IkenasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ikenas',
      theme: appState.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      locale: appState.locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: appState.textDirection,
          child: child!,
        );
      },
      // Production: Use AuthGate for proper authentication flow
      // Testing: Change to ChatConversationsScreen() to test chat feature
      home: const AuthGate(),
    );
  }
}
