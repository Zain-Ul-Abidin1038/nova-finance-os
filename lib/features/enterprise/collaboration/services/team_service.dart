import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nova_live_nova_finance_os/features/enterprise/collaboration/domain/team.dart';
import 'package:uuid/uuid.dart';

final teamServiceProvider = Provider((ref) => TeamService());

final teamsStreamProvider = StreamProvider<List<Team>>((ref) {
  final service = ref.watch(teamServiceProvider);
  return service.watchTeams();
});

class TeamService {
  static const String _teamsBox = 'teams';
  final _uuid = const Uuid();

  Future<void> initialize() async {
    await Hive.openBox<Team>(_teamsBox);
    await _seedTeams();
  }

  Future<void> _seedTeams() async {
    final box = Hive.box<Team>(_teamsBox);
    if (box.isEmpty) {
      final teams = [
        Team(
          id: _uuid.v4(),
          name: 'Finance Team',
          description: 'Main accounting and finance operations',
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          members: [
            TeamMember(
              id: _uuid.v4(),
              name: 'You',
              email: 'you@company.com',
              role: TeamRole.owner,
              joinedAt: DateTime.now().subtract(const Duration(days: 90)),
            ),
            TeamMember(
              id: _uuid.v4(),
              name: 'Sarah Johnson',
              email: 'sarah@company.com',
              role: TeamRole.admin,
              joinedAt: DateTime.now().subtract(const Duration(days: 60)),
            ),
            TeamMember(
              id: _uuid.v4(),
              name: 'Mike Chen',
              email: 'mike@company.com',
              role: TeamRole.member,
              joinedAt: DateTime.now().subtract(const Duration(days: 30)),
            ),
          ],
        ),
        Team(
          id: _uuid.v4(),
          name: 'Marketing Budget',
          description: 'Marketing department expense tracking',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          members: [
            TeamMember(
              id: _uuid.v4(),
              name: 'You',
              email: 'you@company.com',
              role: TeamRole.admin,
              joinedAt: DateTime.now().subtract(const Duration(days: 45)),
            ),
            TeamMember(
              id: _uuid.v4(),
              name: 'Emily Rodriguez',
              email: 'emily@company.com',
              role: TeamRole.member,
              joinedAt: DateTime.now().subtract(const Duration(days: 20)),
            ),
          ],
        ),
      ];

      for (var team in teams) {
        await box.add(team);
      }
    }
  }

  Stream<List<Team>> watchTeams() {
    final box = Hive.box<Team>(_teamsBox);
    return Stream.value(box.values.toList())
        .asyncExpand((initial) => box.watch().map((_) => box.values.toList()).startWith(initial));
  }

  Future<void> createTeam({
    required String name,
    required String description,
  }) async {
    final box = Hive.box<Team>(_teamsBox);
    final team = Team(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      members: [
        TeamMember(
          id: _uuid.v4(),
          name: 'You',
          email: 'you@company.com',
          role: TeamRole.owner,
          joinedAt: DateTime.now(),
        ),
      ],
    );
    await box.add(team);
  }

  Future<void> addMember({
    required String teamId,
    required String name,
    required String email,
    required TeamRole role,
  }) async {
    final box = Hive.box<Team>(_teamsBox);
    final team = box.values.firstWhere((t) => t.id == teamId);
    final index = box.values.toList().indexOf(team);

    final newMember = TeamMember(
      id: _uuid.v4(),
      name: name,
      email: email,
      role: role,
      joinedAt: DateTime.now(),
    );

    final updatedMembers = List<TeamMember>.from(team.members)..add(newMember);

    final updated = Team(
      id: team.id,
      name: team.name,
      description: team.description,
      createdAt: team.createdAt,
      members: updatedMembers,
    );

    await box.putAt(index, updated);
  }

  Future<void> removeMember(String teamId, String memberId) async {
    final box = Hive.box<Team>(_teamsBox);
    final team = box.values.firstWhere((t) => t.id == teamId);
    final index = box.values.toList().indexOf(team);

    final updatedMembers = team.members.where((m) => m.id != memberId).toList();

    final updated = Team(
      id: team.id,
      name: team.name,
      description: team.description,
      createdAt: team.createdAt,
      members: updatedMembers,
    );

    await box.putAt(index, updated);
  }

  Future<void> updateMemberRole(String teamId, String memberId, TeamRole newRole) async {
    final box = Hive.box<Team>(_teamsBox);
    final team = box.values.firstWhere((t) => t.id == teamId);
    final index = box.values.toList().indexOf(team);

    final updatedMembers = team.members.map((m) {
      if (m.id == memberId) {
        return TeamMember(
          id: m.id,
          name: m.name,
          email: m.email,
          role: newRole,
          joinedAt: m.joinedAt,
        );
      }
      return m;
    }).toList();

    final updated = Team(
      id: team.id,
      name: team.name,
      description: team.description,
      createdAt: team.createdAt,
      members: updatedMembers,
    );

    await box.putAt(index, updated);
  }

  Future<void> deleteTeam(String teamId) async {
    final box = Hive.box<Team>(_teamsBox);
    final team = box.values.firstWhere((t) => t.id == teamId);
    final index = box.values.toList().indexOf(team);
    await box.deleteAt(index);
  }
}
