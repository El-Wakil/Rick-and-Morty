import 'package:dio/dio.dart';
import '../models/character.dart';
import '../models/api_response.dart';

class RickAndMortyService {
  static const String baseUrl = 'https://rickandmortyapi.com/api';
  late final Dio _dio;

  RickAndMortyService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Add interceptors for logging (optional)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj),
      ),
    );
  }

  Future<List<Character>> getAllCharacters({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/character',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(response.data);
        return apiResponse.results
            .map((json) => Character.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load characters');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Character> getCharacterById(int id) async {
    try {
      final response = await _dio.get('/character/$id');

      if (response.statusCode == 200) {
        return Character.fromJson(response.data);
      } else {
        throw Exception('Failed to load character');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<Character>> searchCharacters({
    String? name,
    String? status,
    String? species,
    String? gender,
    int page = 1,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page};

      if (name != null && name.isNotEmpty) queryParameters['name'] = name;
      if (status != null && status.isNotEmpty)
        queryParameters['status'] = status;
      if (species != null && species.isNotEmpty)
        queryParameters['species'] = species;
      if (gender != null && gender.isNotEmpty)
        queryParameters['gender'] = gender;

      final response = await _dio.get(
        '/character',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(response.data);
        return apiResponse.results
            .map((json) => Character.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to search characters');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return []; // No characters found
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<ApiResponse> getCharactersWithPagination({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/character',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load characters');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
