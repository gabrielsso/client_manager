
import 'dart:ffi';
import 'dart:math';

import 'package:app_gerenciamento_cliente/global/constants.dart';
import 'package:app_gerenciamento_cliente/global/dto/person_dto.dart';
import 'package:app_gerenciamento_cliente/global/model/person_model.dart';
import 'package:app_gerenciamento_cliente/global/repository/person_repository.dart';
import 'package:app_gerenciamento_cliente/global/service/person_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mocktail/mocktail.dart';

class MockService extends Mock implements PersonService {}
class MockBox<T> extends Mock implements Box<T> {}
class MockPersonRepository extends Mock implements PersonRepository {}
class MockHiveInterface extends Mock implements HiveInterface {}

void main() {
  late MockService mockService;
  late MockBox<Person> mockBox;
  late MockPersonRepository mockRepository;
  late MockHiveInterface mockHive;

  setUp(() async {
    await setUpTestHive();
    mockHive = MockHiveInterface();
    mockService = MockService();
    mockBox = MockBox<Person>();
    mockRepository = MockPersonRepository();
    when(() => mockHive.openBox(any())).thenAnswer((_) async => mockBox);
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  test('Deve mockar corretamente o Hive.openBox', () async {
    final box = await mockHive.openBox('person');

    verify(() => mockHive.openBox('person')).called(1);

    expect(box, mockBox);
  });

  group('getPersons', () {
    test('Deve retornar a lista de pessoas presentes no Hive quando não estiver vazia', () async {
      final persons = [
        Person(name: 'Alice', isDeleted: false, email: 'alice@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z'),
        Person(name: 'Bob', isDeleted: true, email: 'bob@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z'),
      ];
      when(() => mockBox.isNotEmpty).thenReturn(true);
      when(() => mockHive.openBox('person')).thenAnswer((_) async => mockBox);
      when(() => mockBox.values).thenReturn(persons);

      final data = mockBox.values.where((person) => !person.isDeleted).toList();

      expect(mockBox.isNotEmpty, isTrue);
      expect(mockBox.values.toList(), isNotEmpty);
      expect(data.length, 1);
      expect(data.first.name, 'Alice');
    });

    test('Deve retornar uma lista vazia quando não houver dados no Hive e o dispositivo estiver sem conexão', () async {
      when(() => mockBox.isNotEmpty).thenReturn(false);
      when(() => mockBox.values).thenReturn([]);
      when(() => mockRepository.isConnected()).thenAnswer((_) async => false);
      when(() => mockRepository.getPersons()).thenAnswer((_) async => []);

      expect(mockBox.isNotEmpty, isFalse);
      expect(mockBox.values.toList(), isEmpty);
      expect(await mockRepository.isConnected(), isFalse);
      expect(await mockRepository.getPersons(), isEmpty);

      verify(() => mockRepository.getPersons()).called(1);
    });

    test('Deve retornar uma lista de pessoas do serviço quando não houver dados no Hive e o dispositivo estiver conectado à internet', () async {
      final dtoList = [ PersonDTO(id: 1, name: 'Alice', email: 'alice@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z') ];
      final persons = <Person>[];
      when(() => mockBox.isNotEmpty).thenReturn(false);
      when(() => mockService.fetchPersons()).thenAnswer((_) async => dtoList);
      when(() => mockRepository.syncPersonOnHive(dtoList)).thenAnswer((_) async => dtoList.map((person) => Person.fromDto(person, sync: true)).toList());

      expect(mockBox.isNotEmpty, isFalse);
      final fetchedPersons = await mockService.fetchPersons();
      expect(fetchedPersons, isNotEmpty);
      expect(fetchedPersons.first.name, 'Alice');

      persons.addAll(await mockRepository.syncPersonOnHive(fetchedPersons));
      expect(persons.length, 1);
      expect(persons.first.name, 'Alice');
      verify(() => mockService.fetchPersons()).called(1);
      verify(() => mockRepository.syncPersonOnHive(dtoList)).called(1);
    });
  });

  group('addPerson', () {
    test('Deve adicionar um cliente ao Hive mesmo sem conexão com a internet', () async {
      final personDto = PersonDTO(
          id: null,
          name: 'Alice',
          email: 'alice@mail.com',
          phone: '(27)99999-9999',
          birthDate: '2024-11-21T00:00:00Z'
      );
      final persons = <Person>[];

      when(() => mockRepository.isConnected()).thenAnswer((_) async => false);
      when(() => mockRepository.addPerson(personDto, null)).thenAnswer((_) async => true);

      expect(await mockRepository.isConnected(), false, reason: 'Deveria não está conectado a internet');
      expect(persons, isEmpty, reason: 'A lista de pessoas deve começar vazia.');

      final result = await mockRepository.addPerson(personDto, null);
      expect(result, true, reason: 'A adição da pessoa deve retornar true.');

      persons.add(Person.fromDto(personDto));
      expect(
          persons,
          isNotEmpty,
          reason: 'A lista de pessoas não deve estar vazia após adicionar uma pessoa.'
      );

      expect(
          persons.length,
          1,
          reason: 'A lista deve conter exatamente uma pessoa.'
      );
      expect(
        persons.first.name,
        equals('Alice'),
        reason: 'O nome da pessoa adicionada deve ser Alice.',
      );
      expect(
        persons.first.serverId,
        equals(null),
        reason: 'A pessoa só foi adicionada localmente',
      );

      verify(() => mockRepository.addPerson(personDto, null)).called(1);
    });

    test('Deve adicionar um cliente ao Hive com o ID retornado pelo servidor quando o dispositivo estiver conectado', () async {
      final personDto = PersonDTO(
          id: null,
          name: 'Alice',
          email: 'alice@mail.com',
          phone: '(27)99999-9999',
          birthDate: '2024-11-21T00:00:00Z'
      );
      final persons = <Person>[];

      when(() => mockRepository.isConnected()).thenAnswer((_) async => true);
      when(() => mockService.addPerson(personDto)).thenAnswer((_) async => 200);
      when(() => mockRepository.addPerson(personDto, null)).thenAnswer((_) async => true);

      final isConnected = await mockRepository.isConnected();
      expect(isConnected, isTrue, reason: 'Necessita de conexão a internet para adicionar o cliente no servidor');

      expect(personDto.id, isNull, reason: 'O cliente não foi salvo no servidor ainda');
      expect(persons, isEmpty, reason: 'A lista de pessoas deve começar vazia.');

      final serverId = await mockService.addPerson(personDto);
      expect(serverId, isNotNull, reason: 'O servidor deve retornar um id caso tenha dado sucesso');

      final result = await mockRepository.addPerson(personDto, null);
      expect(result, true, reason: 'A adição da pessoa deve retornar true.');

      final personLocal = Person.fromDto(personDto);
      personLocal.serverId = serverId;

      persons.add(personLocal);
      expect(
          persons,
          isNotEmpty,
          reason: 'A lista de pessoas não deve estar vazia após adicionar uma pessoa.'
      );
      expect(
          persons.length,
          1,
          reason: 'A lista deve conter exatamente uma pessoa.'
      );
      expect(
        persons.first.name,
        equals('Alice'),
        reason: 'O nome da pessoa adicionada deve ser Alice.',
      );
      expect(
        persons.first.serverId,
        equals(200),
        reason: 'A pessoa foi adicionada no servidor.',
      );


      verify(() => mockRepository.isConnected()).called(1);
      verify(() => mockService.addPerson(personDto)).called(1);
      verify(() => mockRepository.addPerson(personDto, null)).called(1);
    });

    test('Deve retornar um erro de duplicidade ao tentar adicionar um email já cadastrado', () async {
      final personDto = PersonDTO(
          id: null,
          name: 'Alice',
          email: 'alice@mail.com',
          phone: '(27)99999-9999',
          birthDate: '2024-11-21T00:00:00Z'
      );

      when(() => mockRepository.isConnected()).thenAnswer((_) async => true);
      when(() => mockService.addPerson(personDto)).thenThrow( Exception('Erro: Email already taken'));

      final isConnected = await mockRepository.isConnected();
      expect(isConnected, isTrue, reason: 'Necessita de conexão a internet para adicionar o cliente no servidor');

      try {
        await mockService.addPerson(personDto);
        fail('O serviço deveria ter lançado uma exceção');
      } catch (e) {
        expect(e, isA<Exception>(), reason: 'Esperado erro de tipo Exception');
        expect(e.toString(), contains('Erro: Email already taken'), reason: 'Erro específico esperado');
      }

      verify(() => mockRepository.isConnected()).called(1);
      verify(() => mockService.addPerson(personDto)).called(1);
    });
  });

  group('deletePerson', () {
    test('Deve excluir a pessoa localmente porque não foi enviada para o servidor', () async {
      final persons = [
        Person(name: 'Alice', isDeleted: false, email: 'alice@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z'),
        Person(name: 'Bob', isDeleted: true, email: 'bob@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z', serverId: 100),
      ];

      when(() => mockBox.values).thenReturn(persons);
      when(() => mockRepository.deletePerson(persons.first)).thenAnswer((_) async => true);

      final data = mockBox.values.toList();
      final personToDelete = data.first;
      expect(data.length, equals(2), reason: 'A lista deve ter dois clientes cadastrados');
      expect(personToDelete.serverId, equals(null), reason: 'O cliente foi cadastrado localmente não deveria ter um serverId');
      expect(personToDelete.name, equals('Alice'), reason: 'O cliente deve ser Alice pois ela foi cadastrada localmente');

      final resultDelete = await mockRepository.deletePerson(personToDelete);
      expect(resultDelete, isTrue, reason: 'Deve deletar o cliente desejado');

      data.remove(personToDelete);
      expect(data.length, 1, reason: 'A lista deve ter somente um pois Alice foi deletada');
      expect(data.first.serverId, isNotNull, reason: 'O cliente restante deve ser Bob');
      expect(data.first.name, equals('Bob'), reason: 'O cliiente restante deve ser Bob');

      verify(() => mockRepository.deletePerson(personToDelete)).called(1);
    });

    test('Deve marcar a pessoa como para ser deletada porque não há conexão e ela já foi sincronizada com o servidor', () async {
      final persons = [
        Person(name: 'Alice', isDeleted: false, email: 'alice@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z', serverId: 200, isSynced: true),
        Person(name: 'Bob', isDeleted: true, email: 'bob@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z', serverId: 100, isSynced: true),
      ];
      when(() => mockRepository.isConnected()).thenAnswer((_) async => false);
      when(() => mockBox.values).thenReturn(persons);
      when(() => mockRepository.deletePerson(persons.first)).thenAnswer((_) async => true);

      final isConnected = await mockRepository.isConnected();
      expect(isConnected, isFalse, reason: 'O dispositivo deve está sem conexão');

      var data = mockBox.values.toList();
      final personToDelete = data.first;
      expect(data.length, equals(2), reason: 'A lista deve ter dois clientes cadastrados');
      expect(personToDelete.serverId, isNotNull, reason: 'O cliente foi sincronizado com o servidor então deveria ter um serverId');
      expect(personToDelete.name, equals('Alice'), reason: 'O cliente deve ser Alice');
      expect(personToDelete.isDeleted, isFalse, reason: 'O cliente não foi marcado ainda para deletar');

      final resultDelete = await mockRepository.deletePerson(personToDelete);
      expect(resultDelete, isTrue, reason: 'Deve marcar o cliente desejado para deletar na próxima sincronização');

      data = data.map((person) {
        if(person.serverId == 200) {
          person.isDeleted = true;
        }
        return person;
      }).toList();

      expect(data.length, 2, reason: 'A lista deve manter os dois clientes');
      expect(data.where((person) => person.isDeleted).length, 2, reason: 'A lista deve ter dois clientes marcados para ser removidos');
      expect(data.first.serverId, isNotNull, reason: 'O cliente deve estar com o serverId');
      expect(data.first.isDeleted, isTrue, reason: 'O cliente deve está marcado para ser deletado');
      expect(data.first.name, equals('Alice'), reason: 'O cliente deve ser Alice');

      verify(() => mockRepository.isConnected()).called(1);
      verify(() => mockRepository.deletePerson(personToDelete)).called(1);
    });

    test('Deve deletar a pessoa localmente e no servidor', () async {
      final persons = [
        Person(name: 'Alice', isDeleted: false, email: 'alice@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z', serverId: 200, isSynced: true),
        Person(name: 'Bob', isDeleted: true, email: 'bob@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z', serverId: 100, isSynced: true),
      ];
      when(() => mockRepository.isConnected()).thenAnswer((_) async => true);
      when(() => mockBox.values).thenReturn(persons);
      when(() => mockRepository.deletePerson(persons.first)).thenAnswer((_) async => true);

      final isConnected = await mockRepository.isConnected();
      expect(isConnected, isTrue, reason: 'O dispositivo deve está com conexão');

      var data = mockBox.values.toList();
      final personToDelete = data.first;
      expect(data.length, equals(2), reason: 'A lista deve ter dois clientes cadastrados');
      expect(personToDelete.serverId, isNotNull, reason: 'O cliente foi sincronizado com o servidor então deveria ter um serverId');
      expect(personToDelete.name, equals('Alice'), reason: 'O cliente deve ser Alice');

      final resultDelete = await mockRepository.deletePerson(personToDelete);
      expect(resultDelete, isTrue, reason: 'Deve remover o cliente da lista');

      data.remove(personToDelete);

      expect(data.length, 1, reason: 'O cliente deveria ter sido removido');
      expect(data.first.serverId, isNotNull, reason: 'O cliente restante deve ser Bob pois Alice foi removida');
      expect(data.first.isDeleted, isTrue, reason: 'O cliente Bob deve ainda está marcado para ser removido na próxima sincronização');
      expect(data.first.name, equals('Bob'), reason: 'O cliente deve ser Bob');

      verify(() => mockRepository.isConnected()).called(1);
      verify(() => mockRepository.deletePerson(personToDelete)).called(1);
    });
  });

  group('editPerson', () {
    test('Deve editar um cliente no Hive e marcar como não sincronizado quando o dispositivo estiver sem conexão', () async {
      final persons = [
        Person(name: 'Alice', isDeleted: false, email: 'alice@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z', serverId: 200, isSynced: true),
        Person(name: 'Bob', isDeleted: true, email: 'bob@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z', serverId: 100, isSynced: true),
      ];
      when(() => mockRepository.isConnected()).thenAnswer((_) async => false);
      when(() => mockBox.values).thenReturn(persons);

      final isConnected = await mockRepository.isConnected();
      expect(isConnected, isFalse, reason: 'O dispositivo deve está sem conexão');
      
      List<Person> data = mockBox.values.toList();
      Person personEdit = data.first;
      personEdit.updateData(
        email: 'alice2@mail.com',
        phone: '(27) 47548-5984',
      );
      
      when(() => mockRepository.updatePerson(data.first, personEdit)).thenAnswer((_) async => true);
      final result = await mockRepository.updatePerson(data.first, personEdit);
      expect(result, isTrue, reason: 'A alteração deve dar sucesso e modificar os dados do cliente');

      data = data.map((person) {
        if(person.key == personEdit.key) {
          return personEdit;
        } else {
          return person;
        }
      }).toList();
      
      expect(data.first.email, equals('alice2@mail.com'), reason: 'O cliente deveria ter tido as informações alteradas');
      expect(data.first.phone, equals('(27) 47548-5984'), reason: 'O cliente deveria ter tido as informações alteradas');
      expect(data.first.isSynced, isFalse, reason: 'O cliente deve ter alterações pendentes');

      verify(() => mockRepository.isConnected()).called(1);
      verify(() => mockRepository.updatePerson(data.first, personEdit)).called(1);
    });

    test('Deve editar um cliente no Hive e marcar como sincronizado quando houver conexão com a internet', () async {
      final persons = [
        Person(name: 'Alice', isDeleted: false, email: 'alice@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z', serverId: 200, isSynced: true),
        Person(name: 'Bob', isDeleted: true, email: 'bob@mail.com', phone: '(27)99999-9999', birthDate: '2024-11-21T00:00:00Z', serverId: 100, isSynced: true),
      ];
      when(() => mockRepository.isConnected()).thenAnswer((_) async => true);
      when(() => mockBox.values).thenReturn(persons);

      final isConnected = await mockRepository.isConnected();
      expect(isConnected, isTrue, reason: 'O dispositivo deveria ter conexão');

      List<Person> data = mockBox.values.toList();
      Person personEdit = data.first;
      personEdit.updateData(
        email: 'alice2@mail.com',
        phone: '(27) 47548-5984',
        isSynced: true
      );

      when(() => mockRepository.updatePerson(data.first, personEdit)).thenAnswer((_) async => true);
      final result = await mockRepository.updatePerson(data.first, personEdit);
      expect(result, isTrue, reason: 'A alteração deve dar sucesso e modificar os dados do cliente');

      data = data.map((person) {
        if(person.key == personEdit.key) {
          return personEdit;
        } else {
          return person;
        }
      }).toList();

      expect(data.first.email, equals('alice2@mail.com'), reason: 'O cliente deveria ter tido as informações alteradas');
      expect(data.first.phone, equals('(27) 47548-5984'), reason: 'O cliente deveria ter tido as informações alteradas');
      expect(data.first.isSynced, isTrue, reason: 'O cliente deve ter alterações sincronizada');

      verify(() => mockRepository.isConnected()).called(1);
      verify(() => mockRepository.updatePerson(data.first, personEdit)).called(1);
    });

    test('Deve retornar um erro de email duplicado ao tentar editar um cliente com email já cadastrado', () async {
      final personDto = PersonDTO(
          id: null,
          name: 'Alice',
          email: 'bob@mail.com',
          phone: '(27) 47548-5984',
          birthDate: '2024-11-21T00:00:00Z'
      );
      when(() => mockRepository.isConnected()).thenAnswer((_) async => true);
      when(() => mockService.updatePerson(personDto)).thenThrow( Exception('Erro: Email already taken'));

      final isConnected = await mockRepository.isConnected();
      expect(isConnected, isTrue, reason: 'Necessita de conexão a internet para adicionar o cliente no servidor');

      try {
        await mockService.updatePerson(personDto);
        fail('O serviço deveria ter lançado uma exceção');
      } catch (e) {
        expect(e, isA<Exception>(), reason: 'Esperado erro de tipo Exception');
        expect(e.toString(), contains('Erro: Email already taken'), reason: 'Erro específico esperado');
      }

      verify(() => mockRepository.isConnected()).called(1);
      verify(() => mockService.updatePerson(personDto)).called(1);
    });

  });
}
