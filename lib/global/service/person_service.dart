

import 'dart:convert';

import 'package:app_gerenciamento_cliente/global/dto/person_dto.dart';
import 'package:http/http.dart' as http;

class PersonService {
    final String apiUrl = "https://dev-api-plt.4asset.net.br/exam/v1";

    Future<int?> addPerson(PersonDTO person) async {
      try {
        final url = Uri.parse('$apiUrl/persons');
        final response = await http.post(url, body: person.toJson());
        if(response.statusCode == 200 || response.statusCode == 201) {
          final json = jsonDecode(response.body);
          return json['id'] as int?;
        } else {
          final json = jsonDecode(response.body);
          throw Exception('Erro: ${json['message'] ?? "Ocorreu um erro enquanto efetuava cadastro"}');
        }
      } on Exception catch (_) {
        rethrow;
      }
    }

    Future<bool> updatePerson(PersonDTO person) async {
      try {
        final url = Uri.parse('$apiUrl/persons/${person.id}');
        final response = await http.patch(url, body: person.toJson());
        if(response.statusCode == 200 || response.statusCode == 201) {
          return true;
        } else {
          final json = jsonDecode(response.body);
          throw Exception('Erro: ${json['message'] ?? "Ocorreu um erro enquanto efetuava edição"}');
        }
      } on Exception catch (_) {
        rethrow;
      }
    }

    Future<List<PersonDTO>> fetchPersons() async {
      try {
        final url = Uri.parse('$apiUrl/persons');
        final response = await http.get(url);
        if(response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final data = (json['results'] as List<dynamic>).cast<Map<String,dynamic>>();
          return data.map((item) => PersonDTO.fromJson(item)).toList();
        } else {
          throw Exception('Falha ao carregar dados');
        }
      } on Exception catch(e) {
        throw Exception('$e');
      }
    }

    Future<bool> deletePerson(int id) async {
      try {
        final url = Uri.parse('$apiUrl/persons/$id');
        final response = await http.delete(url);
        if(response.statusCode == 204 || response.statusCode == 200) {
          return true;
        } else {
          throw Exception('Falha na tentativa de deletar o cliente');
        }
      } on Exception catch(e) {
        throw Exception('$e');
      }
    }
}