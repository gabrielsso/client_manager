
import 'package:json_annotation/json_annotation.dart';

part 'person_dto.g.dart';

@JsonSerializable(includeIfNull: false)
class PersonDTO {
  final int? id;
  final String? email;
  final String? name;
  final String? phone;
  final String? birthDate;

  PersonDTO({this.id, this.email, this.name, this.phone, this.birthDate});

  /*factory PersonDTO.fromJson(Map<String, dynamic> json) =>
      PersonDTO(
        id: json['id'] as int?,
        email: json['email'] as String?,
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        birthDate: json['birthDate'] as String?
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'birthDate': birthDate,
  };*/

  factory PersonDTO.fromJson(Map<String, dynamic> json) => _$PersonDTOFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$PersonDTOToJson(this);
    json.remove('id');
    return json;
  }

}