import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      return result.files.first;
    }
    return null;
  }

  Future<String?> uploadFile({
    required PlatformFile file,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path).child(file.name);
      
      UploadTask uploadTask;
      
      if (file.bytes != null) {
        // Web or when bytes are available
        uploadTask = ref.putData(file.bytes!);
      } else if (file.path != null) {
        // Mobile / Desktop
        uploadTask = ref.putFile(File(file.path!));
      } else {
        return null;
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}
