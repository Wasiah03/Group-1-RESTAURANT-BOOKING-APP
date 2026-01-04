import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/menu_package.dart';

class MenuProvider extends ChangeNotifier {
  List<MenuPackage> _packages = [];
  bool _isLoading = false;

  List<MenuPackage> get packages => _packages;
  bool get isLoading => _isLoading;

  Future<void> fetchPackages() async {
    try {
      _isLoading = true;
      notifyListeners();

      _packages = await DatabaseHelper.instance.getAllMenuPackages();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching packages: $e');
      _packages = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MenuPackage?> getPackageById(int id) async {
    try {
      return await DatabaseHelper.instance.getMenuPackage(id);
    } catch (e) {
      print('Error getting package by id: $e');
      return null;
    }
  }

  Future<bool> addPackage(MenuPackage package) async {
    try {
      final id = await DatabaseHelper.instance.insertMenuPackage(package);
      if (id > 0) {
        await fetchPackages();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding package: $e');
      return false;
    }
  }

  Future<bool> updatePackage(MenuPackage package) async {
    try {
      final result = await DatabaseHelper.instance.updateMenuPackage(package);
      if (result > 0) {
        await fetchPackages();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating package: $e');
      return false;
    }
  }

  Future<bool> deletePackage(int id) async {
    try {
      final result = await DatabaseHelper.instance.deleteMenuPackage(id);
      if (result > 0) {
        await fetchPackages();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting package: $e');
      return false;
    }
  }
}
