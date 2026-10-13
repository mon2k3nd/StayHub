// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'roommate_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoommateModel {

 int get id; int get contractId; int get roomId; String get fullName; String? get phoneNumber; String? get cccdNumber; String? get hometown; DateTime? get birthday; String? get gender; DateTime? get checkInDate; DateTime? get checkOutDate; bool get isActive;
/// Create a copy of RoommateModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoommateModelCopyWith<RoommateModel> get copyWith => _$RoommateModelCopyWithImpl<RoommateModel>(this as RoommateModel, _$identity);

  /// Serializes this RoommateModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoommateModel&&(identical(other.id, id) || other.id == id)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.cccdNumber, cccdNumber) || other.cccdNumber == cccdNumber)&&(identical(other.hometown, hometown) || other.hometown == hometown)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.checkInDate, checkInDate) || other.checkInDate == checkInDate)&&(identical(other.checkOutDate, checkOutDate) || other.checkOutDate == checkOutDate)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,contractId,roomId,fullName,phoneNumber,cccdNumber,hometown,birthday,gender,checkInDate,checkOutDate,isActive);

@override
String toString() {
  return 'RoommateModel(id: $id, contractId: $contractId, roomId: $roomId, fullName: $fullName, phoneNumber: $phoneNumber, cccdNumber: $cccdNumber, hometown: $hometown, birthday: $birthday, gender: $gender, checkInDate: $checkInDate, checkOutDate: $checkOutDate, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $RoommateModelCopyWith<$Res>  {
  factory $RoommateModelCopyWith(RoommateModel value, $Res Function(RoommateModel) _then) = _$RoommateModelCopyWithImpl;
@useResult
$Res call({
 int id, int contractId, int roomId, String fullName, String? phoneNumber, String? cccdNumber, String? hometown, DateTime? birthday, String? gender, DateTime? checkInDate, DateTime? checkOutDate, bool isActive
});




}
/// @nodoc
class _$RoommateModelCopyWithImpl<$Res>
    implements $RoommateModelCopyWith<$Res> {
  _$RoommateModelCopyWithImpl(this._self, this._then);

  final RoommateModel _self;
  final $Res Function(RoommateModel) _then;

/// Create a copy of RoommateModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? contractId = null,Object? roomId = null,Object? fullName = null,Object? phoneNumber = freezed,Object? cccdNumber = freezed,Object? hometown = freezed,Object? birthday = freezed,Object? gender = freezed,Object? checkInDate = freezed,Object? checkOutDate = freezed,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,cccdNumber: freezed == cccdNumber ? _self.cccdNumber : cccdNumber // ignore: cast_nullable_to_non_nullable
as String?,hometown: freezed == hometown ? _self.hometown : hometown // ignore: cast_nullable_to_non_nullable
as String?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,checkInDate: freezed == checkInDate ? _self.checkInDate : checkInDate // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOutDate: freezed == checkOutDate ? _self.checkOutDate : checkOutDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RoommateModel].
extension RoommateModelPatterns on RoommateModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoommateModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoommateModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoommateModel value)  $default,){
final _that = this;
switch (_that) {
case _RoommateModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoommateModel value)?  $default,){
final _that = this;
switch (_that) {
case _RoommateModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int contractId,  int roomId,  String fullName,  String? phoneNumber,  String? cccdNumber,  String? hometown,  DateTime? birthday,  String? gender,  DateTime? checkInDate,  DateTime? checkOutDate,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoommateModel() when $default != null:
return $default(_that.id,_that.contractId,_that.roomId,_that.fullName,_that.phoneNumber,_that.cccdNumber,_that.hometown,_that.birthday,_that.gender,_that.checkInDate,_that.checkOutDate,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int contractId,  int roomId,  String fullName,  String? phoneNumber,  String? cccdNumber,  String? hometown,  DateTime? birthday,  String? gender,  DateTime? checkInDate,  DateTime? checkOutDate,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _RoommateModel():
return $default(_that.id,_that.contractId,_that.roomId,_that.fullName,_that.phoneNumber,_that.cccdNumber,_that.hometown,_that.birthday,_that.gender,_that.checkInDate,_that.checkOutDate,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int contractId,  int roomId,  String fullName,  String? phoneNumber,  String? cccdNumber,  String? hometown,  DateTime? birthday,  String? gender,  DateTime? checkInDate,  DateTime? checkOutDate,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _RoommateModel() when $default != null:
return $default(_that.id,_that.contractId,_that.roomId,_that.fullName,_that.phoneNumber,_that.cccdNumber,_that.hometown,_that.birthday,_that.gender,_that.checkInDate,_that.checkOutDate,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoommateModel implements RoommateModel {
  const _RoommateModel({required this.id, required this.contractId, required this.roomId, required this.fullName, this.phoneNumber, this.cccdNumber, this.hometown, this.birthday, this.gender, this.checkInDate, this.checkOutDate, this.isActive = true});
  factory _RoommateModel.fromJson(Map<String, dynamic> json) => _$RoommateModelFromJson(json);

@override final  int id;
@override final  int contractId;
@override final  int roomId;
@override final  String fullName;
@override final  String? phoneNumber;
@override final  String? cccdNumber;
@override final  String? hometown;
@override final  DateTime? birthday;
@override final  String? gender;
@override final  DateTime? checkInDate;
@override final  DateTime? checkOutDate;
@override@JsonKey() final  bool isActive;

/// Create a copy of RoommateModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoommateModelCopyWith<_RoommateModel> get copyWith => __$RoommateModelCopyWithImpl<_RoommateModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoommateModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoommateModel&&(identical(other.id, id) || other.id == id)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.cccdNumber, cccdNumber) || other.cccdNumber == cccdNumber)&&(identical(other.hometown, hometown) || other.hometown == hometown)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.checkInDate, checkInDate) || other.checkInDate == checkInDate)&&(identical(other.checkOutDate, checkOutDate) || other.checkOutDate == checkOutDate)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,contractId,roomId,fullName,phoneNumber,cccdNumber,hometown,birthday,gender,checkInDate,checkOutDate,isActive);

@override
String toString() {
  return 'RoommateModel(id: $id, contractId: $contractId, roomId: $roomId, fullName: $fullName, phoneNumber: $phoneNumber, cccdNumber: $cccdNumber, hometown: $hometown, birthday: $birthday, gender: $gender, checkInDate: $checkInDate, checkOutDate: $checkOutDate, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$RoommateModelCopyWith<$Res> implements $RoommateModelCopyWith<$Res> {
  factory _$RoommateModelCopyWith(_RoommateModel value, $Res Function(_RoommateModel) _then) = __$RoommateModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int contractId, int roomId, String fullName, String? phoneNumber, String? cccdNumber, String? hometown, DateTime? birthday, String? gender, DateTime? checkInDate, DateTime? checkOutDate, bool isActive
});




}
/// @nodoc
class __$RoommateModelCopyWithImpl<$Res>
    implements _$RoommateModelCopyWith<$Res> {
  __$RoommateModelCopyWithImpl(this._self, this._then);

  final _RoommateModel _self;
  final $Res Function(_RoommateModel) _then;

/// Create a copy of RoommateModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? contractId = null,Object? roomId = null,Object? fullName = null,Object? phoneNumber = freezed,Object? cccdNumber = freezed,Object? hometown = freezed,Object? birthday = freezed,Object? gender = freezed,Object? checkInDate = freezed,Object? checkOutDate = freezed,Object? isActive = null,}) {
  return _then(_RoommateModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,cccdNumber: freezed == cccdNumber ? _self.cccdNumber : cccdNumber // ignore: cast_nullable_to_non_nullable
as String?,hometown: freezed == hometown ? _self.hometown : hometown // ignore: cast_nullable_to_non_nullable
as String?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,checkInDate: freezed == checkInDate ? _self.checkInDate : checkInDate // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOutDate: freezed == checkOutDate ? _self.checkOutDate : checkOutDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
