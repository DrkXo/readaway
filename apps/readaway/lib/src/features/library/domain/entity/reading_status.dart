import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ReadingStatus {
  @JsonValue('unread')
  unread,
  @JsonValue('reading')
  reading,
  @JsonValue('finished')
  finished,
  @JsonValue('abandoned')
  abandoned;

  String get label => switch (this) {
        ReadingStatus.unread => 'Unread',
        ReadingStatus.reading => 'Reading',
        ReadingStatus.finished => 'Finished',
        ReadingStatus.abandoned => 'On Hold',
      };
}
