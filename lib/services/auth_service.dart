import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registrar un nuevo trabajador
  Future<UserCredential> registerWorker({
    required String email,
    required String password,
    required String name,
    required String companyId,
    required String trabajadorId,
  }) async {
    try {
      // Crear el usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear el documento del usuario en Firestore
      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set({
        'email': email,
        'tipo': 'trabajador',
        'isActive': true,
        'empresaId': companyId,
        'trabajadorId': trabajadorId,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw Exception('Error al registrar trabajador: $e');
    }
  }

  // Iniciar sesión
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener datos del usuario actual desde Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return userDoc.data();
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  // Verificar si el usuario es administrador
  Future<bool> isAdmin() async {
    try {
      final userData = await getCurrentUserData();
      return userData?['tipo'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Verificar si el usuario es trabajador
  Future<bool> isWorker() async {
    try {
      final userData = await getCurrentUserData();
      return userData?['tipo'] == 'trabajador';
    } catch (e) {
      return false;
    }
  }

  // Obtener el ID de la empresa del usuario actual
  Future<String?> getCurrentUserCompanyId() async {
    try {
      final userData = await getCurrentUserData();
      return userData?['empresaId'];
    } catch (e) {
      return null;
    }
  }
} 