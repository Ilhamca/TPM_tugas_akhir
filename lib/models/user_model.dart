class User {
  final String nama;
  final String username;
  final String password;

  User({required this.nama, required this.username, required this.password});
}

List<User> daftarUser = [
  User(nama: 'Ilham Cesario', username: 'ilhamcs', password: '106'),
  User(nama: 'Dhimas Efendi', username: 'dhixdi', password: '166'),
];
