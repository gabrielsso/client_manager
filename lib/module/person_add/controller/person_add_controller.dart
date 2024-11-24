

import 'package:app_gerenciamento_cliente/global/dto/person_dto.dart';
import 'package:app_gerenciamento_cliente/global/extension/extension_date_time.dart';
import 'package:app_gerenciamento_cliente/global/model/person_model.dart';
import 'package:app_gerenciamento_cliente/global/repository/person_repository.dart';
import 'package:app_gerenciamento_cliente/global/shared/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PersonAddController extends GetxController {

  final PersonRepository _repository;

  final TextEditingController nomeTextController = TextEditingController();
  final TextEditingController emailTextController = TextEditingController();
  final TextEditingController telefoneTextController = TextEditingController();
  final TextEditingController nascimentoTextController = TextEditingController();
  ValueNotifier<DateTime?> nascimento = ValueNotifier(null as DateTime?);
  Person? personEdit;

  MaskTextInputFormatter telefoneMask = MaskTextInputFormatter(
    mask: "(##) #####-####",
    filter: {"#": RegExp(r'[0-9]')},
  );

  PersonAddController(this._repository);

  void loadInfo(Person data) {
    personEdit = data;
    nomeTextController.text = data.name;
    emailTextController.text = data.email;
    telefoneTextController.text = data.phone;
    telefoneMask.formatEditUpdate(telefoneTextController.value, telefoneTextController.value);
    final date = DateTime.parse(data.birthDate);
    nascimento.value = date;
    nascimentoTextController.text = date.formatDateFromIso;
  }

  void setDate(DateTime date) {
    nascimento.value = date;
    nascimentoTextController.text = date.formatDateFromIso;
  }

  bool validateEmail(String email) {
    String pattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  Future<void> sendPerson({required VoidCallback onSuccessCallback}) async {
    try {
      if(personEdit != null && personEdit!.serverId != null) {
        await _updatePerson(onSuccessCallback);
      } else {
        await _addPerson(onSuccessCallback);
      }
    } on Exception catch (e) {
      _handleMessageSnackbar('$e');
    }
  }

  Future<void> _addPerson(VoidCallback onSuccessCallback) async {
    final success = await _repository.addPerson(_buildPersonDTO(), personEdit?.key);
    _handleResponse(success, 'Cadastro realizado com sucesso', onSuccessCallback);
  }

  Future<void> _updatePerson(VoidCallback onSuccessCallback) async {
    final success = await _repository.updatePerson(personEdit!, _updatePersonData());
    _handleResponse(success, 'Edição realizada com sucesso', onSuccessCallback);
  }

  PersonDTO _buildPersonDTO({int? id}) {
    return PersonDTO(
      id: id,
      email: emailTextController.text,
      name: nomeTextController.text,
      phone: telefoneMask.getMaskedText(),
      birthDate: nascimento.value!.toUtc().toIso8601String(),
    );
  }

  Person _updatePersonData() {
    return personEdit!.copyWith(
      email: emailTextController.text,
      name: nomeTextController.text,
      phone: telefoneMask.getMaskedText(),
      birthDate: nascimento.value!.toUtc().toIso8601String(),
      isSynced: false
    );
  }

  void _handleResponse(bool success, String successMessage, VoidCallback onSuccessCallback) {
    if(success) {
      onSuccessCallback.call();
      _handleMessageSnackbar(successMessage);
    } else {
      _handleMessageSnackbar('Ocorreu um erro ao salvar os dados.');
    }
  }

  void _handleMessageSnackbar(String message) {
    showSnackbar(message: message);
  }
}