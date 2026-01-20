import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Holiday {
  final int year;
  final int month;
  final String country;
  final String date;
  final String name;
  final String type;
  final String weekday;

  Holiday({
    required this.year,
    required this.month,
    required this.country,
    required this.date,
    required this.name,
    required this.type,
    required this.weekday,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      country: json['country'] ?? '',
      date: json['date'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      weekday: json['weekday'] ?? '',
    );
  }
}

class GoogleCalendarPage extends StatefulWidget {
  const GoogleCalendarPage({super.key});

  @override
  State<GoogleCalendarPage> createState() => _GoogleCalendarPageState();
}

class _GoogleCalendarPageState extends State<GoogleCalendarPage> {
  final String apiBase = 'https://school.globaltechsoftwaresolutions.cloud/api';

  List<Holiday> holidays = [];
  bool isLoading = true;
  String? error;
  String selectedDate = DateTime.now().toIso8601String().split('T')[0];
  int year = DateTime.now().year;
  int month = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final monthsList = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  final Map<String, Color> holidayColors = {
    "National Holiday": Colors.red,
    "Government Holiday": Colors.blue,
    "Jayanti/Festival": Colors.purple,
    "Festival": Colors.green,
    "Regional Festival": Colors.orange,
    "Harvest Festival": Colors.amber,
    "Observance": Colors.grey,
    "Observance/Restricted": Colors.grey,
    "Festival/National Holiday": Colors.pink,
    "Jayanti": Colors.purple,
    "Other": Colors.blueGrey,
  };

  void goToPreviousMonth() {
    if (month == 1) {
      setState(() {
        month = 12;
        year -= 1;
        selectedYear = year;
      });
    } else {
      setState(() => month -= 1);
    }
  }

  void goToNextMonth() {
    if (month == 12) {
      setState(() {
        month = 1;
        year += 1;
        selectedYear = year;
      });
    } else {
      setState(() => month += 1);
    }
  }

  void goToToday() {
    final today = DateTime.now();
    setState(() {
      year = today.year;
      month = today.month;
      selectedDate = today.toIso8601String().split('T')[0];
    });
  }

  String normalizeDate(String dateStr) {
    final d = DateTime.parse(dateStr);
    final year = d.year.toString();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  void initState() {
    super.initState();
    fetchHolidays();
  }

  Future<void> fetchHolidays() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      print('Fetching holidays from: $apiBase/holidays/');
      final response = await http.get(Uri.parse('$apiBase/holidays/'));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception(
          'Failed to fetch holidays - Status: ${response.statusCode}',
        );
      }

      final data = json.decode(response.body);
      print('Parsed data type: ${data.runtimeType}');
      print('Data: $data');

      final holidaysList = data is List ? data : [];
      print('Holidays list length: ${holidaysList.length}');

      setState(() {
        holidays = holidaysList.map((h) => Holiday.fromJson(h)).toList();
        isLoading = false;
      });

      print('Successfully loaded ${holidays.length} holidays');
    } catch (e) {
      print('Error fetching holidays: $e');
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  List<Holiday> getHolidaysForDate(DateTime date) {
    return holidays.where((holiday) {
      final holidayDate = DateTime.parse(holiday.date);
      return holidayDate.year == date.year &&
          holidayDate.month == date.month &&
          holidayDate.day == date.day;
    }).toList();
  }

  List<Holiday> getHolidaysForMonth(DateTime date) {
    return holidays.where((holiday) {
      final holidayDate = DateTime.parse(holiday.date);
      return holidayDate.year == date.year && holidayDate.month == date.month;
    }).toList();
  }

  List<int> _getAvailableYears() {
    final years = holidays.map((holiday) => holiday.year).toSet().toList();
    years.sort();
    return years;
  }

  List<Holiday> getHolidaysForYear(int year) {
    return holidays.where((holiday) => holiday.year == year).toList();
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingDay = firstDay.weekday % 7; // 0 = Sunday

    final days = <Widget>[];

    // Empty days for the start of the month
    for (int i = 0; i < startingDay; i++) {
      days.add(
        Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade50,
          ),
        ),
      );
    }

    // Actual days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final isToday = dateStr == DateTime.now().toIso8601String().split('T')[0];
      final isSelected = dateStr == selectedDate;
      final dayHolidays = holidays
          .where((h) => normalizeDate(h.date) == dateStr)
          .toList();

      days.add(
        GestureDetector(
          onTap: () => setState(() => selectedDate = dateStr),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: isSelected
                  ? Colors.blue
                  : isToday
                  ? Colors.blue.shade50
                  : Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                // Holiday indicators
                ...dayHolidays
                    .take(2)
                    .map(
                      (holiday) => Container(
                        margin: const EdgeInsets.only(bottom: 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color:
                              holidayColors[holiday.type]?.withOpacity(0.8) ??
                              Colors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          holiday.name.length > 6
                              ? '${holiday.name.substring(0, 6)}...'
                              : holiday.name,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                if (dayHolidays.length > 2)
                  Text(
                    '+${dayHolidays.length - 2}',
                    style: TextStyle(
                      fontSize: 8,
                      color: isSelected
                          ? Colors.blue.shade200
                          : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: days,
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthHolidays = getHolidaysForMonth(DateTime(year, month));
    final selectedDateHolidays = getHolidaysForDate(
      DateTime.parse(selectedDate),
    );

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fetchHolidays,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            child: Column(
              children: [
                // Year selector
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Select Year: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: _getAvailableYears()
                            .map(
                              (year) => DropdownMenuItem<int>(
                                value: year,
                                child: Text(
                                  year.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedYear = value;
                              // Reset calendar to first month of selected year
                              year = value;
                              month = 1;
                              selectedDate = '$value-01-01';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Month navigation header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: goToPreviousMonth,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Column(
                        children: [
                          Text(
                            '${monthsList[month - 1]} $year',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${monthHolidays.length} holidays this month',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: goToToday,
                            child: const Text('Today'),
                          ),
                          IconButton(
                            onPressed: goToNextMonth,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Days of week header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

                // Calendar grid
                _buildCalendarGrid(),

                const SizedBox(height: 16),

                // Selected date details
                if (selectedDateHolidays.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Holidays on ${DateTime.parse(selectedDate).toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...selectedDateHolidays.map(
                          (holiday) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  holidayColors[holiday.type]?.withOpacity(
                                    0.1,
                                  ) ??
                                  Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    holidayColors[holiday.type] ?? Colors.grey,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color:
                                        holidayColors[holiday.type] ??
                                        Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        holiday.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        holiday.type,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Monthly Holiday List for Selected Year
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Holidays for $selectedYear',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(12, (monthIndex) {
                        final monthNumber = monthIndex + 1;
                        final monthHolidays = holidays
                            .where(
                              (h) =>
                                  h.year == selectedYear &&
                                  h.month == monthNumber,
                            )
                            .toList();

                        if (monthHolidays.isEmpty)
                          return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                monthsList[monthIndex],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            ...monthHolidays.map(
                              (holiday) => Container(
                                margin: const EdgeInsets.only(
                                  bottom: 6,
                                  left: 8,
                                ),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color:
                                        holidayColors[holiday.type]
                                            ?.withOpacity(0.3) ??
                                        Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color:
                                            holidayColors[holiday.type] ??
                                            Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            holiday.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '${holiday.date} (${holiday.weekday})',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                      // Show message if no holidays for selected year
                      if (getHolidaysForYear(selectedYear).isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No holidays found for $selectedYear',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
