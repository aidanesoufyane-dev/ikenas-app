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

      final updatedUser = await _apiService.updateProfile(updatedData);
      _appState.updateUser(updatedUser);
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
