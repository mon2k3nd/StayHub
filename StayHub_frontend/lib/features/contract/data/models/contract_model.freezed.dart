// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContractModel {

 int get id; int get roomId; int get tenantId; int get ownerId; DateTime get startDate; DateTime get endDate; double get monthlyRent; double? get depositAmount; double? get electricityPrice; double? get waterPrice; double? get serviceFee; String? get terms; String get status; DateTime? get signedAt; DateTime? get terminatedAt; String? get terminationReason; String? get contractImages; String? get electricityMeterImage; String? get waterMeterImage; String? get roomName; int? get branchId; String? get branchName; String? get ownerName; String? get tenantName; bool get ekycVerified; String? get ekycDocumentId; String? get digitalSignatureId; String? get signatureProvider; DateTime get createdAt;
/// Create a copy of ContractModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractModelCopyWith<ContractModel> get copyWith => _$ContractModelCopyWithImpl<ContractModel>(this as ContractModel, _$identity);

  /// Serializes this ContractModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractModel&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.monthlyRent, monthlyRent) || other.monthlyRent == monthlyRent)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount)&&(identical(other.electricityPrice, electricityPrice) || other.electricityPrice == electricityPrice)&&(identical(other.waterPrice, waterPrice) || other.waterPrice == waterPrice)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.status, status) || other.status == status)&&(identical(other.signedAt, signedAt) || other.signedAt == signedAt)&&(identical(other.terminatedAt, terminatedAt) || other.terminatedAt == terminatedAt)&&(identical(other.terminationReason, terminationReason) || other.terminationReason == terminationReason)&&(identical(other.contractImages, contractImages) || other.contractImages == contractImages)&&(identical(other.electricityMeterImage, electricityMeterImage) || other.electricityMeterImage == electricityMeterImage)&&(identical(other.waterMeterImage, waterMeterImage) || other.waterMeterImage == waterMeterImage)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.ekycVerified, ekycVerified) || other.ekycVerified == ekycVerified)&&(identical(other.ekycDocumentId, ekycDocumentId) || other.ekycDocumentId == ekycDocumentId)&&(identical(other.digitalSignatureId, digitalSignatureId) || other.digitalSignatureId == digitalSignatureId)&&(identical(other.signatureProvider, signatureProvider) || other.signatureProvider == signatureProvider)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,roomId,tenantId,ownerId,startDate,endDate,monthlyRent,depositAmount,electricityPrice,waterPrice,serviceFee,terms,status,signedAt,terminatedAt,terminationReason,contractImages,electricityMeterImage,waterMeterImage,roomName,branchId,branchName,ownerName,tenantName,ekycVerified,ekycDocumentId,digitalSignatureId,signatureProvider,createdAt]);

@override
String toString() {
  return 'ContractModel(id: $id, roomId: $roomId, tenantId: $tenantId, ownerId: $ownerId, startDate: $startDate, endDate: $endDate, monthlyRent: $monthlyRent, depositAmount: $depositAmount, electricityPrice: $electricityPrice, waterPrice: $waterPrice, serviceFee: $serviceFee, terms: $terms, status: $status, signedAt: $signedAt, terminatedAt: $terminatedAt, terminationReason: $terminationReason, contractImages: $contractImages, electricityMeterImage: $electricityMeterImage, waterMeterImage: $waterMeterImage, roomName: $roomName, branchId: $branchId, branchName: $branchName, ownerName: $ownerName, tenantName: $tenantName, ekycVerified: $ekycVerified, ekycDocumentId: $ekycDocumentId, digitalSignatureId: $digitalSignatureId, signatureProvider: $signatureProvider, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ContractModelCopyWith<$Res>  {
  factory $ContractModelCopyWith(ContractModel value, $Res Function(ContractModel) _then) = _$ContractModelCopyWithImpl;
@useResult
$Res call({
 int id, int roomId, int tenantId, int ownerId, DateTime startDate, DateTime endDate, double monthlyRent, double? depositAmount, double? electricityPrice, double? waterPrice, double? serviceFee, String? terms, String status, DateTime? signedAt, DateTime? terminatedAt, String? terminationReason, String? contractImages, String? electricityMeterImage, String? waterMeterImage, String? roomName, int? branchId, String? branchName, String? ownerName, String? tenantName, bool ekycVerified, String? ekycDocumentId, String? digitalSignatureId, String? signatureProvider, DateTime createdAt
});




}
/// @nodoc
class _$ContractModelCopyWithImpl<$Res>
    implements $ContractModelCopyWith<$Res> {
  _$ContractModelCopyWithImpl(this._self, this._then);

  final ContractModel _self;
  final $Res Function(ContractModel) _then;

/// Create a copy of ContractModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomId = null,Object? tenantId = null,Object? ownerId = null,Object? startDate = null,Object? endDate = null,Object? monthlyRent = null,Object? depositAmount = freezed,Object? electricityPrice = freezed,Object? waterPrice = freezed,Object? serviceFee = freezed,Object? terms = freezed,Object? status = null,Object? signedAt = freezed,Object? terminatedAt = freezed,Object? terminationReason = freezed,Object? contractImages = freezed,Object? electricityMeterImage = freezed,Object? waterMeterImage = freezed,Object? roomName = freezed,Object? branchId = freezed,Object? branchName = freezed,Object? ownerName = freezed,Object? tenantName = freezed,Object? ekycVerified = null,Object? ekycDocumentId = freezed,Object? digitalSignatureId = freezed,Object? signatureProvider = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as int,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,monthlyRent: null == monthlyRent ? _self.monthlyRent : monthlyRent // ignore: cast_nullable_to_non_nullable
as double,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as double?,electricityPrice: freezed == electricityPrice ? _self.electricityPrice : electricityPrice // ignore: cast_nullable_to_non_nullable
as double?,waterPrice: freezed == waterPrice ? _self.waterPrice : waterPrice // ignore: cast_nullable_to_non_nullable
as double?,serviceFee: freezed == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double?,terms: freezed == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,signedAt: freezed == signedAt ? _self.signedAt : signedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,terminatedAt: freezed == terminatedAt ? _self.terminatedAt : terminatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,terminationReason: freezed == terminationReason ? _self.terminationReason : terminationReason // ignore: cast_nullable_to_non_nullable
as String?,contractImages: freezed == contractImages ? _self.contractImages : contractImages // ignore: cast_nullable_to_non_nullable
as String?,electricityMeterImage: freezed == electricityMeterImage ? _self.electricityMeterImage : electricityMeterImage // ignore: cast_nullable_to_non_nullable
as String?,waterMeterImage: freezed == waterMeterImage ? _self.waterMeterImage : waterMeterImage // ignore: cast_nullable_to_non_nullable
as String?,roomName: freezed == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as int?,branchName: freezed == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String?,ownerName: freezed == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String?,tenantName: freezed == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String?,ekycVerified: null == ekycVerified ? _self.ekycVerified : ekycVerified // ignore: cast_nullable_to_non_nullable
as bool,ekycDocumentId: freezed == ekycDocumentId ? _self.ekycDocumentId : ekycDocumentId // ignore: cast_nullable_to_non_nullable
as String?,digitalSignatureId: freezed == digitalSignatureId ? _self.digitalSignatureId : digitalSignatureId // ignore: cast_nullable_to_non_nullable
as String?,signatureProvider: freezed == signatureProvider ? _self.signatureProvider : signatureProvider // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ContractModel].
extension ContractModelPatterns on ContractModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContractModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContractModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContractModel value)  $default,){
final _that = this;
switch (_that) {
case _ContractModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContractModel value)?  $default,){
final _that = this;
switch (_that) {
case _ContractModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int roomId,  int tenantId,  int ownerId,  DateTime startDate,  DateTime endDate,  double monthlyRent,  double? depositAmount,  double? electricityPrice,  double? waterPrice,  double? serviceFee,  String? terms,  String status,  DateTime? signedAt,  DateTime? terminatedAt,  String? terminationReason,  String? contractImages,  String? electricityMeterImage,  String? waterMeterImage,  String? roomName,  int? branchId,  String? branchName,  String? ownerName,  String? tenantName,  bool ekycVerified,  String? ekycDocumentId,  String? digitalSignatureId,  String? signatureProvider,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContractModel() when $default != null:
return $default(_that.id,_that.roomId,_that.tenantId,_that.ownerId,_that.startDate,_that.endDate,_that.monthlyRent,_that.depositAmount,_that.electricityPrice,_that.waterPrice,_that.serviceFee,_that.terms,_that.status,_that.signedAt,_that.terminatedAt,_that.terminationReason,_that.contractImages,_that.electricityMeterImage,_that.waterMeterImage,_that.roomName,_that.branchId,_that.branchName,_that.ownerName,_that.tenantName,_that.ekycVerified,_that.ekycDocumentId,_that.digitalSignatureId,_that.signatureProvider,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int roomId,  int tenantId,  int ownerId,  DateTime startDate,  DateTime endDate,  double monthlyRent,  double? depositAmount,  double? electricityPrice,  double? waterPrice,  double? serviceFee,  String? terms,  String status,  DateTime? signedAt,  DateTime? terminatedAt,  String? terminationReason,  String? contractImages,  String? electricityMeterImage,  String? waterMeterImage,  String? roomName,  int? branchId,  String? branchName,  String? ownerName,  String? tenantName,  bool ekycVerified,  String? ekycDocumentId,  String? digitalSignatureId,  String? signatureProvider,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ContractModel():
return $default(_that.id,_that.roomId,_that.tenantId,_that.ownerId,_that.startDate,_that.endDate,_that.monthlyRent,_that.depositAmount,_that.electricityPrice,_that.waterPrice,_that.serviceFee,_that.terms,_that.status,_that.signedAt,_that.terminatedAt,_that.terminationReason,_that.contractImages,_that.electricityMeterImage,_that.waterMeterImage,_that.roomName,_that.branchId,_that.branchName,_that.ownerName,_that.tenantName,_that.ekycVerified,_that.ekycDocumentId,_that.digitalSignatureId,_that.signatureProvider,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int roomId,  int tenantId,  int ownerId,  DateTime startDate,  DateTime endDate,  double monthlyRent,  double? depositAmount,  double? electricityPrice,  double? waterPrice,  double? serviceFee,  String? terms,  String status,  DateTime? signedAt,  DateTime? terminatedAt,  String? terminationReason,  String? contractImages,  String? electricityMeterImage,  String? waterMeterImage,  String? roomName,  int? branchId,  String? branchName,  String? ownerName,  String? tenantName,  bool ekycVerified,  String? ekycDocumentId,  String? digitalSignatureId,  String? signatureProvider,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ContractModel() when $default != null:
return $default(_that.id,_that.roomId,_that.tenantId,_that.ownerId,_that.startDate,_that.endDate,_that.monthlyRent,_that.depositAmount,_that.electricityPrice,_that.waterPrice,_that.serviceFee,_that.terms,_that.status,_that.signedAt,_that.terminatedAt,_that.terminationReason,_that.contractImages,_that.electricityMeterImage,_that.waterMeterImage,_that.roomName,_that.branchId,_that.branchName,_that.ownerName,_that.tenantName,_that.ekycVerified,_that.ekycDocumentId,_that.digitalSignatureId,_that.signatureProvider,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContractModel extends ContractModel {
  const _ContractModel({required this.id, required this.roomId, required this.tenantId, required this.ownerId, required this.startDate, required this.endDate, required this.monthlyRent, this.depositAmount, this.electricityPrice, this.waterPrice, this.serviceFee, this.terms, this.status = 'ACTIVE', this.signedAt, this.terminatedAt, this.terminationReason, this.contractImages, this.electricityMeterImage, this.waterMeterImage, this.roomName, this.branchId, this.branchName, this.ownerName, this.tenantName, this.ekycVerified = false, this.ekycDocumentId, this.digitalSignatureId, this.signatureProvider, required this.createdAt}): super._();
  factory _ContractModel.fromJson(Map<String, dynamic> json) => _$ContractModelFromJson(json);

@override final  int id;
@override final  int roomId;
@override final  int tenantId;
@override final  int ownerId;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  double monthlyRent;
@override final  double? depositAmount;
@override final  double? electricityPrice;
@override final  double? waterPrice;
@override final  double? serviceFee;
@override final  String? terms;
@override@JsonKey() final  String status;
@override final  DateTime? signedAt;
@override final  DateTime? terminatedAt;
@override final  String? terminationReason;
@override final  String? contractImages;
@override final  String? electricityMeterImage;
@override final  String? waterMeterImage;
@override final  String? roomName;
@override final  int? branchId;
@override final  String? branchName;
@override final  String? ownerName;
@override final  String? tenantName;
@override@JsonKey() final  bool ekycVerified;
@override final  String? ekycDocumentId;
@override final  String? digitalSignatureId;
@override final  String? signatureProvider;
@override final  DateTime createdAt;

/// Create a copy of ContractModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractModelCopyWith<_ContractModel> get copyWith => __$ContractModelCopyWithImpl<_ContractModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractModel&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.monthlyRent, monthlyRent) || other.monthlyRent == monthlyRent)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount)&&(identical(other.electricityPrice, electricityPrice) || other.electricityPrice == electricityPrice)&&(identical(other.waterPrice, waterPrice) || other.waterPrice == waterPrice)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.status, status) || other.status == status)&&(identical(other.signedAt, signedAt) || other.signedAt == signedAt)&&(identical(other.terminatedAt, terminatedAt) || other.terminatedAt == terminatedAt)&&(identical(other.terminationReason, terminationReason) || other.terminationReason == terminationReason)&&(identical(other.contractImages, contractImages) || other.contractImages == contractImages)&&(identical(other.electricityMeterImage, electricityMeterImage) || other.electricityMeterImage == electricityMeterImage)&&(identical(other.waterMeterImage, waterMeterImage) || other.waterMeterImage == waterMeterImage)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.ekycVerified, ekycVerified) || other.ekycVerified == ekycVerified)&&(identical(other.ekycDocumentId, ekycDocumentId) || other.ekycDocumentId == ekycDocumentId)&&(identical(other.digitalSignatureId, digitalSignatureId) || other.digitalSignatureId == digitalSignatureId)&&(identical(other.signatureProvider, signatureProvider) || other.signatureProvider == signatureProvider)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,roomId,tenantId,ownerId,startDate,endDate,monthlyRent,depositAmount,electricityPrice,waterPrice,serviceFee,terms,status,signedAt,terminatedAt,terminationReason,contractImages,electricityMeterImage,waterMeterImage,roomName,branchId,branchName,ownerName,tenantName,ekycVerified,ekycDocumentId,digitalSignatureId,signatureProvider,createdAt]);

@override
String toString() {
  return 'ContractModel(id: $id, roomId: $roomId, tenantId: $tenantId, ownerId: $ownerId, startDate: $startDate, endDate: $endDate, monthlyRent: $monthlyRent, depositAmount: $depositAmount, electricityPrice: $electricityPrice, waterPrice: $waterPrice, serviceFee: $serviceFee, terms: $terms, status: $status, signedAt: $signedAt, terminatedAt: $terminatedAt, terminationReason: $terminationReason, contractImages: $contractImages, electricityMeterImage: $electricityMeterImage, waterMeterImage: $waterMeterImage, roomName: $roomName, branchId: $branchId, branchName: $branchName, ownerName: $ownerName, tenantName: $tenantName, ekycVerified: $ekycVerified, ekycDocumentId: $ekycDocumentId, digitalSignatureId: $digitalSignatureId, signatureProvider: $signatureProvider, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ContractModelCopyWith<$Res> implements $ContractModelCopyWith<$Res> {
  factory _$ContractModelCopyWith(_ContractModel value, $Res Function(_ContractModel) _then) = __$ContractModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int roomId, int tenantId, int ownerId, DateTime startDate, DateTime endDate, double monthlyRent, double? depositAmount, double? electricityPrice, double? waterPrice, double? serviceFee, String? terms, String status, DateTime? signedAt, DateTime? terminatedAt, String? terminationReason, String? contractImages, String? electricityMeterImage, String? waterMeterImage, String? roomName, int? branchId, String? branchName, String? ownerName, String? tenantName, bool ekycVerified, String? ekycDocumentId, String? digitalSignatureId, String? signatureProvider, DateTime createdAt
});




}
/// @nodoc
class __$ContractModelCopyWithImpl<$Res>
    implements _$ContractModelCopyWith<$Res> {
  __$ContractModelCopyWithImpl(this._self, this._then);

  final _ContractModel _self;
  final $Res Function(_ContractModel) _then;

/// Create a copy of ContractModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomId = null,Object? tenantId = null,Object? ownerId = null,Object? startDate = null,Object? endDate = null,Object? monthlyRent = null,Object? depositAmount = freezed,Object? electricityPrice = freezed,Object? waterPrice = freezed,Object? serviceFee = freezed,Object? terms = freezed,Object? status = null,Object? signedAt = freezed,Object? terminatedAt = freezed,Object? terminationReason = freezed,Object? contractImages = freezed,Object? electricityMeterImage = freezed,Object? waterMeterImage = freezed,Object? roomName = freezed,Object? branchId = freezed,Object? branchName = freezed,Object? ownerName = freezed,Object? tenantName = freezed,Object? ekycVerified = null,Object? ekycDocumentId = freezed,Object? digitalSignatureId = freezed,Object? signatureProvider = freezed,Object? createdAt = null,}) {
  return _then(_ContractModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as int,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,monthlyRent: null == monthlyRent ? _self.monthlyRent : monthlyRent // ignore: cast_nullable_to_non_nullable
as double,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as double?,electricityPrice: freezed == electricityPrice ? _self.electricityPrice : electricityPrice // ignore: cast_nullable_to_non_nullable
as double?,waterPrice: freezed == waterPrice ? _self.waterPrice : waterPrice // ignore: cast_nullable_to_non_nullable
as double?,serviceFee: freezed == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double?,terms: freezed == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,signedAt: freezed == signedAt ? _self.signedAt : signedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,terminatedAt: freezed == terminatedAt ? _self.terminatedAt : terminatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,terminationReason: freezed == terminationReason ? _self.terminationReason : terminationReason // ignore: cast_nullable_to_non_nullable
as String?,contractImages: freezed == contractImages ? _self.contractImages : contractImages // ignore: cast_nullable_to_non_nullable
as String?,electricityMeterImage: freezed == electricityMeterImage ? _self.electricityMeterImage : electricityMeterImage // ignore: cast_nullable_to_non_nullable
as String?,waterMeterImage: freezed == waterMeterImage ? _self.waterMeterImage : waterMeterImage // ignore: cast_nullable_to_non_nullable
as String?,roomName: freezed == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String?,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as int?,branchName: freezed == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String?,ownerName: freezed == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String?,tenantName: freezed == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String?,ekycVerified: null == ekycVerified ? _self.ekycVerified : ekycVerified // ignore: cast_nullable_to_non_nullable
as bool,ekycDocumentId: freezed == ekycDocumentId ? _self.ekycDocumentId : ekycDocumentId // ignore: cast_nullable_to_non_nullable
as String?,digitalSignatureId: freezed == digitalSignatureId ? _self.digitalSignatureId : digitalSignatureId // ignore: cast_nullable_to_non_nullable
as String?,signatureProvider: freezed == signatureProvider ? _self.signatureProvider : signatureProvider // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
