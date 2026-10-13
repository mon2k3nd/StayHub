// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkout_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CheckoutRequestModel {

 int get id; int get roomId; int get tenantId; int get ownerId; int get contractId; String get status; DateTime get targetCheckoutDate; String? get checkoutImages; String get tenantNote; String? get ownerReason; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of CheckoutRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutRequestModelCopyWith<CheckoutRequestModel> get copyWith => _$CheckoutRequestModelCopyWithImpl<CheckoutRequestModel>(this as CheckoutRequestModel, _$identity);

  /// Serializes this CheckoutRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.status, status) || other.status == status)&&(identical(other.targetCheckoutDate, targetCheckoutDate) || other.targetCheckoutDate == targetCheckoutDate)&&(identical(other.checkoutImages, checkoutImages) || other.checkoutImages == checkoutImages)&&(identical(other.tenantNote, tenantNote) || other.tenantNote == tenantNote)&&(identical(other.ownerReason, ownerReason) || other.ownerReason == ownerReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,tenantId,ownerId,contractId,status,targetCheckoutDate,checkoutImages,tenantNote,ownerReason,createdAt,updatedAt);

@override
String toString() {
  return 'CheckoutRequestModel(id: $id, roomId: $roomId, tenantId: $tenantId, ownerId: $ownerId, contractId: $contractId, status: $status, targetCheckoutDate: $targetCheckoutDate, checkoutImages: $checkoutImages, tenantNote: $tenantNote, ownerReason: $ownerReason, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CheckoutRequestModelCopyWith<$Res>  {
  factory $CheckoutRequestModelCopyWith(CheckoutRequestModel value, $Res Function(CheckoutRequestModel) _then) = _$CheckoutRequestModelCopyWithImpl;
@useResult
$Res call({
 int id, int roomId, int tenantId, int ownerId, int contractId, String status, DateTime targetCheckoutDate, String? checkoutImages, String tenantNote, String? ownerReason, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$CheckoutRequestModelCopyWithImpl<$Res>
    implements $CheckoutRequestModelCopyWith<$Res> {
  _$CheckoutRequestModelCopyWithImpl(this._self, this._then);

  final CheckoutRequestModel _self;
  final $Res Function(CheckoutRequestModel) _then;

/// Create a copy of CheckoutRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomId = null,Object? tenantId = null,Object? ownerId = null,Object? contractId = null,Object? status = null,Object? targetCheckoutDate = null,Object? checkoutImages = freezed,Object? tenantNote = null,Object? ownerReason = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as int,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,targetCheckoutDate: null == targetCheckoutDate ? _self.targetCheckoutDate : targetCheckoutDate // ignore: cast_nullable_to_non_nullable
as DateTime,checkoutImages: freezed == checkoutImages ? _self.checkoutImages : checkoutImages // ignore: cast_nullable_to_non_nullable
as String?,tenantNote: null == tenantNote ? _self.tenantNote : tenantNote // ignore: cast_nullable_to_non_nullable
as String,ownerReason: freezed == ownerReason ? _self.ownerReason : ownerReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutRequestModel].
extension CheckoutRequestModelPatterns on CheckoutRequestModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutRequestModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutRequestModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutRequestModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int roomId,  int tenantId,  int ownerId,  int contractId,  String status,  DateTime targetCheckoutDate,  String? checkoutImages,  String tenantNote,  String? ownerReason,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutRequestModel() when $default != null:
return $default(_that.id,_that.roomId,_that.tenantId,_that.ownerId,_that.contractId,_that.status,_that.targetCheckoutDate,_that.checkoutImages,_that.tenantNote,_that.ownerReason,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int roomId,  int tenantId,  int ownerId,  int contractId,  String status,  DateTime targetCheckoutDate,  String? checkoutImages,  String tenantNote,  String? ownerReason,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CheckoutRequestModel():
return $default(_that.id,_that.roomId,_that.tenantId,_that.ownerId,_that.contractId,_that.status,_that.targetCheckoutDate,_that.checkoutImages,_that.tenantNote,_that.ownerReason,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int roomId,  int tenantId,  int ownerId,  int contractId,  String status,  DateTime targetCheckoutDate,  String? checkoutImages,  String tenantNote,  String? ownerReason,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutRequestModel() when $default != null:
return $default(_that.id,_that.roomId,_that.tenantId,_that.ownerId,_that.contractId,_that.status,_that.targetCheckoutDate,_that.checkoutImages,_that.tenantNote,_that.ownerReason,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutRequestModel extends CheckoutRequestModel {
  const _CheckoutRequestModel({required this.id, required this.roomId, required this.tenantId, required this.ownerId, required this.contractId, required this.status, required this.targetCheckoutDate, this.checkoutImages, required this.tenantNote, this.ownerReason, required this.createdAt, required this.updatedAt}): super._();
  factory _CheckoutRequestModel.fromJson(Map<String, dynamic> json) => _$CheckoutRequestModelFromJson(json);

@override final  int id;
@override final  int roomId;
@override final  int tenantId;
@override final  int ownerId;
@override final  int contractId;
@override final  String status;
@override final  DateTime targetCheckoutDate;
@override final  String? checkoutImages;
@override final  String tenantNote;
@override final  String? ownerReason;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of CheckoutRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutRequestModelCopyWith<_CheckoutRequestModel> get copyWith => __$CheckoutRequestModelCopyWithImpl<_CheckoutRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.status, status) || other.status == status)&&(identical(other.targetCheckoutDate, targetCheckoutDate) || other.targetCheckoutDate == targetCheckoutDate)&&(identical(other.checkoutImages, checkoutImages) || other.checkoutImages == checkoutImages)&&(identical(other.tenantNote, tenantNote) || other.tenantNote == tenantNote)&&(identical(other.ownerReason, ownerReason) || other.ownerReason == ownerReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,tenantId,ownerId,contractId,status,targetCheckoutDate,checkoutImages,tenantNote,ownerReason,createdAt,updatedAt);

@override
String toString() {
  return 'CheckoutRequestModel(id: $id, roomId: $roomId, tenantId: $tenantId, ownerId: $ownerId, contractId: $contractId, status: $status, targetCheckoutDate: $targetCheckoutDate, checkoutImages: $checkoutImages, tenantNote: $tenantNote, ownerReason: $ownerReason, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CheckoutRequestModelCopyWith<$Res> implements $CheckoutRequestModelCopyWith<$Res> {
  factory _$CheckoutRequestModelCopyWith(_CheckoutRequestModel value, $Res Function(_CheckoutRequestModel) _then) = __$CheckoutRequestModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int roomId, int tenantId, int ownerId, int contractId, String status, DateTime targetCheckoutDate, String? checkoutImages, String tenantNote, String? ownerReason, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$CheckoutRequestModelCopyWithImpl<$Res>
    implements _$CheckoutRequestModelCopyWith<$Res> {
  __$CheckoutRequestModelCopyWithImpl(this._self, this._then);

  final _CheckoutRequestModel _self;
  final $Res Function(_CheckoutRequestModel) _then;

/// Create a copy of CheckoutRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomId = null,Object? tenantId = null,Object? ownerId = null,Object? contractId = null,Object? status = null,Object? targetCheckoutDate = null,Object? checkoutImages = freezed,Object? tenantNote = null,Object? ownerReason = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_CheckoutRequestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as int,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,targetCheckoutDate: null == targetCheckoutDate ? _self.targetCheckoutDate : targetCheckoutDate // ignore: cast_nullable_to_non_nullable
as DateTime,checkoutImages: freezed == checkoutImages ? _self.checkoutImages : checkoutImages // ignore: cast_nullable_to_non_nullable
as String?,tenantNote: null == tenantNote ? _self.tenantNote : tenantNote // ignore: cast_nullable_to_non_nullable
as String,ownerReason: freezed == ownerReason ? _self.ownerReason : ownerReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
