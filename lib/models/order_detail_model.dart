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

class OrderDetailModel {
  final int id;
  final String trxId;
  final int orderTotal;
  final String status;
  final String paymentMethod;
  final String createdAt;
  final List<OrderItemModel> items;

  const OrderDetailModel({
    required this.id,
    required this.trxId,
    required this.orderTotal,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final id = _parseInt(json['id']);
    final trxId = json['trx_id'] ?? '';
    final orderTotal = _parseInt(json['order_total']);
    final status = json['status'] ?? '';
    final paymentMethod = json['payment_method'] ?? '';
    
    // Parse created_at to clean Indonesian date format
    String dateStr = '';
    try {
      final rawDate = json['created_at'];
      if (rawDate != null) {
        final parsedDate = DateTime.parse(rawDate);
        dateStr = formatIndonesianDate(parsedDate);
      }
    } catch (_) {
      dateStr = json['created_at']?.toString() ?? '';
    }

    final List<OrderItemModel> itemsList = [];
    if (json['items'] != null) {
      final List rawItems = json['items'];
      for (final item in rawItems) {
        itemsList.add(OrderItemModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return OrderDetailModel(
      id: id,
      trxId: trxId,
      orderTotal: orderTotal,
      status: status,
      paymentMethod: paymentMethod,
      createdAt: dateStr.isNotEmpty ? dateStr : (json['created_at'] ?? ''),
      items: itemsList,
    );
  }
}

class OrderItemModel {
  final int id;
  final String ticketCode;
  final String ticketName;
  final String ticketCategory;
  final String eventName;
  final String eventDate;
  final String eventTime;
  final String seatLabel;
  final int pricePerTicket;

  const OrderItemModel({
    required this.id,
    required this.ticketCode,
    required this.ticketName,
    required this.ticketCategory,
    required this.eventName,
    required this.eventDate,
    required this.eventTime,
    required this.seatLabel,
    required this.pricePerTicket,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final id = _parseInt(json['id']);
    final ticketCode = json['ticket_code'] ?? '';
    final ticketName = json['ticket_name'] ?? '';
    final ticketCategory = json['ticket_category'] ?? '';
    final eventName = json['event_name'] ?? '';
    final pricePerTicket = _parseInt(json['price_per_ticket']);
    final seatLabel = json['seat_label'] ?? 'Free Seating';

    // Parse event date and time
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

    return OrderItemModel(
      id: id,
      ticketCode: ticketCode,
      ticketName: ticketName,
      ticketCategory: ticketCategory,
      eventName: eventName,
      eventDate: dateStr,
      eventTime: timeStr,
      seatLabel: seatLabel,
      pricePerTicket: pricePerTicket,
    );
  }
}
