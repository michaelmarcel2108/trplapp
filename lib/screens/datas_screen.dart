// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

import 'package:trplapp/dto/datas.dart';
import 'package:trplapp/endpoints/endpoints.dart';

import 'package:trplapp/services/data_service.dart';

class DatasScreen extends StatefulWidget {
  const DatasScreen({Key? key}) : super(key: key);

  @override
  _DatasScreenState createState() => _DatasScreenState();
}
  
class _DatasScreenState extends State<DatasScreen> {
  Future<List<Datas>>? _datas;

  @override
  void initState() {
    super.initState();
    _datas = DataService.fetchDatas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data List'),
        leading: IconButton(
          icon: const Icon(Icons
              .arrow_back), // Customize icon (optional)// Customize color (optional)
          onPressed: () {
            // Your custom back button functionality here
            Navigator.pushReplacementNamed(
                context, '/'); // Default back button behavior
            // You can add additional actions here (e.g., show confirmation dialog)
          },
        ),
      ),
      body: FutureBuilder<List<Datas>>(
        future: _datas,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  title: item.imageUrl != null
                      ? Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                fit: BoxFit.fitWidth,
                                width: 350,
                                Uri.parse(
                                        '${Endpoints.baseURLLive}/public/${item.imageUrl!}')
                                    .toString(),
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons
                                        .error), // Display error icon if image fails to load
                              ),
                            ),
                          ],
                        )
                      : null,
                  subtitle: Column(
                      children: [Text('Name : ${item.name}'), const Divider()]),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
