// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopItem _$ShopItemFromJson(Map<String, dynamic> json) => ShopItem(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  type: json['type'] as String,
  amount: (json['amount'] as num?)?.toInt(),
  costUsd: (json['cost_usd'] as num?)?.toDouble(),
  costGems: (json['cost_gems'] as num?)?.toInt(),
  itemId: json['item_id'] as String?,
  imageUrl: json['image_url'] as String?,
  durationDays: (json['duration_days'] as num?)?.toInt(),
);

Map<String, dynamic> _$ShopItemToJson(ShopItem instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'type': instance.type,
  'amount': instance.amount,
  'cost_usd': instance.costUsd,
  'cost_gems': instance.costGems,
  'item_id': instance.itemId,
  'image_url': instance.imageUrl,
  'duration_days': instance.durationDays,
};

InventoryItemModel _$InventoryItemModelFromJson(Map<String, dynamic> json) =>
    InventoryItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toInt(),
      affectionValue: (json['affectionValue'] as num).toInt(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$InventoryItemModelToJson(InventoryItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'affectionValue': instance.affectionValue,
      'description': instance.description,
    };

GiftRequest _$GiftRequestFromJson(Map<String, dynamic> json) => GiftRequest(
  characterId: json['characterId'] as String,
  itemId: json['itemId'] as String,
);

Map<String, dynamic> _$GiftRequestToJson(GiftRequest instance) =>
    <String, dynamic>{
      'characterId': instance.characterId,
      'itemId': instance.itemId,
    };

GiftResponse _$GiftResponseFromJson(Map<String, dynamic> json) => GiftResponse(
  success: json['success'] as bool,
  affectionAdded: (json['affectionAdded'] as num?)?.toInt(),
  message: json['message'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$GiftResponseToJson(GiftResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'affectionAdded': instance.affectionAdded,
      'message': instance.message,
      'error': instance.error,
    };
