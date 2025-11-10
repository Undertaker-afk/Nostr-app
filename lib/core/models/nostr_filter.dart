class NostrFilter {
  final List<String>? ids;
  final List<String>? authors;
  final List<int>? kinds;
  final Map<String, List<String>>? tags;
  final int? since;
  final int? until;
  final int? limit;

  NostrFilter({
    this.ids,
    this.authors,
    this.kinds,
    this.tags,
    this.since,
    this.until,
    this.limit,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (ids != null) json['ids'] = ids;
    if (authors != null) json['authors'] = authors;
    if (kinds != null) json['kinds'] = kinds;
    if (tags != null) {
      tags!.forEach((key, value) {
        json['#$key'] = value;
      });
    }
    if (since != null) json['since'] = since;
    if (until != null) json['until'] = until;
    if (limit != null) json['limit'] = limit;
    return json;
  }
}
