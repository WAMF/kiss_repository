const _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [created] the way the product list shows a creation time.
///
/// A time less than a week old reads as a relative label, such as `Just now`
/// or `5 minutes ago`. Anything older reads as a full local date and time.
///
/// [now] defaults to [DateTime.now]. Tests pass a fixed value.
String formatCreatedDate(DateTime created, {DateTime? now}) {
  final localCreated = created.toLocal();
  final difference = (now ?? DateTime.now()).difference(localCreated);
  return _relativeLabel(difference) ?? _absoluteLabel(localCreated);
}

/// The relative label for [difference], or `null` when it is a week or more.
String? _relativeLabel(Duration difference) {
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return _agoLabel(difference.inMinutes, 'minute');
  if (difference.inDays < 1) return _agoLabel(difference.inHours, 'hour');
  if (difference.inDays < 7) return _agoLabel(difference.inDays, 'day');
  return null;
}

String _agoLabel(int count, String unit) =>
    '$count $unit${count == 1 ? '' : 's'} ago';

String _absoluteLabel(DateTime localCreated) {
  final month = _monthAbbreviations[localCreated.month - 1];
  final minute = localCreated.minute.toString().padLeft(2, '0');
  final hour = localCreated.hour;
  final amPm = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

  return '$month ${localCreated.day}, ${localCreated.year} '
      'at $displayHour:$minute $amPm';
}
