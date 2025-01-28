import 'package:ads_schools/models/models.dart';
import 'package:ads_schools/services/auth_service.dart';
import 'package:ads_schools/services/services.dart';
import 'package:flutter/material.dart';

class GlobalDataProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _studentService = Services().studentService;
  final _classService = Services().classService;
  final _subjectService = Services().subjectService;
  UserModel? _currentUser;
  List<Student> _students = [];
  List<SchoolClass> _classes = [];

  List<Subject> _subjects = [];
  bool _isLoading = true;

  GlobalDataProvider() {
    _initializeData();
  }
  List<SchoolClass> get classes => _classes;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  List<Student> get students => _students;
  List<Subject> get subjects => _subjects;

  Future<void> _fetchClasses() async {
    try {
      _classes = await _classService.getAll().first;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      _currentUser = await _authService.getUserInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  Future<void> _fetchStudents() async {
    try {
      _students = await _studentService.getAll().first;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching students: $e');
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      _subjects = await _subjectService.getAll().first;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching courses: $e');
    }
  }

  Future<void> _initializeData() async {
    _setLoading(true);
    try {
      await _fetchCurrentUser();
      await _fetchClasses();
      await _fetchStudents();
      await _fetchSubjects();
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

class NavigatorService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void goBack() {
    navigatorKey.currentState!.pop();
  }

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!
        .pushNamed(routeName, arguments: arguments);
  }
}

class Routes {
  static const String loginScreen = "/loginScreen";
  static const String splashScreen = "/splashScreen";
  static const String welcomeScreen = "/welcomeScreen";
  static const String forgetScreen = "/forgetScreen";
  static const String createPassword = "/createPassword";
  static const String adminDashboard = '/adminDashboard';
  static const String studentDashboard = '/studentDashboard';
}
