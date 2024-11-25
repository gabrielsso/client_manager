

import 'dart:io';

import 'package:app_gerenciamento_cliente/global/constants.dart';
import 'package:app_gerenciamento_cliente/global/dto/person_dto.dart';
import 'package:app_gerenciamento_cliente/global/model/person_model.dart';
import 'package:app_gerenciamento_cliente/global/service/person_service.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PersonRepository extends GetxService {
    final PersonService service = PersonService();

    Future<List<Person>?> syncDataOnline({
      required Function(String) onErrorCallback
    }) async {
      final box = await Hive.openBox<Person>(hiveBoxName);
      if(box.isNotEmpty && await isConnected()) {
        await _handleUnsyncedData(box, onErrorCallback);
        await _handlePendingDeleteData(box, onErrorCallback);
        await _handleUpdateDataWithServer(box);

        return box.values.toList();
      }
      return null;
    }

    Future<void> _handleUnsyncedData(Box box, Function(String) onErrorCallback) async {
      final unsyncedData = box.values.where((person) => !person.isSynced && !person.isDeleted && person.isValid);

      for (var person in unsyncedData) {
        if (person.serverId == null) {
          try {
            final serverId = await service.addPerson(person.toDto());
            if (serverId != null) {
              person.isSynced = true;
              person.serverId = serverId;
              await box.put(person.key, person);
            } else {
              person.flagInvalidPerson();
              await box.put(person.key, person);
              onErrorCallback.call('Erro ao adicionar ${person.name}');
            }
          } on Exception catch(e) {
            person.flagInvalidPerson();
            await box.put(person.key, person);
            onErrorCallback.call(
                'Ocorreu um erro durante a sincronização de dados pendentes: ${person.name}'
            );
          }
        } else {
          try {
            final success = await service.updatePerson(person.toDto());
            if (success) {
              person.isSynced = true;
              await box.put(person.key, person);
            } else {
              person.flagInvalidPerson();
              await box.put(person.key, person);
              onErrorCallback.call('Erro ao editar ${person.name}');
            }
          } on Exception catch(e) {
            person.flagInvalidPerson();
            await box.put(person.key, person);
            onErrorCallback.call(
                'Ocorreu um erro durante a sincronização de dados pendentes: ${person.name}'
            );
          }
        }
      }
    }

    Future<void> _handlePendingDeleteData(Box box, Function(String) onErrorCallback) async {
      final personsToDelete = box.values.where((person) => person.isDeleted && person.serverId != null);
      for (var person in personsToDelete) {
        final success = await service.deletePerson(person.serverId!);
        if(success) {
          await box.delete(person.key);
        } else {
          onErrorCallback.call('Erro ao excluir ${person.name}');
        }
      }
    }

    Future<void> _handleUpdateDataWithServer(Box box) async {
      final serverData = await service.fetchPersons();
      for (var serverPerson in serverData) {
        final personExist = box.values.any(
          (person) => person.serverId == serverPerson.id && person.isValid
        );

        if (!personExist) {
          await box.add(Person.fromDto(serverPerson, sync: true));
        } else {
          final existingPerson = box.values.firstWhere(
                  (person) => person.serverId == serverPerson.id
          );
          if(!existingPerson.equalToDto(serverPerson)) {
            existingPerson.updateData(
                email: serverPerson.email,
                name: serverPerson.name,
                phone: serverPerson.phone,
                birthDate: serverPerson.birthDate,
                isSynced: true
            );
            await box.put(existingPerson.key, existingPerson);
          }
        }
      }
    }

    Future<bool> addPerson(PersonDTO data, int? keyOriginal) async {
      final box = await Hive.openBox<Person>(hiveBoxName);
      final personLocal = Person.fromDto(data);
      int keyLocal;
      if(keyOriginal != null) {
        keyLocal = keyOriginal;
        await box.put(keyOriginal, personLocal);
      } else {
        keyLocal = await box.add(personLocal);
      }
      if(await isConnected()) {
        try {
          final success = await service.addPerson(data);
          if(success != null) {
            personLocal.isSynced = true;
            personLocal.isValid = true;
            personLocal.serverId = success;
            await box.put(personLocal.key, personLocal);
          }
        } on Exception catch (_) {
          if(keyOriginal == null) {
            await box.delete(keyLocal);
          } else {
            personLocal.flagInvalidPerson();
            await box.put(keyOriginal, personLocal);
          }
          throw Exception(
              'Ocorreu um erro durante a tentativa de salvar o cliente: ${personLocal.name}'
          );
        }
      }

      return true;
    }

    Future<bool> updatePerson(Person originalData, Person newData) async {
      final box = await Hive.openBox<Person>(hiveBoxName);

      final keyOriginal = originalData.key;

      await box.put(originalData.key, newData);

      try {
        if(await isConnected()) {
          final success =  await service.updatePerson(newData.toDto());
          if(success) {
            newData.isValid = true;
            newData.isSynced = true;
            await box.put(keyOriginal, newData);
          } else {
            await box.put(keyOriginal, originalData);
            return false;
          }
        } else {
          newData.isSynced = false;
          await box.put(keyOriginal, newData);
        }

        return true;
      } on Exception catch(_) {
        await box.put(keyOriginal, originalData);
        throw Exception(
            'Ocorreu um erro durante a tentativa de atualização do cliente: ${originalData.name}'
        );
      }
    }

    Future<List<Person>> getPersons() async {
        final box = await Hive.openBox<Person>(hiveBoxName);
        if(box.isNotEmpty) {
          return box.values.where((person) => !person.isDeleted).toList();
        } else {
          var data = <PersonDTO>[];
          if(await isConnected()) {
            data = await service.fetchPersons();
          }
          return await syncPersonOnHive(data);
        }
    }

    Future<bool> deletePerson(Person person) async {
      final box = await Hive.openBox<Person>(hiveBoxName);
      if(person.serverId == null) {
        await box.delete(person.key);
      } else {
        if(await isConnected()) {
          final success = await service.deletePerson(person.serverId!);
          if(success) {
            await box.delete(person.key);
            return true;
          } else {
            return false;
          }
        } else {
          if(!person.isDeleted) {
            person.isDeleted = true;
            await box.put(person.key, person);
          }
        }
      }

      return true;
    }

    Future<List<Person>> syncPersonOnHive(List<PersonDTO> data) async {
      final box = await Hive.openBox<Person>(hiveBoxName);
      List<Person> syncedPersons = [];

      for (var person in data) {
        final personLocal = Person.fromDto(person, sync: true);
        box.add(personLocal);
        syncedPersons.add(personLocal);
      }

      return syncedPersons;
    }

    Future<bool> isConnected() async {
      try {
        final result = await InternetAddress.lookup('example.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (e) {
        return false;
      }
    }
}