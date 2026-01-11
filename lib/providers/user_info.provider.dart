import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/providers/auth.provider.dart';

final userInfoProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState.token == null) return null;
  final response = await http.get(
    Uri.parse('https://pictioniary.wevox.cloud/api/me'),
    headers: {'Authorization': 'Bearer ${authState.token}'},
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  return null;
});
