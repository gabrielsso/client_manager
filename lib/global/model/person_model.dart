

import 'package:app_gerenciamento_cliente/global/dto/person_dto.dart';
import 'package:hive/hive.dart';

part 'person_model.g.dart';

@HiveType(typeId: 0)
class Person extends HiveObject {
  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String birthDate;

  @HiveField(5)
  int? serverId;

  @HiveField(6)
  bool isDeleted;

  @HiveField(7)
  bool isSynced;

  @HiveField(8)
  bool isValid;

  Person({
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    this.serverId,
    this.isDeleted = false,
    this.isSynced = false,
    this.isValid = true,
  });

  factory Person.fromDto(PersonDTO dto, {bool sync = false}) {
    return Person(
      name: dto.name ?? '',
      email: dto.email ?? '',
      phone: dto.phone ?? '',
      birthDate: dto.birthDate ?? '',
      serverId: dto.id,
      isDeleted: false,
      isSynced: sync,
      isValid: true,
    );
  }

  PersonDTO toDto() {
    return PersonDTO(
      id: serverId,
      name: name,
      email: email,
      birthDate: birthDate,
      phone: phone,
    );
  }

  copyWith({String? name, String? email, String? phone, String? birthDate, bool isSynced = false}) {
    return Person(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        birthDate: birthDate ?? this.birthDate,
        serverId: serverId,
        isSynced: isSynced,
        isDeleted: isDeleted,
        isValid: isValid
    );
  }

  updateData({String? name, String? email, String? phone, String? birthDate, bool isSynced = false}) {
    if (name != null && name.isNotEmpty) {
      this.name = name.trim();
    }
    if (email != null && email.contains('@')) {
      this.email = email;
    }
    if (phone != null && phone.length >= 10) {
      this.phone = phone;
    }
    if (birthDate != null) {
      this.birthDate = birthDate;
    }

    this.isSynced = isSynced;
  }

  equalToDto(PersonDTO person) {
    return email == person.email &&
        name == person.name &&
        phone == person.phone &&
        birthDate == person.birthDate;
  }

  flagInvalidPerson() {
    isValid = false;
  }
}