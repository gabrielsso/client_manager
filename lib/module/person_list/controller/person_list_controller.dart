import 'package:app_gerenciamento_cliente/global/model/person_model.dart';
import 'package:app_gerenciamento_cliente/global/repository/person_repository.dart';
import 'package:app_gerenciamento_cliente/global/shared/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

class PersonListController extends GetxController {

  final PersonRepository _repository;
  ValueNotifier<List<Person>> persons = ValueNotifier([]);
  ValueNotifier<bool> showLoading = ValueNotifier(false);

  PersonListController(this._repository);

  Future<void> startSyncData() async {
    try {
      final data = await _repository.syncDataOnline(
          onErrorCallback: (msg) {
            _handleMessageSnackbar(msg);
          }
      );
      if(data != null) {
        persons.value = data;
        _handleMessageSnackbar('Dados sincronizados');
      }
    } on Exception catch(e) {
      _handleMessageSnackbar('$e');
    }
  }

  Future<void> getPersons() async {
    try {
      showLoading.value = true;
      final result = await _repository.getPersons();
      persons.value = result;
    } on Exception catch(e) {
      _handleMessageSnackbar('$e');
    } finally {
      showLoading.value = false;
    }
  }

  Future<void> deletePerson(Person person) async {
    try {
      showLoading.value = true;
      final result = await _repository.deletePerson(person);
      if(result) {
        _handleMessageSnackbar('Cliente deletado com sucesso');
        getPersons();
      } else {
        _handleMessageSnackbar('Ocorreu um erro durante a exclusão do cliente');
      }
    } on Exception catch(e) {
      _handleMessageSnackbar('$e');
    } finally {
      showLoading.value = false;
    }
  }

  void _handleMessageSnackbar(String message) {
    showSnackbar(message: message);
  }
}