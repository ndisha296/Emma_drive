import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService({FirebaseStorage? storage});

  /// Encodes waste item image as a compressed base64 data URI.
  /// This stores directly in Firestore, requiring $0 payment and no Cloud Storage bucket.
  Future<String> uploadWasteItemImage({
    required String driveId,
    required String submissionId,
    required XFile imageFile,
  }) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  /// Encodes profile image as a base64 data URI.
  Future<String> uploadProfileImage({
    required String uid,
    required XFile imageFile,
  }) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}
