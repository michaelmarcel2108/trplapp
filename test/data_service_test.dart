import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trplapp/services/data_service.dart';
import 'package:trplapp/dto/datas.dart';

void main() {
  group('DataService', () {
    test('fetchDatas returns list of Datas on success', () async {
      // Arrange
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/rest/v1/presensi')) {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'name': 'Test User',
                'judul': 'Hadir',
                'status': 'Hadir',
                'created_at': '2023-10-27T10:00:00Z'
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      // Act
      final result = await DataService.fetchDatas(client: mockClient);

      // Assert
      expect(result, isA<List<Datas>>());
      expect(result.length, 1);
      expect(result.first.name, 'Test User');
    });

    test('fetchDatas throws exception on failure', () async {
      // Arrange
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      // Act & Assert
      expect(
        () async => await DataService.fetchDatas(client: mockClient),
        throwsException,
      );
    });
  });
}
