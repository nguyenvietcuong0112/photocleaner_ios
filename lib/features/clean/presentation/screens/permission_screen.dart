import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phonecleaner/data/photo_repository.dart';
import 'package:phonecleaner/core/theme.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  final Widget onGranted;
  const PermissionScreen({super.key, required this.onGranted});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _isChecking = false;

  Future<void> _requestAccess() async {
    setState(() => _isChecking = true);
    final granted = await ref.read(photoRepositoryProvider).requestPermission();
    setState(() => _isChecking = false);
    
    if (granted) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => widget.onGranted),
        );
      }
    } else {
      _showDeniedDialog();
    }
  }

  void _showDeniedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Access Denied'),
        content: const Text('SwipeClean needs photo access to help you clean your library. Please enable it in Settings.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Settings'),
            onPressed: () {
              // In a real app, use open_settings or similar package
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.softGradient,
        ),
        child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.photo_on_rectangle,
                  size: 60,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Access Your Photos',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'To start cleaning, we need permission to view your photo library. We never upload your photos anywhere.',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_isChecking)
                const CupertinoActivityIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(16),
                    onPressed: _requestAccess,
                    child: const Text(
                      'Give Access',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
