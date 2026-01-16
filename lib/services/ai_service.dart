import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

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
      description: json['description'],
    );
  }
}

class AIService {
  static const String apiKey = 'YOUR_API_KEY_HERE'; // Replace with your API key
  
  static Future<ExpenseData?> parseExpense(String input) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
      );

      final prompt = '''
Parse the following expense description and extract the amount, category, and description.
Return ONLY a valid JSON object with these exact keys: "amount" (number), "category" (string), "description" (string).

Valid categories are: "Home", "College", "Medicine", "Lifestyle"

If a category isn't explicitly mentioned, infer it from context:
- Home: rent, groceries, utilities, wifi, electricity, water bills, furniture, repairs
- College: tuition, books, food at campus, transport to college, supplies, fees
- Medicine: doctor, medicines, insulin, insurance, checkup, pharmacy, hospital
- Lifestyle: shopping, movies, travel, music, entertainment, dining, hobbies, gym

Examples:
Input: "Spent 200 on fever medicine"
Output: {"amount": 200, "category": "Medicine", "description": "Fever medicine"}

Input: "Paid 5000 for rent this month"
Output: {"amount": 5000, "category": "Home", "description": "Rent"}

Input: "Movie tickets 500"
Output: {"amount": 500, "category": "Lifestyle", "description": "Movie tickets"}

Now parse this:
Input: "$input"
Output:''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text != null) {
        // Clean the response text
        String jsonStr = response.text!.trim();
        
        // Remove markdown code blocks if present
        if (jsonStr.startsWith('```json')) {
          jsonStr = jsonStr.substring(7);
        }
        if (jsonStr.startsWith('```')) {
          jsonStr = jsonStr.substring(3);
        }
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3);
        }
        jsonStr = jsonStr.trim();
        
        // Parse JSON
        final Map<String, dynamic> jsonData = json.decode(jsonStr);
        return ExpenseData.fromJson(jsonData);
      }
      
      return null;
    } catch (e) {
      print('Error parsing expense: $e');
      return null;
    }
  }
}
