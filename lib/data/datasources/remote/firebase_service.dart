import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/exceptions.dart' as app_exceptions;

/// Service for Firebase operations
abstract class FirebaseService {
  FirebaseAuth get auth;
  FirebaseFirestore get firestore;
  
  // Auth operations
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signUpWithEmail(String email, String password);
  Future<void> signOut();
  User? get currentUser;
  
  // Database operations
  Future<List<Map<String, dynamic>>> select(String collection, {Map<String, dynamic>? filters});
  Future<Map<String, dynamic>> insert(String collection, Map<String, dynamic> data);
  Future<Map<String, dynamic>> update(String collection, String id, Map<String, dynamic> data);
  Future<void> delete(String collection, String id);
  Future<Map<String, dynamic>?> getById(String collection, String id);
}

/// Implementation of [FirebaseService]
class FirebaseServiceImpl implements FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseServiceImpl(this._auth, this._firestore);

  @override
  FirebaseAuth get auth => _auth;

  @override
  FirebaseFirestore get firestore => _firestore;

  @override
  User? get currentUser => _auth.currentUser;
  
  @override
  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw app_exceptions.AuthException(message: e.message ?? 'Authentication failed');
    } catch (e) {
      throw app_exceptions.AuthException(message: e.toString());
    }
  }

  @override
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw app_exceptions.AuthException(message: e.message ?? 'Registration failed');
    } catch (e) {
      throw app_exceptions.AuthException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw app_exceptions.AuthException(message: e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> select(
    String collection, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.where(key, isEqualTo: value);
        });
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is included
        return data;
      }).toList();
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> insert(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      // If ID is provided in data, use it as document ID, otherwise generate one
      DocumentReference ref;
      if (data.containsKey('id') && data['id'] != null && (data['id'] as String).isNotEmpty) {
        ref = _firestore.collection(collection).doc(data['id']);
        await ref.set(data);
      } else {
        ref = await _firestore.collection(collection).add(data);
      }
      
      final snapshot = await ref.get();
      final resultData = snapshot.data() as Map<String, dynamic>;
      resultData['id'] = snapshot.id;
      return resultData;
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final ref = _firestore.collection(collection).doc(id);
      await ref.update(data);
      
      final snapshot = await ref.get();
      final resultData = snapshot.data() as Map<String, dynamic>;
      resultData['id'] = snapshot.id;
      return resultData;
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }

  @override
  Future<void> delete(String collection, String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      throw app_exceptions.ServerException(message: e.toString());
    }
  }
}
