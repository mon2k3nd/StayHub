// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meter_reading_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeterReadingModel {

 int get roomId; String get roomName; int? get currentTenantId; int? get currentContractId; double get electricPrevious; double get waterPrevious; double? get electricCurrent; double? get waterCurrent; int? get currentMonthBillId; int get month; int get year;
/// Create a copy of MeterReadingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeterReadingModelCopyWith<MeterReadingModel> get copyWith => _$MeterReadingModelCopyWithImpl<MeterReadingModel>(this as MeterReadingModel, _$identity);

  /// Serializes this MeterReadingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeterReadingModel&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.currentTenantId, currentTenantId) || other.currentTenantId == currentTenantId)&&(identical(other.currentContractId, currentContractId) || other.currentContractId == currentContractId)&&(identical(other.electricPrevious, electricPrevious) || other.electricPrevious == electricPrevious)&&(identical(other.waterPrevious, waterPrevious) || other.waterPrevious == waterPrevious)&&(identical(other.electricCurrent, electricCurrent) || other.electricCurrent == electricCurrent)&&(identical(other.waterCurrent, waterCurrent) || other.waterCurrent == waterCurrent)&&(identical(other.currentMonthBillId, currentMonthBillId) || other.currentMonthBillId == currentMonthBillId)&&(identical(other.month, month) || other.month == month)&&(identical(other.year, year) || other.year == year));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,roomName,currentTenantId,currentContractId,electricPrevious,waterPrevious,electricCurrent,waterCurrent,currentMonthBillId,month,year);

@override
String toString() {
  return 'MeterReadingModel(roomId: $roomId, roomName: $roomName, currentTenantId: $currentTenantId, currentContractId: $currentContractId, electricPrevious: $electricPrevious, waterPrevious: $waterPrevious, electricCurrent: $electricCurrent, waterCurrent: $waterCurrent, currentMonthBillId: $currentMonthBillId, month: $month, year: $year)';
}


}

/// @nodoc
abstract mixin class $MeterReadingModelCopyWith<$Res>  {
  factory $MeterReadingModelCopyWith(MeterReadingModel value, $Res Function(MeterReadingModel) _then) = _$MeterReadingModelCopyWithImpl;
@useResult
$Res call({
 int roomId, String roomName, int? currentTenantId, int? currentContractId, double electricPrevious, double waterPrevious, double? electricCurrent, double? waterCurrent, int? currentMonthBillId, int month, int year
});




}
/// @nodoc
class _$MeterReadingModelCopyWithImpl<$Res>
    implements $MeterReadingModelCopyWith<$Res> {
  _$MeterReadingModelCopyWithImpl(this._self, this._then);

  final MeterReadingModel _self;
  final $Res Function(MeterReadingModel) _then;

/// Create a copy of MeterReadingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? roomName = null,Object? currentTenantId = freezed,Object? currentContractId = freezed,Object? electricPrevious = null,Object? waterPrevious = null,Object? electricCurrent = freezed,Object? waterCurrent = freezed,Object? currentMonthBillId = freezed,Object? month = null,Object? year = null,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,currentTenantId: freezed == currentTenantId ? _self.currentTenantId : currentTenantId // ignore: cast_nullable_to_non_nullable
as int?,currentContractId: freezed == currentContractId ? _self.currentContractId : currentContractId // ignore: cast_nullable_to_non_nullable
as int?,electricPrevious: null == electricPrevious ? _self.electricPrevious : electricPrevious // ignore: cast_nullable_to_non_nullable
as double,waterPrevious: null == waterPrevious ? _self.waterPrevious : waterPrevious // ignore: cast_nullable_to_non_nullable
as double,electricCurrent: freezed == electricCurrent ? _self.electricCurrent : electricCurrent // ignore: cast_nullable_to_non_nullable
as double?,waterCurrent: freezed == waterCurrent ? _self.waterCurrent : waterCurrent // ignore: cast_nullable_to_non_nullable
as double?,currentMonthBillId: freezed == currentMonthBillId ? _self.currentMonthBillId : currentMonthBillId // ignore: cast_nullable_to_non_nullable
as int?,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MeterReadingModel].
extension MeterReadingModelPatterns on MeterReadingModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeterReadingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeterReadingModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeterReadingModel value)  $default,){
final _that = this;
switch (_that) {
case _MeterReadingModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeterReadingModel value)?  $default,){
final _that = this;
switch (_that) {
case _MeterReadingModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int roomId,  String roomName,  int? currentTenantId,  int? currentContractId,  double electricPrevious,  double waterPrevious,  double? electricCurrent,  double? waterCurrent,  int? currentMonthBillId,  int month,  int year)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeterReadingModel() when $default != null:
return $default(_that.roomId,_that.roomName,_that.currentTenantId,_that.currentContractId,_that.electricPrevious,_that.waterPrevious,_that.electricCurrent,_that.waterCurrent,_that.currentMonthBillId,_that.month,_that.year);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int roomId,  String roomName,  int? currentTenantId,  int? currentContractId,  double electricPrevious,  double waterPrevious,  double? electricCurrent,  double? waterCurrent,  int? currentMonthBillId,  int month,  int year)  $default,) {final _that = this;
switch (_that) {
case _MeterReadingModel():
return $default(_that.roomId,_that.roomName,_that.currentTenantId,_that.currentContractId,_that.electricPrevious,_that.waterPrevious,_that.electricCurrent,_that.waterCurrent,_that.currentMonthBillId,_that.month,_that.year);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int roomId,  String roomName,  int? currentTenantId,  int? currentContractId,  double electricPrevious,  double waterPrevious,  double? electricCurrent,  double? waterCurrent,  int? currentMonthBillId,  int month,  int year)?  $default,) {final _that = this;
switch (_that) {
case _MeterReadingModel() when $default != null:
return $default(_that.roomId,_that.roomName,_that.currentTenantId,_that.currentContractId,_that.electricPrevious,_that.waterPrevious,_that.electricCurrent,_that.waterCurrent,_that.currentMonthBillId,_that.month,_that.year);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeterReadingModel implements MeterReadingModel {
  const _MeterReadingModel({required this.roomId, required this.roomName, this.currentTenantId, this.currentContractId, this.electricPrevious = 0.0, this.waterPrevious = 0.0, this.electricCurrent, this.waterCurrent, this.currentMonthBillId, required this.month, required this.year});
  factory _MeterReadingModel.fromJson(Map<String, dynamic> json) => _$MeterReadingModelFromJson(json);

@override final  int roomId;
@override final  String roomName;
@override final  int? currentTenantId;
@override final  int? currentContractId;
@override@JsonKey() final  double electricPrevious;
@override@JsonKey() final  double waterPrevious;
@override final  double? electricCurrent;
@override final  double? waterCurrent;
@override final  int? currentMonthBillId;
@override final  int month;
@override final  int year;

/// Create a copy of MeterReadingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeterReadingModelCopyWith<_MeterReadingModel> get copyWith => __$MeterReadingModelCopyWithImpl<_MeterReadingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeterReadingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeterReadingModel&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.currentTenantId, currentTenantId) || other.currentTenantId == currentTenantId)&&(identical(other.currentContractId, currentContractId) || other.currentContractId == currentContractId)&&(identical(other.electricPrevious, electricPrevious) || other.electricPrevious == electricPrevious)&&(identical(other.waterPrevious, waterPrevious) || other.waterPrevious == waterPrevious)&&(identical(other.electricCurrent, electricCurrent) || other.electricCurrent == electricCurrent)&&(identical(other.waterCurrent, waterCurrent) || other.waterCurrent == waterCurrent)&&(identical(other.currentMonthBillId, currentMonthBillId) || other.currentMonthBillId == currentMonthBillId)&&(identical(other.month, month) || other.month == month)&&(identical(other.year, year) || other.year == year));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,roomName,currentTenantId,currentContractId,electricPrevious,waterPrevious,electricCurrent,waterCurrent,currentMonthBillId,month,year);

@override
String toString() {
  return 'MeterReadingModel(roomId: $roomId, roomName: $roomName, currentTenantId: $currentTenantId, currentContractId: $currentContractId, electricPrevious: $electricPrevious, waterPrevious: $waterPrevious, electricCurrent: $electricCurrent, waterCurrent: $waterCurrent, currentMonthBillId: $currentMonthBillId, month: $month, year: $year)';
}


}

/// @nodoc
abstract mixin class _$MeterReadingModelCopyWith<$Res> implements $MeterReadingModelCopyWith<$Res> {
  factory _$MeterReadingModelCopyWith(_MeterReadingModel value, $Res Function(_MeterReadingModel) _then) = __$MeterReadingModelCopyWithImpl;
@override @useResult
$Res call({
 int roomId, String roomName, int? currentTenantId, int? currentContractId, double electricPrevious, double waterPrevious, double? electricCurrent, double? waterCurrent, int? currentMonthBillId, int month, int year
});




}
/// @nodoc
class __$MeterReadingModelCopyWithImpl<$Res>
    implements _$MeterReadingModelCopyWith<$Res> {
  __$MeterReadingModelCopyWithImpl(this._self, this._then);

  final _MeterReadingModel _self;
  final $Res Function(_MeterReadingModel) _then;

/// Create a copy of MeterReadingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? roomName = null,Object? currentTenantId = freezed,Object? currentContractId = freezed,Object? electricPrevious = null,Object? waterPrevious = null,Object? electricCurrent = freezed,Object? waterCurrent = freezed,Object? currentMonthBillId = freezed,Object? month = null,Object? year = null,}) {
  return _then(_MeterReadingModel(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,currentTenantId: freezed == currentTenantId ? _self.currentTenantId : currentTenantId // ignore: cast_nullable_to_non_nullable
as int?,currentContractId: freezed == currentContractId ? _self.currentContractId : currentContractId // ignore: cast_nullable_to_non_nullable
as int?,electricPrevious: null == electricPrevious ? _self.electricPrevious : electricPrevious // ignore: cast_nullable_to_non_nullable
as double,waterPrevious: null == waterPrevious ? _self.waterPrevious : waterPrevious // ignore: cast_nullable_to_non_nullable
as double,electricCurrent: freezed == electricCurrent ? _self.electricCurrent : electricCurrent // ignore: cast_nullable_to_non_nullable
as double?,waterCurrent: freezed == waterCurrent ? _self.waterCurrent : waterCurrent // ignore: cast_nullable_to_non_nullable
as double?,currentMonthBillId: freezed == currentMonthBillId ? _self.currentMonthBillId : currentMonthBillId // ignore: cast_nullable_to_non_nullable
as int?,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
