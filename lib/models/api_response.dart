class ApiResponse {
  final ApiInfo info;
  final List<dynamic> results;

  ApiResponse({required this.info, required this.results});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      info: ApiInfo.fromJson(json['info']),
      results: json['results'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'info': info.toJson(), 'results': results};
  }
}

class ApiInfo {
  final int count;
  final int pages;
  final String? next;
  final String? prev;

  ApiInfo({required this.count, required this.pages, this.next, this.prev});

  factory ApiInfo.fromJson(Map<String, dynamic> json) {
    return ApiInfo(
      count: json['count'],
      pages: json['pages'],
      next: json['next'],
      prev: json['prev'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'count': count, 'pages': pages, 'next': next, 'prev': prev};
  }
}
