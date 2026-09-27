enum TeamSide { home, away }

String teamNameForSide(TeamSide side) {
  return switch (side) {
    TeamSide.home => 'Green FC',
    TeamSide.away => 'White FC',
  };
}

class DemoPlayer {
  const DemoPlayer({
    required this.id,
    required this.teamSide,
    required this.teamName,
    required this.number,
    required this.name,
    required this.isStarter,
  });

  final String id;
  final TeamSide teamSide;
  final String teamName;
  final int number;
  final String name;
  final bool isStarter;

  String get rosterLabel {
    final role = isStarter ? 'XI' : 'Bench';
    return '$teamName #$number — $name ($role)';
  }
}

const demoPlayers = [
  DemoPlayer(
    id: 'home-1',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 1,
    name: 'S. Patel',
  ),
  DemoPlayer(
    id: 'home-2',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 2,
    name: 'N. Torres',
  ),
  DemoPlayer(
    id: 'home-3',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 3,
    name: 'R. Morgan',
  ),
  DemoPlayer(
    id: 'home-4',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 4,
    name: 'T. Okafor',
  ),
  DemoPlayer(
    id: 'home-5',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 5,
    name: 'D. Rivera',
  ),
  DemoPlayer(
    id: 'home-6',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 6,
    name: 'M. Nguyen',
  ),
  DemoPlayer(
    id: 'home-7',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 7,
    name: 'A. Khan',
  ),
  DemoPlayer(
    id: 'home-8',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 8,
    name: 'B. Johnson',
  ),
  DemoPlayer(
    id: 'home-9',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 9,
    name: 'M. Silva',
  ),
  DemoPlayer(
    id: 'home-10',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 10,
    name: 'J. Brooks',
  ),
  DemoPlayer(
    id: 'home-11',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: true,
    number: 11,
    name: 'E. Garcia',
  ),
  DemoPlayer(
    id: 'home-12',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: false,
    number: 12,
    name: 'P. Williams',
  ),
  DemoPlayer(
    id: 'home-13',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: false,
    number: 13,
    name: 'C. Young',
  ),
  DemoPlayer(
    id: 'home-14',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: false,
    number: 14,
    name: 'H. Singh',
  ),
  DemoPlayer(
    id: 'home-15',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: false,
    number: 15,
    name: 'O. Murphy',
  ),
  DemoPlayer(
    id: 'home-16',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: false,
    number: 16,
    name: 'F. Martinez',
  ),
  DemoPlayer(
    id: 'home-17',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: false,
    number: 17,
    name: 'I. Wilson',
  ),
  DemoPlayer(
    id: 'home-18',
    teamSide: TeamSide.home,
    teamName: 'Green FC',
    isStarter: false,
    number: 18,
    name: 'K. Lewis',
  ),
  DemoPlayer(
    id: 'away-1',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 1,
    name: 'G. Miller',
  ),
  DemoPlayer(
    id: 'away-2',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 2,
    name: 'V. Brown',
  ),
  DemoPlayer(
    id: 'away-3',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 3,
    name: 'Y. Kim',
  ),
  DemoPlayer(
    id: 'away-4',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 4,
    name: 'D. Chen',
  ),
  DemoPlayer(
    id: 'away-5',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 5,
    name: 'S. Evans',
  ),
  DemoPlayer(
    id: 'away-6',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 6,
    name: 'A. Scott',
  ),
  DemoPlayer(
    id: 'away-7',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 7,
    name: 'L. Adams',
  ),
  DemoPlayer(
    id: 'away-8',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 8,
    name: 'L. Carter',
  ),
  DemoPlayer(
    id: 'away-9',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 9,
    name: 'P. Wright',
  ),
  DemoPlayer(
    id: 'away-10',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 10,
    name: 'M. Clarke',
  ),
  DemoPlayer(
    id: 'away-11',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: true,
    number: 11,
    name: 'R. Ali',
  ),
  DemoPlayer(
    id: 'away-12',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: false,
    number: 12,
    name: 'J. Baker',
  ),
  DemoPlayer(
    id: 'away-13',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: false,
    number: 13,
    name: 'C. Cooper',
  ),
  DemoPlayer(
    id: 'away-14',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: false,
    number: 14,
    name: 'T. Reed',
  ),
  DemoPlayer(
    id: 'away-15',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: false,
    number: 15,
    name: 'N. Price',
  ),
  DemoPlayer(
    id: 'away-16',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: false,
    number: 16,
    name: 'E. Bell',
  ),
  DemoPlayer(
    id: 'away-17',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: false,
    number: 17,
    name: 'Q. Foster',
  ),
  DemoPlayer(
    id: 'away-18',
    teamSide: TeamSide.away,
    teamName: 'White FC',
    isStarter: false,
    number: 18,
    name: 'U. Hayes',
  ),
];

List<DemoPlayer> demoPlayersForSide(TeamSide side) {
  return demoPlayers.where((player) => player.teamSide == side).toList();
}

List<DemoPlayer> demoStartersForSide(TeamSide side) {
  return demoPlayers
      .where((player) => player.teamSide == side && player.isStarter)
      .toList();
}

List<DemoPlayer> demoBenchPlayersForSide(TeamSide side) {
  return demoPlayers
      .where((player) => player.teamSide == side && !player.isStarter)
      .toList();
}
