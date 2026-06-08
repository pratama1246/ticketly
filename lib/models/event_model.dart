// ─────────────────────────────────────────────
// TICKETLY — EventModel & Helper
// Representasi data event hasil parsing API
// ─────────────────────────────────────────────

const List<String> _indonesianMonths = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String formatIndonesianDate(DateTime dateTime) {
  return "${dateTime.day} ${_indonesianMonths[dateTime.month - 1]} ${dateTime.year}";
}

String formatIndonesianTime(DateTime dateTime) {
  final minutes = dateTime.minute.toString().padLeft(2, '0');
  final hours = dateTime.hour.toString().padLeft(2, '0');
  return "$hours.$minutes WIB";
}

class EventModel {
  final String id;
  final String slug;
  final String title;
  final String location;
  final String date;
  final String time;
  final String imageUrl;
  final String? badge;
  final bool isSoldOut;

  const EventModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.imageUrl,
    this.badge,
    this.isSoldOut = false,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final slug = json['slug'] ?? '';
    final name = json['name'] ?? '';
    final venue = json['venue'] ?? '';
    final posterImage = json['poster_image'] ?? '';
    
    // Parse date & time
    String dateStr = '';
    String timeStr = '';
    try {
      final rawDate = json['event_date'];
      if (rawDate != null) {
        final parsedDate = DateTime.parse(rawDate);
        dateStr = formatIndonesianDate(parsedDate);
        timeStr = formatIndonesianTime(parsedDate);
      }
    } catch (_) {
      dateStr = json['event_date']?.toString() ?? '';
    }

    // Tentukan status sold out
    final isSoldOutStatus = json['event_status'] == 'sold_out';

    return EventModel(
      id: id,
      slug: slug,
      title: name,
      location: venue,
      date: dateStr,
      time: timeStr,
      imageUrl: posterImage,
      isSoldOut: isSoldOutStatus,
      badge: null, // Default null agar bersih di card list, atau sesuaikan jika perlu
    );
  }
}
