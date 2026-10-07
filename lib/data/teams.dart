/// Nickname for each team code. Codes are the only identifiers stored.
const Map<String, String> teamNicknames = {
  'ARI': 'Cardinals',
  'ATL': 'Falcons',
  'BAL': 'Ravens',
  'BUF': 'Bills',
  'CAR': 'Panthers',
  'CHI': 'Bears',
  'CIN': 'Bengals',
  'CLE': 'Browns',
  'DAL': 'Cowboys',
  'DEN': 'Broncos',
  'DET': 'Lions',
  'GB': 'Packers',
  'HOU': 'Texans',
  'IND': 'Colts',
  'JAX': 'Jaguars',
  'KC': 'Chiefs',
  'LV': 'Raiders',
  'LAC': 'Chargers',
  'LAR': 'Rams',
  'MIA': 'Dolphins',
  'MIN': 'Vikings',
  'NE': 'Patriots',
  'NO': 'Saints',
  'NYG': 'Giants',
  'NYJ': 'Jets',
  'PHI': 'Eagles',
  'PIT': 'Steelers',
  'SEA': 'Seahawks',
  'SF': '49ers',
  'TB': 'Buccaneers',
  'TEN': 'Titans',
  'WSH': 'Commanders',
};

String nicknameOf(String code) {
  final nickname = teamNicknames[code];
  if (nickname == null) {
    throw ArgumentError.value(code, 'code', 'Unknown team code');
  }
  return nickname;
}
