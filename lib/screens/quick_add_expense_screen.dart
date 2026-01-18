import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/category_data.dart';
import 'add_expense_screen.dart';

class QuickAddExpenseScreen extends StatefulWidget {
  const QuickAddExpenseScreen({super.key});

  @override
  State<QuickAddExpenseScreen> createState() => _QuickAddExpenseScreenState();
}

class _QuickAddExpenseScreenState extends State<QuickAddExpenseScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Debug: List available models
    AIService.listAvailableModels();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processExpense() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await AIService.parseExpense(_controller.text);

      if (result != null && mounted) {
        print("Parsed - Amount: ${result.amount}, Category: ${result.category}, Description: ${result.description}");
        
        // Check if category exists
        final category = CategoryData.categories[result.category];
        
        if (category != null && result.amount != null) {
          // Navigate to add expense screen with pre-filled data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreenWithData(
                category: category,
                amount: result.amount!,
                description: result.description ?? '',
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Could not parse the expense. Please try again.';
            _isProcessing = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Could not understand the input. Please try again.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUICK ADD',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94a3b8),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Smart Expense',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10b981).withOpacity(0.1),
                      const Color(0xFF10b981).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10b981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10b981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF10b981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Describe your expense naturally, like:\n"Spent 200 on fever medicine"',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94a3b8),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Input Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Describe your expense',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'E.g., Paid 5000 for rent, Movie tickets 500...',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _processExpense(),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: MediaQuery.of(context).size.height * 0.15),

              // Process Button
              GestureDetector(
                onTap: _isProcessing ? null : _processExpense,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _controller.text.isNotEmpty && !_isProcessing
                        ? const Color(0xFF10b981)
                        : const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _controller.text.isNotEmpty && !_isProcessing
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10b981).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isProcessing)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Parse with AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _controller.text.isNotEmpty
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Extended AddExpenseScreen to accept pre-filled data
class AddExpenseScreenWithData extends StatefulWidget {
  final CategoryData category;
  final double amount;
  final String description;

  const AddExpenseScreenWithData({
    super.key,
    required this.category,
    required this.amount,
    required this.description,
  });

  @override
  State<AddExpenseScreenWithData> createState() => _AddExpenseScreenWithDataState();
}

class _AddExpenseScreenWithDataState extends State<AddExpenseScreenWithData> {
  @override
  Widget build(BuildContext context) {
    return AddExpenseScreen(
      category: widget.category,
      initialAmount: widget.amount,
      initialDescription: widget.description,
    );
  }
}
