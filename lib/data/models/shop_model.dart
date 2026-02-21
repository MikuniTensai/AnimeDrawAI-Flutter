import 'package:json_annotation/json_annotation.dart';

part 'shop_model.g.dart';

@JsonSerializable()
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String type; // "item", "currency" or "subscription"
  final int? amount;
  @JsonKey(name: 'cost_usd')
  final double? costUsd;
  @JsonKey(name: 'cost_gems')
  final int? costGems;
  @JsonKey(name: 'item_id')
  final String? itemId;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'duration_days')
  final int? durationDays;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.amount,
    this.costUsd,
    this.costGems,
    this.itemId,
    this.imageUrl,
    this.durationDays,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) =>
      _$ShopItemFromJson(json);
  Map<String, dynamic> toJson() => _$ShopItemToJson(this);
}

@JsonSerializable()
class InventoryItemModel {
  final String id;
  final String name;
  final int amount;
  final int affectionValue;
  final String description;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.affectionValue,
    required this.description,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryItemModelToJson(this);
}

@JsonSerializable()
class GiftRequest {
  final String characterId;
  final String itemId;

  GiftRequest({required this.characterId, required this.itemId});

  factory GiftRequest.fromJson(Map<String, dynamic> json) =>
      _$GiftRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GiftRequestToJson(this);
}

@JsonSerializable()
class GiftResponse {
  final bool success;
  final int? affectionAdded;
  final String? message;
  final String? error;

  GiftResponse({
    required this.success,
    this.affectionAdded,
    this.message,
    this.error,
  });

  factory GiftResponse.fromJson(Map<String, dynamic> json) =>
      _$GiftResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GiftResponseToJson(this);
}

class UseItemRequest {
  final String itemId;

  UseItemRequest({required this.itemId});

  factory UseItemRequest.fromJson(Map<String, dynamic> json) =>
      UseItemRequest(itemId: json['itemId'] as String);

  Map<String, dynamic> toJson() => <String, dynamic>{'itemId': itemId};
}

class UseItemResponse {
  final bool success;
  final String? message;
  final String? error;

  UseItemResponse({required this.success, this.message, this.error});

  factory UseItemResponse.fromJson(Map<String, dynamic> json) =>
      UseItemResponse(
        success: json['success'] as bool,
        message: json['message'] as String?,
        error: json['error'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'success': success,
    'message': message,
    'error': error,
  };
}
