import 'package:cloud_firestore/cloud_firestore.dart';

class Trabajador {
  final String id;
  final String nombre;
  final String apellidos;
  final String dni;
  final String empresaId;
  final String telefono;
  final String email;
  final String password;
  final DateTime fechaContratacion;

  Trabajador({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.dni,
    required this.empresaId,
    required this.telefono,
    required this.email,
    required this.password,
    required this.fechaContratacion,
  });

  factory Trabajador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trabajador(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellidos: data['apellidos'] ?? '',
      dni: data['dni'] ?? '',
      empresaId: data['empresaId'] ?? '',
      telefono: data['telefono'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '123456',
      fechaContratacion: (data['fechaContratacion'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellidos': apellidos,
      'dni': dni,
      'empresaId': empresaId,
      'telefono': telefono,
      'email': email,
      'password': password,
      'fechaContratacion': Timestamp.fromDate(fechaContratacion),
    };
  }

  factory Trabajador.fromMap(Map<String, dynamic> map) {
    return Trabajador(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      apellidos: map['apellidos'] ?? '',
      dni: map['dni'] ?? '',
      empresaId: map['empresaId'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      fechaContratacion: (map['fechaContratacion'] as Timestamp).toDate(),
    );
  }
} 