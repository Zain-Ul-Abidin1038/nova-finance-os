import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/advisors/domain/advisor.dart';
import 'package:nova_live_nova_finance_os/features/advisors/services/advisor_service.dart';
import 'package:intl/intl.dart';

class AdvisorMarketplaceScreen extends ConsumerStatefulWidget {
  const AdvisorMarketplaceScreen({super.key});

  @override
  ConsumerState<AdvisorMarketplaceScreen> createState() => _AdvisorMarketplaceScreenState();
}

class _AdvisorMarketplaceScreenState extends ConsumerState<AdvisorMarketplaceScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    ref.read(advisorServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final advisorsAsync = ref.watch(advisorsStreamProvider);
    final bookingsAsync = ref.watch(bookingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Financial Advisors',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search advisors...',
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    bookingsAsync.when(
                      data: (bookings) {
                        final upcoming = bookings.where((b) => 
                          b.status == BookingStatus.scheduled && 
                          b.scheduledDate.isAfter(DateTime.now())
                        ).toList();
                        
                        if (upcoming.isEmpty) return const SizedBox.shrink();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upcoming Sessions',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...upcoming.map((booking) => _buildBookingCard(booking)),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const Text(
                      'Available Advisors',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            advisorsAsync.when(
              data: (advisors) {
                final filtered = _searchQuery.isEmpty
                    ? advisors
                    : ref.read(advisorServiceProvider).searchAdvisors(_searchQuery);
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildAdvisorCard(filtered[index]),
                    ),
                    childCount: filtered.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(AdvisorBooking booking) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.advisorName,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM dd, yyyy • hh:mm a').format(booking.scheduledDate)} • ${booking.durationMinutes} min',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  booking.topic,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: AppColors.error),
            onPressed: () => _cancelBooking(booking.id),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorCard(FinancialAdvisor advisor) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  advisor.name.split(' ').map((n) => n[0]).join(),
                  style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advisor.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      advisor.specialty,
                      style: const TextStyle(color: AppColors.primary, fontSize: 14),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${advisor.rating} (${advisor.reviewCount} reviews)',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!advisor.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Busy',
                    style: TextStyle(color: AppColors.error, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advisor.bio,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: advisor.certifications.map((cert) => Chip(
              label: Text(cert, style: const TextStyle(fontSize: 10)),
              backgroundColor: AppColors.primary.withOpacity(0.2),
              labelStyle: const TextStyle(color: AppColors.primary),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${advisor.hourlyRate.toStringAsFixed(0)}/hour • ${advisor.yearsExperience} years exp',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: advisor.isAvailable ? () => _showBookingDialog(advisor) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Book Session'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(FinancialAdvisor advisor) {
    final topicController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int duration = 60;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Book ${advisor.name}', style: const TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: topicController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Session Topic',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date & Time', style: TextStyle(color: AppColors.textSecondary)),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(selectedDate),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: duration,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  items: [30, 60, 90, 120].map((min) => DropdownMenuItem(
                    value: min,
                    child: Text('$min minutes'),
                  )).toList(),
                  onChanged: (value) => setState(() => duration = value!),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Cost: \$${(advisor.hourlyRate * duration / 60).toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (topicController.text.isEmpty) return;
                
                await ref.read(advisorServiceProvider).bookAdvisor(
                  advisorId: advisor.id,
                  advisorName: advisor.name,
                  scheduledDate: selectedDate,
                  durationMinutes: duration,
                  topic: topicController.text,
                  cost: advisor.hourlyRate * duration / 60,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session booked successfully!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Booking?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to cancel this session?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(advisorServiceProvider).cancelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled')),
        );
      }
    }
  }
}
