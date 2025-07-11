import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'loket_cti/models/branch_model.dart';

class BranchStorageHelper {
  static const _key = 'last_branch';

  static Future<void> saveBranch(Branch branch) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, jsonEncode(branch.toJson()));
  }

  static Future<Branch?> loadBranch() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    return Branch.fromJson(jsonDecode(json));
  }

  static Future<void> clearBranch() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_key);
  }
}
