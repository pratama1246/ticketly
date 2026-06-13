import '../models/event_model.dart';

// ─────────────────────────────────────────────
// TICKETLY — Dummy Data Model
// Placeholder data untuk home page
// ─────────────────────────────────────────────

class HomeDummyData {
  static final List<EventModel> concertEvents = [
    EventModel(
      id: '1',
      slug: 'nct-dream-the-dream-show-4-world-tour',
      title: 'NCT DREAM: THE DREAM SHOW 4 WORLD TOUR',
      location: 'Jakarta International Stadium',
      date: '15 Januari 2026',
      time: '19.00 WIB',
      imageUrl: 'assets/images/placeholder_event.png',
      eventDate: DateTime(2026, 1, 15),
    ),
    EventModel(
      id: '2',
      slug: 'nct-dream-the-dream-show-4-world-tour-2',
      title: 'NCT DREAM: THE DREAM SHOW 4 WORLD TOUR',
      location: 'Jakarta International Stadium',
      date: '16 Januari 2026',
      time: '19.00 WIB',
      imageUrl: 'assets/images/placeholder_event.png',
      eventDate: DateTime(2026, 1, 16),
    ),
  ];

  static final List<EventModel> festivalEvents = [
    EventModel(
      id: '3',
      slug: 'p-land-season-of-wishes',
      title: 'P-LAND Season of Wishes - Bank RAYA User',
      location: 'Blok M Hub, Jakarta Selatan',
      date: '12 Des 2025',
      time: '10.00 WIB',
      imageUrl: 'assets/images/placeholder_event.png',
      eventDate: DateTime(2025, 12, 12),
    ),
    EventModel(
      id: '4',
      slug: 'p-land-season-of-wishes-2',
      title: 'P-LAND Season of Wishes - Bank RAYA User',
      location: 'Blok M Hub, Jakarta Selatan',
      date: '13 Des 2025',
      time: '10.00 WIB',
      imageUrl: 'assets/images/placeholder_event.png',
      eventDate: DateTime(2025, 12, 13),
    ),
  ];

  static final List<EventModel> otherEvents = [
    EventModel(
      id: '5',
      slug: 'law-fellas',
      title: 'Law Fellas',
      location: 'Gor Satria Purwokerto, Kabupaten Banyumas',
      date: '20 Nov 2025',
      time: '15.00 WIB',
      imageUrl: 'assets/images/placeholder_event.png',
      eventDate: DateTime(2025, 11, 20),
    ),
    EventModel(
      id: '6',
      slug: 'law-fellas-2',
      title: 'Law Fellas',
      location: 'Gor Satria Purwokerto, Kabupaten Banyumas',
      date: '21 Nov 2025',
      time: '15.00 WIB',
      imageUrl: 'assets/images/placeholder_event.png',
      eventDate: DateTime(2025, 11, 21),
    ),
  ];

  static const List<FaqModel> faqItems = [
    FaqModel(
      question: 'Bagaimana cara menerima tiket setelah bayar?',
      answer:
          'Setelah pembayaran dikonfirmasi, tiket akan dikirim ke email yang terdaftar dalam bentuk E-Tiket. Kamu juga bisa mengaksesnya melalui menu "Tiket Saya".',
    ),
    FaqModel(
      question: 'Apakah tiket bisa dipindahtangankan ke orang lain?',
      answer:
          'Tiket bersifat non-transferable dan terikat dengan data pemesan. Pemindahtanganan tiket tidak diperbolehkan dan dapat mengakibatkan pembatalan tiket.',
    ),
    FaqModel(
      question:
          'Saya sudah bayar tapi belum terima tiket di Email atau aplikasi Tiket Saya?',
      answer:
          'Mohon tunggu hingga 15 menit setelah pembayaran. Jika lebih dari itu, silakan cek folder spam emailmu. Jika masih belum ada, hubungi support kami.',
    ),
    FaqModel(
      question: 'Apakah E-Tiket perlu dicetak (print)?',
      answer:
          'Tidak perlu. E-Tiket cukup ditunjukkan melalui layar smartphone saat verifikasi di venue. Pastikan kecerahan layar cukup untuk scan QR Code.',
    ),
  ];
}

class FaqModel {
  final String question;
  final String answer;

  const FaqModel({required this.question, required this.answer});
}

class StepModel {
  final int number;
  final String title;
  final String description;

  const StepModel({
    required this.number,
    required this.title,
    required this.description,
  });
}
