class AppConstants {
  static const int postsPerPage = 20;
  static const int maxPostLength = 500;
  static const int maxBioLength = 150;
  
  // Default avatar generator
  static String getDefaultAvatar(String name) {
    final encodedName = Uri.encodeComponent(name);
    return 'https://ui-avatars.com/api/?name=$encodedName&background=random&size=200&bold=true';
  }
}