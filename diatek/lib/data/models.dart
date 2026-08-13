/// A row from the 'film' table.
class Film {
  const Film({required this.id, required this.name});

  final int id;
  final String name;

  factory Film.fromMap(Map<String, dynamic> map) => Film(
        id: map['id_film'] as int,
        name: map['name'] as String? ?? 'Untitled',
      );
}

/// A row from the 'profile' table.
class Profile {
  const Profile({this.username, this.avatarUrl});

  final String? username;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        username: map['username'] as String?,
        avatarUrl: map['avatar'] as String?,
      );
}
