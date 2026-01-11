import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/category_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double totalBalance = 0.00;
  int entryCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'My Wallet',
                        style: TextStyle(
                          fontSize: 28,
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.code,
                          color: AppColors.textGray,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.accentTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primaryDark,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3dd598),
                      Color(0xFF2fb87d),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${totalBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$entryCount Entries',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Add Entry Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Entry',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.textWhite,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Category Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.6,
                children: const [
                    CategoryCard(
                      title: 'Home',
                      icon: Icons.home_outlined,
                      color: AppColors.homeBlue,
                    ),
                    CategoryCard(
                      title: 'College',
                      icon: Icons.school_outlined,
                      color: AppColors.collegeOrange,
                    ),
                  CategoryCard(
                    title: 'Medicine',
                    icon: Icons.favorite_border,
                    color: AppColors.medicinePink,
                  ),
                ],
              ),
              const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
