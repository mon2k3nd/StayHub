// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'electronic_contract_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ElectronicContractState implements DiagnosticableTreeMixin {

 bool get isLoading; String get error; bool get isTenantSigned; bool get isOwnerSigned; bool get isSignatureSuccess; int get countdownSeconds;
/// Create a copy of ElectronicContractState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ElectronicContractStateCopyWith<ElectronicContractState> get copyWith => _$ElectronicContractStateCopyWithImpl<ElectronicContractState>(this as ElectronicContractState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ElectronicContractState'))
    ..add(DiagnosticsProperty('isLoading', isLoading))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('isTenantSigned', isTenantSigned))..add(DiagnosticsProperty('isOwnerSigned', isOwnerSigned))..add(DiagnosticsProperty('isSignatureSuccess', isSignatureSuccess))..add(DiagnosticsProperty('countdownSeconds', countdownSeconds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ElectronicContractState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.isTenantSigned, isTenantSigned) || other.isTenantSigned == isTenantSigned)&&(identical(other.isOwnerSigned, isOwnerSigned) || other.isOwnerSigned == isOwnerSigned)&&(identical(other.isSignatureSuccess, isSignatureSuccess) || other.isSignatureSuccess == isSignatureSuccess)&&(identical(other.countdownSeconds, countdownSeconds) || other.countdownSeconds == countdownSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,error,isTenantSigned,isOwnerSigned,isSignatureSuccess,countdownSeconds);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ElectronicContractState(isLoading: $isLoading, error: $error, isTenantSigned: $isTenantSigned, isOwnerSigned: $isOwnerSigned, isSignatureSuccess: $isSignatureSuccess, countdownSeconds: $countdownSeconds)';
}


}

/// @nodoc
abstract mixin class $ElectronicContractStateCopyWith<$Res>  {
  factory $ElectronicContractStateCopyWith(ElectronicContractState value, $Res Function(ElectronicContractState) _then) = _$ElectronicContractStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String error, bool isTenantSigned, bool isOwnerSigned, bool isSignatureSuccess, int countdownSeconds
});




}
/// @nodoc
class _$ElectronicContractStateCopyWithImpl<$Res>
    implements $ElectronicContractStateCopyWith<$Res> {
  _$ElectronicContractStateCopyWithImpl(this._self, this._then);

  final ElectronicContractState _self;
  final $Res Function(ElectronicContractState) _then;

/// Create a copy of ElectronicContractState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? error = null,Object? isTenantSigned = null,Object? isOwnerSigned = null,Object? isSignatureSuccess = null,Object? countdownSeconds = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,isTenantSigned: null == isTenantSigned ? _self.isTenantSigned : isTenantSigned // ignore: cast_nullable_to_non_nullable
as bool,isOwnerSigned: null == isOwnerSigned ? _self.isOwnerSigned : isOwnerSigned // ignore: cast_nullable_to_non_nullable
as bool,isSignatureSuccess: null == isSignatureSuccess ? _self.isSignatureSuccess : isSignatureSuccess // ignore: cast_nullable_to_non_nullable
as bool,countdownSeconds: null == countdownSeconds ? _self.countdownSeconds : countdownSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ElectronicContractState].
extension ElectronicContractStatePatterns on ElectronicContractState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ElectronicContractState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ElectronicContractState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ElectronicContractState value)  $default,){
final _that = this;
switch (_that) {
case _ElectronicContractState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ElectronicContractState value)?  $default,){
final _that = this;
switch (_that) {
case _ElectronicContractState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String error,  bool isTenantSigned,  bool isOwnerSigned,  bool isSignatureSuccess,  int countdownSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ElectronicContractState() when $default != null:
return $default(_that.isLoading,_that.error,_that.isTenantSigned,_that.isOwnerSigned,_that.isSignatureSuccess,_that.countdownSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String error,  bool isTenantSigned,  bool isOwnerSigned,  bool isSignatureSuccess,  int countdownSeconds)  $default,) {final _that = this;
switch (_that) {
case _ElectronicContractState():
return $default(_that.isLoading,_that.error,_that.isTenantSigned,_that.isOwnerSigned,_that.isSignatureSuccess,_that.countdownSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String error,  bool isTenantSigned,  bool isOwnerSigned,  bool isSignatureSuccess,  int countdownSeconds)?  $default,) {final _that = this;
switch (_that) {
case _ElectronicContractState() when $default != null:
return $default(_that.isLoading,_that.error,_that.isTenantSigned,_that.isOwnerSigned,_that.isSignatureSuccess,_that.countdownSeconds);case _:
  return null;

}
}

}

/// @nodoc


class _ElectronicContractState with DiagnosticableTreeMixin implements ElectronicContractState {
  const _ElectronicContractState({this.isLoading = false, this.error = '', this.isTenantSigned = false, this.isOwnerSigned = false, this.isSignatureSuccess = false, this.countdownSeconds = 60});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  String error;
@override@JsonKey() final  bool isTenantSigned;
@override@JsonKey() final  bool isOwnerSigned;
@override@JsonKey() final  bool isSignatureSuccess;
@override@JsonKey() final  int countdownSeconds;

/// Create a copy of ElectronicContractState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ElectronicContractStateCopyWith<_ElectronicContractState> get copyWith => __$ElectronicContractStateCopyWithImpl<_ElectronicContractState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ElectronicContractState'))
    ..add(DiagnosticsProperty('isLoading', isLoading))..add(DiagnosticsProperty('error', error))..add(DiagnosticsProperty('isTenantSigned', isTenantSigned))..add(DiagnosticsProperty('isOwnerSigned', isOwnerSigned))..add(DiagnosticsProperty('isSignatureSuccess', isSignatureSuccess))..add(DiagnosticsProperty('countdownSeconds', countdownSeconds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ElectronicContractState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.isTenantSigned, isTenantSigned) || other.isTenantSigned == isTenantSigned)&&(identical(other.isOwnerSigned, isOwnerSigned) || other.isOwnerSigned == isOwnerSigned)&&(identical(other.isSignatureSuccess, isSignatureSuccess) || other.isSignatureSuccess == isSignatureSuccess)&&(identical(other.countdownSeconds, countdownSeconds) || other.countdownSeconds == countdownSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,error,isTenantSigned,isOwnerSigned,isSignatureSuccess,countdownSeconds);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ElectronicContractState(isLoading: $isLoading, error: $error, isTenantSigned: $isTenantSigned, isOwnerSigned: $isOwnerSigned, isSignatureSuccess: $isSignatureSuccess, countdownSeconds: $countdownSeconds)';
}


}

/// @nodoc
abstract mixin class _$ElectronicContractStateCopyWith<$Res> implements $ElectronicContractStateCopyWith<$Res> {
  factory _$ElectronicContractStateCopyWith(_ElectronicContractState value, $Res Function(_ElectronicContractState) _then) = __$ElectronicContractStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String error, bool isTenantSigned, bool isOwnerSigned, bool isSignatureSuccess, int countdownSeconds
});




}
/// @nodoc
class __$ElectronicContractStateCopyWithImpl<$Res>
    implements _$ElectronicContractStateCopyWith<$Res> {
  __$ElectronicContractStateCopyWithImpl(this._self, this._then);

  final _ElectronicContractState _self;
  final $Res Function(_ElectronicContractState) _then;

/// Create a copy of ElectronicContractState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? error = null,Object? isTenantSigned = null,Object? isOwnerSigned = null,Object? isSignatureSuccess = null,Object? countdownSeconds = null,}) {
  return _then(_ElectronicContractState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,isTenantSigned: null == isTenantSigned ? _self.isTenantSigned : isTenantSigned // ignore: cast_nullable_to_non_nullable
as bool,isOwnerSigned: null == isOwnerSigned ? _self.isOwnerSigned : isOwnerSigned // ignore: cast_nullable_to_non_nullable
as bool,isSignatureSuccess: null == isSignatureSuccess ? _self.isSignatureSuccess : isSignatureSuccess // ignore: cast_nullable_to_non_nullable
as bool,countdownSeconds: null == countdownSeconds ? _self.countdownSeconds : countdownSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
