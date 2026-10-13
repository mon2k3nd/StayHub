// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

 int get id;@JsonKey(name: 'fullName') String get fullName;@JsonKey(name: 'phone') String? get phone; String? get email;@JsonKey(name: 'roleId', readValue: readRoleIdValue) String get roleId;@JsonKey(name: 'packageId') String get packageId; String? get status; String? get bankName; String? get bankAccountNumber; String? get bankAccountName; String? get cccdNumber; String? get cccdIssueDate; String? get cccdIssuePlace; String? get emergencyContactName; String? get emergencyContactPhone; String? get vehicleType; String? get licensePlate; String? get hometown; String? get gender; String? get dateOfBirth; String? get occupation; String? get ownerStatus; String? get signature; String? get kycStatus; int? get trustScore; String? get avatarUrl; bool get requirePasswordSetup;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.packageId, packageId) || other.packageId == packageId)&&(identical(other.status, status) || other.status == status)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankAccountNumber, bankAccountNumber) || other.bankAccountNumber == bankAccountNumber)&&(identical(other.bankAccountName, bankAccountName) || other.bankAccountName == bankAccountName)&&(identical(other.cccdNumber, cccdNumber) || other.cccdNumber == cccdNumber)&&(identical(other.cccdIssueDate, cccdIssueDate) || other.cccdIssueDate == cccdIssueDate)&&(identical(other.cccdIssuePlace, cccdIssuePlace) || other.cccdIssuePlace == cccdIssuePlace)&&(identical(other.emergencyContactName, emergencyContactName) || other.emergencyContactName == emergencyContactName)&&(identical(other.emergencyContactPhone, emergencyContactPhone) || other.emergencyContactPhone == emergencyContactPhone)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.licensePlate, licensePlate) || other.licensePlate == licensePlate)&&(identical(other.hometown, hometown) || other.hometown == hometown)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.occupation, occupation) || other.occupation == occupation)&&(identical(other.ownerStatus, ownerStatus) || other.ownerStatus == ownerStatus)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.trustScore, trustScore) || other.trustScore == trustScore)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.requirePasswordSetup, requirePasswordSetup) || other.requirePasswordSetup == requirePasswordSetup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,fullName,phone,email,roleId,packageId,status,bankName,bankAccountNumber,bankAccountName,cccdNumber,cccdIssueDate,cccdIssuePlace,emergencyContactName,emergencyContactPhone,vehicleType,licensePlate,hometown,gender,dateOfBirth,occupation,ownerStatus,signature,kycStatus,trustScore,avatarUrl,requirePasswordSetup]);

@override
String toString() {
  return 'UserModel(id: $id, fullName: $fullName, phone: $phone, email: $email, roleId: $roleId, packageId: $packageId, status: $status, bankName: $bankName, bankAccountNumber: $bankAccountNumber, bankAccountName: $bankAccountName, cccdNumber: $cccdNumber, cccdIssueDate: $cccdIssueDate, cccdIssuePlace: $cccdIssuePlace, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, vehicleType: $vehicleType, licensePlate: $licensePlate, hometown: $hometown, gender: $gender, dateOfBirth: $dateOfBirth, occupation: $occupation, ownerStatus: $ownerStatus, signature: $signature, kycStatus: $kycStatus, trustScore: $trustScore, avatarUrl: $avatarUrl, requirePasswordSetup: $requirePasswordSetup)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'fullName') String fullName,@JsonKey(name: 'phone') String? phone, String? email,@JsonKey(name: 'roleId', readValue: readRoleIdValue) String roleId,@JsonKey(name: 'packageId') String packageId, String? status, String? bankName, String? bankAccountNumber, String? bankAccountName, String? cccdNumber, String? cccdIssueDate, String? cccdIssuePlace, String? emergencyContactName, String? emergencyContactPhone, String? vehicleType, String? licensePlate, String? hometown, String? gender, String? dateOfBirth, String? occupation, String? ownerStatus, String? signature, String? kycStatus, int? trustScore, String? avatarUrl, bool requirePasswordSetup
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? phone = freezed,Object? email = freezed,Object? roleId = null,Object? packageId = null,Object? status = freezed,Object? bankName = freezed,Object? bankAccountNumber = freezed,Object? bankAccountName = freezed,Object? cccdNumber = freezed,Object? cccdIssueDate = freezed,Object? cccdIssuePlace = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? vehicleType = freezed,Object? licensePlate = freezed,Object? hometown = freezed,Object? gender = freezed,Object? dateOfBirth = freezed,Object? occupation = freezed,Object? ownerStatus = freezed,Object? signature = freezed,Object? kycStatus = freezed,Object? trustScore = freezed,Object? avatarUrl = freezed,Object? requirePasswordSetup = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String,packageId: null == packageId ? _self.packageId : packageId // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,bankAccountNumber: freezed == bankAccountNumber ? _self.bankAccountNumber : bankAccountNumber // ignore: cast_nullable_to_non_nullable
as String?,bankAccountName: freezed == bankAccountName ? _self.bankAccountName : bankAccountName // ignore: cast_nullable_to_non_nullable
as String?,cccdNumber: freezed == cccdNumber ? _self.cccdNumber : cccdNumber // ignore: cast_nullable_to_non_nullable
as String?,cccdIssueDate: freezed == cccdIssueDate ? _self.cccdIssueDate : cccdIssueDate // ignore: cast_nullable_to_non_nullable
as String?,cccdIssuePlace: freezed == cccdIssuePlace ? _self.cccdIssuePlace : cccdIssuePlace // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String?,licensePlate: freezed == licensePlate ? _self.licensePlate : licensePlate // ignore: cast_nullable_to_non_nullable
as String?,hometown: freezed == hometown ? _self.hometown : hometown // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,ownerStatus: freezed == ownerStatus ? _self.ownerStatus : ownerStatus // ignore: cast_nullable_to_non_nullable
as String?,signature: freezed == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String?,kycStatus: freezed == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String?,trustScore: freezed == trustScore ? _self.trustScore : trustScore // ignore: cast_nullable_to_non_nullable
as int?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,requirePasswordSetup: null == requirePasswordSetup ? _self.requirePasswordSetup : requirePasswordSetup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'fullName')  String fullName, @JsonKey(name: 'phone')  String? phone,  String? email, @JsonKey(name: 'roleId', readValue: readRoleIdValue)  String roleId, @JsonKey(name: 'packageId')  String packageId,  String? status,  String? bankName,  String? bankAccountNumber,  String? bankAccountName,  String? cccdNumber,  String? cccdIssueDate,  String? cccdIssuePlace,  String? emergencyContactName,  String? emergencyContactPhone,  String? vehicleType,  String? licensePlate,  String? hometown,  String? gender,  String? dateOfBirth,  String? occupation,  String? ownerStatus,  String? signature,  String? kycStatus,  int? trustScore,  String? avatarUrl,  bool requirePasswordSetup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.fullName,_that.phone,_that.email,_that.roleId,_that.packageId,_that.status,_that.bankName,_that.bankAccountNumber,_that.bankAccountName,_that.cccdNumber,_that.cccdIssueDate,_that.cccdIssuePlace,_that.emergencyContactName,_that.emergencyContactPhone,_that.vehicleType,_that.licensePlate,_that.hometown,_that.gender,_that.dateOfBirth,_that.occupation,_that.ownerStatus,_that.signature,_that.kycStatus,_that.trustScore,_that.avatarUrl,_that.requirePasswordSetup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'fullName')  String fullName, @JsonKey(name: 'phone')  String? phone,  String? email, @JsonKey(name: 'roleId', readValue: readRoleIdValue)  String roleId, @JsonKey(name: 'packageId')  String packageId,  String? status,  String? bankName,  String? bankAccountNumber,  String? bankAccountName,  String? cccdNumber,  String? cccdIssueDate,  String? cccdIssuePlace,  String? emergencyContactName,  String? emergencyContactPhone,  String? vehicleType,  String? licensePlate,  String? hometown,  String? gender,  String? dateOfBirth,  String? occupation,  String? ownerStatus,  String? signature,  String? kycStatus,  int? trustScore,  String? avatarUrl,  bool requirePasswordSetup)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.id,_that.fullName,_that.phone,_that.email,_that.roleId,_that.packageId,_that.status,_that.bankName,_that.bankAccountNumber,_that.bankAccountName,_that.cccdNumber,_that.cccdIssueDate,_that.cccdIssuePlace,_that.emergencyContactName,_that.emergencyContactPhone,_that.vehicleType,_that.licensePlate,_that.hometown,_that.gender,_that.dateOfBirth,_that.occupation,_that.ownerStatus,_that.signature,_that.kycStatus,_that.trustScore,_that.avatarUrl,_that.requirePasswordSetup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'fullName')  String fullName, @JsonKey(name: 'phone')  String? phone,  String? email, @JsonKey(name: 'roleId', readValue: readRoleIdValue)  String roleId, @JsonKey(name: 'packageId')  String packageId,  String? status,  String? bankName,  String? bankAccountNumber,  String? bankAccountName,  String? cccdNumber,  String? cccdIssueDate,  String? cccdIssuePlace,  String? emergencyContactName,  String? emergencyContactPhone,  String? vehicleType,  String? licensePlate,  String? hometown,  String? gender,  String? dateOfBirth,  String? occupation,  String? ownerStatus,  String? signature,  String? kycStatus,  int? trustScore,  String? avatarUrl,  bool requirePasswordSetup)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.id,_that.fullName,_that.phone,_that.email,_that.roleId,_that.packageId,_that.status,_that.bankName,_that.bankAccountNumber,_that.bankAccountName,_that.cccdNumber,_that.cccdIssueDate,_that.cccdIssuePlace,_that.emergencyContactName,_that.emergencyContactPhone,_that.vehicleType,_that.licensePlate,_that.hometown,_that.gender,_that.dateOfBirth,_that.occupation,_that.ownerStatus,_that.signature,_that.kycStatus,_that.trustScore,_that.avatarUrl,_that.requirePasswordSetup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel extends UserModel {
  const _UserModel({required this.id, @JsonKey(name: 'fullName') required this.fullName, @JsonKey(name: 'phone') this.phone, this.email, @JsonKey(name: 'roleId', readValue: readRoleIdValue) required this.roleId, @JsonKey(name: 'packageId') this.packageId = 'FREE', this.status, this.bankName, this.bankAccountNumber, this.bankAccountName, this.cccdNumber, this.cccdIssueDate, this.cccdIssuePlace, this.emergencyContactName, this.emergencyContactPhone, this.vehicleType, this.licensePlate, this.hometown, this.gender, this.dateOfBirth, this.occupation, this.ownerStatus, this.signature, this.kycStatus, this.trustScore, this.avatarUrl, this.requirePasswordSetup = false}): super._();
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'fullName') final  String fullName;
@override@JsonKey(name: 'phone') final  String? phone;
@override final  String? email;
@override@JsonKey(name: 'roleId', readValue: readRoleIdValue) final  String roleId;
@override@JsonKey(name: 'packageId') final  String packageId;
@override final  String? status;
@override final  String? bankName;
@override final  String? bankAccountNumber;
@override final  String? bankAccountName;
@override final  String? cccdNumber;
@override final  String? cccdIssueDate;
@override final  String? cccdIssuePlace;
@override final  String? emergencyContactName;
@override final  String? emergencyContactPhone;
@override final  String? vehicleType;
@override final  String? licensePlate;
@override final  String? hometown;
@override final  String? gender;
@override final  String? dateOfBirth;
@override final  String? occupation;
@override final  String? ownerStatus;
@override final  String? signature;
@override final  String? kycStatus;
@override final  int? trustScore;
@override final  String? avatarUrl;
@override@JsonKey() final  bool requirePasswordSetup;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.packageId, packageId) || other.packageId == packageId)&&(identical(other.status, status) || other.status == status)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankAccountNumber, bankAccountNumber) || other.bankAccountNumber == bankAccountNumber)&&(identical(other.bankAccountName, bankAccountName) || other.bankAccountName == bankAccountName)&&(identical(other.cccdNumber, cccdNumber) || other.cccdNumber == cccdNumber)&&(identical(other.cccdIssueDate, cccdIssueDate) || other.cccdIssueDate == cccdIssueDate)&&(identical(other.cccdIssuePlace, cccdIssuePlace) || other.cccdIssuePlace == cccdIssuePlace)&&(identical(other.emergencyContactName, emergencyContactName) || other.emergencyContactName == emergencyContactName)&&(identical(other.emergencyContactPhone, emergencyContactPhone) || other.emergencyContactPhone == emergencyContactPhone)&&(identical(other.vehicleType, vehicleType) || other.vehicleType == vehicleType)&&(identical(other.licensePlate, licensePlate) || other.licensePlate == licensePlate)&&(identical(other.hometown, hometown) || other.hometown == hometown)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.occupation, occupation) || other.occupation == occupation)&&(identical(other.ownerStatus, ownerStatus) || other.ownerStatus == ownerStatus)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.trustScore, trustScore) || other.trustScore == trustScore)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.requirePasswordSetup, requirePasswordSetup) || other.requirePasswordSetup == requirePasswordSetup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,fullName,phone,email,roleId,packageId,status,bankName,bankAccountNumber,bankAccountName,cccdNumber,cccdIssueDate,cccdIssuePlace,emergencyContactName,emergencyContactPhone,vehicleType,licensePlate,hometown,gender,dateOfBirth,occupation,ownerStatus,signature,kycStatus,trustScore,avatarUrl,requirePasswordSetup]);

@override
String toString() {
  return 'UserModel(id: $id, fullName: $fullName, phone: $phone, email: $email, roleId: $roleId, packageId: $packageId, status: $status, bankName: $bankName, bankAccountNumber: $bankAccountNumber, bankAccountName: $bankAccountName, cccdNumber: $cccdNumber, cccdIssueDate: $cccdIssueDate, cccdIssuePlace: $cccdIssuePlace, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, vehicleType: $vehicleType, licensePlate: $licensePlate, hometown: $hometown, gender: $gender, dateOfBirth: $dateOfBirth, occupation: $occupation, ownerStatus: $ownerStatus, signature: $signature, kycStatus: $kycStatus, trustScore: $trustScore, avatarUrl: $avatarUrl, requirePasswordSetup: $requirePasswordSetup)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'fullName') String fullName,@JsonKey(name: 'phone') String? phone, String? email,@JsonKey(name: 'roleId', readValue: readRoleIdValue) String roleId,@JsonKey(name: 'packageId') String packageId, String? status, String? bankName, String? bankAccountNumber, String? bankAccountName, String? cccdNumber, String? cccdIssueDate, String? cccdIssuePlace, String? emergencyContactName, String? emergencyContactPhone, String? vehicleType, String? licensePlate, String? hometown, String? gender, String? dateOfBirth, String? occupation, String? ownerStatus, String? signature, String? kycStatus, int? trustScore, String? avatarUrl, bool requirePasswordSetup
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? phone = freezed,Object? email = freezed,Object? roleId = null,Object? packageId = null,Object? status = freezed,Object? bankName = freezed,Object? bankAccountNumber = freezed,Object? bankAccountName = freezed,Object? cccdNumber = freezed,Object? cccdIssueDate = freezed,Object? cccdIssuePlace = freezed,Object? emergencyContactName = freezed,Object? emergencyContactPhone = freezed,Object? vehicleType = freezed,Object? licensePlate = freezed,Object? hometown = freezed,Object? gender = freezed,Object? dateOfBirth = freezed,Object? occupation = freezed,Object? ownerStatus = freezed,Object? signature = freezed,Object? kycStatus = freezed,Object? trustScore = freezed,Object? avatarUrl = freezed,Object? requirePasswordSetup = null,}) {
  return _then(_UserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,roleId: null == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String,packageId: null == packageId ? _self.packageId : packageId // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,bankAccountNumber: freezed == bankAccountNumber ? _self.bankAccountNumber : bankAccountNumber // ignore: cast_nullable_to_non_nullable
as String?,bankAccountName: freezed == bankAccountName ? _self.bankAccountName : bankAccountName // ignore: cast_nullable_to_non_nullable
as String?,cccdNumber: freezed == cccdNumber ? _self.cccdNumber : cccdNumber // ignore: cast_nullable_to_non_nullable
as String?,cccdIssueDate: freezed == cccdIssueDate ? _self.cccdIssueDate : cccdIssueDate // ignore: cast_nullable_to_non_nullable
as String?,cccdIssuePlace: freezed == cccdIssuePlace ? _self.cccdIssuePlace : cccdIssuePlace // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactName: freezed == emergencyContactName ? _self.emergencyContactName : emergencyContactName // ignore: cast_nullable_to_non_nullable
as String?,emergencyContactPhone: freezed == emergencyContactPhone ? _self.emergencyContactPhone : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
as String?,vehicleType: freezed == vehicleType ? _self.vehicleType : vehicleType // ignore: cast_nullable_to_non_nullable
as String?,licensePlate: freezed == licensePlate ? _self.licensePlate : licensePlate // ignore: cast_nullable_to_non_nullable
as String?,hometown: freezed == hometown ? _self.hometown : hometown // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,ownerStatus: freezed == ownerStatus ? _self.ownerStatus : ownerStatus // ignore: cast_nullable_to_non_nullable
as String?,signature: freezed == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String?,kycStatus: freezed == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String?,trustScore: freezed == trustScore ? _self.trustScore : trustScore // ignore: cast_nullable_to_non_nullable
as int?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,requirePasswordSetup: null == requirePasswordSetup ? _self.requirePasswordSetup : requirePasswordSetup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
