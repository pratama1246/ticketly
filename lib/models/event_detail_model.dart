import 'event_model.dart';

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final parsedDouble = double.tryParse(value);
    if (parsedDouble != null) {
      return parsedDouble.toInt();
    }
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

class EventDetailModel {
  final String id;
  final String name;
  final String slug;
  final String category;
  final String venue;
  final String date;
  final String time;
  final String? posterImage;
  final String description;
  final String? seatmapImage;
  final String eventStatus;
  final int totalStock;
  final int totalSold;
  final List<TicketTypeModel> tickets;

  const EventDetailModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    required this.venue,
    required this.date,
    required this.time,
    this.posterImage,
    required this.description,
    this.seatmapImage,
    required this.eventStatus,
    required this.totalStock,
    required this.totalSold,
    required this.tickets,
  });

  factory EventDetailModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final name = json['name'] ?? '';
    final slug = json['slug'] ?? '';
    final category = json['category'] ?? '';
    final venue = json['venue'] ?? '';
    final posterImage = json['poster_image'];
    final description = json['description'] ?? '';
    final seatmapImage = json['seatmap_image'];
    final eventStatus = json['event_status'] ?? 'available';
    final totalStock = _parseInt(json['total_stock']);
    final totalSold = _parseInt(json['total_sold']);

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

    // Parse tickets
    final List<TicketTypeModel> ticketsList = [];
    if (json['tickets'] != null) {
      final List rawTickets = json['tickets'];
      for (final t in rawTickets) {
        ticketsList.add(TicketTypeModel.fromJson(Map<String, dynamic>.from(t)));
      }
    }

    return EventDetailModel(
      id: id,
      name: name,
      slug: slug,
      category: category,
      venue: venue,
      date: dateStr,
      time: timeStr,
      posterImage: posterImage,
      description: description,
      seatmapImage: seatmapImage,
      eventStatus: eventStatus,
      totalStock: totalStock,
      totalSold: totalSold,
      tickets: ticketsList,
    );
  }
}

class TicketTypeModel {
  final int id;
  final String name;
  final String? ticketDate;
  final String ticketCategory;
  final int price;
  final String uiColor;
  final String rawDescription;
  final List<String> bulletDescriptions;
  final int quantityTotal;
  final int quantitySold;
  final int quantityLeft;

  const TicketTypeModel({
    required this.id,
    required this.name,
    this.ticketDate,
    required this.ticketCategory,
    required this.price,
    required this.uiColor,
    required this.rawDescription,
    required this.bulletDescriptions,
    required this.quantityTotal,
    required this.quantitySold,
    required this.quantityLeft,
  });

  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    final id = _parseInt(json['id']);
    final name = json['name'] ?? '';
    final ticketDate = json['ticket_date']?.toString();
    final ticketCategory = json['ticket_category'] ?? 'Standing';
    final price = _parseInt(json['price']);
    final uiColor = json['ui_color'] ?? '#3B82F6';
    final rawDescription = json['description'] ?? '';

    // Convert HTML <ul><li>...</li></ul> to List of bullet points
    final List<String> bullets = _parseHtmlToList(rawDescription);

    final quantityTotal = _parseInt(json['quantity_total']);
    final quantitySold = _parseInt(json['quantity_sold']);
    final quantityLeft = _parseInt(json['quantity_left']);

    return TicketTypeModel(
      id: id,
      name: name,
      ticketDate: ticketDate,
      ticketCategory: ticketCategory,
      price: price,
      uiColor: uiColor,
      rawDescription: rawDescription,
      bulletDescriptions: bullets,
      quantityTotal: quantityTotal,
      quantitySold: quantitySold,
      quantityLeft: quantityLeft,
    );
  }

  static List<String> _parseHtmlToList(String html) {
    if (html.isEmpty) return [];
    // Unescape &amp; to &
    String clean = html.replaceAll('&amp;', '&');
    // Remove <ul> and </ul> tags
    clean = clean.replaceAll(RegExp(r'<\/?ul>'), '');
    // Split by <li>
    final List<String> rawParts = clean.split(RegExp(r'<li>'));
    final List<String> bullets = [];
    for (final part in rawParts) {
      final item = part.replaceAll(RegExp(r'<\/li>'), '').replaceAll(RegExp(r'\r\n|\n'), ' ').trim();
      if (item.isNotEmpty) {
        bullets.add(item);
      }
    }
    return bullets;
  }
}
