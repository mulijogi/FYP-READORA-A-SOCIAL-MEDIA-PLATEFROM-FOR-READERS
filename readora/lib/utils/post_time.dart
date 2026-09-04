import 'package:cloud_firestore/cloud_firestore.dart';

class PostTime {
  
  static String timeAgo(dynamic timestamp) {
    if (timestamp == null) {
      return "Just now";
    }

    DateTime postDate;
    if (timestamp is Timestamp) {
      postDate = timestamp.toDate();
    } else if (timestamp is DateTime) {
      postDate = timestamp;
    } else if (timestamp is int) {
      if (timestamp.toString().length <= 10) {
        postDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        postDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } else if (timestamp is String) {
      final parsedInt = int.tryParse(timestamp);
      if (parsedInt != null) {
        if (parsedInt.toString().length <= 10) {
          postDate = DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000);
        } else {
          postDate = DateTime.fromMillisecondsSinceEpoch(parsedInt);
        }
      } else {
        final parsedDate = DateTime.tryParse(timestamp);
        if (parsedDate != null) {
          postDate = parsedDate;
        } else {
          return "Just now";
        }
      }
    } else {
      return "Just now";
    }

    DateTime now = DateTime.now();
    Duration difference = now.difference(postDate);

    if (difference.inDays >= 30) {
      int months = (difference.inDays / 30).floor();
      return "$months month${months > 1 ? 's' : ''} ago";
    } else if (difference.inDays >= 7) {
      int weeks = (difference.inDays / 7).floor();
      return "$weeks week${weeks > 1 ? 's' : ''} ago";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }

}
