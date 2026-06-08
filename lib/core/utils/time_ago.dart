String timeAgoText(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Baru saja';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}mnt lalu';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}j lalu';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}h lalu';
  } else if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()}mgg lalu';
  } else if (difference.inDays < 365) {
    return '${(difference.inDays / 30).floor()}bln lalu';
  }
  return '${(difference.inDays / 365).floor()}thn lalu';
}
