import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/member_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/skills_provider.dart';
import 'providers/owner_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/login_screen.dart';
import 'screens/parent_dashboard.dart';
import 'screens/coach_dashboard.dart';
import 'screens/owner_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiClient)..tryAutoLogin(),
        ),
        ChangeNotifierProvider(create: (_) => MemberProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => AttendanceProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => SkillsProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => OwnerProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ScheduleProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(apiClient)),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'PK Ušće CMS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF005696),
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(),
          ),
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAuth) {
      return const LoginScreen();
    }

    final roleStr = auth.user?.role.toString().toUpperCase() ?? '';
    print("DEBUG: AuthWrapper detektovao ulogu -> $roleStr");

    if (roleStr.contains('OWNER')) {
      return const OwnerDashboard();
    } else if (roleStr.contains('COACH')) {
      return const CoachDashboard();
    } else {
      return const ParentDashboard();
    }
  }
}
