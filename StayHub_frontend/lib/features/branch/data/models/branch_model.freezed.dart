// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'branch_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BranchModel {

 int get id; int get ownerId; String get branchName; String? get branchCode; String get address; String? get addressOld; String? get legalProvince; String? get legalDistrict; String? get legalWard; String? get description; String? get pois; double? get electricityPrice; String? get electricityPricingType; double? get waterPrice; String? get waterPricingType;@JsonKey(name: 'internetFee') double? get internetPrice;@JsonKey(name: 'parkingFee') double? get parkingPrice;@JsonKey(name: 'garbageFee') double? get trashPrice; double? get serviceFee; String? get serviceFeePricingType; int? get propertyType; int? get numberOfFloors; int? get managementType; int get totalRooms; String? get coverImage;@JsonKey(name: 'coverImages') String? get coverImages; bool get isActive; String get creationStatus; String get approvalStatus; bool get step1Done; bool get step2Done; bool get step3Done; bool get step4Done; bool get step5Done; DateTime? get completedAt; DateTime? get createdAt; DateTime? get updatedAt; double? get latitude; double? get longitude; bool? get petPolicy; bool? get roommatePolicy; String? get closingTime; String? get cookingPolicy; bool? get hasPccc;@JsonKey(name: 'pcccImages') String? get pcccImages; bool? get evChargingAllowed; String? get evChargeType; double? get evFixedPrice; double? get evPercentage; int? get billingDay; int? get minLeaseDays; bool get isDeleted;
/// Create a copy of BranchModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchModelCopyWith<BranchModel> get copyWith => _$BranchModelCopyWithImpl<BranchModel>(this as BranchModel, _$identity);

  /// Serializes this BranchModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.branchCode, branchCode) || other.branchCode == branchCode)&&(identical(other.address, address) || other.address == address)&&(identical(other.addressOld, addressOld) || other.addressOld == addressOld)&&(identical(other.legalProvince, legalProvince) || other.legalProvince == legalProvince)&&(identical(other.legalDistrict, legalDistrict) || other.legalDistrict == legalDistrict)&&(identical(other.legalWard, legalWard) || other.legalWard == legalWard)&&(identical(other.description, description) || other.description == description)&&(identical(other.pois, pois) || other.pois == pois)&&(identical(other.electricityPrice, electricityPrice) || other.electricityPrice == electricityPrice)&&(identical(other.electricityPricingType, electricityPricingType) || other.electricityPricingType == electricityPricingType)&&(identical(other.waterPrice, waterPrice) || other.waterPrice == waterPrice)&&(identical(other.waterPricingType, waterPricingType) || other.waterPricingType == waterPricingType)&&(identical(other.internetPrice, internetPrice) || other.internetPrice == internetPrice)&&(identical(other.parkingPrice, parkingPrice) || other.parkingPrice == parkingPrice)&&(identical(other.trashPrice, trashPrice) || other.trashPrice == trashPrice)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.serviceFeePricingType, serviceFeePricingType) || other.serviceFeePricingType == serviceFeePricingType)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.numberOfFloors, numberOfFloors) || other.numberOfFloors == numberOfFloors)&&(identical(other.managementType, managementType) || other.managementType == managementType)&&(identical(other.totalRooms, totalRooms) || other.totalRooms == totalRooms)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.coverImages, coverImages) || other.coverImages == coverImages)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.creationStatus, creationStatus) || other.creationStatus == creationStatus)&&(identical(other.approvalStatus, approvalStatus) || other.approvalStatus == approvalStatus)&&(identical(other.step1Done, step1Done) || other.step1Done == step1Done)&&(identical(other.step2Done, step2Done) || other.step2Done == step2Done)&&(identical(other.step3Done, step3Done) || other.step3Done == step3Done)&&(identical(other.step4Done, step4Done) || other.step4Done == step4Done)&&(identical(other.step5Done, step5Done) || other.step5Done == step5Done)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.petPolicy, petPolicy) || other.petPolicy == petPolicy)&&(identical(other.roommatePolicy, roommatePolicy) || other.roommatePolicy == roommatePolicy)&&(identical(other.closingTime, closingTime) || other.closingTime == closingTime)&&(identical(other.cookingPolicy, cookingPolicy) || other.cookingPolicy == cookingPolicy)&&(identical(other.hasPccc, hasPccc) || other.hasPccc == hasPccc)&&(identical(other.pcccImages, pcccImages) || other.pcccImages == pcccImages)&&(identical(other.evChargingAllowed, evChargingAllowed) || other.evChargingAllowed == evChargingAllowed)&&(identical(other.evChargeType, evChargeType) || other.evChargeType == evChargeType)&&(identical(other.evFixedPrice, evFixedPrice) || other.evFixedPrice == evFixedPrice)&&(identical(other.evPercentage, evPercentage) || other.evPercentage == evPercentage)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.minLeaseDays, minLeaseDays) || other.minLeaseDays == minLeaseDays)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ownerId,branchName,branchCode,address,addressOld,legalProvince,legalDistrict,legalWard,description,pois,electricityPrice,electricityPricingType,waterPrice,waterPricingType,internetPrice,parkingPrice,trashPrice,serviceFee,serviceFeePricingType,propertyType,numberOfFloors,managementType,totalRooms,coverImage,coverImages,isActive,creationStatus,approvalStatus,step1Done,step2Done,step3Done,step4Done,step5Done,completedAt,createdAt,updatedAt,latitude,longitude,petPolicy,roommatePolicy,closingTime,cookingPolicy,hasPccc,pcccImages,evChargingAllowed,evChargeType,evFixedPrice,evPercentage,billingDay,minLeaseDays,isDeleted]);

@override
String toString() {
  return 'BranchModel(id: $id, ownerId: $ownerId, branchName: $branchName, branchCode: $branchCode, address: $address, addressOld: $addressOld, legalProvince: $legalProvince, legalDistrict: $legalDistrict, legalWard: $legalWard, description: $description, pois: $pois, electricityPrice: $electricityPrice, electricityPricingType: $electricityPricingType, waterPrice: $waterPrice, waterPricingType: $waterPricingType, internetPrice: $internetPrice, parkingPrice: $parkingPrice, trashPrice: $trashPrice, serviceFee: $serviceFee, serviceFeePricingType: $serviceFeePricingType, propertyType: $propertyType, numberOfFloors: $numberOfFloors, managementType: $managementType, totalRooms: $totalRooms, coverImage: $coverImage, coverImages: $coverImages, isActive: $isActive, creationStatus: $creationStatus, approvalStatus: $approvalStatus, step1Done: $step1Done, step2Done: $step2Done, step3Done: $step3Done, step4Done: $step4Done, step5Done: $step5Done, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt, latitude: $latitude, longitude: $longitude, petPolicy: $petPolicy, roommatePolicy: $roommatePolicy, closingTime: $closingTime, cookingPolicy: $cookingPolicy, hasPccc: $hasPccc, pcccImages: $pcccImages, evChargingAllowed: $evChargingAllowed, evChargeType: $evChargeType, evFixedPrice: $evFixedPrice, evPercentage: $evPercentage, billingDay: $billingDay, minLeaseDays: $minLeaseDays, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $BranchModelCopyWith<$Res>  {
  factory $BranchModelCopyWith(BranchModel value, $Res Function(BranchModel) _then) = _$BranchModelCopyWithImpl;
@useResult
$Res call({
 int id, int ownerId, String branchName, String? branchCode, String address, String? addressOld, String? legalProvince, String? legalDistrict, String? legalWard, String? description, String? pois, double? electricityPrice, String? electricityPricingType, double? waterPrice, String? waterPricingType,@JsonKey(name: 'internetFee') double? internetPrice,@JsonKey(name: 'parkingFee') double? parkingPrice,@JsonKey(name: 'garbageFee') double? trashPrice, double? serviceFee, String? serviceFeePricingType, int? propertyType, int? numberOfFloors, int? managementType, int totalRooms, String? coverImage,@JsonKey(name: 'coverImages') String? coverImages, bool isActive, String creationStatus, String approvalStatus, bool step1Done, bool step2Done, bool step3Done, bool step4Done, bool step5Done, DateTime? completedAt, DateTime? createdAt, DateTime? updatedAt, double? latitude, double? longitude, bool? petPolicy, bool? roommatePolicy, String? closingTime, String? cookingPolicy, bool? hasPccc,@JsonKey(name: 'pcccImages') String? pcccImages, bool? evChargingAllowed, String? evChargeType, double? evFixedPrice, double? evPercentage, int? billingDay, int? minLeaseDays, bool isDeleted
});




}
/// @nodoc
class _$BranchModelCopyWithImpl<$Res>
    implements $BranchModelCopyWith<$Res> {
  _$BranchModelCopyWithImpl(this._self, this._then);

  final BranchModel _self;
  final $Res Function(BranchModel) _then;

/// Create a copy of BranchModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? branchName = null,Object? branchCode = freezed,Object? address = null,Object? addressOld = freezed,Object? legalProvince = freezed,Object? legalDistrict = freezed,Object? legalWard = freezed,Object? description = freezed,Object? pois = freezed,Object? electricityPrice = freezed,Object? electricityPricingType = freezed,Object? waterPrice = freezed,Object? waterPricingType = freezed,Object? internetPrice = freezed,Object? parkingPrice = freezed,Object? trashPrice = freezed,Object? serviceFee = freezed,Object? serviceFeePricingType = freezed,Object? propertyType = freezed,Object? numberOfFloors = freezed,Object? managementType = freezed,Object? totalRooms = null,Object? coverImage = freezed,Object? coverImages = freezed,Object? isActive = null,Object? creationStatus = null,Object? approvalStatus = null,Object? step1Done = null,Object? step2Done = null,Object? step3Done = null,Object? step4Done = null,Object? step5Done = null,Object? completedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? petPolicy = freezed,Object? roommatePolicy = freezed,Object? closingTime = freezed,Object? cookingPolicy = freezed,Object? hasPccc = freezed,Object? pcccImages = freezed,Object? evChargingAllowed = freezed,Object? evChargeType = freezed,Object? evFixedPrice = freezed,Object? evPercentage = freezed,Object? billingDay = freezed,Object? minLeaseDays = freezed,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as int,branchName: null == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String,branchCode: freezed == branchCode ? _self.branchCode : branchCode // ignore: cast_nullable_to_non_nullable
as String?,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,addressOld: freezed == addressOld ? _self.addressOld : addressOld // ignore: cast_nullable_to_non_nullable
as String?,legalProvince: freezed == legalProvince ? _self.legalProvince : legalProvince // ignore: cast_nullable_to_non_nullable
as String?,legalDistrict: freezed == legalDistrict ? _self.legalDistrict : legalDistrict // ignore: cast_nullable_to_non_nullable
as String?,legalWard: freezed == legalWard ? _self.legalWard : legalWard // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,pois: freezed == pois ? _self.pois : pois // ignore: cast_nullable_to_non_nullable
as String?,electricityPrice: freezed == electricityPrice ? _self.electricityPrice : electricityPrice // ignore: cast_nullable_to_non_nullable
as double?,electricityPricingType: freezed == electricityPricingType ? _self.electricityPricingType : electricityPricingType // ignore: cast_nullable_to_non_nullable
as String?,waterPrice: freezed == waterPrice ? _self.waterPrice : waterPrice // ignore: cast_nullable_to_non_nullable
as double?,waterPricingType: freezed == waterPricingType ? _self.waterPricingType : waterPricingType // ignore: cast_nullable_to_non_nullable
as String?,internetPrice: freezed == internetPrice ? _self.internetPrice : internetPrice // ignore: cast_nullable_to_non_nullable
as double?,parkingPrice: freezed == parkingPrice ? _self.parkingPrice : parkingPrice // ignore: cast_nullable_to_non_nullable
as double?,trashPrice: freezed == trashPrice ? _self.trashPrice : trashPrice // ignore: cast_nullable_to_non_nullable
as double?,serviceFee: freezed == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double?,serviceFeePricingType: freezed == serviceFeePricingType ? _self.serviceFeePricingType : serviceFeePricingType // ignore: cast_nullable_to_non_nullable
as String?,propertyType: freezed == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as int?,numberOfFloors: freezed == numberOfFloors ? _self.numberOfFloors : numberOfFloors // ignore: cast_nullable_to_non_nullable
as int?,managementType: freezed == managementType ? _self.managementType : managementType // ignore: cast_nullable_to_non_nullable
as int?,totalRooms: null == totalRooms ? _self.totalRooms : totalRooms // ignore: cast_nullable_to_non_nullable
as int,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,coverImages: freezed == coverImages ? _self.coverImages : coverImages // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,creationStatus: null == creationStatus ? _self.creationStatus : creationStatus // ignore: cast_nullable_to_non_nullable
as String,approvalStatus: null == approvalStatus ? _self.approvalStatus : approvalStatus // ignore: cast_nullable_to_non_nullable
as String,step1Done: null == step1Done ? _self.step1Done : step1Done // ignore: cast_nullable_to_non_nullable
as bool,step2Done: null == step2Done ? _self.step2Done : step2Done // ignore: cast_nullable_to_non_nullable
as bool,step3Done: null == step3Done ? _self.step3Done : step3Done // ignore: cast_nullable_to_non_nullable
as bool,step4Done: null == step4Done ? _self.step4Done : step4Done // ignore: cast_nullable_to_non_nullable
as bool,step5Done: null == step5Done ? _self.step5Done : step5Done // ignore: cast_nullable_to_non_nullable
as bool,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,petPolicy: freezed == petPolicy ? _self.petPolicy : petPolicy // ignore: cast_nullable_to_non_nullable
as bool?,roommatePolicy: freezed == roommatePolicy ? _self.roommatePolicy : roommatePolicy // ignore: cast_nullable_to_non_nullable
as bool?,closingTime: freezed == closingTime ? _self.closingTime : closingTime // ignore: cast_nullable_to_non_nullable
as String?,cookingPolicy: freezed == cookingPolicy ? _self.cookingPolicy : cookingPolicy // ignore: cast_nullable_to_non_nullable
as String?,hasPccc: freezed == hasPccc ? _self.hasPccc : hasPccc // ignore: cast_nullable_to_non_nullable
as bool?,pcccImages: freezed == pcccImages ? _self.pcccImages : pcccImages // ignore: cast_nullable_to_non_nullable
as String?,evChargingAllowed: freezed == evChargingAllowed ? _self.evChargingAllowed : evChargingAllowed // ignore: cast_nullable_to_non_nullable
as bool?,evChargeType: freezed == evChargeType ? _self.evChargeType : evChargeType // ignore: cast_nullable_to_non_nullable
as String?,evFixedPrice: freezed == evFixedPrice ? _self.evFixedPrice : evFixedPrice // ignore: cast_nullable_to_non_nullable
as double?,evPercentage: freezed == evPercentage ? _self.evPercentage : evPercentage // ignore: cast_nullable_to_non_nullable
as double?,billingDay: freezed == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int?,minLeaseDays: freezed == minLeaseDays ? _self.minLeaseDays : minLeaseDays // ignore: cast_nullable_to_non_nullable
as int?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BranchModel].
extension BranchModelPatterns on BranchModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BranchModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BranchModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BranchModel value)  $default,){
final _that = this;
switch (_that) {
case _BranchModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BranchModel value)?  $default,){
final _that = this;
switch (_that) {
case _BranchModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int ownerId,  String branchName,  String? branchCode,  String address,  String? addressOld,  String? legalProvince,  String? legalDistrict,  String? legalWard,  String? description,  String? pois,  double? electricityPrice,  String? electricityPricingType,  double? waterPrice,  String? waterPricingType, @JsonKey(name: 'internetFee')  double? internetPrice, @JsonKey(name: 'parkingFee')  double? parkingPrice, @JsonKey(name: 'garbageFee')  double? trashPrice,  double? serviceFee,  String? serviceFeePricingType,  int? propertyType,  int? numberOfFloors,  int? managementType,  int totalRooms,  String? coverImage, @JsonKey(name: 'coverImages')  String? coverImages,  bool isActive,  String creationStatus,  String approvalStatus,  bool step1Done,  bool step2Done,  bool step3Done,  bool step4Done,  bool step5Done,  DateTime? completedAt,  DateTime? createdAt,  DateTime? updatedAt,  double? latitude,  double? longitude,  bool? petPolicy,  bool? roommatePolicy,  String? closingTime,  String? cookingPolicy,  bool? hasPccc, @JsonKey(name: 'pcccImages')  String? pcccImages,  bool? evChargingAllowed,  String? evChargeType,  double? evFixedPrice,  double? evPercentage,  int? billingDay,  int? minLeaseDays,  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BranchModel() when $default != null:
return $default(_that.id,_that.ownerId,_that.branchName,_that.branchCode,_that.address,_that.addressOld,_that.legalProvince,_that.legalDistrict,_that.legalWard,_that.description,_that.pois,_that.electricityPrice,_that.electricityPricingType,_that.waterPrice,_that.waterPricingType,_that.internetPrice,_that.parkingPrice,_that.trashPrice,_that.serviceFee,_that.serviceFeePricingType,_that.propertyType,_that.numberOfFloors,_that.managementType,_that.totalRooms,_that.coverImage,_that.coverImages,_that.isActive,_that.creationStatus,_that.approvalStatus,_that.step1Done,_that.step2Done,_that.step3Done,_that.step4Done,_that.step5Done,_that.completedAt,_that.createdAt,_that.updatedAt,_that.latitude,_that.longitude,_that.petPolicy,_that.roommatePolicy,_that.closingTime,_that.cookingPolicy,_that.hasPccc,_that.pcccImages,_that.evChargingAllowed,_that.evChargeType,_that.evFixedPrice,_that.evPercentage,_that.billingDay,_that.minLeaseDays,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int ownerId,  String branchName,  String? branchCode,  String address,  String? addressOld,  String? legalProvince,  String? legalDistrict,  String? legalWard,  String? description,  String? pois,  double? electricityPrice,  String? electricityPricingType,  double? waterPrice,  String? waterPricingType, @JsonKey(name: 'internetFee')  double? internetPrice, @JsonKey(name: 'parkingFee')  double? parkingPrice, @JsonKey(name: 'garbageFee')  double? trashPrice,  double? serviceFee,  String? serviceFeePricingType,  int? propertyType,  int? numberOfFloors,  int? managementType,  int totalRooms,  String? coverImage, @JsonKey(name: 'coverImages')  String? coverImages,  bool isActive,  String creationStatus,  String approvalStatus,  bool step1Done,  bool step2Done,  bool step3Done,  bool step4Done,  bool step5Done,  DateTime? completedAt,  DateTime? createdAt,  DateTime? updatedAt,  double? latitude,  double? longitude,  bool? petPolicy,  bool? roommatePolicy,  String? closingTime,  String? cookingPolicy,  bool? hasPccc, @JsonKey(name: 'pcccImages')  String? pcccImages,  bool? evChargingAllowed,  String? evChargeType,  double? evFixedPrice,  double? evPercentage,  int? billingDay,  int? minLeaseDays,  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _BranchModel():
return $default(_that.id,_that.ownerId,_that.branchName,_that.branchCode,_that.address,_that.addressOld,_that.legalProvince,_that.legalDistrict,_that.legalWard,_that.description,_that.pois,_that.electricityPrice,_that.electricityPricingType,_that.waterPrice,_that.waterPricingType,_that.internetPrice,_that.parkingPrice,_that.trashPrice,_that.serviceFee,_that.serviceFeePricingType,_that.propertyType,_that.numberOfFloors,_that.managementType,_that.totalRooms,_that.coverImage,_that.coverImages,_that.isActive,_that.creationStatus,_that.approvalStatus,_that.step1Done,_that.step2Done,_that.step3Done,_that.step4Done,_that.step5Done,_that.completedAt,_that.createdAt,_that.updatedAt,_that.latitude,_that.longitude,_that.petPolicy,_that.roommatePolicy,_that.closingTime,_that.cookingPolicy,_that.hasPccc,_that.pcccImages,_that.evChargingAllowed,_that.evChargeType,_that.evFixedPrice,_that.evPercentage,_that.billingDay,_that.minLeaseDays,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int ownerId,  String branchName,  String? branchCode,  String address,  String? addressOld,  String? legalProvince,  String? legalDistrict,  String? legalWard,  String? description,  String? pois,  double? electricityPrice,  String? electricityPricingType,  double? waterPrice,  String? waterPricingType, @JsonKey(name: 'internetFee')  double? internetPrice, @JsonKey(name: 'parkingFee')  double? parkingPrice, @JsonKey(name: 'garbageFee')  double? trashPrice,  double? serviceFee,  String? serviceFeePricingType,  int? propertyType,  int? numberOfFloors,  int? managementType,  int totalRooms,  String? coverImage, @JsonKey(name: 'coverImages')  String? coverImages,  bool isActive,  String creationStatus,  String approvalStatus,  bool step1Done,  bool step2Done,  bool step3Done,  bool step4Done,  bool step5Done,  DateTime? completedAt,  DateTime? createdAt,  DateTime? updatedAt,  double? latitude,  double? longitude,  bool? petPolicy,  bool? roommatePolicy,  String? closingTime,  String? cookingPolicy,  bool? hasPccc, @JsonKey(name: 'pcccImages')  String? pcccImages,  bool? evChargingAllowed,  String? evChargeType,  double? evFixedPrice,  double? evPercentage,  int? billingDay,  int? minLeaseDays,  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _BranchModel() when $default != null:
return $default(_that.id,_that.ownerId,_that.branchName,_that.branchCode,_that.address,_that.addressOld,_that.legalProvince,_that.legalDistrict,_that.legalWard,_that.description,_that.pois,_that.electricityPrice,_that.electricityPricingType,_that.waterPrice,_that.waterPricingType,_that.internetPrice,_that.parkingPrice,_that.trashPrice,_that.serviceFee,_that.serviceFeePricingType,_that.propertyType,_that.numberOfFloors,_that.managementType,_that.totalRooms,_that.coverImage,_that.coverImages,_that.isActive,_that.creationStatus,_that.approvalStatus,_that.step1Done,_that.step2Done,_that.step3Done,_that.step4Done,_that.step5Done,_that.completedAt,_that.createdAt,_that.updatedAt,_that.latitude,_that.longitude,_that.petPolicy,_that.roommatePolicy,_that.closingTime,_that.cookingPolicy,_that.hasPccc,_that.pcccImages,_that.evChargingAllowed,_that.evChargeType,_that.evFixedPrice,_that.evPercentage,_that.billingDay,_that.minLeaseDays,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BranchModel implements BranchModel {
  const _BranchModel({required this.id, required this.ownerId, required this.branchName, this.branchCode, required this.address, this.addressOld, this.legalProvince, this.legalDistrict, this.legalWard, this.description, this.pois, this.electricityPrice, this.electricityPricingType, this.waterPrice, this.waterPricingType, @JsonKey(name: 'internetFee') this.internetPrice, @JsonKey(name: 'parkingFee') this.parkingPrice, @JsonKey(name: 'garbageFee') this.trashPrice, this.serviceFee, this.serviceFeePricingType, this.propertyType, this.numberOfFloors, this.managementType, this.totalRooms = 0, this.coverImage, @JsonKey(name: 'coverImages') this.coverImages, this.isActive = true, this.creationStatus = 'DRAFT', this.approvalStatus = 'APPROVED', this.step1Done = false, this.step2Done = false, this.step3Done = false, this.step4Done = false, this.step5Done = false, this.completedAt, this.createdAt, this.updatedAt, this.latitude, this.longitude, this.petPolicy, this.roommatePolicy, this.closingTime, this.cookingPolicy, this.hasPccc, @JsonKey(name: 'pcccImages') this.pcccImages, this.evChargingAllowed, this.evChargeType, this.evFixedPrice, this.evPercentage, this.billingDay, this.minLeaseDays, this.isDeleted = false});
  factory _BranchModel.fromJson(Map<String, dynamic> json) => _$BranchModelFromJson(json);

@override final  int id;
@override final  int ownerId;
@override final  String branchName;
@override final  String? branchCode;
@override final  String address;
@override final  String? addressOld;
@override final  String? legalProvince;
@override final  String? legalDistrict;
@override final  String? legalWard;
@override final  String? description;
@override final  String? pois;
@override final  double? electricityPrice;
@override final  String? electricityPricingType;
@override final  double? waterPrice;
@override final  String? waterPricingType;
@override@JsonKey(name: 'internetFee') final  double? internetPrice;
@override@JsonKey(name: 'parkingFee') final  double? parkingPrice;
@override@JsonKey(name: 'garbageFee') final  double? trashPrice;
@override final  double? serviceFee;
@override final  String? serviceFeePricingType;
@override final  int? propertyType;
@override final  int? numberOfFloors;
@override final  int? managementType;
@override@JsonKey() final  int totalRooms;
@override final  String? coverImage;
@override@JsonKey(name: 'coverImages') final  String? coverImages;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  String creationStatus;
@override@JsonKey() final  String approvalStatus;
@override@JsonKey() final  bool step1Done;
@override@JsonKey() final  bool step2Done;
@override@JsonKey() final  bool step3Done;
@override@JsonKey() final  bool step4Done;
@override@JsonKey() final  bool step5Done;
@override final  DateTime? completedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  double? latitude;
@override final  double? longitude;
@override final  bool? petPolicy;
@override final  bool? roommatePolicy;
@override final  String? closingTime;
@override final  String? cookingPolicy;
@override final  bool? hasPccc;
@override@JsonKey(name: 'pcccImages') final  String? pcccImages;
@override final  bool? evChargingAllowed;
@override final  String? evChargeType;
@override final  double? evFixedPrice;
@override final  double? evPercentage;
@override final  int? billingDay;
@override final  int? minLeaseDays;
@override@JsonKey() final  bool isDeleted;

/// Create a copy of BranchModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BranchModelCopyWith<_BranchModel> get copyWith => __$BranchModelCopyWithImpl<_BranchModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BranchModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BranchModel&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.branchCode, branchCode) || other.branchCode == branchCode)&&(identical(other.address, address) || other.address == address)&&(identical(other.addressOld, addressOld) || other.addressOld == addressOld)&&(identical(other.legalProvince, legalProvince) || other.legalProvince == legalProvince)&&(identical(other.legalDistrict, legalDistrict) || other.legalDistrict == legalDistrict)&&(identical(other.legalWard, legalWard) || other.legalWard == legalWard)&&(identical(other.description, description) || other.description == description)&&(identical(other.pois, pois) || other.pois == pois)&&(identical(other.electricityPrice, electricityPrice) || other.electricityPrice == electricityPrice)&&(identical(other.electricityPricingType, electricityPricingType) || other.electricityPricingType == electricityPricingType)&&(identical(other.waterPrice, waterPrice) || other.waterPrice == waterPrice)&&(identical(other.waterPricingType, waterPricingType) || other.waterPricingType == waterPricingType)&&(identical(other.internetPrice, internetPrice) || other.internetPrice == internetPrice)&&(identical(other.parkingPrice, parkingPrice) || other.parkingPrice == parkingPrice)&&(identical(other.trashPrice, trashPrice) || other.trashPrice == trashPrice)&&(identical(other.serviceFee, serviceFee) || other.serviceFee == serviceFee)&&(identical(other.serviceFeePricingType, serviceFeePricingType) || other.serviceFeePricingType == serviceFeePricingType)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.numberOfFloors, numberOfFloors) || other.numberOfFloors == numberOfFloors)&&(identical(other.managementType, managementType) || other.managementType == managementType)&&(identical(other.totalRooms, totalRooms) || other.totalRooms == totalRooms)&&(identical(other.coverImage, coverImage) || other.coverImage == coverImage)&&(identical(other.coverImages, coverImages) || other.coverImages == coverImages)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.creationStatus, creationStatus) || other.creationStatus == creationStatus)&&(identical(other.approvalStatus, approvalStatus) || other.approvalStatus == approvalStatus)&&(identical(other.step1Done, step1Done) || other.step1Done == step1Done)&&(identical(other.step2Done, step2Done) || other.step2Done == step2Done)&&(identical(other.step3Done, step3Done) || other.step3Done == step3Done)&&(identical(other.step4Done, step4Done) || other.step4Done == step4Done)&&(identical(other.step5Done, step5Done) || other.step5Done == step5Done)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.petPolicy, petPolicy) || other.petPolicy == petPolicy)&&(identical(other.roommatePolicy, roommatePolicy) || other.roommatePolicy == roommatePolicy)&&(identical(other.closingTime, closingTime) || other.closingTime == closingTime)&&(identical(other.cookingPolicy, cookingPolicy) || other.cookingPolicy == cookingPolicy)&&(identical(other.hasPccc, hasPccc) || other.hasPccc == hasPccc)&&(identical(other.pcccImages, pcccImages) || other.pcccImages == pcccImages)&&(identical(other.evChargingAllowed, evChargingAllowed) || other.evChargingAllowed == evChargingAllowed)&&(identical(other.evChargeType, evChargeType) || other.evChargeType == evChargeType)&&(identical(other.evFixedPrice, evFixedPrice) || other.evFixedPrice == evFixedPrice)&&(identical(other.evPercentage, evPercentage) || other.evPercentage == evPercentage)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.minLeaseDays, minLeaseDays) || other.minLeaseDays == minLeaseDays)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,ownerId,branchName,branchCode,address,addressOld,legalProvince,legalDistrict,legalWard,description,pois,electricityPrice,electricityPricingType,waterPrice,waterPricingType,internetPrice,parkingPrice,trashPrice,serviceFee,serviceFeePricingType,propertyType,numberOfFloors,managementType,totalRooms,coverImage,coverImages,isActive,creationStatus,approvalStatus,step1Done,step2Done,step3Done,step4Done,step5Done,completedAt,createdAt,updatedAt,latitude,longitude,petPolicy,roommatePolicy,closingTime,cookingPolicy,hasPccc,pcccImages,evChargingAllowed,evChargeType,evFixedPrice,evPercentage,billingDay,minLeaseDays,isDeleted]);

@override
String toString() {
  return 'BranchModel(id: $id, ownerId: $ownerId, branchName: $branchName, branchCode: $branchCode, address: $address, addressOld: $addressOld, legalProvince: $legalProvince, legalDistrict: $legalDistrict, legalWard: $legalWard, description: $description, pois: $pois, electricityPrice: $electricityPrice, electricityPricingType: $electricityPricingType, waterPrice: $waterPrice, waterPricingType: $waterPricingType, internetPrice: $internetPrice, parkingPrice: $parkingPrice, trashPrice: $trashPrice, serviceFee: $serviceFee, serviceFeePricingType: $serviceFeePricingType, propertyType: $propertyType, numberOfFloors: $numberOfFloors, managementType: $managementType, totalRooms: $totalRooms, coverImage: $coverImage, coverImages: $coverImages, isActive: $isActive, creationStatus: $creationStatus, approvalStatus: $approvalStatus, step1Done: $step1Done, step2Done: $step2Done, step3Done: $step3Done, step4Done: $step4Done, step5Done: $step5Done, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt, latitude: $latitude, longitude: $longitude, petPolicy: $petPolicy, roommatePolicy: $roommatePolicy, closingTime: $closingTime, cookingPolicy: $cookingPolicy, hasPccc: $hasPccc, pcccImages: $pcccImages, evChargingAllowed: $evChargingAllowed, evChargeType: $evChargeType, evFixedPrice: $evFixedPrice, evPercentage: $evPercentage, billingDay: $billingDay, minLeaseDays: $minLeaseDays, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$BranchModelCopyWith<$Res> implements $BranchModelCopyWith<$Res> {
  factory _$BranchModelCopyWith(_BranchModel value, $Res Function(_BranchModel) _then) = __$BranchModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int ownerId, String branchName, String? branchCode, String address, String? addressOld, String? legalProvince, String? legalDistrict, String? legalWard, String? description, String? pois, double? electricityPrice, String? electricityPricingType, double? waterPrice, String? waterPricingType,@JsonKey(name: 'internetFee') double? internetPrice,@JsonKey(name: 'parkingFee') double? parkingPrice,@JsonKey(name: 'garbageFee') double? trashPrice, double? serviceFee, String? serviceFeePricingType, int? propertyType, int? numberOfFloors, int? managementType, int totalRooms, String? coverImage,@JsonKey(name: 'coverImages') String? coverImages, bool isActive, String creationStatus, String approvalStatus, bool step1Done, bool step2Done, bool step3Done, bool step4Done, bool step5Done, DateTime? completedAt, DateTime? createdAt, DateTime? updatedAt, double? latitude, double? longitude, bool? petPolicy, bool? roommatePolicy, String? closingTime, String? cookingPolicy, bool? hasPccc,@JsonKey(name: 'pcccImages') String? pcccImages, bool? evChargingAllowed, String? evChargeType, double? evFixedPrice, double? evPercentage, int? billingDay, int? minLeaseDays, bool isDeleted
});




}
/// @nodoc
class __$BranchModelCopyWithImpl<$Res>
    implements _$BranchModelCopyWith<$Res> {
  __$BranchModelCopyWithImpl(this._self, this._then);

  final _BranchModel _self;
  final $Res Function(_BranchModel) _then;

/// Create a copy of BranchModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? branchName = null,Object? branchCode = freezed,Object? address = null,Object? addressOld = freezed,Object? legalProvince = freezed,Object? legalDistrict = freezed,Object? legalWard = freezed,Object? description = freezed,Object? pois = freezed,Object? electricityPrice = freezed,Object? electricityPricingType = freezed,Object? waterPrice = freezed,Object? waterPricingType = freezed,Object? internetPrice = freezed,Object? parkingPrice = freezed,Object? trashPrice = freezed,Object? serviceFee = freezed,Object? serviceFeePricingType = freezed,Object? propertyType = freezed,Object? numberOfFloors = freezed,Object? managementType = freezed,Object? totalRooms = null,Object? coverImage = freezed,Object? coverImages = freezed,Object? isActive = null,Object? creationStatus = null,Object? approvalStatus = null,Object? step1Done = null,Object? step2Done = null,Object? step3Done = null,Object? step4Done = null,Object? step5Done = null,Object? completedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? petPolicy = freezed,Object? roommatePolicy = freezed,Object? closingTime = freezed,Object? cookingPolicy = freezed,Object? hasPccc = freezed,Object? pcccImages = freezed,Object? evChargingAllowed = freezed,Object? evChargeType = freezed,Object? evFixedPrice = freezed,Object? evPercentage = freezed,Object? billingDay = freezed,Object? minLeaseDays = freezed,Object? isDeleted = null,}) {
  return _then(_BranchModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as int,branchName: null == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String,branchCode: freezed == branchCode ? _self.branchCode : branchCode // ignore: cast_nullable_to_non_nullable
as String?,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,addressOld: freezed == addressOld ? _self.addressOld : addressOld // ignore: cast_nullable_to_non_nullable
as String?,legalProvince: freezed == legalProvince ? _self.legalProvince : legalProvince // ignore: cast_nullable_to_non_nullable
as String?,legalDistrict: freezed == legalDistrict ? _self.legalDistrict : legalDistrict // ignore: cast_nullable_to_non_nullable
as String?,legalWard: freezed == legalWard ? _self.legalWard : legalWard // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,pois: freezed == pois ? _self.pois : pois // ignore: cast_nullable_to_non_nullable
as String?,electricityPrice: freezed == electricityPrice ? _self.electricityPrice : electricityPrice // ignore: cast_nullable_to_non_nullable
as double?,electricityPricingType: freezed == electricityPricingType ? _self.electricityPricingType : electricityPricingType // ignore: cast_nullable_to_non_nullable
as String?,waterPrice: freezed == waterPrice ? _self.waterPrice : waterPrice // ignore: cast_nullable_to_non_nullable
as double?,waterPricingType: freezed == waterPricingType ? _self.waterPricingType : waterPricingType // ignore: cast_nullable_to_non_nullable
as String?,internetPrice: freezed == internetPrice ? _self.internetPrice : internetPrice // ignore: cast_nullable_to_non_nullable
as double?,parkingPrice: freezed == parkingPrice ? _self.parkingPrice : parkingPrice // ignore: cast_nullable_to_non_nullable
as double?,trashPrice: freezed == trashPrice ? _self.trashPrice : trashPrice // ignore: cast_nullable_to_non_nullable
as double?,serviceFee: freezed == serviceFee ? _self.serviceFee : serviceFee // ignore: cast_nullable_to_non_nullable
as double?,serviceFeePricingType: freezed == serviceFeePricingType ? _self.serviceFeePricingType : serviceFeePricingType // ignore: cast_nullable_to_non_nullable
as String?,propertyType: freezed == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as int?,numberOfFloors: freezed == numberOfFloors ? _self.numberOfFloors : numberOfFloors // ignore: cast_nullable_to_non_nullable
as int?,managementType: freezed == managementType ? _self.managementType : managementType // ignore: cast_nullable_to_non_nullable
as int?,totalRooms: null == totalRooms ? _self.totalRooms : totalRooms // ignore: cast_nullable_to_non_nullable
as int,coverImage: freezed == coverImage ? _self.coverImage : coverImage // ignore: cast_nullable_to_non_nullable
as String?,coverImages: freezed == coverImages ? _self.coverImages : coverImages // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,creationStatus: null == creationStatus ? _self.creationStatus : creationStatus // ignore: cast_nullable_to_non_nullable
as String,approvalStatus: null == approvalStatus ? _self.approvalStatus : approvalStatus // ignore: cast_nullable_to_non_nullable
as String,step1Done: null == step1Done ? _self.step1Done : step1Done // ignore: cast_nullable_to_non_nullable
as bool,step2Done: null == step2Done ? _self.step2Done : step2Done // ignore: cast_nullable_to_non_nullable
as bool,step3Done: null == step3Done ? _self.step3Done : step3Done // ignore: cast_nullable_to_non_nullable
as bool,step4Done: null == step4Done ? _self.step4Done : step4Done // ignore: cast_nullable_to_non_nullable
as bool,step5Done: null == step5Done ? _self.step5Done : step5Done // ignore: cast_nullable_to_non_nullable
as bool,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,petPolicy: freezed == petPolicy ? _self.petPolicy : petPolicy // ignore: cast_nullable_to_non_nullable
as bool?,roommatePolicy: freezed == roommatePolicy ? _self.roommatePolicy : roommatePolicy // ignore: cast_nullable_to_non_nullable
as bool?,closingTime: freezed == closingTime ? _self.closingTime : closingTime // ignore: cast_nullable_to_non_nullable
as String?,cookingPolicy: freezed == cookingPolicy ? _self.cookingPolicy : cookingPolicy // ignore: cast_nullable_to_non_nullable
as String?,hasPccc: freezed == hasPccc ? _self.hasPccc : hasPccc // ignore: cast_nullable_to_non_nullable
as bool?,pcccImages: freezed == pcccImages ? _self.pcccImages : pcccImages // ignore: cast_nullable_to_non_nullable
as String?,evChargingAllowed: freezed == evChargingAllowed ? _self.evChargingAllowed : evChargingAllowed // ignore: cast_nullable_to_non_nullable
as bool?,evChargeType: freezed == evChargeType ? _self.evChargeType : evChargeType // ignore: cast_nullable_to_non_nullable
as String?,evFixedPrice: freezed == evFixedPrice ? _self.evFixedPrice : evFixedPrice // ignore: cast_nullable_to_non_nullable
as double?,evPercentage: freezed == evPercentage ? _self.evPercentage : evPercentage // ignore: cast_nullable_to_non_nullable
as double?,billingDay: freezed == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int?,minLeaseDays: freezed == minLeaseDays ? _self.minLeaseDays : minLeaseDays // ignore: cast_nullable_to_non_nullable
as int?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
