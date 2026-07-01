// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trplapp/dto/datas.dart';

import 'package:trplapp/services/data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Datas>> _datasFuture;
  Map<DateTime, List<Datas>> _groupedDatas = {};
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _employeeName = "Karyawan";

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadProfileName();
    _fetchDatas();
  }

  void _fetchDatas() {
    _datasFuture = DataService.fetchDatas().then((datas) {
      _groupDatasByDate(datas);
      return datas;
    });
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _employeeName = prefs.getString('emp_name') ?? "Karyawan";
    });
  }

  void _groupDatasByDate(List<Datas> datas) {
    _groupedDatas = {};
    for (var data in datas) {
      final date = DateTime(data.createdAt.year, data.createdAt.month, data.createdAt.day);
      if (_groupedDatas[date] == null) {
        _groupedDatas[date] = [];
      }
      _groupedDatas[date]!.add(data);
    }
  }

  List<Datas> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _groupedDatas[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<Datas>>(
        future: _datasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 40),
                  decoration: BoxDecoration(
                    color: Colors.indigo[800],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat datang kembali,',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _employeeName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar<Datas>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.indigo[200],
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.indigo[800],
                            shape: BoxShape.circle,
                          ),
                        ),
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          }
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        eventLoader: _getEventsForDay,
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            if (events.isNotEmpty) {
                              return Positioned(
                                right: 1,
                                bottom: 1,
                                child: _buildEventsMarker(date, events),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Text(
                    'Riwayat Presensi (${_selectedDay != null ? DateFormat('dd MMM').format(_selectedDay!) : ''})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (selectedEvents.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    alignment: Alignment.center,
                    child: Text(
                      'Tidak ada data presensi pada tanggal ini.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = selectedEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  item.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10.0),
                                          child: Image.network(
                                            item.imageUrl!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.error, size: 60),
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(10)
                                          ),
                                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                        ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.judul ?? 'Presensi',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('HH:mm').format(item.createdAt),
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(item.status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _getStatusColor(item.status).withValues(alpha: 0.5))
                                    ),
                                    child: Text(
                                      item.status ?? 'Hadir',
                                      style: TextStyle(
                                        color: _getStatusColor(item.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.deskripsi != null && item.deskripsi!.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(),
                                ),
                                Text(
                                  'Catatan: ${item.deskripsi}',
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: selectedEvents.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // padding for FAB
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/upload_foto').then((_) {
            // Refresh data when coming back
            setState(() {
               _fetchDatas();
            });
          });
        },
        backgroundColor: Colors.indigo[800],
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Presensi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List<Datas> events) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle().copyWith(
            color: Colors.white,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.green;
    switch (status.toLowerCase()) {
      case 'izin':
        return Colors.orange;
      case 'sakit':
        return Colors.red;
      case 'hadir':
      default:
        return Colors.green;
    }
  }
}
