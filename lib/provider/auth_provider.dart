import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginProvider with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    const url = 'http://127.0.0.1:8000/api/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Simpan token, role, dan nama pengguna
        await prefs.setString('token', responseData['token']);
        await prefs.setString('role', responseData['role']);
        await prefs.setString('name', responseData['user']['name']);

        notifyListeners();
        return true;
      } else {
        _errorMessage = responseData['message'] ?? 'Login gagal';
        notifyListeners();
        return false;
      }
    } catch (error) {
      _errorMessage = 'Terjadi kesalahan: $error';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password,
      String confirmPassword) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    const url = 'http://127.0.0.1:8000/api/register';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        _errorMessage = 'Pendaftaran berhasil. Silakan login.';
        notifyListeners();
        return true;
      } else {
        // Tampilkan error dari server
        if (responseData.containsKey('message')) {
          _errorMessage = responseData['message'];
        } else if (responseData.containsKey('errors')) {
          _errorMessage = (responseData['errors'] as Map<String, dynamic>)
              .values
              .map((e) => e.join(', '))
              .join('\n');
        } else {
          _errorMessage = 'Pendaftaran gagal.';
        }
        notifyListeners();
        return false;
      }
    } catch (error) {
      _errorMessage = 'Terjadi kesalahan: $error';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    const url = 'http://127.0.0.1:8000/api/logout';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('token');
        await prefs.remove('role');
        await prefs.remove('name');
        notifyListeners();
        return true;
      } else {
        throw Exception('Logout gagal');
      }
    } catch (error) {
      _errorMessage = 'Terjadi kesalahan: $error';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    const url = 'http://127.0.0.1:8000/api/profile';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Ambil data user dari response
        final userData = responseData['user'] as Map<String, dynamic>;

        // Menyimpan data ke shared preferences jika perlu
        await prefs.setString('name', userData['name']);
        await prefs.setString('email', userData['email']);

        notifyListeners(); // Memberi tahu bahwa data telah diubah
        return userData; // Mengembalikan data profil pengguna
      } else {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        _errorMessage = responseData['message'] ?? 'Gagal mengambil profil';
        notifyListeners();
        return null;
      }
    } catch (error) {
      _errorMessage = 'Terjadi kesalahan: $error';
      notifyListeners();
      return null;
    }
  }
}