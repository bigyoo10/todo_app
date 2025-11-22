import 'package:hive/hive.dart';
import 'todo.dart';
/// build_runner가 만든 기본 어댑터 대신,
/// 과거 레코드의 null 필드들을 안전하게 읽기 위한 수동 어댑터입니다.
class TodoAdapterManual extends TypeAdapter<Todo> {
  @override
  final int typeId = 32; // 기존과 동일해야 과거 데이터 읽기 가능
  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Todo(
      title: fields[0] as String? ?? '',
      description: fields[1] as String? ?? '',
      createdAt: fields[2] as DateTime? ?? DateTime.now(),
      category: fields[3] as String?,
      priority: fields[4] as int?,
      notificationTime: fields[5] as DateTime?,
      isCompleted: fields[6] as bool? ?? false,
      completedAt: fields[7] as DateTime?,
      notificationId: fields[8] as int?,
      sortOrder: fields[9] as int?, // ← null 허용!
    );
  }
  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.notificationTime)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.completedAt)
      ..writeByte(8)
      ..write(obj.notificationId)
      ..writeByte(9)
      ..write(obj.sortOrder);
  }
}
