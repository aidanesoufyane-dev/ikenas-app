import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/app_state.dart';

class ProfileViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final AppState _appState;

  bool _isUpdating = false;
  String? _errorMessage;

  ProfileViewModel(this._appState);

  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _appState.currentUser;

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    int? avatarIndex,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedData = <String, dynamic>{};
      if (name != null) updatedData['name'] = name;
      if (email != null) updatedData['email'] = email;
      if (phone != null) updatedData['phone'] = phone;
      if (avatarIndex != null) updatedData['avatarIndex'] = avatarIndex;

      await _apiService.updateProfile(updatedData);
      
      if (user != null) {
        final newUser = user!.copyWith(
          name: name ?? user!.name,
          email: email ?? user!.email,
          phone: phone ?? user!.phone,
          avatarIndex: avatarIndex ?? user!.avatarIndex,
        );
        _appState.updateUser(newUser);
      }
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
