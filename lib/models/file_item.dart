enum FileType { pdf, image, docx, txt }

class FileItem {
  final String id;
  final String name;
  final FileType type;
  final String date;
  final String? content;
  final String? path;
  final String? thumbnailPath;

  FileItem({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    this.content,
    this.path,
    this.thumbnailPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'date': date,
    'content': content,
    'path': path,
    'thumbnailPath': thumbnailPath,
  };

  factory FileItem.fromJson(Map<String, dynamic> json) => FileItem(
    id: json['id'],
    name: json['name'],
    type: FileType.values.byName(json['type']),
    date: json['date'],
    content: json['content'],
    path: json['path'],
    thumbnailPath: json['thumbnailPath'],
  );
}
