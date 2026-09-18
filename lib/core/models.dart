import 'util.dart';

class AppUser {
  const AppUser({required this.uid, required this.name, required this.email});
  final String uid, name, email;
}

enum FileStatus { unprocessed, queued, processing, ready, failed }

/// One section of an indexed course file. Retrieval works on chunks, so a
/// study turn only sends the sections that matter.
class Chunk {
  const Chunk({
    required this.fileId,
    required this.fileName,
    required this.heading,
    required this.text,
  });
  final String fileId, fileName, heading, text;
  int get tokens => estimateTokens(heading) + estimateTokens(text);
}

class CourseFile {
  CourseFile({
    required this.id,
    required this.courseId,
    required this.name,
    required this.kind,
    required this.sourceTokens,
  });

  final String id, courseId, name;

  /// 'pdf' | 'slides' | 'assignment' | 'page'
  final String kind;

  /// Size of the full file once extracted, which is what a student would paste into
  /// a chatbot without Zakerly.
  final int sourceTokens;

  FileStatus status = FileStatus.unprocessed;
  String? summary;
  List<Chunk> chunks = const [];
  String? error;
}

class Course {
  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.term,
    required this.files,
  });

  final String id, code, name, term;
  final List<CourseFile> files;

  Iterable<CourseFile> get readyFiles =>
      files.where((f) => f.status == FileStatus.ready);
  int get readyCount => readyFiles.length;
  bool get isFullyIndexed => readyCount == files.length;
  bool get hasPendingWork => files.any((f) =>
      f.status == FileStatus.queued || f.status == FileStatus.processing);
  bool get hasStarted => files.any((f) => f.status != FileStatus.unprocessed);
}

enum StudyMode { explain, socratic, quiz }

extension StudyModeLabel on StudyMode {
  String get label => switch (this) {
        StudyMode.explain => 'Explain',
        StudyMode.socratic => 'Guide me',
        StudyMode.quiz => 'Quiz me',
      };

  /// Short hint shown as the mode switch tooltip.
  String get tooltip => switch (this) {
        StudyMode.explain => 'Get a clear answer',
        StudyMode.socratic => 'Work it out with hints',
        StudyMode.quiz => 'Test yourself',
      };
}

enum Author { student, tutor }

class Citation {
  const Citation(this.fileName, this.heading);
  final String fileName, heading;
}

class ChatMessage {
  ChatMessage({
    required this.author,
    required this.text,
    this.pending = false,
  });

  final Author author;
  String text;
  bool pending;
  bool failed = false;
  List<Citation> citations = const [];
  int tokens = 0;

  /// What the same turn would have cost with the full files pasted in.
  int naiveTokens = 0;
}
