import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/collaboration/domain/team.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/collaboration/services/team_service.dart';
import 'package:intl/intl.dart';

class TeamWorkspaceScreen extends ConsumerStatefulWidget {
  const TeamWorkspaceScreen({super.key});

  @override
  ConsumerState<TeamWorkspaceScreen> createState() => _TeamWorkspaceScreenState();
}

class _TeamWorkspaceScreenState extends ConsumerState<TeamWorkspaceScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(teamServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);

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
                'Team Collaboration',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  onPressed: _showCreateTeamDialog,
                ),
              ],
            ),
            teamsAsync.when(
              data: (teams) {
                if (teams.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.groups_outlined, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text(
                            'No teams yet',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first team to collaborate',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showCreateTeamDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Team'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _buildTeamCard(teams[index]),
                    ),
                    childCount: teams.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $error', style: const TextStyle(color: AppColors.error))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    final ownerMember = team.members.firstWhere((m) => m.role == TeamRole.owner);
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      team.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                color: AppColors.surface,
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteTeam(team.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error, size: 20),
                        SizedBox(width: 8),
                        Text('Delete Team', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Created ${DateFormat('MMM dd, yyyy').format(team.createdAt)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${team.members.length} members',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Team Members',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...team.members.map((member) => _buildMemberRow(team.id, member, ownerMember.id)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddMemberDialog(team.id),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Member'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(String teamId, TeamMember member, String ownerId) {
    final isOwner = member.id == ownerId;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _getRoleColor(member.role).withOpacity(0.2),
            child: Text(
              member.name.split(' ').map((n) => n[0]).join(),
              style: TextStyle(color: _getRoleColor(member.role), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  member.email,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(member.role).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              member.role.name.toUpperCase(),
              style: TextStyle(
                color: _getRoleColor(member.role),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 20),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'remove') {
                  _removeMember(teamId, member.id);
                } else if (value == 'promote') {
                  _updateRole(teamId, member.id, TeamRole.admin);
                } else if (value == 'demote') {
                  _updateRole(teamId, member.id, TeamRole.member);
                }
              },
              itemBuilder: (context) => [
                if (member.role != TeamRole.admin)
                  const PopupMenuItem(
                    value: 'promote',
                    child: Text('Promote to Admin', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  ),
                if (member.role == TeamRole.admin)
                  const PopupMenuItem(
                    value: 'demote',
                    child: Text('Demote to Member', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return AppColors.primary;
      case TeamRole.admin:
        return AppColors.success;
      case TeamRole.member:
        return AppColors.accent;
      case TeamRole.viewer:
        return AppColors.textSecondary;
    }
  }

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create Team', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Team Name',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              
              await ref.read(teamServiceProvider).createTeam(
                name: nameController.text,
                description: descController.text,
              );
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team created!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(String teamId) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    TeamRole selectedRole = TeamRole.member;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Member', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TeamRole>(
                value: selectedRole,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: [TeamRole.admin, TeamRole.member, TeamRole.viewer].map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.name),
                )).toList(),
                onChanged: (value) => setState(() => selectedRole = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty) return;
                
                await ref.read(teamServiceProvider).addMember(
                  teamId: teamId,
                  name: nameController.text,
                  email: emailController.text,
                  role: selectedRole,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member added!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(String teamId, String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove Member?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to remove this member?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(teamServiceProvider).removeMember(teamId, memberId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed')),
        );
      }
    }
  }

  Future<void> _updateRole(String teamId, String memberId, TeamRole newRole) async {
    await ref.read(teamServiceProvider).updateMemberRole(teamId, memberId, newRole);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to ${newRole.name}')),
      );
    }
  }

  Future<void> _deleteTeam(String teamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Team?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will permanently delete the team and all its data.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(teamServiceProvider).deleteTeam(teamId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team deleted')),
        );
      }
    }
  }
}
