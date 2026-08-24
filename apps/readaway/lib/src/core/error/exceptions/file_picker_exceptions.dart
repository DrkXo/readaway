part of '../errors.dart';

/// Exception thrown when a file exceeds the maximum allowed size
class FileSizeException implements Exception {
  final String message;
  final int actualSize;
  final int maxSize;
  final String fileName;

  FileSizeException(this.message, this.actualSize, this.maxSize, this.fileName);

  @override
  String toString() => message;
}

/// Exception thrown when a file has an unsupported file extension
class FileTypeException implements Exception {
  final String message;
  final String fileExtension;
  final List<String> allowedExtensions;
  final String fileName;

  FileTypeException(
    this.message,
    this.fileExtension,
    this.allowedExtensions,
    this.fileName,
  );

  @override
  String toString() => message;
}

/// General exception for file picker errors
class FilePickerException implements Exception {
  final String message;

  FilePickerException(this.message);

  @override
  String toString() => message;
}
