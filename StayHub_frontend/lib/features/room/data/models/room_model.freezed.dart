// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomModel {

 int get id; int get ownerId; int? get branchId; dynamic get branch; String get roomName; double? get price; String? get address; String get status; String? get description;@JsonKey(readValue: readDepositValue) double? get deposit;@JsonKey(readValue: readMaxGuestsValue) int? get maxGuests;@JsonKey(readValue: readAreaValue) double? get area; double? get electricityPrice; double? get waterPrice; double? get serviceFee; double? get internetPrice; double? get parkingPrice; double? get trashPrice; String? get roomImages; String? get inspectionImages; String? get qrCode; int? get currentTenantId; int? get currentContractId; String? get bathroomType; String? get direction; bool? get hasBalcony; bool? get hasWindow; Map<String, dynamic>? get detailedInfo; String? get availableFrom; double? get mezzanineArea; int? get maxVehicles; dynamic get furniture; String? get approvalStatus; bool get isDeleted;
/// Create a copy of RoomModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomModelCopyWith<RoomModel> get copyWith => _$RoomModelCopyWithImpl<RoomModel>(this as RoomModel, _$identity);

  /// Serializes this RoomModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&const DeepCollectionEquality().equals(other.branch, branch)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.price, price) || other.price == price)&&(identical(other.address, address) || other.address == address)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.deposit, deposit) || other.deposit == deposit)&&(identical(other.maxGuests, maxGuests) || other.maxGuests == maxGuests)&&(identical(other.area, area) || other.area == area)&&(identical(other.electricityPrice, electricityPrice) || other.electricityPrice == electricityPrice)&&(identical(other.waterPrice, waterPrice) || other.waterPrice == waterPrice)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.internetPrice, internetPrice) || other.internetPrice == internetPrice)&&(identical(other.parkingPrice, parkingPrice) || other.parkingPrice == parkingPrice)&&(identical(other.trashPrice, trashPrice) || other.trashPrice == trashPrice)&&(identical(other.roomImages, roomImages) || other.roomImages == roomImages)&&(identical(other.inspectionImages, inspectionImages) || other.inspectionImages == inspectionImages)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode)&&(identical(other.currentTenantId, currentTenantId) || other.currentTenantId == currentTenantId)&&(identical(other.currentContractId, currentContractId) || other.currentContractId == currentContractId)&&(identical(other.bathroomType, bathroomType) || other.bathroomType == bathroomType)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.hasBalcony, hasBalcony) || other.hasBalcony == hasBalcony)&&(identical(other.hasWindow, hasWindow) || other.hasWindow == hasWindow)&&const DeepCollectionEquality().equals(other.detailedInfo, detailedInfo)&&(identical(other.availableFrom, availableFrom) || other.availableFrom == availableFrom)&&(identical(other.mezzanineArea, mezzanineArea) || other.mezzanineArea == mezzanineArea)&&(identical(other.maxVehicles, maxVehicles) || other.maxVehicles == maxVehicles)&&const DeepCollectionEquality().equals(other.furniture, furniture)&&(identical(other.approvalStatus, approvalStatus) || other.approvalStatus == approvalStatus)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ownerId,branchId,const DeepCollectionEquality().hash(branch),roomName,price,address,status,description,deposit,maxGuests,area,electricityPrice,waterPrice,serviceFee,internetPrice,parkingPrice,trashPrice,roomImages,inspectionImages,qrCode,currentTenantId,currentContractId,bathroomType,direction,hasBalcony,hasWindow,const DeepCollectionEquality().hash(detailedInfo),availableFrom,mezzanineArea,maxVehicles,const DeepCollectionEquality().hash(furniture),approvalStatus,isDeleted]);

@override
String toString() {
  return 'RoomModel(id: $id, ownerId: $ownerId, branchId: $branchId, branch: $branch, roomName: $roomName, price: $price, address: $address, status: $status, description: $description, deposit: $deposit, maxGuests: $maxGuests, area: $area, electricityPrice: $electricityPrice, waterPrice: $waterPrice, serviceFee: $serviceFee, internetPrice: $internetPrice, parkingPrice: $parkingPrice, trashPrice: $trashPrice, roomImages: $roomImages, inspectionImages: $inspectionImages, qrCode: $qrCode, currentTenantId: $currentTenantId, currentContractId: $currentContractId, bathroomType: $bathroomType, direction: $direction, hasBalcony: $hasBalcony, hasWindow: $hasWindow, detailedInfo: $detailedInfo, availableFrom: $availableFrom, mezzanineArea: $mezzanineArea, maxVehicles: $maxVehicles, furniture: $furniture, approvalStatus: $approvalStatus, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $RoomModelCopyWith<$Res>  {
  factory $RoomModelCopyWith(RoomModel value, $Res Function(RoomModel) _then) = _$RoomModelCopyWithImpl;
@useResult
$Res call({
 int id, int ownerId, int? branchId, dynamic branch, String roomName, double? price, String? address, String status, String? description,@JsonKey(readValue: readDepositValue) double? deposit,@JsonKey(readValue: readMaxGuestsValue) int? maxGuests,@JsonKey(readValue: readAreaValue) double? area, double? electricityPrice, double? waterPrice, double? serviceFee, double? internetPrice, double? parkingPrice, double? trashPrice, String? roomImages, String? inspectionImages, String? qrCode, int? currentTenantId, int? currentContractId, String? bathroomType, String? direction, bool? hasBalcony, bool? hasWindow, Map<String, dynamic>? detailedInfo, String? availableFrom, double? mezzanineArea, int? maxVehicles, dynamic furniture, String? approvalStatus, bool isDeleted
});




}
/// @nodoc
class _$RoomModelCopyWithImpl<$Res>
    implements $RoomModelCopyWith<$Res> {
  _$RoomModelCopyWithImpl(this._self, this._then);

  final RoomModel _self;
  final $Res Function(RoomModel) _then;

/// Create a copy of RoomModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? branchId = freezed,Object? branch = freezed,Object? roomName = null,Object? price = freezed,Object? address = freezed,Object? status = null,Object? description = freezed,Object? deposit = freezed,Object? maxGuests = freezed,Object? area = freezed,Object? electricityPrice = freezed,Object? waterPrice = freezed,Object? serviceFee = freezed,Object? internetPrice = freezed,Object? parkingPrice = freezed,Object? trashPrice = freezed,Object? roomImages = freezed,Object? inspectionImages = freezed,Object? qrCode = freezed,Object? currentTenantId = freezed,Object? currentContractId = freezed,Object? bathroomType = freezed,Object? direction = freezed,Object? hasBalcony = freezed,Object? hasWindow = freezed,Object? detailedInfo = freezed,Object? availableFrom = freezed,Object? mezzanineArea = freezed,Object? maxVehicles = freezed,Object? furniture = freezed,Object? approvalStatus = freezed,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as int,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as int?,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as dynamic,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,deposit: freezed == deposit ? _self.deposit : deposit // ignore: cast_nullable_to_non_nullable
as double?,maxGuests: freezed == maxGuests ? _self.maxGuests : maxGuests // ignore: cast_nullable_to_non_nullable
as int?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as double?,electricityPrice: freezed == electricityPrice ? _self.electricityPrice : electricityPrice // ignore: cast_nullable_to_non_nullable
as double?,waterPrice: freezed == waterPrice ? _self.waterPrice : waterPrice // ignore: cast_nullable_to_non_nullable
as double?,serviceFee: freezed == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double?,internetPrice: freezed == internetPrice ? _self.internetPrice : internetPrice // ignore: cast_nullable_to_non_nullable
as double?,parkingPrice: freezed == parkingPrice ? _self.parkingPrice : parkingPrice // ignore: cast_nullable_to_non_nullable
as double?,trashPrice: freezed == trashPrice ? _self.trashPrice : trashPrice // ignore: cast_nullable_to_non_nullable
as double?,roomImages: freezed == roomImages ? _self.roomImages : roomImages // ignore: cast_nullable_to_non_nullable
as String?,inspectionImages: freezed == inspectionImages ? _self.inspectionImages : inspectionImages // ignore: cast_nullable_to_non_nullable
as String?,qrCode: freezed == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String?,currentTenantId: freezed == currentTenantId ? _self.currentTenantId : currentTenantId // ignore: cast_nullable_to_non_nullable
as int?,currentContractId: freezed == currentContractId ? _self.currentContractId : currentContractId // ignore: cast_nullable_to_non_nullable
as int?,bathroomType: freezed == bathroomType ? _self.bathroomType : bathroomType // ignore: cast_nullable_to_non_nullable
as String?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,hasBalcony: freezed == hasBalcony ? _self.hasBalcony : hasBalcony // ignore: cast_nullable_to_non_nullable
as bool?,hasWindow: freezed == hasWindow ? _self.hasWindow : hasWindow // ignore: cast_nullable_to_non_nullable
as bool?,detailedInfo: freezed == detailedInfo ? _self.detailedInfo : detailedInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,availableFrom: freezed == availableFrom ? _self.availableFrom : availableFrom // ignore: cast_nullable_to_non_nullable
as String?,mezzanineArea: freezed == mezzanineArea ? _self.mezzanineArea : mezzanineArea // ignore: cast_nullable_to_non_nullable
as double?,maxVehicles: freezed == maxVehicles ? _self.maxVehicles : maxVehicles // ignore: cast_nullable_to_non_nullable
as int?,furniture: freezed == furniture ? _self.furniture : furniture // ignore: cast_nullable_to_non_nullable
as dynamic,approvalStatus: freezed == approvalStatus ? _self.approvalStatus : approvalStatus // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomModel].
extension RoomModelPatterns on RoomModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomModel value)  $default,){
final _that = this;
switch (_that) {
case _RoomModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomModel value)?  $default,){
final _that = this;
switch (_that) {
case _RoomModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int ownerId,  int? branchId,  dynamic branch,  String roomName,  double? price,  String? address,  String status,  String? description, @JsonKey(readValue: readDepositValue)  double? deposit, @JsonKey(readValue: readMaxGuestsValue)  int? maxGuests, @JsonKey(readValue: readAreaValue)  double? area,  double? electricityPrice,  double? waterPrice,  double? serviceFee,  double? internetPrice,  double? parkingPrice,  double? trashPrice,  String? roomImages,  String? inspectionImages,  String? qrCode,  int? currentTenantId,  int? currentContractId,  String? bathroomType,  String? direction,  bool? hasBalcony,  bool? hasWindow,  Map<String, dynamic>? detailedInfo,  String? availableFrom,  double? mezzanineArea,  int? maxVehicles,  dynamic furniture,  String? approvalStatus,  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomModel() when $default != null:
return $default(_that.id,_that.ownerId,_that.branchId,_that.branch,_that.roomName,_that.price,_that.address,_that.status,_that.description,_that.deposit,_that.maxGuests,_that.area,_that.electricityPrice,_that.waterPrice,_that.serviceFee,_that.internetPrice,_that.parkingPrice,_that.trashPrice,_that.roomImages,_that.inspectionImages,_that.qrCode,_that.currentTenantId,_that.currentContractId,_that.bathroomType,_that.direction,_that.hasBalcony,_that.hasWindow,_that.detailedInfo,_that.availableFrom,_that.mezzanineArea,_that.maxVehicles,_that.furniture,_that.approvalStatus,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int ownerId,  int? branchId,  dynamic branch,  String roomName,  double? price,  String? address,  String status,  String? description, @JsonKey(readValue: readDepositValue)  double? deposit, @JsonKey(readValue: readMaxGuestsValue)  int? maxGuests, @JsonKey(readValue: readAreaValue)  double? area,  double? electricityPrice,  double? waterPrice,  double? serviceFee,  double? internetPrice,  double? parkingPrice,  double? trashPrice,  String? roomImages,  String? inspectionImages,  String? qrCode,  int? currentTenantId,  int? currentContractId,  String? bathroomType,  String? direction,  bool? hasBalcony,  bool? hasWindow,  Map<String, dynamic>? detailedInfo,  String? availableFrom,  double? mezzanineArea,  int? maxVehicles,  dynamic furniture,  String? approvalStatus,  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _RoomModel():
return $default(_that.id,_that.ownerId,_that.branchId,_that.branch,_that.roomName,_that.price,_that.address,_that.status,_that.description,_that.deposit,_that.maxGuests,_that.area,_that.electricityPrice,_that.waterPrice,_that.serviceFee,_that.internetPrice,_that.parkingPrice,_that.trashPrice,_that.roomImages,_that.inspectionImages,_that.qrCode,_that.currentTenantId,_that.currentContractId,_that.bathroomType,_that.direction,_that.hasBalcony,_that.hasWindow,_that.detailedInfo,_that.availableFrom,_that.mezzanineArea,_that.maxVehicles,_that.furniture,_that.approvalStatus,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int ownerId,  int? branchId,  dynamic branch,  String roomName,  double? price,  String? address,  String status,  String? description, @JsonKey(readValue: readDepositValue)  double? deposit, @JsonKey(readValue: readMaxGuestsValue)  int? maxGuests, @JsonKey(readValue: readAreaValue)  double? area,  double? electricityPrice,  double? waterPrice,  double? serviceFee,  double? internetPrice,  double? parkingPrice,  double? trashPrice,  String? roomImages,  String? inspectionImages,  String? qrCode,  int? currentTenantId,  int? currentContractId,  String? bathroomType,  String? direction,  bool? hasBalcony,  bool? hasWindow,  Map<String, dynamic>? detailedInfo,  String? availableFrom,  double? mezzanineArea,  int? maxVehicles,  dynamic furniture,  String? approvalStatus,  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _RoomModel() when $default != null:
return $default(_that.id,_that.ownerId,_that.branchId,_that.branch,_that.roomName,_that.price,_that.address,_that.status,_that.description,_that.deposit,_that.maxGuests,_that.area,_that.electricityPrice,_that.waterPrice,_that.serviceFee,_that.internetPrice,_that.parkingPrice,_that.trashPrice,_that.roomImages,_that.inspectionImages,_that.qrCode,_that.currentTenantId,_that.currentContractId,_that.bathroomType,_that.direction,_that.hasBalcony,_that.hasWindow,_that.detailedInfo,_that.availableFrom,_that.mezzanineArea,_that.maxVehicles,_that.furniture,_that.approvalStatus,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomModel extends RoomModel {
  const _RoomModel({required this.id, required this.ownerId, this.branchId, this.branch, required this.roomName, this.price, this.address, this.status = 'TRONG', this.description, @JsonKey(readValue: readDepositValue) this.deposit, @JsonKey(readValue: readMaxGuestsValue) this.maxGuests, @JsonKey(readValue: readAreaValue) this.area, this.electricityPrice, this.waterPrice, this.serviceFee, this.internetPrice, this.parkingPrice, this.trashPrice, this.roomImages, this.inspectionImages, this.qrCode, this.currentTenantId, this.currentContractId, this.bathroomType, this.direction, this.hasBalcony, this.hasWindow, final  Map<String, dynamic>? detailedInfo, this.availableFrom, this.mezzanineArea, this.maxVehicles, this.furniture, this.approvalStatus, this.isDeleted = false}): _detailedInfo = detailedInfo,super._();
  factory _RoomModel.fromJson(Map<String, dynamic> json) => _$RoomModelFromJson(json);

@override final  int id;
@override final  int ownerId;
@override final  int? branchId;
@override final  dynamic branch;
@override final  String roomName;
@override final  double? price;
@override final  String? address;
@override@JsonKey() final  String status;
@override final  String? description;
@override@JsonKey(readValue: readDepositValue) final  double? deposit;
@override@JsonKey(readValue: readMaxGuestsValue) final  int? maxGuests;
@override@JsonKey(readValue: readAreaValue) final  double? area;
@override final  double? electricityPrice;
@override final  double? waterPrice;
@override final  double? serviceFee;
@override final  double? internetPrice;
@override final  double? parkingPrice;
@override final  double? trashPrice;
@override final  String? roomImages;
@override final  String? inspectionImages;
@override final  String? qrCode;
@override final  int? currentTenantId;
@override final  int? currentContractId;
@override final  String? bathroomType;
@override final  String? direction;
@override final  bool? hasBalcony;
@override final  bool? hasWindow;
 final  Map<String, dynamic>? _detailedInfo;
@override Map<String, dynamic>? get detailedInfo {
  final value = _detailedInfo;
  if (value == null) return null;
  if (_detailedInfo is EqualUnmodifiableMapView) return _detailedInfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? availableFrom;
@override final  double? mezzanineArea;
@override final  int? maxVehicles;
@override final  dynamic furniture;
@override final  String? approvalStatus;
@override@JsonKey() final  bool isDeleted;

/// Create a copy of RoomModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomModelCopyWith<_RoomModel> get copyWith => __$RoomModelCopyWithImpl<_RoomModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&const DeepCollectionEquality().equals(other.branch, branch)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.price, price) || other.price == price)&&(identical(other.address, address) || other.address == address)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.deposit, deposit) || other.deposit == deposit)&&(identical(other.maxGuests, maxGuests) || other.maxGuests == maxGuests)&&(identical(other.area, area) || other.area == area)&&(identical(other.electricityPrice, electricityPrice) || other.electricityPrice == electricityPrice)&&(identical(other.waterPrice, waterPrice) || other.waterPrice == waterPrice)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.internetPrice, internetPrice) || other.internetPrice == internetPrice)&&(identical(other.parkingPrice, parkingPrice) || other.parkingPrice == parkingPrice)&&(identical(other.trashPrice, trashPrice) || other.trashPrice == trashPrice)&&(identical(other.roomImages, roomImages) || other.roomImages == roomImages)&&(identical(other.inspectionImages, inspectionImages) || other.inspectionImages == inspectionImages)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode)&&(identical(other.currentTenantId, currentTenantId) || other.currentTenantId == currentTenantId)&&(identical(other.currentContractId, currentContractId) || other.currentContractId == currentContractId)&&(identical(other.bathroomType, bathroomType) || other.bathroomType == bathroomType)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.hasBalcony, hasBalcony) || other.hasBalcony == hasBalcony)&&(identical(other.hasWindow, hasWindow) || other.hasWindow == hasWindow)&&const DeepCollectionEquality().equals(other._detailedInfo, _detailedInfo)&&(identical(other.availableFrom, availableFrom) || other.availableFrom == availableFrom)&&(identical(other.mezzanineArea, mezzanineArea) || other.mezzanineArea == mezzanineArea)&&(identical(other.maxVehicles, maxVehicles) || other.maxVehicles == maxVehicles)&&const DeepCollectionEquality().equals(other.furniture, furniture)&&(identical(other.approvalStatus, approvalStatus) || other.approvalStatus == approvalStatus)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ownerId,branchId,const DeepCollectionEquality().hash(branch),roomName,price,address,status,description,deposit,maxGuests,area,electricityPrice,waterPrice,serviceFee,internetPrice,parkingPrice,trashPrice,roomImages,inspectionImages,qrCode,currentTenantId,currentContractId,bathroomType,direction,hasBalcony,hasWindow,const DeepCollectionEquality().hash(_detailedInfo),availableFrom,mezzanineArea,maxVehicles,const DeepCollectionEquality().hash(furniture),approvalStatus,isDeleted]);

@override
String toString() {
  return 'RoomModel(id: $id, ownerId: $ownerId, branchId: $branchId, branch: $branch, roomName: $roomName, price: $price, address: $address, status: $status, description: $description, deposit: $deposit, maxGuests: $maxGuests, area: $area, electricityPrice: $electricityPrice, waterPrice: $waterPrice, serviceFee: $serviceFee, internetPrice: $internetPrice, parkingPrice: $parkingPrice, trashPrice: $trashPrice, roomImages: $roomImages, inspectionImages: $inspectionImages, qrCode: $qrCode, currentTenantId: $currentTenantId, currentContractId: $currentContractId, bathroomType: $bathroomType, direction: $direction, hasBalcony: $hasBalcony, hasWindow: $hasWindow, detailedInfo: $detailedInfo, availableFrom: $availableFrom, mezzanineArea: $mezzanineArea, maxVehicles: $maxVehicles, furniture: $furniture, approvalStatus: $approvalStatus, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$RoomModelCopyWith<$Res> implements $RoomModelCopyWith<$Res> {
  factory _$RoomModelCopyWith(_RoomModel value, $Res Function(_RoomModel) _then) = __$RoomModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int ownerId, int? branchId, dynamic branch, String roomName, double? price, String? address, String status, String? description,@JsonKey(readValue: readDepositValue) double? deposit,@JsonKey(readValue: readMaxGuestsValue) int? maxGuests,@JsonKey(readValue: readAreaValue) double? area, double? electricityPrice, double? waterPrice, double? serviceFee, double? internetPrice, double? parkingPrice, double? trashPrice, String? roomImages, String? inspectionImages, String? qrCode, int? currentTenantId, int? currentContractId, String? bathroomType, String? direction, bool? hasBalcony, bool? hasWindow, Map<String, dynamic>? detailedInfo, String? availableFrom, double? mezzanineArea, int? maxVehicles, dynamic furniture, String? approvalStatus, bool isDeleted
});




}
/// @nodoc
class __$RoomModelCopyWithImpl<$Res>
    implements _$RoomModelCopyWith<$Res> {
  __$RoomModelCopyWithImpl(this._self, this._then);

  final _RoomModel _self;
  final $Res Function(_RoomModel) _then;

/// Create a copy of RoomModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? branchId = freezed,Object? branch = freezed,Object? roomName = null,Object? price = freezed,Object? address = freezed,Object? status = null,Object? description = freezed,Object? deposit = freezed,Object? maxGuests = freezed,Object? area = freezed,Object? electricityPrice = freezed,Object? waterPrice = freezed,Object? serviceFee = freezed,Object? internetPrice = freezed,Object? parkingPrice = freezed,Object? trashPrice = freezed,Object? roomImages = freezed,Object? inspectionImages = freezed,Object? qrCode = freezed,Object? currentTenantId = freezed,Object? currentContractId = freezed,Object? bathroomType = freezed,Object? direction = freezed,Object? hasBalcony = freezed,Object? hasWindow = freezed,Object? detailedInfo = freezed,Object? availableFrom = freezed,Object? mezzanineArea = freezed,Object? maxVehicles = freezed,Object? furniture = freezed,Object? approvalStatus = freezed,Object? isDeleted = null,}) {
  return _then(_RoomModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as int,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as int?,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as dynamic,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,deposit: freezed == deposit ? _self.deposit : deposit // ignore: cast_nullable_to_non_nullable
as double?,maxGuests: freezed == maxGuests ? _self.maxGuests : maxGuests // ignore: cast_nullable_to_non_nullable
as int?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as double?,electricityPrice: freezed == electricityPrice ? _self.electricityPrice : electricityPrice // ignore: cast_nullable_to_non_nullable
as double?,waterPrice: freezed == waterPrice ? _self.waterPrice : waterPrice // ignore: cast_nullable_to_non_nullable
as double?,serviceFee: freezed == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double?,internetPrice: freezed == internetPrice ? _self.internetPrice : internetPrice // ignore: cast_nullable_to_non_nullable
as double?,parkingPrice: freezed == parkingPrice ? _self.parkingPrice : parkingPrice // ignore: cast_nullable_to_non_nullable
as double?,trashPrice: freezed == trashPrice ? _self.trashPrice : trashPrice // ignore: cast_nullable_to_non_nullable
as double?,roomImages: freezed == roomImages ? _self.roomImages : roomImages // ignore: cast_nullable_to_non_nullable
as String?,inspectionImages: freezed == inspectionImages ? _self.inspectionImages : inspectionImages // ignore: cast_nullable_to_non_nullable
as String?,qrCode: freezed == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String?,currentTenantId: freezed == currentTenantId ? _self.currentTenantId : currentTenantId // ignore: cast_nullable_to_non_nullable
as int?,currentContractId: freezed == currentContractId ? _self.currentContractId : currentContractId // ignore: cast_nullable_to_non_nullable
as int?,bathroomType: freezed == bathroomType ? _self.bathroomType : bathroomType // ignore: cast_nullable_to_non_nullable
as String?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,hasBalcony: freezed == hasBalcony ? _self.hasBalcony : hasBalcony // ignore: cast_nullable_to_non_nullable
as bool?,hasWindow: freezed == hasWindow ? _self.hasWindow : hasWindow // ignore: cast_nullable_to_non_nullable
as bool?,detailedInfo: freezed == detailedInfo ? _self._detailedInfo : detailedInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,availableFrom: freezed == availableFrom ? _self.availableFrom : availableFrom // ignore: cast_nullable_to_non_nullable
as String?,mezzanineArea: freezed == mezzanineArea ? _self.mezzanineArea : mezzanineArea // ignore: cast_nullable_to_non_nullable
as double?,maxVehicles: freezed == maxVehicles ? _self.maxVehicles : maxVehicles // ignore: cast_nullable_to_non_nullable
as int?,furniture: freezed == furniture ? _self.furniture : furniture // ignore: cast_nullable_to_non_nullable
as dynamic,approvalStatus: freezed == approvalStatus ? _self.approvalStatus : approvalStatus // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
