/// Single tile on the customer home category grid — stored in Firestore for admin edits.
class CustomerHomeCategory {
  const CustomerHomeCategory({
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.imageUrl,
    this.order = 0,
  });

  final String title;
  final String subtitle;
  final String tagline;
  final String imageUrl;
  final int order;

  Map<String, dynamic> toFirestoreMap() => {
        'title': title,
        'subtitle': subtitle,
        'tagline': tagline,
        'imageUrl': imageUrl,
        'order': order,
      };

  static CustomerHomeCategory? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final title = (m['title'] as String?)?.trim();
    final subtitle = (m['subtitle'] as String?)?.trim();
    final tagline = (m['tagline'] as String?)?.trim();
    final imageUrl = (m['imageUrl'] as String?)?.trim();
    if (title == null ||
        title.isEmpty ||
        subtitle == null ||
        tagline == null ||
        imageUrl == null ||
        imageUrl.isEmpty) {
      return null;
    }
    final orderRaw = m['order'];
    final order = orderRaw is int
        ? orderRaw
        : orderRaw is num
            ? orderRaw.toInt()
            : 0;
    return CustomerHomeCategory(
      title: title,
      subtitle: subtitle,
      tagline: tagline,
      imageUrl: imageUrl,
      order: order,
    );
  }
}
