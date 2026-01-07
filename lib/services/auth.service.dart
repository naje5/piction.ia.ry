import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "https://pictioniary.wevox.cloud/api";

  Future<String?> login(String username, String password) async {

    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": username,
        "password": password,
      }),
    );

   if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["token"];
  }
    return null;
  }

 Future<String?> register(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/players"),
      body: {
        "name": username,
        "password": password,
      },
    );

    if(response.statusCode == 201) {
      return response.body;
    }
    return null;
  }
}
