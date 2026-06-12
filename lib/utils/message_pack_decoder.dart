/**
 * MessagePack Binary Decoder Utility
 * 
 * Provides binary decoding for WebSocket messages to improve performance.
 * MessagePack is ~50-70% smaller than JSON and 5-10x faster to parse.
 */

import 'dart:typed_data';
import 'package:messagepack/messagepack.dart';

class MessagePackDecoder {
  /// Check if data is binary (MessagePack) format
  /// WebSocket messages can be either String (JSON) or Uint8List (binary)
  static bool isBinaryMessage(dynamic message) {
    return message is Uint8List || message is List<int>;
  }

  /// Decode MessagePack binary data to Dart object
  /// Handles the array-of-arrays structure from trade engine
  /// Returns null if decoding fails (fallback to JSON)
  static dynamic decodeBinary(Uint8List binaryData) {
    if (binaryData.isEmpty) return null;
    try {
      final unpacker = Unpacker(binaryData);
      final firstByte = binaryData[0];
      
      // Determine if it's a map or list based on header byte:
      // fixmap (0x80 - 0x8f), map 16 (0xde), map 32 (0xdf)
      if ((firstByte >= 0x80 && firstByte <= 0x8f) || firstByte == 0xde || firstByte == 0xdf) {
        return unpacker.unpackMap();
      }
      
      // Default / fallback to unpacking as list
      return unpacker.unpackList();
    } catch (e) {
      print('⚠️ MessagePack: Decoding error: $e');
      return null;
    }
  }

  /// Decode WebSocket message (handles both JSON and binary)
  /// Returns decoded data or null if both formats fail
  static dynamic decodeWebSocketMessage(dynamic message) {
    // Check if message is binary (MessagePack)
    if (isBinaryMessage(message)) {
      final binaryData = message is Uint8List 
          ? message 
          : Uint8List.fromList(message as List<int>);
      
      final decoded = decodeBinary(binaryData);
      if (decoded != null) {
        return decoded;
      }
      // If binary decoding fails, return null (caller should handle)
      print('⚠️ MessagePack: Binary decode failed, message might be corrupted');
      return null;
    }
    
    // Message is JSON string - return as-is for JSON parsing
    return message;
  }

  /// Get message format type for debugging
  static String getMessageFormat(dynamic message) {
    if (isBinaryMessage(message)) {
      return 'binary (MessagePack)';
    } else if (message is String) {
      return 'JSON';
    } else {
      return 'unknown';
    }
  }

  /// Get message size for performance monitoring
  static Map<String, dynamic> getMessageSize(dynamic message) {
    if (isBinaryMessage(message)) {
      final binaryData = message is Uint8List 
          ? message 
          : Uint8List.fromList(message as List<int>);
      return {
        'format': 'binary',
        'size': binaryData.length,
        'sizeKB': (binaryData.length / 1024).toStringAsFixed(2),
      };
    } else if (message is String) {
      final utf8Bytes = message.codeUnits.length * 2; // Approximate
      return {
        'format': 'JSON',
        'size': utf8Bytes,
        'sizeKB': (utf8Bytes / 1024).toStringAsFixed(2),
      };
    }
    return {'format': 'unknown', 'size': 0, 'sizeKB': '0.00'};
  }
}

