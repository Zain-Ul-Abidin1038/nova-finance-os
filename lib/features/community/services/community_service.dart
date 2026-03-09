import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nova_live_nova_finance_os/features/community/domain/community.dart';
import 'package:uuid/uuid.dart';

final communityServiceProvider = Provider((ref) => CommunityService());

final postsStreamProvider = StreamProvider<List<CommunityPost>>((ref) {
  final service = ref.watch(communityServiceProvider);
  return service.watchPosts();
});

final benchmarksStreamProvider = StreamProvider<List<FinancialBenchmark>>((ref) {
  final service = ref.watch(communityServiceProvider);
  return service.watchBenchmarks();
});

final challengesStreamProvider = StreamProvider<List<Challenge>>((ref) {
  final service = ref.watch(communityServiceProvider);
  return service.watchChallenges();
});

class CommunityService {
  static const String _postsBox = 'community_posts';
  static const String _benchmarksBox = 'financial_benchmarks';
  static const String _challengesBox = 'challenges';
  final _uuid = const Uuid();

  Future<void> initialize() async {
    await Hive.openBox<CommunityPost>(_postsBox);
    await Hive.openBox<FinancialBenchmark>(_benchmarksBox);
    await Hive.openBox<Challenge>(_challengesBox);
    await _seedData();
  }

  Future<void> _seedData() async {
    final postsBox = Hive.box<CommunityPost>(_postsBox);
    if (postsBox.isEmpty) {
      final posts = [
        CommunityPost(
          id: _uuid.v4(),
          authorName: 'Sarah M.',
          title: 'Finally paid off my credit card debt!',
          content: 'After 2 years of budgeting and side hustles, I\'m debt-free! The 50/30/20 rule really works.',
          category: PostCategory.debt,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 47,
          comments: 12,
        ),
        CommunityPost(
          id: _uuid.v4(),
          authorName: 'Anonymous',
          title: 'Tax deduction tips for freelancers',
          content: 'Don\'t forget to track home office expenses, internet, and equipment. Saved me \$3K last year!',
          category: PostCategory.taxes,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          likes: 89,
          comments: 23,
          isAnonymous: true,
        ),
        CommunityPost(
          id: _uuid.v4(),
          authorName: 'Mike Chen',
          title: 'Started investing with just \$100/month',
          content: 'Index funds are perfect for beginners. Set it and forget it approach is working great!',
          category: PostCategory.investing,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          likes: 156,
          comments: 34,
        ),
      ];
      for (var post in posts) {
        await postsBox.add(post);
      }
    }

    final benchmarksBox = Hive.box<FinancialBenchmark>(_benchmarksBox);
    if (benchmarksBox.isEmpty) {
      final benchmarks = [
        FinancialBenchmark(
          category: 'Monthly Savings Rate',
          userValue: 22.0,
          communityAverage: 18.5,
          percentile: 68.0,
          insight: 'You\'re saving more than 68% of users!',
        ),
        FinancialBenchmark(
          category: 'Dining Out Spending',
          userValue: 450.0,
          communityAverage: 380.0,
          percentile: 42.0,
          insight: 'Consider reducing dining expenses',
        ),
        FinancialBenchmark(
          category: 'Emergency Fund (months)',
          userValue: 4.5,
          communityAverage: 3.2,
          percentile: 72.0,
          insight: 'Great progress! Aim for 6 months',
        ),
      ];
      for (var benchmark in benchmarks) {
        await benchmarksBox.add(benchmark);
      }
    }

    final challengesBox = Hive.box<Challenge>(_challengesBox);
    if (challengesBox.isEmpty) {
      final challenges = [
        Challenge(
          id: _uuid.v4(),
          title: '30-Day No Dining Out Challenge',
          description: 'Cook all meals at home for 30 days and save money!',
          type: ChallengeType.noSpend,
          targetAmount: 500.0,
          durationDays: 30,
          startDate: DateTime.now(),
          participants: 1247,
        ),
        Challenge(
          id: _uuid.v4(),
          title: 'Save \$1000 in 3 Months',
          description: 'Build your emergency fund with consistent savings',
          type: ChallengeType.savings,
          targetAmount: 1000.0,
          durationDays: 90,
          startDate: DateTime.now().subtract(const Duration(days: 15)),
          participants: 892,
        ),
        Challenge(
          id: _uuid.v4(),
          title: 'Debt Snowball Sprint',
          description: 'Pay off smallest debt first, then roll payments to next',
          type: ChallengeType.debtPayoff,
          targetAmount: 2000.0,
          durationDays: 180,
          startDate: DateTime.now().add(const Duration(days: 7)),
          participants: 543,
        ),
      ];
      for (var challenge in challenges) {
        await challengesBox.add(challenge);
      }
    }
  }

  Stream<List<CommunityPost>> watchPosts() {
    final box = Hive.box<CommunityPost>(_postsBox);
    return Stream.value(box.values.toList())
        .asyncExpand((initial) => box.watch().map((_) => box.values.toList()).startWith(initial));
  }

  Stream<List<FinancialBenchmark>> watchBenchmarks() {
    final box = Hive.box<FinancialBenchmark>(_benchmarksBox);
    return Stream.value(box.values.toList())
        .asyncExpand((initial) => box.watch().map((_) => box.values.toList()).startWith(initial));
  }

  Stream<List<Challenge>> watchChallenges() {
    final box = Hive.box<Challenge>(_challengesBox);
    return Stream.value(box.values.toList())
        .asyncExpand((initial) => box.watch().map((_) => box.values.toList()).startWith(initial));
  }

  Future<void> createPost({
    required String authorName,
    required String title,
    required String content,
    required PostCategory category,
    bool isAnonymous = false,
  }) async {
    final box = Hive.box<CommunityPost>(_postsBox);
    final post = CommunityPost(
      id: _uuid.v4(),
      authorName: isAnonymous ? 'Anonymous' : authorName,
      title: title,
      content: content,
      category: category,
      createdAt: DateTime.now(),
      isAnonymous: isAnonymous,
    );
    await box.add(post);
  }

  Future<void> joinChallenge(String challengeId) async {
    final box = Hive.box<Challenge>(_challengesBox);
    final challenge = box.values.firstWhere((c) => c.id == challengeId);
    final index = box.values.toList().indexOf(challenge);
    
    final updated = Challenge(
      id: challenge.id,
      title: challenge.title,
      description: challenge.description,
      type: challenge.type,
      targetAmount: challenge.targetAmount,
      durationDays: challenge.durationDays,
      startDate: challenge.startDate,
      participants: challenge.participants + 1,
      isJoined: true,
      currentProgress: 0.0,
    );
    await box.putAt(index, updated);
  }

  List<CommunityPost> filterPosts(PostCategory? category) {
    final box = Hive.box<CommunityPost>(_postsBox);
    if (category == null) return box.values.toList();
    return box.values.where((post) => post.category == category).toList();
  }
}
