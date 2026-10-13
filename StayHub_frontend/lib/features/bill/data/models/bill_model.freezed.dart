// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bill_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BillModel {

 int get id; int get roomId; int? get contractId; int? get tenantId; int get month; int get year; double? get electricCurrent; double? get electricPrevious; double? get waterCurrent; double? get waterPrevious; double? get electricUnitPrice; double? get waterUnitPrice; double? get electricAmount; double? get waterAmount; double? get rentAmount; double? get serviceAmount; double? get totalAmount; String? get electricImage; String? get waterImage; String? get paymentQrUrl; String get type; String get status; double? get damageFee; String? get damageReason; double? get sharedPoolAmount; String? get serviceDetails; double? get discountAmount; bool get isPaid; DateTime? get paidAt; bool get paidByCash; int? get collectedByStaffId; DateTime? get dueDate; DateTime get createdAt;
/// Create a copy of BillModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillModelCopyWith<BillModel> get copyWith => _$BillModelCopyWithImpl<BillModel>(this as BillModel, _$identity);

  /// Serializes this BillModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillModel&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.month, month) || other.month == month)&&(identical(other.year, year) || other.year == year)&&(identical(other.electricCurrent, electricCurrent) || other.electricCurrent == electricCurrent)&&(identical(other.electricPrevious, electricPrevious) || other.electricPrevious == electricPrevious)&&(identical(other.waterCurrent, waterCurrent) || other.waterCurrent == waterCurrent)&&(identical(other.waterPrevious, waterPrevious) || other.waterPrevious == waterPrevious)&&(identical(other.electricUnitPrice, electricUnitPrice) || other.electricUnitPrice == electricUnitPrice)&&(identical(other.waterUnitPrice, waterUnitPrice) || other.waterUnitPrice == waterUnitPrice)&&(identical(other.electricAmount, electricAmount) || other.electricAmount == electricAmount)&&(identical(other.waterAmount, waterAmount) || other.waterAmount == waterAmount)&&(identical(other.rentAmount, rentAmount) || other.rentAmount == rentAmount)&&(identical(other.serviceAmount, serviceAmount) || other.serviceAmount == serviceAmount)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.electricImage, electricImage) || other.electricImage == electricImage)&&(identical(other.waterImage, waterImage) || other.waterImage == waterImage)&&(identical(other.paymentQrUrl, paymentQrUrl) || other.paymentQrUrl == paymentQrUrl)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.damageFee, damageFee) || other.damageFee == damageFee)&&(identical(other.damageReason, damageReason) || other.damageReason == damageReason)&&(identical(other.sharedPoolAmount, sharedPoolAmount) || other.sharedPoolAmount == sharedPoolAmount)&&(identical(other.serviceDetails, serviceDetails) || other.serviceDetails == serviceDetails)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.paidByCash, paidByCash) || other.paidByCash == paidByCash)&&(identical(other.collectedByStaffId, collectedByStaffId) || other.collectedByStaffId == collectedByStaffId)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,roomId,contractId,tenantId,month,year,electricCurrent,electricPrevious,waterCurrent,waterPrevious,electricUnitPrice,waterUnitPrice,electricAmount,waterAmount,rentAmount,serviceAmount,totalAmount,electricImage,waterImage,paymentQrUrl,type,status,damageFee,damageReason,sharedPoolAmount,serviceDetails,discountAmount,isPaid,paidAt,paidByCash,collectedByStaffId,dueDate,createdAt]);

@override
String toString() {
  return 'BillModel(id: $id, roomId: $roomId, contractId: $contractId, tenantId: $tenantId, month: $month, year: $year, electricCurrent: $electricCurrent, electricPrevious: $electricPrevious, waterCurrent: $waterCurrent, waterPrevious: $waterPrevious, electricUnitPrice: $electricUnitPrice, waterUnitPrice: $waterUnitPrice, electricAmount: $electricAmount, waterAmount: $waterAmount, rentAmount: $rentAmount, serviceAmount: $serviceAmount, totalAmount: $totalAmount, electricImage: $electricImage, waterImage: $waterImage, paymentQrUrl: $paymentQrUrl, type: $type, status: $status, damageFee: $damageFee, damageReason: $damageReason, sharedPoolAmount: $sharedPoolAmount, serviceDetails: $serviceDetails, discountAmount: $discountAmount, isPaid: $isPaid, paidAt: $paidAt, paidByCash: $paidByCash, collectedByStaffId: $collectedByStaffId, dueDate: $dueDate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BillModelCopyWith<$Res>  {
  factory $BillModelCopyWith(BillModel value, $Res Function(BillModel) _then) = _$BillModelCopyWithImpl;
@useResult
$Res call({
 int id, int roomId, int? contractId, int? tenantId, int month, int year, double? electricCurrent, double? electricPrevious, double? waterCurrent, double? waterPrevious, double? electricUnitPrice, double? waterUnitPrice, double? electricAmount, double? waterAmount, double? rentAmount, double? serviceAmount, double? totalAmount, String? electricImage, String? waterImage, String? paymentQrUrl, String type, String status, double? damageFee, String? damageReason, double? sharedPoolAmount, String? serviceDetails, double? discountAmount, bool isPaid, DateTime? paidAt, bool paidByCash, int? collectedByStaffId, DateTime? dueDate, DateTime createdAt
});




}
/// @nodoc
class _$BillModelCopyWithImpl<$Res>
    implements $BillModelCopyWith<$Res> {
  _$BillModelCopyWithImpl(this._self, this._then);

  final BillModel _self;
  final $Res Function(BillModel) _then;

/// Create a copy of BillModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomId = null,Object? contractId = freezed,Object? tenantId = freezed,Object? month = null,Object? year = null,Object? electricCurrent = freezed,Object? electricPrevious = freezed,Object? waterCurrent = freezed,Object? waterPrevious = freezed,Object? electricUnitPrice = freezed,Object? waterUnitPrice = freezed,Object? electricAmount = freezed,Object? waterAmount = freezed,Object? rentAmount = freezed,Object? serviceAmount = freezed,Object? totalAmount = freezed,Object? electricImage = freezed,Object? waterImage = freezed,Object? paymentQrUrl = freezed,Object? type = null,Object? status = null,Object? damageFee = freezed,Object? damageReason = freezed,Object? sharedPoolAmount = freezed,Object? serviceDetails = freezed,Object? discountAmount = freezed,Object? isPaid = null,Object? paidAt = freezed,Object? paidByCash = null,Object? collectedByStaffId = freezed,Object? dueDate = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as int?,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as int?,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,electricCurrent: freezed == electricCurrent ? _self.electricCurrent : electricCurrent // ignore: cast_nullable_to_non_nullable
as double?,electricPrevious: freezed == electricPrevious ? _self.electricPrevious : electricPrevious // ignore: cast_nullable_to_non_nullable
as double?,waterCurrent: freezed == waterCurrent ? _self.waterCurrent : waterCurrent // ignore: cast_nullable_to_non_nullable
as double?,waterPrevious: freezed == waterPrevious ? _self.waterPrevious : waterPrevious // ignore: cast_nullable_to_non_nullable
as double?,electricUnitPrice: freezed == electricUnitPrice ? _self.electricUnitPrice : electricUnitPrice // ignore: cast_nullable_to_non_nullable
as double?,waterUnitPrice: freezed == waterUnitPrice ? _self.waterUnitPrice : waterUnitPrice // ignore: cast_nullable_to_non_nullable
as double?,electricAmount: freezed == electricAmount ? _self.electricAmount : electricAmount // ignore: cast_nullable_to_non_nullable
as double?,waterAmount: freezed == waterAmount ? _self.waterAmount : waterAmount // ignore: cast_nullable_to_non_nullable
as double?,rentAmount: freezed == rentAmount ? _self.rentAmount : rentAmount // ignore: cast_nullable_to_non_nullable
as double?,serviceAmount: freezed == serviceAmount ? _self.serviceAmount : serviceAmount // ignore: cast_nullable_to_non_nullable
as double?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,electricImage: freezed == electricImage ? _self.electricImage : electricImage // ignore: cast_nullable_to_non_nullable
as String?,waterImage: freezed == waterImage ? _self.waterImage : waterImage // ignore: cast_nullable_to_non_nullable
as String?,paymentQrUrl: freezed == paymentQrUrl ? _self.paymentQrUrl : paymentQrUrl // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,damageFee: freezed == damageFee ? _self.damageFee : damageFee // ignore: cast_nullable_to_non_nullable
as double?,damageReason: freezed == damageReason ? _self.damageReason : damageReason // ignore: cast_nullable_to_non_nullable
as String?,sharedPoolAmount: freezed == sharedPoolAmount ? _self.sharedPoolAmount : sharedPoolAmount // ignore: cast_nullable_to_non_nullable
as double?,serviceDetails: freezed == serviceDetails ? _self.serviceDetails : serviceDetails // ignore: cast_nullable_to_non_nullable
as String?,discountAmount: freezed == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double?,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidByCash: null == paidByCash ? _self.paidByCash : paidByCash // ignore: cast_nullable_to_non_nullable
as bool,collectedByStaffId: freezed == collectedByStaffId ? _self.collectedByStaffId : collectedByStaffId // ignore: cast_nullable_to_non_nullable
as int?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BillModel].
extension BillModelPatterns on BillModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillModel value)  $default,){
final _that = this;
switch (_that) {
case _BillModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillModel value)?  $default,){
final _that = this;
switch (_that) {
case _BillModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int roomId,  int? contractId,  int? tenantId,  int month,  int year,  double? electricCurrent,  double? electricPrevious,  double? waterCurrent,  double? waterPrevious,  double? electricUnitPrice,  double? waterUnitPrice,  double? electricAmount,  double? waterAmount,  double? rentAmount,  double? serviceAmount,  double? totalAmount,  String? electricImage,  String? waterImage,  String? paymentQrUrl,  String type,  String status,  double? damageFee,  String? damageReason,  double? sharedPoolAmount,  String? serviceDetails,  double? discountAmount,  bool isPaid,  DateTime? paidAt,  bool paidByCash,  int? collectedByStaffId,  DateTime? dueDate,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillModel() when $default != null:
return $default(_that.id,_that.roomId,_that.contractId,_that.tenantId,_that.month,_that.year,_that.electricCurrent,_that.electricPrevious,_that.waterCurrent,_that.waterPrevious,_that.electricUnitPrice,_that.waterUnitPrice,_that.electricAmount,_that.waterAmount,_that.rentAmount,_that.serviceAmount,_that.totalAmount,_that.electricImage,_that.waterImage,_that.paymentQrUrl,_that.type,_that.status,_that.damageFee,_that.damageReason,_that.sharedPoolAmount,_that.serviceDetails,_that.discountAmount,_that.isPaid,_that.paidAt,_that.paidByCash,_that.collectedByStaffId,_that.dueDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int roomId,  int? contractId,  int? tenantId,  int month,  int year,  double? electricCurrent,  double? electricPrevious,  double? waterCurrent,  double? waterPrevious,  double? electricUnitPrice,  double? waterUnitPrice,  double? electricAmount,  double? waterAmount,  double? rentAmount,  double? serviceAmount,  double? totalAmount,  String? electricImage,  String? waterImage,  String? paymentQrUrl,  String type,  String status,  double? damageFee,  String? damageReason,  double? sharedPoolAmount,  String? serviceDetails,  double? discountAmount,  bool isPaid,  DateTime? paidAt,  bool paidByCash,  int? collectedByStaffId,  DateTime? dueDate,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _BillModel():
return $default(_that.id,_that.roomId,_that.contractId,_that.tenantId,_that.month,_that.year,_that.electricCurrent,_that.electricPrevious,_that.waterCurrent,_that.waterPrevious,_that.electricUnitPrice,_that.waterUnitPrice,_that.electricAmount,_that.waterAmount,_that.rentAmount,_that.serviceAmount,_that.totalAmount,_that.electricImage,_that.waterImage,_that.paymentQrUrl,_that.type,_that.status,_that.damageFee,_that.damageReason,_that.sharedPoolAmount,_that.serviceDetails,_that.discountAmount,_that.isPaid,_that.paidAt,_that.paidByCash,_that.collectedByStaffId,_that.dueDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int roomId,  int? contractId,  int? tenantId,  int month,  int year,  double? electricCurrent,  double? electricPrevious,  double? waterCurrent,  double? waterPrevious,  double? electricUnitPrice,  double? waterUnitPrice,  double? electricAmount,  double? waterAmount,  double? rentAmount,  double? serviceAmount,  double? totalAmount,  String? electricImage,  String? waterImage,  String? paymentQrUrl,  String type,  String status,  double? damageFee,  String? damageReason,  double? sharedPoolAmount,  String? serviceDetails,  double? discountAmount,  bool isPaid,  DateTime? paidAt,  bool paidByCash,  int? collectedByStaffId,  DateTime? dueDate,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BillModel() when $default != null:
return $default(_that.id,_that.roomId,_that.contractId,_that.tenantId,_that.month,_that.year,_that.electricCurrent,_that.electricPrevious,_that.waterCurrent,_that.waterPrevious,_that.electricUnitPrice,_that.waterUnitPrice,_that.electricAmount,_that.waterAmount,_that.rentAmount,_that.serviceAmount,_that.totalAmount,_that.electricImage,_that.waterImage,_that.paymentQrUrl,_that.type,_that.status,_that.damageFee,_that.damageReason,_that.sharedPoolAmount,_that.serviceDetails,_that.discountAmount,_that.isPaid,_that.paidAt,_that.paidByCash,_that.collectedByStaffId,_that.dueDate,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillModel extends BillModel {
  const _BillModel({required this.id, required this.roomId, this.contractId, this.tenantId, required this.month, required this.year, this.electricCurrent, this.electricPrevious, this.waterCurrent, this.waterPrevious, this.electricUnitPrice, this.waterUnitPrice, this.electricAmount, this.waterAmount, this.rentAmount, this.serviceAmount, this.totalAmount, this.electricImage, this.waterImage, this.paymentQrUrl, this.type = 'MONTHLY', this.status = 'PENDING', this.damageFee, this.damageReason, this.sharedPoolAmount, this.serviceDetails, this.discountAmount, this.isPaid = false, this.paidAt, this.paidByCash = false, this.collectedByStaffId, this.dueDate, required this.createdAt}): super._();
  factory _BillModel.fromJson(Map<String, dynamic> json) => _$BillModelFromJson(json);

@override final  int id;
@override final  int roomId;
@override final  int? contractId;
@override final  int? tenantId;
@override final  int month;
@override final  int year;
@override final  double? electricCurrent;
@override final  double? electricPrevious;
@override final  double? waterCurrent;
@override final  double? waterPrevious;
@override final  double? electricUnitPrice;
@override final  double? waterUnitPrice;
@override final  double? electricAmount;
@override final  double? waterAmount;
@override final  double? rentAmount;
@override final  double? serviceAmount;
@override final  double? totalAmount;
@override final  String? electricImage;
@override final  String? waterImage;
@override final  String? paymentQrUrl;
@override@JsonKey() final  String type;
@override@JsonKey() final  String status;
@override final  double? damageFee;
@override final  String? damageReason;
@override final  double? sharedPoolAmount;
@override final  String? serviceDetails;
@override final  double? discountAmount;
@override@JsonKey() final  bool isPaid;
@override final  DateTime? paidAt;
@override@JsonKey() final  bool paidByCash;
@override final  int? collectedByStaffId;
@override final  DateTime? dueDate;
@override final  DateTime createdAt;

/// Create a copy of BillModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillModelCopyWith<_BillModel> get copyWith => __$BillModelCopyWithImpl<_BillModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillModel&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.month, month) || other.month == month)&&(identical(other.year, year) || other.year == year)&&(identical(other.electricCurrent, electricCurrent) || other.electricCurrent == electricCurrent)&&(identical(other.electricPrevious, electricPrevious) || other.electricPrevious == electricPrevious)&&(identical(other.waterCurrent, waterCurrent) || other.waterCurrent == waterCurrent)&&(identical(other.waterPrevious, waterPrevious) || other.waterPrevious == waterPrevious)&&(identical(other.electricUnitPrice, electricUnitPrice) || other.electricUnitPrice == electricUnitPrice)&&(identical(other.waterUnitPrice, waterUnitPrice) || other.waterUnitPrice == waterUnitPrice)&&(identical(other.electricAmount, electricAmount) || other.electricAmount == electricAmount)&&(identical(other.waterAmount, waterAmount) || other.waterAmount == waterAmount)&&(identical(other.rentAmount, rentAmount) || other.rentAmount == rentAmount)&&(identical(other.serviceAmount, serviceAmount) || other.serviceAmount == serviceAmount)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.electricImage, electricImage) || other.electricImage == electricImage)&&(identical(other.waterImage, waterImage) || other.waterImage == waterImage)&&(identical(other.paymentQrUrl, paymentQrUrl) || other.paymentQrUrl == paymentQrUrl)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.damageFee, damageFee) || other.damageFee == damageFee)&&(identical(other.damageReason, damageReason) || other.damageReason == damageReason)&&(identical(other.sharedPoolAmount, sharedPoolAmount) || other.sharedPoolAmount == sharedPoolAmount)&&(identical(other.serviceDetails, serviceDetails) || other.serviceDetails == serviceDetails)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.paidByCash, paidByCash) || other.paidByCash == paidByCash)&&(identical(other.collectedByStaffId, collectedByStaffId) || other.collectedByStaffId == collectedByStaffId)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,roomId,contractId,tenantId,month,year,electricCurrent,electricPrevious,waterCurrent,waterPrevious,electricUnitPrice,waterUnitPrice,electricAmount,waterAmount,rentAmount,serviceAmount,totalAmount,electricImage,waterImage,paymentQrUrl,type,status,damageFee,damageReason,sharedPoolAmount,serviceDetails,discountAmount,isPaid,paidAt,paidByCash,collectedByStaffId,dueDate,createdAt]);

@override
String toString() {
  return 'BillModel(id: $id, roomId: $roomId, contractId: $contractId, tenantId: $tenantId, month: $month, year: $year, electricCurrent: $electricCurrent, electricPrevious: $electricPrevious, waterCurrent: $waterCurrent, waterPrevious: $waterPrevious, electricUnitPrice: $electricUnitPrice, waterUnitPrice: $waterUnitPrice, electricAmount: $electricAmount, waterAmount: $waterAmount, rentAmount: $rentAmount, serviceAmount: $serviceAmount, totalAmount: $totalAmount, electricImage: $electricImage, waterImage: $waterImage, paymentQrUrl: $paymentQrUrl, type: $type, status: $status, damageFee: $damageFee, damageReason: $damageReason, sharedPoolAmount: $sharedPoolAmount, serviceDetails: $serviceDetails, discountAmount: $discountAmount, isPaid: $isPaid, paidAt: $paidAt, paidByCash: $paidByCash, collectedByStaffId: $collectedByStaffId, dueDate: $dueDate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BillModelCopyWith<$Res> implements $BillModelCopyWith<$Res> {
  factory _$BillModelCopyWith(_BillModel value, $Res Function(_BillModel) _then) = __$BillModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int roomId, int? contractId, int? tenantId, int month, int year, double? electricCurrent, double? electricPrevious, double? waterCurrent, double? waterPrevious, double? electricUnitPrice, double? waterUnitPrice, double? electricAmount, double? waterAmount, double? rentAmount, double? serviceAmount, double? totalAmount, String? electricImage, String? waterImage, String? paymentQrUrl, String type, String status, double? damageFee, String? damageReason, double? sharedPoolAmount, String? serviceDetails, double? discountAmount, bool isPaid, DateTime? paidAt, bool paidByCash, int? collectedByStaffId, DateTime? dueDate, DateTime createdAt
});




}
/// @nodoc
class __$BillModelCopyWithImpl<$Res>
    implements _$BillModelCopyWith<$Res> {
  __$BillModelCopyWithImpl(this._self, this._then);

  final _BillModel _self;
  final $Res Function(_BillModel) _then;

/// Create a copy of BillModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomId = null,Object? contractId = freezed,Object? tenantId = freezed,Object? month = null,Object? year = null,Object? electricCurrent = freezed,Object? electricPrevious = freezed,Object? waterCurrent = freezed,Object? waterPrevious = freezed,Object? electricUnitPrice = freezed,Object? waterUnitPrice = freezed,Object? electricAmount = freezed,Object? waterAmount = freezed,Object? rentAmount = freezed,Object? serviceAmount = freezed,Object? totalAmount = freezed,Object? electricImage = freezed,Object? waterImage = freezed,Object? paymentQrUrl = freezed,Object? type = null,Object? status = null,Object? damageFee = freezed,Object? damageReason = freezed,Object? sharedPoolAmount = freezed,Object? serviceDetails = freezed,Object? discountAmount = freezed,Object? isPaid = null,Object? paidAt = freezed,Object? paidByCash = null,Object? collectedByStaffId = freezed,Object? dueDate = freezed,Object? createdAt = null,}) {
  return _then(_BillModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as int?,tenantId: freezed == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as int?,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,electricCurrent: freezed == electricCurrent ? _self.electricCurrent : electricCurrent // ignore: cast_nullable_to_non_nullable
as double?,electricPrevious: freezed == electricPrevious ? _self.electricPrevious : electricPrevious // ignore: cast_nullable_to_non_nullable
as double?,waterCurrent: freezed == waterCurrent ? _self.waterCurrent : waterCurrent // ignore: cast_nullable_to_non_nullable
as double?,waterPrevious: freezed == waterPrevious ? _self.waterPrevious : waterPrevious // ignore: cast_nullable_to_non_nullable
as double?,electricUnitPrice: freezed == electricUnitPrice ? _self.electricUnitPrice : electricUnitPrice // ignore: cast_nullable_to_non_nullable
as double?,waterUnitPrice: freezed == waterUnitPrice ? _self.waterUnitPrice : waterUnitPrice // ignore: cast_nullable_to_non_nullable
as double?,electricAmount: freezed == electricAmount ? _self.electricAmount : electricAmount // ignore: cast_nullable_to_non_nullable
as double?,waterAmount: freezed == waterAmount ? _self.waterAmount : waterAmount // ignore: cast_nullable_to_non_nullable
as double?,rentAmount: freezed == rentAmount ? _self.rentAmount : rentAmount // ignore: cast_nullable_to_non_nullable
as double?,serviceAmount: freezed == serviceAmount ? _self.serviceAmount : serviceAmount // ignore: cast_nullable_to_non_nullable
as double?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,electricImage: freezed == electricImage ? _self.electricImage : electricImage // ignore: cast_nullable_to_non_nullable
as String?,waterImage: freezed == waterImage ? _self.waterImage : waterImage // ignore: cast_nullable_to_non_nullable
as String?,paymentQrUrl: freezed == paymentQrUrl ? _self.paymentQrUrl : paymentQrUrl // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,damageFee: freezed == damageFee ? _self.damageFee : damageFee // ignore: cast_nullable_to_non_nullable
as double?,damageReason: freezed == damageReason ? _self.damageReason : damageReason // ignore: cast_nullable_to_non_nullable
as String?,sharedPoolAmount: freezed == sharedPoolAmount ? _self.sharedPoolAmount : sharedPoolAmount // ignore: cast_nullable_to_non_nullable
as double?,serviceDetails: freezed == serviceDetails ? _self.serviceDetails : serviceDetails // ignore: cast_nullable_to_non_nullable
as String?,discountAmount: freezed == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double?,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidByCash: null == paidByCash ? _self.paidByCash : paidByCash // ignore: cast_nullable_to_non_nullable
as bool,collectedByStaffId: freezed == collectedByStaffId ? _self.collectedByStaffId : collectedByStaffId // ignore: cast_nullable_to_non_nullable
as int?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
