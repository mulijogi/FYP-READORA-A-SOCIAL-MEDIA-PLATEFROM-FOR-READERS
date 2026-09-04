import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readora/utils/custom_snackbar.dart';

class ChatController extends GetxController {
  final String chatRoomId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  var isLoading = false.obs;
  var allMessages = <Map<String, dynamic>>[].obs;

  // To keep track of raw documents for merging
  final Map<String, List<QueryDocumentSnapshot>> _rawDocs = {};

  ChatController(this.chatRoomId);

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool get isRecording => _recorder.isRecording;

  @override
  void onInit() {
    super.onInit();
    getMessages();
    getPosts();
    initializeRecorder();
    markAllAsRead();
  }

  Future<void> sendMessage(String message,
      {String? imageUrl,
      String? audioUrl,
      String? fileUrl,
      String? fileName}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final timestamp = DateTime.now();

    try {
      isLoading.value = true;
      String content;
      String messageType = 'text';

      if (imageUrl != null) {
        content = 'image:$imageUrl';
        messageType = 'image';
      } else if (audioUrl != null) {
        content = 'audio:$audioUrl';
        messageType = 'audio';
      } else if (fileUrl != null) {
        content = 'file:$fileUrl';
        messageType = 'file';
      } else {
        content = message;
      }

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'text': content,
        'senderId': currentUser.uid,
        'timesstamp': timestamp,
        'isRead': false,
        'type': 'messages',
        'messageType': messageType,
        if (fileName != null) 'fileName': fileName,
      });

      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage':
            messageType == 'text' ? message : 'Shared a $messageType',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      customSnackbar(title: "Error", message: "Failed to send message");
    } finally {
      isLoading.value = false;
    }
  }

  void getMessages() {
    _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timesstamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _updateCombinedList(snapshot.docs, 'messages');
    });
  }

  void getPosts() {
    _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('posts')
        .orderBy('timesstamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _updateCombinedList(snapshot.docs, 'posts');
    });
  }

  void _updateCombinedList(List<QueryDocumentSnapshot> docs, String type) {
    _rawDocs[type] = docs;

    List<Map<String, dynamic>> combined = [];
    _rawDocs.forEach((key, value) {
      for (var doc in value) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        // If it's from posts collection, ensure it has a type for rendering
        if (key == 'posts' && data['type'] == null) {
          data['type'] = 'post_share';
        }
        combined.add(data);
      }
    });

    // Sort by timestamp (descending)
    combined.sort((a, b) {
      var t1 = a['timesstamp'];
      var t2 = b['timesstamp'];
      if (t1 == null) return 1;
      if (t2 == null) return -1;
      return (t2 as Timestamp).compareTo(t1 as Timestamp);
    });

    allMessages.assignAll(combined);
  }

  Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Mark messages from friend as read
      final messagesSnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.update({'isRead': true});
      }

      // Mark posts from friend as read
      final postsSnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('posts')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in postsSnapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print("[ChatController] Error marking as read: $e");
    }
  }

  Future<void> pickImage() async {
    // Request permission first
    PermissionStatus status;
    if (await Permission.photos.status.isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }
    if (!status.isGranted) {
      customSnackbar(
          title: "Permission",
          message: "Storage permission denied. Please allow in settings.");
      return;
    }
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      File selectedImage = File(image.path);
      String? imageUrl = await uploadFile(selectedImage, 'chat_images');
      if (imageUrl != null) sendMessage('', imageUrl: imageUrl);
    }
  }

  Future<void> pickImageFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      customSnackbar(title: "Permission", message: "Camera permission denied.");
      return;
    }
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) {
      File selectedImage = File(image.path);
      String? imageUrl = await uploadFile(selectedImage, 'chat_images');
      if (imageUrl != null) sendMessage('', imageUrl: imageUrl);
    }
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);
        String fileName = result.files.single.name;
        String? fileUrl = await uploadFile(selectedFile, 'chat_files');
        if (fileUrl != null) {
          sendMessage('', fileUrl: fileUrl, fileName: fileName);
        }
      }
    } catch (e) {
      print("[ChatController] pickFile ERROR: $e");
      customSnackbar(
          title: "Error", message: "Unable to pick file. Please try again.");
    }
  }

  Future<String?> uploadFile(File file, String folder) async {
    try {
      print("[ChatController] Starting upload to $folder: ${file.path}");
      String filePath =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      var storageRef = _storage.ref(filePath);
      print("[ChatController] Storage path: $filePath");
      await storageRef.putFile(file);
      String downloadUrl = await storageRef.getDownloadURL();
      print("[ChatController] Upload SUCCESS: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("[ChatController] Upload ERROR: $e");
      customSnackbar(title: "Error", message: "Failed to upload file");
      return null;
    }
  }

  Future<void> initializeRecorder() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await _recorder.openRecorder();
      _isRecorderInitialized = true;
    } else {
      customSnackbar(
          title: "Permission", message: "Microphone permission denied.");
    }
  }

  Future<void> startRecording() async {
    try {
      if (_isRecorderInitialized) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
        print("[ChatController] Starting recorder to: $path");
        await _recorder.startRecorder(toFile: path);
      } else {
        print("[ChatController] Recorder NOT initialized!");
      }
    } catch (e) {
      print("[ChatController] startRecording ERROR: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      if (_isRecorderInitialized) {
        final path = await _recorder.stopRecorder();
        print("[ChatController] Recording stopped. Path: $path");
        if (path != null) {
          File audioFile = File(path);
          if (await audioFile.exists()) {
            String? audioUrl = await uploadFile(audioFile, 'audio_messages');
            if (audioUrl != null) {
              sendMessage('', audioUrl: audioUrl);
            }
          } else {
            print("[ChatController] Recorded file does NOT exist!");
          }
        }
      }
    } catch (e) {
      print("[ChatController] stopRecording ERROR: $e");
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      customSnackbar(title: "Success", message: "Message unsent");
    } catch (e) {
      customSnackbar(title: "Error", message: "Failed to delete message: $e");
    }
  }
}
