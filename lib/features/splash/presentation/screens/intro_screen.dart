import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:phonecleaner/features/clean/presentation/screens/permission_screen.dart';
import 'package:phonecleaner/app.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _introData = [
    {
      'title': 'Swipe to delete photo',
      'description': 'Delete unnecessary photos to optimize phone capacity',
      'image': 'assets/images/intro1@2x.png',
    },
    {
      'title': 'Hide photos',
      'description': 'Photos that are not processed',
      'image': 'assets/images/intro2@2x.png',
    },
    {
      'title': 'Favorite photos',
      'description': 'Add your favorite photos to your own list',
      'image': 'assets/images/intro3@2x.png',
    },
  ];

  void _onNext() {
    if (_currentPage < _introData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  void _onFinish() {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => const PermissionScreen(onGranted: AppScaffold()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: Column(
        children: [
          // Header Illustration Area - Full Width
          Container(
            height: 480.h,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _introData.length,
                itemBuilder: (context, index) {
                  return Image.asset(
                    _introData[index]['image']!,
                    fit: BoxFit.cover, // Ensures full width and height coverage
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                      ),
                      child: const Icon(
                        CupertinoIcons.photo,
                        size: 64,
                        color: CupertinoColors.systemGrey3,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 32.h),
                  Text(
                    _introData[_currentPage]['title']!,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006064),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _introData[_currentPage]['description']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const Spacer(),
                  // Indicators and Navigation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentPage > 0
                          ? GestureDetector(
                              onTap: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Icon(
                                CupertinoIcons.arrow_left_circle,
                                size: 32,
                                color: Colors.grey,
                              ),
                            )
                          : const SizedBox(width: 32),
                      Row(
                        children: List.generate(
                          _introData.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? Colors.black
                                  : CupertinoColors.systemGrey4,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _onNext,
                        child: const Icon(
                          CupertinoIcons.arrow_right_circle_fill,
                          size: 32,
                          color: CupertinoColors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
