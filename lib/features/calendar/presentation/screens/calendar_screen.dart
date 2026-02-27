import 'package:flutter/cupertino.dart';
import 'package:phonecleaner/core/theme.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:phonecleaner/features/clean/presentation/screens/swipe_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phonecleaner/data/photo_repository.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _photoDays = {};

  @override
  void initState() {
    super.initState();
    _loadPhotoDays(_focusedDay);
  }

  Future<void> _loadPhotoDays(DateTime month) async {
    final days = await ref.read(photoRepositoryProvider).getPhotoDays(month);
    if (mounted) {
      setState(() => _photoDays = days);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.softGradient,
        ),
        child: CustomScrollView(
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Calendar'),
              backgroundColor: CupertinoColors.transparent,
              border: null,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      
                      final date = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                      if (_photoDays.contains(date)) {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => SwipeScreen(category: 'On ${selectedDay.day}/${selectedDay.month}'),
                          ),
                        );
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadPhotoDays(focusedDay);
                    },
                    eventLoader: (day) {
                      final date = DateTime(day.year, day.month, day.day);
                      return _photoDays.contains(date) ? [true] : [];
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: CupertinoColors.activeBlue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.delete,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Text(
                  'Select a highlighted date to clean photos taken on that day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
