// ===============================================================
// trip_tabs.dart
// ---------------------------------------------------------------
// My Trips Tabs Widget
//
// PURPOSE
// ---------------------------------------------------------------
// Displays Current, Upcoming and Past trip tabs.
// ===============================================================

import 'package:flutter/material.dart';

class TripTabs extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const TripTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['Current', 'Upcoming', 'Past'];

    return Container(
      color: Colors.white,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isActive = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? const Color(0xff6B46C1)
                          : Colors.grey.shade300,
                      width: isActive ? 3 : 1,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xff6B46C1)
                        : Colors.grey.shade700,
                    fontWeight: isActive
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}