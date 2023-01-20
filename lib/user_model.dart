
import 'dart:ui';

class UserModel {
  String name;
  String token;
  int id;
  String key;

  UserModel({required this.name, required this.token, required this.id, required this.key});

  factory UserModel.fromJson(dynamic json){
    return UserModel(
        name: json['name'],
        token: json['token'],
        id: json['id'],
        key: "",
    );
  }

  Map<String, dynamic>toJson(){
    return {
      'name': name,
      'token': token,
      'id': id,
      'key': key
    };
  }
}

class Log {
  String value;
  Color color;

  Log(this.value, this.color);
}