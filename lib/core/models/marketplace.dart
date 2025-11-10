class MarketplaceListing {
  final String id;
  final String title;
  final String description;
  final int price; // in sats
  final String sellerPubkey;
  final List<String> images;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final String? location;
  final Map<String, dynamic>? metadata;

  MarketplaceListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.sellerPubkey,
    this.images = const [],
    required this.category,
    this.isActive = true,
    required this.createdAt,
    this.location,
    this.metadata,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceListing(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      sellerPubkey: json['sellerPubkey'] as String,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      category: json['category'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      location: json['location'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'sellerPubkey': sellerPubkey,
      'images': images,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'location': location,
      'metadata': metadata,
    };
  }
}

class MarketplaceOrder {
  final String id;
  final String listingId;
  final String buyerPubkey;
  final String sellerPubkey;
  final int amount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? shippingAddress;
  final String? trackingNumber;

  MarketplaceOrder({
    required this.id,
    required this.listingId,
    required this.buyerPubkey,
    required this.sellerPubkey,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.shippingAddress,
    this.trackingNumber,
  });

  factory MarketplaceOrder.fromJson(Map<String, dynamic> json) {
    return MarketplaceOrder(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      buyerPubkey: json['buyerPubkey'] as String,
      sellerPubkey: json['sellerPubkey'] as String,
      amount: json['amount'] as int,
      status: OrderStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      shippingAddress: json['shippingAddress'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'buyerPubkey': buyerPubkey,
      'sellerPubkey': sellerPubkey,
      'amount': amount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'shippingAddress': shippingAddress,
      'trackingNumber': trackingNumber,
    };
  }
}

enum OrderStatus {
  pending,
  paid,
  shipped,
  delivered,
  cancelled,
}
