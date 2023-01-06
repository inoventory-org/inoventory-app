class MyUserInfo {
  final String? name;
  final String? preferredUserName;
  final String? givenName;
  final String? familyName;
  final String? email;

  MyUserInfo(this.name, this.preferredUserName, this.givenName, this.familyName, this.email);

  String? get fullName {
    if (givenName == null && familyName == null) return null;
    return "${givenName ?? ""} ${familyName ?? ""}";
  }
}