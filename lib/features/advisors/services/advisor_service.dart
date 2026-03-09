import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nova_live_nova_finance_os/features/advisors/domain/advisor.dart';
import 'package:uuid/uuid.dart';

final advisorServiceProvider = Provider((ref) => AdvisorService());

final advisorsStreamProvider = StreamProvider<List<FinancialAdvisor>>((ref) {
  final service = ref.watch(advisorServiceProvider);
  return service.watchAdvisors();
});

final bookingsStreamProvider = StreamProvider<List<AdvisorBooking>>((ref) {
  final service = ref.watch(advisorServiceProvider);
  return service.watchBookings();
});

class AdvisorService {
  static const String _advisorsBox = 'advisors';
  static const String _bookingsBox = 'advisor_bookings';
  final _uuid = const Uuid();

  Future<void> initialize() async {
    await Hive.openBox<FinancialAdvisor>(_advisorsBox);
    await Hive.openBox<AdvisorBooking>(_bookingsBox);
    await _seedAdvisors();
  }

  Future<void> _seedAdvisors() async {
    final box = Hive.box<FinancialAdvisor>(_advisorsBox);
    if (box.isEmpty) {
      final advisors = [
        FinancialAdvisor(
          id: _uuid.v4(),
          name: 'Sarah Johnson',
          specialty: 'Tax Planning',
          bio: 'CPA with 15 years experience in tax optimization and business accounting.',
          rating: 4.9,
          reviewCount: 127,
          hourlyRate: 150.0,
          certifications: ['CPA', 'CFP'],
          yearsExperience: 15,
          isAvailable: true,
        ),
        FinancialAdvisor(
          id: _uuid.v4(),
          name: 'Michael Chen',
          specialty: 'Investment Strategy',
          bio: 'Former hedge fund manager specializing in portfolio optimization.',
          rating: 4.8,
          reviewCount: 89,
          hourlyRate: 200.0,
          certifications: ['CFA', 'MBA'],
          yearsExperience: 12,
          isAvailable: true,
        ),
        FinancialAdvisor(
          id: _uuid.v4(),
          name: 'Emily Rodriguez',
          specialty: 'Retirement Planning',
          bio: 'Helping families secure their financial future for over 10 years.',
          rating: 4.95,
          reviewCount: 156,
          hourlyRate: 175.0,
          certifications: ['CFP', 'ChFC'],
          yearsExperience: 10,
          isAvailable: false,
        ),
        FinancialAdvisor(
          id: _uuid.v4(),
          name: 'David Kumar',
          specialty: 'Business Finance',
          bio: 'Small business specialist with expertise in cash flow and growth strategies.',
          rating: 4.7,
          reviewCount: 73,
          hourlyRate: 125.0,
          certifications: ['CPA', 'MBA'],
          yearsExperience: 8,
          isAvailable: true,
        ),
      ];

      for (var advisor in advisors) {
        await box.add(advisor);
      }
    }
  }

  Stream<List<FinancialAdvisor>> watchAdvisors() {
    final box = Hive.box<FinancialAdvisor>(_advisorsBox);
    return Stream.value(box.values.toList())
        .asyncExpand((initial) => box.watch().map((_) => box.values.toList()).startWith(initial));
  }

  Stream<List<AdvisorBooking>> watchBookings() {
    final box = Hive.box<AdvisorBooking>(_bookingsBox);
    return Stream.value(box.values.toList())
        .asyncExpand((initial) => box.watch().map((_) => box.values.toList()).startWith(initial));
  }

  Future<void> bookAdvisor({
    required String advisorId,
    required String advisorName,
    required DateTime scheduledDate,
    required int durationMinutes,
    required String topic,
    required double cost,
  }) async {
    final box = Hive.box<AdvisorBooking>(_bookingsBox);
    final booking = AdvisorBooking(
      id: _uuid.v4(),
      advisorId: advisorId,
      advisorName: advisorName,
      scheduledDate: scheduledDate,
      durationMinutes: durationMinutes,
      topic: topic,
      status: BookingStatus.scheduled,
      cost: cost,
      meetingLink: 'https://meet.novaaccountant.com/${_uuid.v4().substring(0, 8)}',
    );
    await box.add(booking);
  }

  Future<void> cancelBooking(String bookingId) async {
    final box = Hive.box<AdvisorBooking>(_bookingsBox);
    final booking = box.values.firstWhere((b) => b.id == bookingId);
    final index = box.values.toList().indexOf(booking);
    
    final updated = AdvisorBooking(
      id: booking.id,
      advisorId: booking.advisorId,
      advisorName: booking.advisorName,
      scheduledDate: booking.scheduledDate,
      durationMinutes: booking.durationMinutes,
      topic: booking.topic,
      status: BookingStatus.cancelled,
      cost: booking.cost,
      meetingLink: booking.meetingLink,
    );
    await box.putAt(index, updated);
  }

  List<FinancialAdvisor> searchAdvisors(String query) {
    final box = Hive.box<FinancialAdvisor>(_advisorsBox);
    if (query.isEmpty) return box.values.toList();
    
    return box.values.where((advisor) {
      return advisor.name.toLowerCase().contains(query.toLowerCase()) ||
             advisor.specialty.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
