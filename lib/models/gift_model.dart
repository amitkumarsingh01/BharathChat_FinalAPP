class Gift {
  final int id;
  final String name;
  final int diamondAmount;
  final String gifFilename;

  Gift({
    required this.id,
    required this.name,
    required this.diamondAmount,
    required this.gifFilename,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'],
      name: json['name'],
      diamondAmount: json['diamond_amount'],
      gifFilename: json['gif_filename'],
    );
  }
}
