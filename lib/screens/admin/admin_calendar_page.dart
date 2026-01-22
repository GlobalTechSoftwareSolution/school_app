import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Holiday {
  final int? id;
  final int year;
  final int month;
  final String country;
  final String date;
  final String name;
  final String type;
  final String weekday;

  Holiday({
    this.id,
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
      id: json['id'],
      year: json['year'] ?? DateTime.parse(json['date']).year,
      month: json['month'] ?? DateTime.parse(json['date']).month,
      country: json['country'] ?? 'India',
      date: json['date'],
      name: json['name'],
      type: json['type'] ?? 'Other',
      weekday:
          json['weekday'] ??
          DateFormat('EEEE').format(DateTime.parse(json['date'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'country': country,
      'date': date,
      'name': name,
      'type': type,
      'weekday': weekday,
    };
  }
}

class AdminCalendarPage extends StatefulWidget {
  const AdminCalendarPage({super.key});

  @override
  State<AdminCalendarPage> createState() => _AdminCalendarPageState();
}

class _AdminCalendarPageState extends State<AdminCalendarPage> {
  final String apiBaseUrl =
      'https://school.globaltechsoftwaresolutions.cloud/api';

  List<Holiday> holidays = [];
  bool isLoading = true;
  String? error;
  DateTime selectedDate = DateTime.now();
  int currentYear = DateTime.now().year;
  int currentMonth = DateTime.now().month;

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
    "Jayanti": Colors.purpleAccent,
    "Other": Colors.blueGrey,
  };

  @override
  void initState() {
    super.initState();
    fetchHolidays();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<void> fetchHolidays() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/holidays/'),
        headers: token != null
            ? {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              }
            : {'Content-Type': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Server error: ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      final List<dynamic> data = jsonDecode(response.body);
      setState(() => holidays = data.map((e) => Holiday.fromJson(e)).toList());
    } catch (err) {
      setState(() => error = err.toString());
      setState(() => holidays = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveHoliday(Holiday holiday) async {
    setState(() => isLoading = true);

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$apiBaseUrl/holidays/'),
        headers: token != null
            ? {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              }
            : {'Content-Type': 'application/json'},
        body: jsonEncode(holiday.toJson()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to save holiday');
      }

      await fetchHolidays();
    } catch (err) {
      setState(() => error = err.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteHoliday(int id) async {
    setState(() => isLoading = true);

    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/holidays/$id/'),
        headers: token != null
            ? {'Authorization': 'Bearer $token'}
            : {'Content-Type': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete holiday');
      }

      await fetchHolidays();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Holiday deleted successfully')),
      );
    } catch (err) {
      setState(() => error = err.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void goToPreviousMonth() {
    setState(() {
      if (currentMonth == 1) {
        currentMonth = 12;
        currentYear--;
      } else {
        currentMonth--;
      }
    });
  }

  void goToNextMonth() {
    setState(() {
      if (currentMonth == 12) {
        currentMonth = 1;
        currentYear++;
      } else {
        currentMonth++;
      }
    });
  }

  void goToToday() {
    final today = DateTime.now();
    setState(() {
      currentYear = today.year;
      currentMonth = today.month;
      selectedDate = today;
    });
  }

  String normalizeDate(DateTime date) {
    final monthStr = date.month < 10 ? '0${date.month}' : date.month.toString();
    final dayStr = date.day < 10 ? '0${date.day}' : date.day.toString();
    return '${date.year}-${monthStr}-${dayStr}';
  }

  List<Holiday> getSelectedDateHolidays() {
    return holidays.where((h) {
      final holidayDate = DateTime.parse(h.date);
      return normalizeDate(holidayDate) == normalizeDate(selectedDate) &&
          holidayDate.year == currentYear;
    }).toList();
  }

  List<Holiday> getMonthHolidays(int month) {
    return holidays.where((h) {
      final holidayDate = DateTime.parse(h.date);
      return holidayDate.month == month && holidayDate.year == currentYear;
    }).toList();
  }

  void showAddHolidayModal([DateTime? date]) {
    final selectedDate = date ?? this.selectedDate;
    showDialog(
      context: context,
      builder: (context) =>
          AddHolidayDialog(selectedDate: selectedDate, onSave: saveHoliday),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Holiday Calendar',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage holidays and view calendar with advanced holiday tracking',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Year Selector
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_view_month,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Year:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<int>(
                        value: currentYear,
                        underline: const SizedBox(),
                        items: List.generate(5, (index) {
                          final year = DateTime.now().year + index - 2;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => currentYear = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Calendar Section
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Calendar Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: goToPreviousMonth,
                          icon: const Icon(Icons.chevron_left),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              DateFormat(
                                'MMMM yyyy',
                              ).format(DateTime(currentYear, currentMonth)),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: goToNextMonth,
                          icon: const Icon(Icons.chevron_right),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Calendar Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: goToToday,
                          icon: const Icon(Icons.today),
                          label: const Text('Today'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => showAddHolidayModal(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Holiday'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Calendar Grid
                    CalendarGrid(
                      year: currentYear,
                      month: currentMonth,
                      holidays: holidays,
                      selectedDate: selectedDate,
                      onDateSelected: (date) {
                        setState(() => selectedDate = date);
                      },
                      onAddHoliday: showAddHolidayModal,
                    ),
                  ],
                ),
              ),

              // Selected Date Details and Overview - Below Calendar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Date Details
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.date_range,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Selected Date',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              DateFormat(
                                'EEEE, MMMM d, yyyy',
                              ).format(selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Holidays:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...getSelectedDateHolidays().map(
                            (holiday) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color:
                                              holidayColors[holiday.type] ??
                                              Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              holiday.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              holiday.type,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            deleteHoliday(holiday.id!),
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                        ),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: double.infinity,
                                    ),
                                    child: Wrap(
                                      spacing: 16,
                                      runSpacing: 4,
                                      children: [
                                        SizedBox(
                                          width: 130,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  DateFormat(
                                                    'MMM d, yyyy',
                                                  ).format(
                                                    DateTime.parse(
                                                      holiday.date,
                                                    ),
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 130,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  holiday.country,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (getSelectedDateHolidays().isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No holidays on this date',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Overview Stats
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bar_chart,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  holidays
                                      .where((h) {
                                        final date = DateTime.parse(h.date);
                                        return date.year == currentYear;
                                      })
                                      .length
                                      .toString(),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Total Holidays',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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

              const SizedBox(height: 32),

              // Holiday Cards by Month
              HolidayCardsByMonth(),

              if (error != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget HolidayCardsByMonth() {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final holidaysByMonth = <int, List<Holiday>>{};
    for (var holiday in holidays) {
      final date = DateTime.parse(holiday.date);
      if (date.year == currentYear) {
        holidaysByMonth.putIfAbsent(date.month, () => []);
        holidaysByMonth[date.month]!.add(holiday);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Holidays ($currentYear)',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: holidaysByMonth.length,
          itemBuilder: (context, index) {
            final month = holidaysByMonth.keys.elementAt(index);
            final monthHolidays = holidaysByMonth[month]!;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthNames[month - 1],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: monthHolidays.length,
                      itemBuilder: (context, holidayIndex) {
                        final holiday = monthHolidays[holidayIndex];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color:
                                      holidayColors[holiday.type] ??
                                      Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    DateTime.parse(holiday.date).day.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      holiday.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      holiday.type,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => deleteHoliday(holiday.id!),
                                icon: const Icon(Icons.delete, size: 14),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final List<Holiday> holidays;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onAddHoliday;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    required this.holidays,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onAddHoliday,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingDayOfWeek = firstDay.weekday;

    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        // Week Days Header
        Row(
          children: weekDays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),

        // Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: 42, // 6 weeks * 7 days
          itemBuilder: (context, index) {
            final dayNumber = index - startingDayOfWeek + 2;
            final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;

            if (!isCurrentMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(year, month, dayNumber);
            final isToday =
                DateTime.now().year == year &&
                DateTime.now().month == month &&
                DateTime.now().day == dayNumber;
            final isSelected =
                selectedDate.year == year &&
                selectedDate.month == month &&
                selectedDate.day == dayNumber;

            final dayHolidays = holidays.where((h) {
              final holidayDate = DateTime.parse(h.date);
              return holidayDate.year == year &&
                  holidayDate.month == month &&
                  holidayDate.day == dayNumber;
            }).toList();

            return InkWell(
              onTap: () => onDateSelected(date),
              onDoubleTap: () => onAddHoliday(date),
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue
                      : isToday
                      ? Colors.blue[50]
                      : Colors.white,
                  border: Border.all(
                    color: isToday ? Colors.blue : Colors.grey[200]!,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  children: [
                    // Day number
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),

                    // Holiday indicators
                    if (dayHolidays.isNotEmpty)
                      Positioned(
                        bottom: 2,
                        left: 2,
                        right: 2,
                        child: Column(
                          children: dayHolidays.take(2).map((holiday) {
                            final color =
                                {
                                  "National Holiday": Colors.red,
                                  "Government Holiday": Colors.blue,
                                  "Jayanti/Festival": Colors.purple,
                                  "Festival": Colors.green,
                                  "Regional Festival": Colors.orange,
                                  "Harvest Festival": Colors.amber,
                                  "Observance": Colors.grey,
                                  "Observance/Restricted": Colors.grey,
                                  "Festival/National Holiday": Colors.pink,
                                  "Jayanti": Colors.purpleAccent,
                                  "Other": Colors.blueGrey,
                                }[holiday.type] ??
                                Colors.grey;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                holiday.name.length > 8
                                    ? '${holiday.name.substring(0, 8)}...'
                                    : holiday.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Show +count if more than 2 holidays
                    if (dayHolidays.length > 2)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Text(
                          '+${dayHolidays.length - 2}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.lightBlue
                                : Colors.grey[600],
                            fontSize: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class AddHolidayDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Holiday) onSave;

  const AddHolidayDialog({
    super.key,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<AddHolidayDialog> createState() => _AddHolidayDialogState();
}

class _AddHolidayDialogState extends State<AddHolidayDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  late TextEditingController _countryController;
  String _selectedType = 'National Holiday';

  final holidayTypes = [
    'National Holiday',
    'Government Holiday',
    'Jayanti/Festival',
    'Festival',
    'Regional Festival',
    'Harvest Festival',
    'Observance',
    'Observance/Restricted',
    'Festival/National Holiday',
    'Jayanti',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dateController = TextEditingController(
      text: widget.selectedDate.toIso8601String().split('T')[0],
    );
    _countryController = TextEditingController(text: 'India');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Holiday',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Holiday Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Holiday Name',
                  hintText: 'e.g. Independence Day',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter holiday name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date and Type Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(_dateController.text),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          _dateController.text = date.toIso8601String().split(
                            'T',
                          )[0];
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: holidayTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Country
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country/Scope',
                  hintText: 'e.g. India',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveHoliday,
                    child: const Text('Create Holiday'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveHoliday() {
    if (_formKey.currentState!.validate()) {
      final date = DateTime.parse(_dateController.text);
      final holiday = Holiday(
        year: date.year,
        month: date.month,
        country: _countryController.text,
        date: _dateController.text,
        name: _nameController.text,
        type: _selectedType,
        weekday: DateFormat('EEEE').format(date),
      );

      widget.onSave(holiday);
      Navigator.of(context).pop();
    }
  }
}
