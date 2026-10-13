// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signature_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SignatureHistoryModel {

 int get id; int get userId; String get signature; String get createdAt;
/// Create a copy of SignatureHistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignatureHistoryModelCopyWith<SignatureHistoryModel> get copyWith => _$SignatureHistoryModelCopyWithImpl<SignatureHistoryModel>(this as SignatureHistoryModel, _$identity);

  /// Serializes this SignatureHistoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignatureHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,signature,createdAt);

@override
String toString() {
  return 'SignatureHistoryModel(id: $id, userId: $userId, signature: $signature, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SignatureHistoryModelCopyWith<$Res>  {
  factory $SignatureHistoryModelCopyWith(SignatureHistoryModel value, $Res Function(SignatureHistoryModel) _then) = _$SignatureHistoryModelCopyWithImpl;
@useResult
$Res call({
 int id, int userId, String signature, String createdAt
});




}
/// @nodoc
class _$SignatureHistoryModelCopyWithImpl<$Res>
    implements $SignatureHistoryModelCopyWith<$Res> {
  _$SignatureHistoryModelCopyWithImpl(this._self, this._then);

  final SignatureHistoryModel _self;
  final $Res Function(SignatureHistoryModel) _then;

/// Create a copy of SignatureHistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? signature = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SignatureHistoryModel].
extension SignatureHistoryModelPatterns on SignatureHistoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignatureHistoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignatureHistoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignatureHistoryModel value)  $default,){
final _that = this;
switch (_that) {
case _SignatureHistoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignatureHistoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _SignatureHistoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int userId,  String signature,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignatureHistoryModel() when $default != null:
return $default(_that.id,_that.userId,_that.signature,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int userId,  String signature,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _SignatureHistoryModel():
return $default(_that.id,_that.userId,_that.signature,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int userId,  String signature,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SignatureHistoryModel() when $default != null:
return $default(_that.id,_that.userId,_that.signature,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SignatureHistoryModel implements SignatureHistoryModel {
  const _SignatureHistoryModel({required this.id, required this.userId, required this.signature, required this.createdAt});
  factory _SignatureHistoryModel.fromJson(Map<String, dynamic> json) => _$SignatureHistoryModelFromJson(json);

@override final  int id;
@override final  int userId;
@override final  String signature;
@override final  String createdAt;

/// Create a copy of SignatureHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignatureHistoryModelCopyWith<_SignatureHistoryModel> get copyWith => __$SignatureHistoryModelCopyWithImpl<_SignatureHistoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignatureHistoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignatureHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,signature,createdAt);

@override
String toString() {
  return 'SignatureHistoryModel(id: $id, userId: $userId, signature: $signature, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SignatureHistoryModelCopyWith<$Res> implements $SignatureHistoryModelCopyWith<$Res> {
  factory _$SignatureHistoryModelCopyWith(_SignatureHistoryModel value, $Res Function(_SignatureHistoryModel) _then) = __$SignatureHistoryModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int userId, String signature, String createdAt
});




}
/// @nodoc
class __$SignatureHistoryModelCopyWithImpl<$Res>
    implements _$SignatureHistoryModelCopyWith<$Res> {
  __$SignatureHistoryModelCopyWithImpl(this._self, this._then);

  final _SignatureHistoryModel _self;
  final $Res Function(_SignatureHistoryModel) _then;

/// Create a copy of SignatureHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? signature = null,Object? createdAt = null,}) {
  return _then(_SignatureHistoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
