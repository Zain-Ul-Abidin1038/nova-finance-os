import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/community/domain/community.dart';
import 'package:nova_live_nova_finance_os/features/community/services/community_service.dart';
import 'package:intl/intl.dart';

class CommunityInsightsScreen extends ConsumerStatefulWidget {
  const CommunityInsightsScreen({super.key});

  @override
  ConsumerState<CommunityInsightsScreen> createState() => _CommunityInsightsScreenState();
}

class _CommunityInsightsScreenState extends ConsumerState<CommunityInsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PostCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    ref.read(communityServiceProvider).initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Community',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Discussions'),
                Tab(text: 'Benchmarks'),
                Tab(text: 'Challenges'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDiscussionsTab(),
                  _buildBenchmarksTab(),
                  _buildChallengesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showCreatePostDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDiscussionsTab() {
    final postsAsync = ref.watch(postsStreamProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', null),
                _buildCategoryChip('Budgeting', PostCategory.budgeting),
                _buildCategoryChip('Investing', PostCategory.investing),
                _buildCategoryChip('Taxes', PostCategory.taxes),
                _buildCategoryChip('Debt', PostCategory.debt),
                _buildCategoryChip('Savings', PostCategory.savings),
              ],
            ),
          ),
        ),
        Expanded(
          child: postsAsync.when(
            data: (posts) {
              final filtered = _selectedCategory == null
                  ? posts
                  : ref.read(communityServiceProvider).filterPosts(_selectedCategory);
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _buildPostCard(filtered[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error))),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, PostCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedCategory = selected ? category : null),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withOpacity(0.3),
        labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondary),
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: post.isAnonymous ? AppColors.textSecondary.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
                child: Icon(
                  post.isAnonymous ? Icons.person_off : Icons.person,
                  size: 16,
                  color: post.isAnonymous ? AppColors.textSecondary : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      _formatTimestamp(post.createdAt),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(post.category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  post.category.name.toUpperCase(),
                  style: TextStyle(color: _getCategoryColor(post.category), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${post.likes}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${post.comments}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarksTab() {
    final benchmarksAsync = ref.watch(benchmarksStreamProvider);

    return benchmarksAsync.when(
      data: (benchmarks) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'How You Compare',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Anonymous comparison with community averages',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...benchmarks.map((benchmark) => _buildBenchmarkCard(benchmark)),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error))),
    );
  }

  Widget _buildBenchmarkCard(FinancialBenchmark benchmark) {
    final isAboveAverage = benchmark.userValue > benchmark.communityAverage;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                benchmark.category,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAboveAverage ? AppColors.success.withOpacity(0.2) : AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${benchmark.percentile.toStringAsFixed(0)}th percentile',
                  style: TextStyle(
                    color: isAboveAverage ? AppColors.success : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('You', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      benchmark.userValue.toStringAsFixed(1),
                      style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Community Avg', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      benchmark.communityAverage.toStringAsFixed(1),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: benchmark.percentile / 100,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation(isAboveAverage ? AppColors.success : AppColors.warning),
          ),
          const SizedBox(height: 8),
          Text(
            benchmark.insight,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    final challengesAsync = ref.watch(challengesStreamProvider);

    return challengesAsync.when(
      data: (challenges) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Active Challenges',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join community challenges to stay motivated',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ...challenges.map((challenge) => _buildChallengeCard(challenge)),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error))),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    final daysLeft = challenge.startDate.add(Duration(days: challenge.durationDays)).difference(DateTime.now()).inDays;
    final isActive = daysLeft > 0;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getChallengeColor(challenge.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getChallengeIcon(challenge.type), color: _getChallengeColor(challenge.type)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${challenge.participants} participants',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (challenge.isJoined)
                const Icon(Icons.check_circle, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            challenge.description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${challenge.durationDays} days',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.attach_money, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '\$${challenge.targetAmount.toStringAsFixed(0)} goal',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              if (isActive)
                Text(
                  '$daysLeft days left',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (challenge.isJoined) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: challenge.currentProgress / challenge.targetAmount,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation(_getChallengeColor(challenge.type)),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${challenge.currentProgress.toStringAsFixed(0)} / \$${challenge.targetAmount.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: challenge.isJoined ? null : () => _joinChallenge(challenge.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: challenge.isJoined ? AppColors.surface : AppColors.primary,
                foregroundColor: challenge.isJoined ? AppColors.textSecondary : AppColors.background,
              ),
              child: Text(challenge.isJoined ? 'Joined' : 'Join Challenge'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.budgeting:
        return AppColors.primary;
      case PostCategory.investing:
        return AppColors.success;
      case PostCategory.taxes:
        return AppColors.warning;
      case PostCategory.debt:
        return AppColors.error;
      case PostCategory.savings:
        return AppColors.accent;
      case PostCategory.general:
        return AppColors.textSecondary;
    }
  }

  Color _getChallengeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.savings:
        return AppColors.success;
      case ChallengeType.noSpend:
        return AppColors.primary;
      case ChallengeType.debtPayoff:
        return AppColors.warning;
      case ChallengeType.budgetStreak:
        return AppColors.accent;
    }
  }

  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.savings:
        return Icons.savings;
      case ChallengeType.noSpend:
        return Icons.block;
      case ChallengeType.debtPayoff:
        return Icons.trending_down;
      case ChallengeType.budgetStreak:
        return Icons.local_fire_department;
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    PostCategory selectedCategory = PostCategory.general;
    bool isAnonymous = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Create Post', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PostCategory>(
                  value: selectedCategory,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  items: PostCategory.values.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat.name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Post anonymously', style: TextStyle(color: AppColors.textPrimary)),
                  value: isAnonymous,
                  onChanged: (value) => setState(() => isAnonymous = value!),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) return;
                
                await ref.read(communityServiceProvider).createPost(
                  authorName: 'You',
                  title: titleController.text,
                  content: contentController.text,
                  category: selectedCategory,
                  isAnonymous: isAnonymous,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post created!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinChallenge(String challengeId) async {
    await ref.read(communityServiceProvider).joinChallenge(challengeId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge joined! Good luck!')),
      );
    }
  }
}
