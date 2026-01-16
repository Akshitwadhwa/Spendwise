import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class ExpenseData {
  final double? amount;
  final String? category;
  final String? description;

  ExpenseData({
    this.amount,
    this.category,
    this.description,
  });

  factory ExpenseData.fromJson(Map<String, dynamic> json) {
    return ExpenseData(
      amount: json['amount']?.toDouble(),
      category: json['category'],
      description: json['title'] ?? json['description'],
    );
  }
}

class AIService {
  // Double check your API Key is exactly as shown in AI Studio
  static const String apiKey = 'AIzaSyDBP0DU5IAkjmmKcx251pdppebDTx_3ReU'; // Replace with your API key

  static Future<ExpenseData?> parseExpense(String input) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
      );

      final prompt = '''
        Extract budget data from: "$input"
        Return ONLY a JSON object. No intro text, no markdown.
        Format: {"amount": number, "category": "Home" | "College" | "Medicine" | "Lifestyle", "title": "string"}
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      final text = response.text;
      if (text == null) {
        print("AI Error: Empty response from Gemini");
        return null;
      }

      print("Raw AI Response: $text"); // THIS WILL SHOW YOU THE ERROR IN THE CONSOLE

      // STRENGTHENED CLEANING LOGIC (Removes ```json and other junk)
      String cleanResponse = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll(RegExp(r'^[^{]*'), '') // Remove anything before the first {
          .replaceAll(RegExp(r'[^}]*$'), '') // Remove anything after the last }
          .trim();

      print("Cleaned JSON: $cleanResponse"); // Debug log

      final Map<String, dynamic> jsonData = jsonDecode(cleanResponse);
      return ExpenseData.fromJson(jsonData);
    } catch (e) {
      // THIS PRINTS THE ACTUAL ERROR TO YOUR DEBUG CONSOLE
      print("CRITICAL ERROR IN AI SERVICE: $e");
      return null;
    }
  }
}
