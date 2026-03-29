// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Command {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Command()';
}


}

/// @nodoc
class $CommandCopyWith<$Res>  {
$CommandCopyWith(Command _, $Res Function(Command) __);
}


/// Adds pattern-matching-related methods to [Command].
extension CommandPatterns on Command {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Command_SetTargetSpeed value)?  setTargetSpeed,TResult Function( Command_SetSpeedRange value)?  setSpeedRange,TResult Function( Command_SetAcceleration value)?  setAcceleration,TResult Function( Command_SetDeceleration value)?  setDeceleration,TResult Function( Command_SetStepFrequency value)?  setStepFrequency,TResult Function( Command_SetStrideLength value)?  setStrideLength,TResult Function( Command_Pause value)?  pause,TResult Function( Command_Resume value)?  resume,TResult Function( Command_StopImmediately value)?  stopImmediately,TResult Function( Command_StopAfterFrames value)?  stopAfterFrames,TResult Function( Command_StopAfterTime value)?  stopAfterTime,TResult Function( Command_JumpToProgress value)?  jumpToProgress,TResult Function( Command_NextTrajectory value)?  nextTrajectory,TResult Function( Command_AddCheckpoint value)?  addCheckpoint,TResult Function( Command_RemoveCheckpoint value)?  removeCheckpoint,TResult Function( Command_ClearCheckpoints value)?  clearCheckpoints,TResult Function( Command_ResetCheckpointStatus value)?  resetCheckpointStatus,TResult Function( Command_SetJitterParams value)?  setJitterParams,TResult Function( Command_SetRefreshRate value)?  setRefreshRate,TResult Function( Command_SetFenceWarningDistance value)?  setFenceWarningDistance,TResult Function( Command_SwitchTrajectory value)?  switchTrajectory,TResult Function( Command_AppendTrajectory value)?  appendTrajectory,TResult Function( Command_Custom value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Command_SetTargetSpeed() when setTargetSpeed != null:
return setTargetSpeed(_that);case Command_SetSpeedRange() when setSpeedRange != null:
return setSpeedRange(_that);case Command_SetAcceleration() when setAcceleration != null:
return setAcceleration(_that);case Command_SetDeceleration() when setDeceleration != null:
return setDeceleration(_that);case Command_SetStepFrequency() when setStepFrequency != null:
return setStepFrequency(_that);case Command_SetStrideLength() when setStrideLength != null:
return setStrideLength(_that);case Command_Pause() when pause != null:
return pause(_that);case Command_Resume() when resume != null:
return resume(_that);case Command_StopImmediately() when stopImmediately != null:
return stopImmediately(_that);case Command_StopAfterFrames() when stopAfterFrames != null:
return stopAfterFrames(_that);case Command_StopAfterTime() when stopAfterTime != null:
return stopAfterTime(_that);case Command_JumpToProgress() when jumpToProgress != null:
return jumpToProgress(_that);case Command_NextTrajectory() when nextTrajectory != null:
return nextTrajectory(_that);case Command_AddCheckpoint() when addCheckpoint != null:
return addCheckpoint(_that);case Command_RemoveCheckpoint() when removeCheckpoint != null:
return removeCheckpoint(_that);case Command_ClearCheckpoints() when clearCheckpoints != null:
return clearCheckpoints(_that);case Command_ResetCheckpointStatus() when resetCheckpointStatus != null:
return resetCheckpointStatus(_that);case Command_SetJitterParams() when setJitterParams != null:
return setJitterParams(_that);case Command_SetRefreshRate() when setRefreshRate != null:
return setRefreshRate(_that);case Command_SetFenceWarningDistance() when setFenceWarningDistance != null:
return setFenceWarningDistance(_that);case Command_SwitchTrajectory() when switchTrajectory != null:
return switchTrajectory(_that);case Command_AppendTrajectory() when appendTrajectory != null:
return appendTrajectory(_that);case Command_Custom() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Command_SetTargetSpeed value)  setTargetSpeed,required TResult Function( Command_SetSpeedRange value)  setSpeedRange,required TResult Function( Command_SetAcceleration value)  setAcceleration,required TResult Function( Command_SetDeceleration value)  setDeceleration,required TResult Function( Command_SetStepFrequency value)  setStepFrequency,required TResult Function( Command_SetStrideLength value)  setStrideLength,required TResult Function( Command_Pause value)  pause,required TResult Function( Command_Resume value)  resume,required TResult Function( Command_StopImmediately value)  stopImmediately,required TResult Function( Command_StopAfterFrames value)  stopAfterFrames,required TResult Function( Command_StopAfterTime value)  stopAfterTime,required TResult Function( Command_JumpToProgress value)  jumpToProgress,required TResult Function( Command_NextTrajectory value)  nextTrajectory,required TResult Function( Command_AddCheckpoint value)  addCheckpoint,required TResult Function( Command_RemoveCheckpoint value)  removeCheckpoint,required TResult Function( Command_ClearCheckpoints value)  clearCheckpoints,required TResult Function( Command_ResetCheckpointStatus value)  resetCheckpointStatus,required TResult Function( Command_SetJitterParams value)  setJitterParams,required TResult Function( Command_SetRefreshRate value)  setRefreshRate,required TResult Function( Command_SetFenceWarningDistance value)  setFenceWarningDistance,required TResult Function( Command_SwitchTrajectory value)  switchTrajectory,required TResult Function( Command_AppendTrajectory value)  appendTrajectory,required TResult Function( Command_Custom value)  custom,}){
final _that = this;
switch (_that) {
case Command_SetTargetSpeed():
return setTargetSpeed(_that);case Command_SetSpeedRange():
return setSpeedRange(_that);case Command_SetAcceleration():
return setAcceleration(_that);case Command_SetDeceleration():
return setDeceleration(_that);case Command_SetStepFrequency():
return setStepFrequency(_that);case Command_SetStrideLength():
return setStrideLength(_that);case Command_Pause():
return pause(_that);case Command_Resume():
return resume(_that);case Command_StopImmediately():
return stopImmediately(_that);case Command_StopAfterFrames():
return stopAfterFrames(_that);case Command_StopAfterTime():
return stopAfterTime(_that);case Command_JumpToProgress():
return jumpToProgress(_that);case Command_NextTrajectory():
return nextTrajectory(_that);case Command_AddCheckpoint():
return addCheckpoint(_that);case Command_RemoveCheckpoint():
return removeCheckpoint(_that);case Command_ClearCheckpoints():
return clearCheckpoints(_that);case Command_ResetCheckpointStatus():
return resetCheckpointStatus(_that);case Command_SetJitterParams():
return setJitterParams(_that);case Command_SetRefreshRate():
return setRefreshRate(_that);case Command_SetFenceWarningDistance():
return setFenceWarningDistance(_that);case Command_SwitchTrajectory():
return switchTrajectory(_that);case Command_AppendTrajectory():
return appendTrajectory(_that);case Command_Custom():
return custom(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Command_SetTargetSpeed value)?  setTargetSpeed,TResult? Function( Command_SetSpeedRange value)?  setSpeedRange,TResult? Function( Command_SetAcceleration value)?  setAcceleration,TResult? Function( Command_SetDeceleration value)?  setDeceleration,TResult? Function( Command_SetStepFrequency value)?  setStepFrequency,TResult? Function( Command_SetStrideLength value)?  setStrideLength,TResult? Function( Command_Pause value)?  pause,TResult? Function( Command_Resume value)?  resume,TResult? Function( Command_StopImmediately value)?  stopImmediately,TResult? Function( Command_StopAfterFrames value)?  stopAfterFrames,TResult? Function( Command_StopAfterTime value)?  stopAfterTime,TResult? Function( Command_JumpToProgress value)?  jumpToProgress,TResult? Function( Command_NextTrajectory value)?  nextTrajectory,TResult? Function( Command_AddCheckpoint value)?  addCheckpoint,TResult? Function( Command_RemoveCheckpoint value)?  removeCheckpoint,TResult? Function( Command_ClearCheckpoints value)?  clearCheckpoints,TResult? Function( Command_ResetCheckpointStatus value)?  resetCheckpointStatus,TResult? Function( Command_SetJitterParams value)?  setJitterParams,TResult? Function( Command_SetRefreshRate value)?  setRefreshRate,TResult? Function( Command_SetFenceWarningDistance value)?  setFenceWarningDistance,TResult? Function( Command_SwitchTrajectory value)?  switchTrajectory,TResult? Function( Command_AppendTrajectory value)?  appendTrajectory,TResult? Function( Command_Custom value)?  custom,}){
final _that = this;
switch (_that) {
case Command_SetTargetSpeed() when setTargetSpeed != null:
return setTargetSpeed(_that);case Command_SetSpeedRange() when setSpeedRange != null:
return setSpeedRange(_that);case Command_SetAcceleration() when setAcceleration != null:
return setAcceleration(_that);case Command_SetDeceleration() when setDeceleration != null:
return setDeceleration(_that);case Command_SetStepFrequency() when setStepFrequency != null:
return setStepFrequency(_that);case Command_SetStrideLength() when setStrideLength != null:
return setStrideLength(_that);case Command_Pause() when pause != null:
return pause(_that);case Command_Resume() when resume != null:
return resume(_that);case Command_StopImmediately() when stopImmediately != null:
return stopImmediately(_that);case Command_StopAfterFrames() when stopAfterFrames != null:
return stopAfterFrames(_that);case Command_StopAfterTime() when stopAfterTime != null:
return stopAfterTime(_that);case Command_JumpToProgress() when jumpToProgress != null:
return jumpToProgress(_that);case Command_NextTrajectory() when nextTrajectory != null:
return nextTrajectory(_that);case Command_AddCheckpoint() when addCheckpoint != null:
return addCheckpoint(_that);case Command_RemoveCheckpoint() when removeCheckpoint != null:
return removeCheckpoint(_that);case Command_ClearCheckpoints() when clearCheckpoints != null:
return clearCheckpoints(_that);case Command_ResetCheckpointStatus() when resetCheckpointStatus != null:
return resetCheckpointStatus(_that);case Command_SetJitterParams() when setJitterParams != null:
return setJitterParams(_that);case Command_SetRefreshRate() when setRefreshRate != null:
return setRefreshRate(_that);case Command_SetFenceWarningDistance() when setFenceWarningDistance != null:
return setFenceWarningDistance(_that);case Command_SwitchTrajectory() when switchTrajectory != null:
return switchTrajectory(_that);case Command_AppendTrajectory() when appendTrajectory != null:
return appendTrajectory(_that);case Command_Custom() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double field0)?  setTargetSpeed,TResult Function( double min,  double max)?  setSpeedRange,TResult Function( double field0)?  setAcceleration,TResult Function( double field0)?  setDeceleration,TResult Function( double field0)?  setStepFrequency,TResult Function( double field0)?  setStrideLength,TResult Function()?  pause,TResult Function()?  resume,TResult Function()?  stopImmediately,TResult Function( int frames,  bool graceful)?  stopAfterFrames,TResult Function( double seconds,  bool graceful)?  stopAfterTime,TResult Function( double field0)?  jumpToProgress,TResult Function()?  nextTrajectory,TResult Function( Checkpoint field0)?  addCheckpoint,TResult Function( String field0)?  removeCheckpoint,TResult Function()?  clearCheckpoints,TResult Function()?  resetCheckpointStatus,TResult Function( double? positionAmplitude,  double? speedAmplitude,  double? bearingAmplitude)?  setJitterParams,TResult Function( double? gps,  double? accelerometer,  double? gyroscope,  double? compass,  double? barometer)?  setRefreshRate,TResult Function( double field0)?  setFenceWarningDistance,TResult Function( BigInt index,  bool seamless)?  switchTrajectory,TResult Function( Trajectory field0)?  appendTrajectory,TResult Function( String field0)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Command_SetTargetSpeed() when setTargetSpeed != null:
return setTargetSpeed(_that.field0);case Command_SetSpeedRange() when setSpeedRange != null:
return setSpeedRange(_that.min,_that.max);case Command_SetAcceleration() when setAcceleration != null:
return setAcceleration(_that.field0);case Command_SetDeceleration() when setDeceleration != null:
return setDeceleration(_that.field0);case Command_SetStepFrequency() when setStepFrequency != null:
return setStepFrequency(_that.field0);case Command_SetStrideLength() when setStrideLength != null:
return setStrideLength(_that.field0);case Command_Pause() when pause != null:
return pause();case Command_Resume() when resume != null:
return resume();case Command_StopImmediately() when stopImmediately != null:
return stopImmediately();case Command_StopAfterFrames() when stopAfterFrames != null:
return stopAfterFrames(_that.frames,_that.graceful);case Command_StopAfterTime() when stopAfterTime != null:
return stopAfterTime(_that.seconds,_that.graceful);case Command_JumpToProgress() when jumpToProgress != null:
return jumpToProgress(_that.field0);case Command_NextTrajectory() when nextTrajectory != null:
return nextTrajectory();case Command_AddCheckpoint() when addCheckpoint != null:
return addCheckpoint(_that.field0);case Command_RemoveCheckpoint() when removeCheckpoint != null:
return removeCheckpoint(_that.field0);case Command_ClearCheckpoints() when clearCheckpoints != null:
return clearCheckpoints();case Command_ResetCheckpointStatus() when resetCheckpointStatus != null:
return resetCheckpointStatus();case Command_SetJitterParams() when setJitterParams != null:
return setJitterParams(_that.positionAmplitude,_that.speedAmplitude,_that.bearingAmplitude);case Command_SetRefreshRate() when setRefreshRate != null:
return setRefreshRate(_that.gps,_that.accelerometer,_that.gyroscope,_that.compass,_that.barometer);case Command_SetFenceWarningDistance() when setFenceWarningDistance != null:
return setFenceWarningDistance(_that.field0);case Command_SwitchTrajectory() when switchTrajectory != null:
return switchTrajectory(_that.index,_that.seamless);case Command_AppendTrajectory() when appendTrajectory != null:
return appendTrajectory(_that.field0);case Command_Custom() when custom != null:
return custom(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double field0)  setTargetSpeed,required TResult Function( double min,  double max)  setSpeedRange,required TResult Function( double field0)  setAcceleration,required TResult Function( double field0)  setDeceleration,required TResult Function( double field0)  setStepFrequency,required TResult Function( double field0)  setStrideLength,required TResult Function()  pause,required TResult Function()  resume,required TResult Function()  stopImmediately,required TResult Function( int frames,  bool graceful)  stopAfterFrames,required TResult Function( double seconds,  bool graceful)  stopAfterTime,required TResult Function( double field0)  jumpToProgress,required TResult Function()  nextTrajectory,required TResult Function( Checkpoint field0)  addCheckpoint,required TResult Function( String field0)  removeCheckpoint,required TResult Function()  clearCheckpoints,required TResult Function()  resetCheckpointStatus,required TResult Function( double? positionAmplitude,  double? speedAmplitude,  double? bearingAmplitude)  setJitterParams,required TResult Function( double? gps,  double? accelerometer,  double? gyroscope,  double? compass,  double? barometer)  setRefreshRate,required TResult Function( double field0)  setFenceWarningDistance,required TResult Function( BigInt index,  bool seamless)  switchTrajectory,required TResult Function( Trajectory field0)  appendTrajectory,required TResult Function( String field0)  custom,}) {final _that = this;
switch (_that) {
case Command_SetTargetSpeed():
return setTargetSpeed(_that.field0);case Command_SetSpeedRange():
return setSpeedRange(_that.min,_that.max);case Command_SetAcceleration():
return setAcceleration(_that.field0);case Command_SetDeceleration():
return setDeceleration(_that.field0);case Command_SetStepFrequency():
return setStepFrequency(_that.field0);case Command_SetStrideLength():
return setStrideLength(_that.field0);case Command_Pause():
return pause();case Command_Resume():
return resume();case Command_StopImmediately():
return stopImmediately();case Command_StopAfterFrames():
return stopAfterFrames(_that.frames,_that.graceful);case Command_StopAfterTime():
return stopAfterTime(_that.seconds,_that.graceful);case Command_JumpToProgress():
return jumpToProgress(_that.field0);case Command_NextTrajectory():
return nextTrajectory();case Command_AddCheckpoint():
return addCheckpoint(_that.field0);case Command_RemoveCheckpoint():
return removeCheckpoint(_that.field0);case Command_ClearCheckpoints():
return clearCheckpoints();case Command_ResetCheckpointStatus():
return resetCheckpointStatus();case Command_SetJitterParams():
return setJitterParams(_that.positionAmplitude,_that.speedAmplitude,_that.bearingAmplitude);case Command_SetRefreshRate():
return setRefreshRate(_that.gps,_that.accelerometer,_that.gyroscope,_that.compass,_that.barometer);case Command_SetFenceWarningDistance():
return setFenceWarningDistance(_that.field0);case Command_SwitchTrajectory():
return switchTrajectory(_that.index,_that.seamless);case Command_AppendTrajectory():
return appendTrajectory(_that.field0);case Command_Custom():
return custom(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double field0)?  setTargetSpeed,TResult? Function( double min,  double max)?  setSpeedRange,TResult? Function( double field0)?  setAcceleration,TResult? Function( double field0)?  setDeceleration,TResult? Function( double field0)?  setStepFrequency,TResult? Function( double field0)?  setStrideLength,TResult? Function()?  pause,TResult? Function()?  resume,TResult? Function()?  stopImmediately,TResult? Function( int frames,  bool graceful)?  stopAfterFrames,TResult? Function( double seconds,  bool graceful)?  stopAfterTime,TResult? Function( double field0)?  jumpToProgress,TResult? Function()?  nextTrajectory,TResult? Function( Checkpoint field0)?  addCheckpoint,TResult? Function( String field0)?  removeCheckpoint,TResult? Function()?  clearCheckpoints,TResult? Function()?  resetCheckpointStatus,TResult? Function( double? positionAmplitude,  double? speedAmplitude,  double? bearingAmplitude)?  setJitterParams,TResult? Function( double? gps,  double? accelerometer,  double? gyroscope,  double? compass,  double? barometer)?  setRefreshRate,TResult? Function( double field0)?  setFenceWarningDistance,TResult? Function( BigInt index,  bool seamless)?  switchTrajectory,TResult? Function( Trajectory field0)?  appendTrajectory,TResult? Function( String field0)?  custom,}) {final _that = this;
switch (_that) {
case Command_SetTargetSpeed() when setTargetSpeed != null:
return setTargetSpeed(_that.field0);case Command_SetSpeedRange() when setSpeedRange != null:
return setSpeedRange(_that.min,_that.max);case Command_SetAcceleration() when setAcceleration != null:
return setAcceleration(_that.field0);case Command_SetDeceleration() when setDeceleration != null:
return setDeceleration(_that.field0);case Command_SetStepFrequency() when setStepFrequency != null:
return setStepFrequency(_that.field0);case Command_SetStrideLength() when setStrideLength != null:
return setStrideLength(_that.field0);case Command_Pause() when pause != null:
return pause();case Command_Resume() when resume != null:
return resume();case Command_StopImmediately() when stopImmediately != null:
return stopImmediately();case Command_StopAfterFrames() when stopAfterFrames != null:
return stopAfterFrames(_that.frames,_that.graceful);case Command_StopAfterTime() when stopAfterTime != null:
return stopAfterTime(_that.seconds,_that.graceful);case Command_JumpToProgress() when jumpToProgress != null:
return jumpToProgress(_that.field0);case Command_NextTrajectory() when nextTrajectory != null:
return nextTrajectory();case Command_AddCheckpoint() when addCheckpoint != null:
return addCheckpoint(_that.field0);case Command_RemoveCheckpoint() when removeCheckpoint != null:
return removeCheckpoint(_that.field0);case Command_ClearCheckpoints() when clearCheckpoints != null:
return clearCheckpoints();case Command_ResetCheckpointStatus() when resetCheckpointStatus != null:
return resetCheckpointStatus();case Command_SetJitterParams() when setJitterParams != null:
return setJitterParams(_that.positionAmplitude,_that.speedAmplitude,_that.bearingAmplitude);case Command_SetRefreshRate() when setRefreshRate != null:
return setRefreshRate(_that.gps,_that.accelerometer,_that.gyroscope,_that.compass,_that.barometer);case Command_SetFenceWarningDistance() when setFenceWarningDistance != null:
return setFenceWarningDistance(_that.field0);case Command_SwitchTrajectory() when switchTrajectory != null:
return switchTrajectory(_that.index,_that.seamless);case Command_AppendTrajectory() when appendTrajectory != null:
return appendTrajectory(_that.field0);case Command_Custom() when custom != null:
return custom(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class Command_SetTargetSpeed extends Command {
  const Command_SetTargetSpeed(this.field0): super._();
  

 final  double field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SetTargetSpeedCopyWith<Command_SetTargetSpeed> get copyWith => _$Command_SetTargetSpeedCopyWithImpl<Command_SetTargetSpeed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SetTargetSpeed&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.setTargetSpeed(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_SetTargetSpeedCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SetTargetSpeedCopyWith(Command_SetTargetSpeed value, $Res Function(Command_SetTargetSpeed) _then) = _$Command_SetTargetSpeedCopyWithImpl;
@useResult
$Res call({
 double field0
});




}
/// @nodoc
class _$Command_SetTargetSpeedCopyWithImpl<$Res>
    implements $Command_SetTargetSpeedCopyWith<$Res> {
  _$Command_SetTargetSpeedCopyWithImpl(this._self, this._then);

  final Command_SetTargetSpeed _self;
  final $Res Function(Command_SetTargetSpeed) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_SetTargetSpeed(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Command_SetSpeedRange extends Command {
  const Command_SetSpeedRange({required this.min, required this.max}): super._();
  

 final  double min;
 final  double max;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SetSpeedRangeCopyWith<Command_SetSpeedRange> get copyWith => _$Command_SetSpeedRangeCopyWithImpl<Command_SetSpeedRange>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SetSpeedRange&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max));
}


@override
int get hashCode => Object.hash(runtimeType,min,max);

@override
String toString() {
  return 'Command.setSpeedRange(min: $min, max: $max)';
}


}

/// @nodoc
abstract mixin class $Command_SetSpeedRangeCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SetSpeedRangeCopyWith(Command_SetSpeedRange value, $Res Function(Command_SetSpeedRange) _then) = _$Command_SetSpeedRangeCopyWithImpl;
@useResult
$Res call({
 double min, double max
});




}
/// @nodoc
class _$Command_SetSpeedRangeCopyWithImpl<$Res>
    implements $Command_SetSpeedRangeCopyWith<$Res> {
  _$Command_SetSpeedRangeCopyWithImpl(this._self, this._then);

  final Command_SetSpeedRange _self;
  final $Res Function(Command_SetSpeedRange) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? min = null,Object? max = null,}) {
  return _then(Command_SetSpeedRange(
min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as double,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Command_SetAcceleration extends Command {
  const Command_SetAcceleration(this.field0): super._();
  

 final  double field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SetAccelerationCopyWith<Command_SetAcceleration> get copyWith => _$Command_SetAccelerationCopyWithImpl<Command_SetAcceleration>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SetAcceleration&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.setAcceleration(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_SetAccelerationCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SetAccelerationCopyWith(Command_SetAcceleration value, $Res Function(Command_SetAcceleration) _then) = _$Command_SetAccelerationCopyWithImpl;
@useResult
$Res call({
 double field0
});




}
/// @nodoc
class _$Command_SetAccelerationCopyWithImpl<$Res>
    implements $Command_SetAccelerationCopyWith<$Res> {
  _$Command_SetAccelerationCopyWithImpl(this._self, this._then);

  final Command_SetAcceleration _self;
  final $Res Function(Command_SetAcceleration) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_SetAcceleration(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Command_SetDeceleration extends Command {
  const Command_SetDeceleration(this.field0): super._();
  

 final  double field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SetDecelerationCopyWith<Command_SetDeceleration> get copyWith => _$Command_SetDecelerationCopyWithImpl<Command_SetDeceleration>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SetDeceleration&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.setDeceleration(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_SetDecelerationCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SetDecelerationCopyWith(Command_SetDeceleration value, $Res Function(Command_SetDeceleration) _then) = _$Command_SetDecelerationCopyWithImpl;
@useResult
$Res call({
 double field0
});




}
/// @nodoc
class _$Command_SetDecelerationCopyWithImpl<$Res>
    implements $Command_SetDecelerationCopyWith<$Res> {
  _$Command_SetDecelerationCopyWithImpl(this._self, this._then);

  final Command_SetDeceleration _self;
  final $Res Function(Command_SetDeceleration) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_SetDeceleration(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Command_SetStepFrequency extends Command {
  const Command_SetStepFrequency(this.field0): super._();
  

 final  double field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SetStepFrequencyCopyWith<Command_SetStepFrequency> get copyWith => _$Command_SetStepFrequencyCopyWithImpl<Command_SetStepFrequency>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SetStepFrequency&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.setStepFrequency(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_SetStepFrequencyCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SetStepFrequencyCopyWith(Command_SetStepFrequency value, $Res Function(Command_SetStepFrequency) _then) = _$Command_SetStepFrequencyCopyWithImpl;
@useResult
$Res call({
 double field0
});




}
/// @nodoc
class _$Command_SetStepFrequencyCopyWithImpl<$Res>
    implements $Command_SetStepFrequencyCopyWith<$Res> {
  _$Command_SetStepFrequencyCopyWithImpl(this._self, this._then);

  final Command_SetStepFrequency _self;
  final $Res Function(Command_SetStepFrequency) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_SetStepFrequency(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Command_SetStrideLength extends Command {
  const Command_SetStrideLength(this.field0): super._();
  

 final  double field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SetStrideLengthCopyWith<Command_SetStrideLength> get copyWith => _$Command_SetStrideLengthCopyWithImpl<Command_SetStrideLength>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SetStrideLength&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.setStrideLength(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_SetStrideLengthCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SetStrideLengthCopyWith(Command_SetStrideLength value, $Res Function(Command_SetStrideLength) _then) = _$Command_SetStrideLengthCopyWithImpl;
@useResult
$Res call({
 double field0
});




}
/// @nodoc
class _$Command_SetStrideLengthCopyWithImpl<$Res>
    implements $Command_SetStrideLengthCopyWith<$Res> {
  _$Command_SetStrideLengthCopyWithImpl(this._self, this._then);

  final Command_SetStrideLength _self;
  final $Res Function(Command_SetStrideLength) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_SetStrideLength(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Command_Pause extends Command {
  const Command_Pause(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_Pause);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Command.pause()';
}


}




/// @nodoc


class Command_Resume extends Command {
  const Command_Resume(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_Resume);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Command.resume()';
}


}




/// @nodoc


class Command_StopImmediately extends Command {
  const Command_StopImmediately(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_StopImmediately);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Command.stopImmediately()';
}


}




/// @nodoc


class Command_StopAfterFrames extends Command {
  const Command_StopAfterFrames({required this.frames, required this.graceful}): super._();
  

 final  int frames;
 final  bool graceful;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_StopAfterFramesCopyWith<Command_StopAfterFrames> get copyWith => _$Command_StopAfterFramesCopyWithImpl<Command_StopAfterFrames>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_StopAfterFrames&&(identical(other.frames, frames) || other.frames == frames)&&(identical(other.graceful, graceful) || other.graceful == graceful));
}


@override
int get hashCode => Object.hash(runtimeType,frames,graceful);

@override
String toString() {
  return 'Command.stopAfterFrames(frames: $frames, graceful: $graceful)';
}


}

/// @nodoc
abstract mixin class $Command_StopAfterFramesCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_StopAfterFramesCopyWith(Command_StopAfterFrames value, $Res Function(Command_StopAfterFrames) _then) = _$Command_StopAfterFramesCopyWithImpl;
@useResult
$Res call({
 int frames, bool graceful
});




}
/// @nodoc
class _$Command_StopAfterFramesCopyWithImpl<$Res>
    implements $Command_StopAfterFramesCopyWith<$Res> {
  _$Command_StopAfterFramesCopyWithImpl(this._self, this._then);

  final Command_StopAfterFrames _self;
  final $Res Function(Command_StopAfterFrames) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? frames = null,Object? graceful = null,}) {
  return _then(Command_StopAfterFrames(
frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as int,graceful: null == graceful ? _self.graceful : graceful // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Command_StopAfterTime extends Command {
  const Command_StopAfterTime({required this.seconds, required this.graceful}): super._();
  

 final  double seconds;
 final  bool graceful;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_StopAfterTimeCopyWith<Command_StopAfterTime> get copyWith => _$Command_StopAfterTimeCopyWithImpl<Command_StopAfterTime>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_StopAfterTime&&(identical(other.seconds, seconds) || other.seconds == seconds)&&(identical(other.graceful, graceful) || other.graceful == graceful));
}


@override
int get hashCode => Object.hash(runtimeType,seconds,graceful);

@override
String toString() {
  return 'Command.stopAfterTime(seconds: $seconds, graceful: $graceful)';
}


}

/// @nodoc
abstract mixin class $Command_StopAfterTimeCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_StopAfterTimeCopyWith(Command_StopAfterTime value, $Res Function(Command_StopAfterTime) _then) = _$Command_StopAfterTimeCopyWithImpl;
@useResult
$Res call({
 double seconds, bool graceful
});




}
/// @nodoc
class _$Command_StopAfterTimeCopyWithImpl<$Res>
    implements $Command_StopAfterTimeCopyWith<$Res> {
  _$Command_StopAfterTimeCopyWithImpl(this._self, this._then);

  final Command_StopAfterTime _self;
  final $Res Function(Command_StopAfterTime) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? seconds = null,Object? graceful = null,}) {
  return _then(Command_StopAfterTime(
seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as double,graceful: null == graceful ? _self.graceful : graceful // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Command_JumpToProgress extends Command {
  const Command_JumpToProgress(this.field0): super._();
  

 final  double field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_JumpToProgressCopyWith<Command_JumpToProgress> get copyWith => _$Command_JumpToProgressCopyWithImpl<Command_JumpToProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_JumpToProgress&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.jumpToProgress(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_JumpToProgressCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_JumpToProgressCopyWith(Command_JumpToProgress value, $Res Function(Command_JumpToProgress) _then) = _$Command_JumpToProgressCopyWithImpl;
@useResult
$Res call({
 double field0
});




}
/// @nodoc
class _$Command_JumpToProgressCopyWithImpl<$Res>
    implements $Command_JumpToProgressCopyWith<$Res> {
  _$Command_JumpToProgressCopyWithImpl(this._self, this._then);

  final Command_JumpToProgress _self;
  final $Res Function(Command_JumpToProgress) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_JumpToProgress(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Command_NextTrajectory extends Command {
  const Command_NextTrajectory(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_NextTrajectory);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Command.nextTrajectory()';
}


}




/// @nodoc


class Command_AddCheckpoint extends Command {
  const Command_AddCheckpoint(this.field0): super._();
  

 final  Checkpoint field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_AddCheckpointCopyWith<Command_AddCheckpoint> get copyWith => _$Command_AddCheckpointCopyWithImpl<Command_AddCheckpoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_AddCheckpoint&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.addCheckpoint(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_AddCheckpointCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_AddCheckpointCopyWith(Command_AddCheckpoint value, $Res Function(Command_AddCheckpoint) _then) = _$Command_AddCheckpointCopyWithImpl;
@useResult
$Res call({
 Checkpoint field0
});




}
/// @nodoc
class _$Command_AddCheckpointCopyWithImpl<$Res>
    implements $Command_AddCheckpointCopyWith<$Res> {
  _$Command_AddCheckpointCopyWithImpl(this._self, this._then);

  final Command_AddCheckpoint _self;
  final $Res Function(Command_AddCheckpoint) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_AddCheckpoint(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Checkpoint,
  ));
}


}

/// @nodoc


class Command_RemoveCheckpoint extends Command {
  const Command_RemoveCheckpoint(this.field0): super._();
  

 final  String field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_RemoveCheckpointCopyWith<Command_RemoveCheckpoint> get copyWith => _$Command_RemoveCheckpointCopyWithImpl<Command_RemoveCheckpoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_RemoveCheckpoint&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.removeCheckpoint(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_RemoveCheckpointCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_RemoveCheckpointCopyWith(Command_RemoveCheckpoint value, $Res Function(Command_RemoveCheckpoint) _then) = _$Command_RemoveCheckpointCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$Command_RemoveCheckpointCopyWithImpl<$Res>
    implements $Command_RemoveCheckpointCopyWith<$Res> {
  _$Command_RemoveCheckpointCopyWithImpl(this._self, this._then);

  final Command_RemoveCheckpoint _self;
  final $Res Function(Command_RemoveCheckpoint) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_RemoveCheckpoint(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class Command_ClearCheckpoints extends Command {
  const Command_ClearCheckpoints(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_ClearCheckpoints);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Command.clearCheckpoints()';
}


}




/// @nodoc


class Command_ResetCheckpointStatus extends Command {
  const Command_ResetCheckpointStatus(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_ResetCheckpointStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Command.resetCheckpointStatus()';
}


}




/// @nodoc


class Command_SetJitterParams extends Command {
  const Command_SetJitterParams({this.positionAmplitude, this.speedAmplitude, this.bearingAmplitude}): super._();
  

 final  double? positionAmplitude;
 final  double? speedAmplitude;
 final  double? bearingAmplitude;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SetJitterParamsCopyWith<Command_SetJitterParams> get copyWith => _$Command_SetJitterParamsCopyWithImpl<Command_SetJitterParams>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SetJitterParams&&(identical(other.positionAmplitude, positionAmplitude) || other.positionAmplitude == positionAmplitude)&&(identical(other.speedAmplitude, speedAmplitude) || other.speedAmplitude == speedAmplitude)&&(identical(other.bearingAmplitude, bearingAmplitude) || other.bearingAmplitude == bearingAmplitude));
}


@override
int get hashCode => Object.hash(runtimeType,positionAmplitude,speedAmplitude,bearingAmplitude);

@override
String toString() {
  return 'Command.setJitterParams(positionAmplitude: $positionAmplitude, speedAmplitude: $speedAmplitude, bearingAmplitude: $bearingAmplitude)';
}


}

/// @nodoc
abstract mixin class $Command_SetJitterParamsCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SetJitterParamsCopyWith(Command_SetJitterParams value, $Res Function(Command_SetJitterParams) _then) = _$Command_SetJitterParamsCopyWithImpl;
@useResult
$Res call({
 double? positionAmplitude, double? speedAmplitude, double? bearingAmplitude
});




}
/// @nodoc
class _$Command_SetJitterParamsCopyWithImpl<$Res>
    implements $Command_SetJitterParamsCopyWith<$Res> {
  _$Command_SetJitterParamsCopyWithImpl(this._self, this._then);

  final Command_SetJitterParams _self;
  final $Res Function(Command_SetJitterParams) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? positionAmplitude = freezed,Object? speedAmplitude = freezed,Object? bearingAmplitude = freezed,}) {
  return _then(Command_SetJitterParams(
positionAmplitude: freezed == positionAmplitude ? _self.positionAmplitude : positionAmplitude // ignore: cast_nullable_to_non_nullable
as double?,speedAmplitude: freezed == speedAmplitude ? _self.speedAmplitude : speedAmplitude // ignore: cast_nullable_to_non_nullable
as double?,bearingAmplitude: freezed == bearingAmplitude ? _self.bearingAmplitude : bearingAmplitude // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc


class Command_SetRefreshRate extends Command {
  const Command_SetRefreshRate({this.gps, this.accelerometer, this.gyroscope, this.compass, this.barometer}): super._();
  

 final  double? gps;
 final  double? accelerometer;
 final  double? gyroscope;
 final  double? compass;
 final  double? barometer;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SetRefreshRateCopyWith<Command_SetRefreshRate> get copyWith => _$Command_SetRefreshRateCopyWithImpl<Command_SetRefreshRate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SetRefreshRate&&(identical(other.gps, gps) || other.gps == gps)&&(identical(other.accelerometer, accelerometer) || other.accelerometer == accelerometer)&&(identical(other.gyroscope, gyroscope) || other.gyroscope == gyroscope)&&(identical(other.compass, compass) || other.compass == compass)&&(identical(other.barometer, barometer) || other.barometer == barometer));
}


@override
int get hashCode => Object.hash(runtimeType,gps,accelerometer,gyroscope,compass,barometer);

@override
String toString() {
  return 'Command.setRefreshRate(gps: $gps, accelerometer: $accelerometer, gyroscope: $gyroscope, compass: $compass, barometer: $barometer)';
}


}

/// @nodoc
abstract mixin class $Command_SetRefreshRateCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SetRefreshRateCopyWith(Command_SetRefreshRate value, $Res Function(Command_SetRefreshRate) _then) = _$Command_SetRefreshRateCopyWithImpl;
@useResult
$Res call({
 double? gps, double? accelerometer, double? gyroscope, double? compass, double? barometer
});




}
/// @nodoc
class _$Command_SetRefreshRateCopyWithImpl<$Res>
    implements $Command_SetRefreshRateCopyWith<$Res> {
  _$Command_SetRefreshRateCopyWithImpl(this._self, this._then);

  final Command_SetRefreshRate _self;
  final $Res Function(Command_SetRefreshRate) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? gps = freezed,Object? accelerometer = freezed,Object? gyroscope = freezed,Object? compass = freezed,Object? barometer = freezed,}) {
  return _then(Command_SetRefreshRate(
gps: freezed == gps ? _self.gps : gps // ignore: cast_nullable_to_non_nullable
as double?,accelerometer: freezed == accelerometer ? _self.accelerometer : accelerometer // ignore: cast_nullable_to_non_nullable
as double?,gyroscope: freezed == gyroscope ? _self.gyroscope : gyroscope // ignore: cast_nullable_to_non_nullable
as double?,compass: freezed == compass ? _self.compass : compass // ignore: cast_nullable_to_non_nullable
as double?,barometer: freezed == barometer ? _self.barometer : barometer // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc


class Command_SetFenceWarningDistance extends Command {
  const Command_SetFenceWarningDistance(this.field0): super._();
  

 final  double field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SetFenceWarningDistanceCopyWith<Command_SetFenceWarningDistance> get copyWith => _$Command_SetFenceWarningDistanceCopyWithImpl<Command_SetFenceWarningDistance>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SetFenceWarningDistance&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.setFenceWarningDistance(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_SetFenceWarningDistanceCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SetFenceWarningDistanceCopyWith(Command_SetFenceWarningDistance value, $Res Function(Command_SetFenceWarningDistance) _then) = _$Command_SetFenceWarningDistanceCopyWithImpl;
@useResult
$Res call({
 double field0
});




}
/// @nodoc
class _$Command_SetFenceWarningDistanceCopyWithImpl<$Res>
    implements $Command_SetFenceWarningDistanceCopyWith<$Res> {
  _$Command_SetFenceWarningDistanceCopyWithImpl(this._self, this._then);

  final Command_SetFenceWarningDistance _self;
  final $Res Function(Command_SetFenceWarningDistance) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_SetFenceWarningDistance(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Command_SwitchTrajectory extends Command {
  const Command_SwitchTrajectory({required this.index, required this.seamless}): super._();
  

 final  BigInt index;
 final  bool seamless;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_SwitchTrajectoryCopyWith<Command_SwitchTrajectory> get copyWith => _$Command_SwitchTrajectoryCopyWithImpl<Command_SwitchTrajectory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_SwitchTrajectory&&(identical(other.index, index) || other.index == index)&&(identical(other.seamless, seamless) || other.seamless == seamless));
}


@override
int get hashCode => Object.hash(runtimeType,index,seamless);

@override
String toString() {
  return 'Command.switchTrajectory(index: $index, seamless: $seamless)';
}


}

/// @nodoc
abstract mixin class $Command_SwitchTrajectoryCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_SwitchTrajectoryCopyWith(Command_SwitchTrajectory value, $Res Function(Command_SwitchTrajectory) _then) = _$Command_SwitchTrajectoryCopyWithImpl;
@useResult
$Res call({
 BigInt index, bool seamless
});




}
/// @nodoc
class _$Command_SwitchTrajectoryCopyWithImpl<$Res>
    implements $Command_SwitchTrajectoryCopyWith<$Res> {
  _$Command_SwitchTrajectoryCopyWithImpl(this._self, this._then);

  final Command_SwitchTrajectory _self;
  final $Res Function(Command_SwitchTrajectory) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,Object? seamless = null,}) {
  return _then(Command_SwitchTrajectory(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as BigInt,seamless: null == seamless ? _self.seamless : seamless // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Command_AppendTrajectory extends Command {
  const Command_AppendTrajectory(this.field0): super._();
  

 final  Trajectory field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_AppendTrajectoryCopyWith<Command_AppendTrajectory> get copyWith => _$Command_AppendTrajectoryCopyWithImpl<Command_AppendTrajectory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_AppendTrajectory&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.appendTrajectory(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_AppendTrajectoryCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_AppendTrajectoryCopyWith(Command_AppendTrajectory value, $Res Function(Command_AppendTrajectory) _then) = _$Command_AppendTrajectoryCopyWithImpl;
@useResult
$Res call({
 Trajectory field0
});




}
/// @nodoc
class _$Command_AppendTrajectoryCopyWithImpl<$Res>
    implements $Command_AppendTrajectoryCopyWith<$Res> {
  _$Command_AppendTrajectoryCopyWithImpl(this._self, this._then);

  final Command_AppendTrajectory _self;
  final $Res Function(Command_AppendTrajectory) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_AppendTrajectory(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Trajectory,
  ));
}


}

/// @nodoc


class Command_Custom extends Command {
  const Command_Custom(this.field0): super._();
  

 final  String field0;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Command_CustomCopyWith<Command_Custom> get copyWith => _$Command_CustomCopyWithImpl<Command_Custom>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Command_Custom&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'Command.custom(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $Command_CustomCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory $Command_CustomCopyWith(Command_Custom value, $Res Function(Command_Custom) _then) = _$Command_CustomCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$Command_CustomCopyWithImpl<$Res>
    implements $Command_CustomCopyWith<$Res> {
  _$Command_CustomCopyWithImpl(this._self, this._then);

  final Command_Custom _self;
  final $Res Function(Command_Custom) _then;

/// Create a copy of Command
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(Command_Custom(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SimulatorEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SimulatorEvent()';
}


}

/// @nodoc
class $SimulatorEventCopyWith<$Res>  {
$SimulatorEventCopyWith(SimulatorEvent _, $Res Function(SimulatorEvent) __);
}


/// Adds pattern-matching-related methods to [SimulatorEvent].
extension SimulatorEventPatterns on SimulatorEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SimulatorEvent_Started value)?  started,TResult Function( SimulatorEvent_Paused value)?  paused,TResult Function( SimulatorEvent_Resumed value)?  resumed,TResult Function( SimulatorEvent_Stopped value)?  stopped,TResult Function( SimulatorEvent_SensorDataUpdated value)?  sensorDataUpdated,TResult Function( SimulatorEvent_PositionUpdated value)?  positionUpdated,TResult Function( SimulatorEvent_SpeedChanged value)?  speedChanged,TResult Function( SimulatorEvent_PhaseChanged value)?  phaseChanged,TResult Function( SimulatorEvent_TrajectorySwitched value)?  trajectorySwitched,TResult Function( SimulatorEvent_CheckpointReached value)?  checkpointReached,TResult Function( SimulatorEvent_AllCheckpointsCompleted value)?  allCheckpointsCompleted,TResult Function( SimulatorEvent_GeofenceEntered value)?  geofenceEntered,TResult Function( SimulatorEvent_GeofenceExited value)?  geofenceExited,TResult Function( SimulatorEvent_ForbiddenZoneEntered value)?  forbiddenZoneEntered,TResult Function( SimulatorEvent_ForbiddenZoneExited value)?  forbiddenZoneExited,TResult Function( SimulatorEvent_ErrorOccurred value)?  errorOccurred,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SimulatorEvent_Started() when started != null:
return started(_that);case SimulatorEvent_Paused() when paused != null:
return paused(_that);case SimulatorEvent_Resumed() when resumed != null:
return resumed(_that);case SimulatorEvent_Stopped() when stopped != null:
return stopped(_that);case SimulatorEvent_SensorDataUpdated() when sensorDataUpdated != null:
return sensorDataUpdated(_that);case SimulatorEvent_PositionUpdated() when positionUpdated != null:
return positionUpdated(_that);case SimulatorEvent_SpeedChanged() when speedChanged != null:
return speedChanged(_that);case SimulatorEvent_PhaseChanged() when phaseChanged != null:
return phaseChanged(_that);case SimulatorEvent_TrajectorySwitched() when trajectorySwitched != null:
return trajectorySwitched(_that);case SimulatorEvent_CheckpointReached() when checkpointReached != null:
return checkpointReached(_that);case SimulatorEvent_AllCheckpointsCompleted() when allCheckpointsCompleted != null:
return allCheckpointsCompleted(_that);case SimulatorEvent_GeofenceEntered() when geofenceEntered != null:
return geofenceEntered(_that);case SimulatorEvent_GeofenceExited() when geofenceExited != null:
return geofenceExited(_that);case SimulatorEvent_ForbiddenZoneEntered() when forbiddenZoneEntered != null:
return forbiddenZoneEntered(_that);case SimulatorEvent_ForbiddenZoneExited() when forbiddenZoneExited != null:
return forbiddenZoneExited(_that);case SimulatorEvent_ErrorOccurred() when errorOccurred != null:
return errorOccurred(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SimulatorEvent_Started value)  started,required TResult Function( SimulatorEvent_Paused value)  paused,required TResult Function( SimulatorEvent_Resumed value)  resumed,required TResult Function( SimulatorEvent_Stopped value)  stopped,required TResult Function( SimulatorEvent_SensorDataUpdated value)  sensorDataUpdated,required TResult Function( SimulatorEvent_PositionUpdated value)  positionUpdated,required TResult Function( SimulatorEvent_SpeedChanged value)  speedChanged,required TResult Function( SimulatorEvent_PhaseChanged value)  phaseChanged,required TResult Function( SimulatorEvent_TrajectorySwitched value)  trajectorySwitched,required TResult Function( SimulatorEvent_CheckpointReached value)  checkpointReached,required TResult Function( SimulatorEvent_AllCheckpointsCompleted value)  allCheckpointsCompleted,required TResult Function( SimulatorEvent_GeofenceEntered value)  geofenceEntered,required TResult Function( SimulatorEvent_GeofenceExited value)  geofenceExited,required TResult Function( SimulatorEvent_ForbiddenZoneEntered value)  forbiddenZoneEntered,required TResult Function( SimulatorEvent_ForbiddenZoneExited value)  forbiddenZoneExited,required TResult Function( SimulatorEvent_ErrorOccurred value)  errorOccurred,}){
final _that = this;
switch (_that) {
case SimulatorEvent_Started():
return started(_that);case SimulatorEvent_Paused():
return paused(_that);case SimulatorEvent_Resumed():
return resumed(_that);case SimulatorEvent_Stopped():
return stopped(_that);case SimulatorEvent_SensorDataUpdated():
return sensorDataUpdated(_that);case SimulatorEvent_PositionUpdated():
return positionUpdated(_that);case SimulatorEvent_SpeedChanged():
return speedChanged(_that);case SimulatorEvent_PhaseChanged():
return phaseChanged(_that);case SimulatorEvent_TrajectorySwitched():
return trajectorySwitched(_that);case SimulatorEvent_CheckpointReached():
return checkpointReached(_that);case SimulatorEvent_AllCheckpointsCompleted():
return allCheckpointsCompleted(_that);case SimulatorEvent_GeofenceEntered():
return geofenceEntered(_that);case SimulatorEvent_GeofenceExited():
return geofenceExited(_that);case SimulatorEvent_ForbiddenZoneEntered():
return forbiddenZoneEntered(_that);case SimulatorEvent_ForbiddenZoneExited():
return forbiddenZoneExited(_that);case SimulatorEvent_ErrorOccurred():
return errorOccurred(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SimulatorEvent_Started value)?  started,TResult? Function( SimulatorEvent_Paused value)?  paused,TResult? Function( SimulatorEvent_Resumed value)?  resumed,TResult? Function( SimulatorEvent_Stopped value)?  stopped,TResult? Function( SimulatorEvent_SensorDataUpdated value)?  sensorDataUpdated,TResult? Function( SimulatorEvent_PositionUpdated value)?  positionUpdated,TResult? Function( SimulatorEvent_SpeedChanged value)?  speedChanged,TResult? Function( SimulatorEvent_PhaseChanged value)?  phaseChanged,TResult? Function( SimulatorEvent_TrajectorySwitched value)?  trajectorySwitched,TResult? Function( SimulatorEvent_CheckpointReached value)?  checkpointReached,TResult? Function( SimulatorEvent_AllCheckpointsCompleted value)?  allCheckpointsCompleted,TResult? Function( SimulatorEvent_GeofenceEntered value)?  geofenceEntered,TResult? Function( SimulatorEvent_GeofenceExited value)?  geofenceExited,TResult? Function( SimulatorEvent_ForbiddenZoneEntered value)?  forbiddenZoneEntered,TResult? Function( SimulatorEvent_ForbiddenZoneExited value)?  forbiddenZoneExited,TResult? Function( SimulatorEvent_ErrorOccurred value)?  errorOccurred,}){
final _that = this;
switch (_that) {
case SimulatorEvent_Started() when started != null:
return started(_that);case SimulatorEvent_Paused() when paused != null:
return paused(_that);case SimulatorEvent_Resumed() when resumed != null:
return resumed(_that);case SimulatorEvent_Stopped() when stopped != null:
return stopped(_that);case SimulatorEvent_SensorDataUpdated() when sensorDataUpdated != null:
return sensorDataUpdated(_that);case SimulatorEvent_PositionUpdated() when positionUpdated != null:
return positionUpdated(_that);case SimulatorEvent_SpeedChanged() when speedChanged != null:
return speedChanged(_that);case SimulatorEvent_PhaseChanged() when phaseChanged != null:
return phaseChanged(_that);case SimulatorEvent_TrajectorySwitched() when trajectorySwitched != null:
return trajectorySwitched(_that);case SimulatorEvent_CheckpointReached() when checkpointReached != null:
return checkpointReached(_that);case SimulatorEvent_AllCheckpointsCompleted() when allCheckpointsCompleted != null:
return allCheckpointsCompleted(_that);case SimulatorEvent_GeofenceEntered() when geofenceEntered != null:
return geofenceEntered(_that);case SimulatorEvent_GeofenceExited() when geofenceExited != null:
return geofenceExited(_that);case SimulatorEvent_ForbiddenZoneEntered() when forbiddenZoneEntered != null:
return forbiddenZoneEntered(_that);case SimulatorEvent_ForbiddenZoneExited() when forbiddenZoneExited != null:
return forbiddenZoneExited(_that);case SimulatorEvent_ErrorOccurred() when errorOccurred != null:
return errorOccurred(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function()?  paused,TResult Function()?  resumed,TResult Function( StopReason reason)?  stopped,TResult Function( SensorData data)?  sensorDataUpdated,TResult Function( GeoPoint position,  double speed,  double bearing)?  positionUpdated,TResult Function( double oldSpeed,  double newSpeed)?  speedChanged,TResult Function( MovementPhase oldPhase,  MovementPhase newPhase)?  phaseChanged,TResult Function( BigInt index,  String trajectoryId)?  trajectorySwitched,TResult Function( Checkpoint checkpoint)?  checkpointReached,TResult Function()?  allCheckpointsCompleted,TResult Function()?  geofenceEntered,TResult Function()?  geofenceExited,TResult Function( BigInt zoneIndex)?  forbiddenZoneEntered,TResult Function( BigInt zoneIndex)?  forbiddenZoneExited,TResult Function( String message)?  errorOccurred,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SimulatorEvent_Started() when started != null:
return started();case SimulatorEvent_Paused() when paused != null:
return paused();case SimulatorEvent_Resumed() when resumed != null:
return resumed();case SimulatorEvent_Stopped() when stopped != null:
return stopped(_that.reason);case SimulatorEvent_SensorDataUpdated() when sensorDataUpdated != null:
return sensorDataUpdated(_that.data);case SimulatorEvent_PositionUpdated() when positionUpdated != null:
return positionUpdated(_that.position,_that.speed,_that.bearing);case SimulatorEvent_SpeedChanged() when speedChanged != null:
return speedChanged(_that.oldSpeed,_that.newSpeed);case SimulatorEvent_PhaseChanged() when phaseChanged != null:
return phaseChanged(_that.oldPhase,_that.newPhase);case SimulatorEvent_TrajectorySwitched() when trajectorySwitched != null:
return trajectorySwitched(_that.index,_that.trajectoryId);case SimulatorEvent_CheckpointReached() when checkpointReached != null:
return checkpointReached(_that.checkpoint);case SimulatorEvent_AllCheckpointsCompleted() when allCheckpointsCompleted != null:
return allCheckpointsCompleted();case SimulatorEvent_GeofenceEntered() when geofenceEntered != null:
return geofenceEntered();case SimulatorEvent_GeofenceExited() when geofenceExited != null:
return geofenceExited();case SimulatorEvent_ForbiddenZoneEntered() when forbiddenZoneEntered != null:
return forbiddenZoneEntered(_that.zoneIndex);case SimulatorEvent_ForbiddenZoneExited() when forbiddenZoneExited != null:
return forbiddenZoneExited(_that.zoneIndex);case SimulatorEvent_ErrorOccurred() when errorOccurred != null:
return errorOccurred(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function()  paused,required TResult Function()  resumed,required TResult Function( StopReason reason)  stopped,required TResult Function( SensorData data)  sensorDataUpdated,required TResult Function( GeoPoint position,  double speed,  double bearing)  positionUpdated,required TResult Function( double oldSpeed,  double newSpeed)  speedChanged,required TResult Function( MovementPhase oldPhase,  MovementPhase newPhase)  phaseChanged,required TResult Function( BigInt index,  String trajectoryId)  trajectorySwitched,required TResult Function( Checkpoint checkpoint)  checkpointReached,required TResult Function()  allCheckpointsCompleted,required TResult Function()  geofenceEntered,required TResult Function()  geofenceExited,required TResult Function( BigInt zoneIndex)  forbiddenZoneEntered,required TResult Function( BigInt zoneIndex)  forbiddenZoneExited,required TResult Function( String message)  errorOccurred,}) {final _that = this;
switch (_that) {
case SimulatorEvent_Started():
return started();case SimulatorEvent_Paused():
return paused();case SimulatorEvent_Resumed():
return resumed();case SimulatorEvent_Stopped():
return stopped(_that.reason);case SimulatorEvent_SensorDataUpdated():
return sensorDataUpdated(_that.data);case SimulatorEvent_PositionUpdated():
return positionUpdated(_that.position,_that.speed,_that.bearing);case SimulatorEvent_SpeedChanged():
return speedChanged(_that.oldSpeed,_that.newSpeed);case SimulatorEvent_PhaseChanged():
return phaseChanged(_that.oldPhase,_that.newPhase);case SimulatorEvent_TrajectorySwitched():
return trajectorySwitched(_that.index,_that.trajectoryId);case SimulatorEvent_CheckpointReached():
return checkpointReached(_that.checkpoint);case SimulatorEvent_AllCheckpointsCompleted():
return allCheckpointsCompleted();case SimulatorEvent_GeofenceEntered():
return geofenceEntered();case SimulatorEvent_GeofenceExited():
return geofenceExited();case SimulatorEvent_ForbiddenZoneEntered():
return forbiddenZoneEntered(_that.zoneIndex);case SimulatorEvent_ForbiddenZoneExited():
return forbiddenZoneExited(_that.zoneIndex);case SimulatorEvent_ErrorOccurred():
return errorOccurred(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function()?  paused,TResult? Function()?  resumed,TResult? Function( StopReason reason)?  stopped,TResult? Function( SensorData data)?  sensorDataUpdated,TResult? Function( GeoPoint position,  double speed,  double bearing)?  positionUpdated,TResult? Function( double oldSpeed,  double newSpeed)?  speedChanged,TResult? Function( MovementPhase oldPhase,  MovementPhase newPhase)?  phaseChanged,TResult? Function( BigInt index,  String trajectoryId)?  trajectorySwitched,TResult? Function( Checkpoint checkpoint)?  checkpointReached,TResult? Function()?  allCheckpointsCompleted,TResult? Function()?  geofenceEntered,TResult? Function()?  geofenceExited,TResult? Function( BigInt zoneIndex)?  forbiddenZoneEntered,TResult? Function( BigInt zoneIndex)?  forbiddenZoneExited,TResult? Function( String message)?  errorOccurred,}) {final _that = this;
switch (_that) {
case SimulatorEvent_Started() when started != null:
return started();case SimulatorEvent_Paused() when paused != null:
return paused();case SimulatorEvent_Resumed() when resumed != null:
return resumed();case SimulatorEvent_Stopped() when stopped != null:
return stopped(_that.reason);case SimulatorEvent_SensorDataUpdated() when sensorDataUpdated != null:
return sensorDataUpdated(_that.data);case SimulatorEvent_PositionUpdated() when positionUpdated != null:
return positionUpdated(_that.position,_that.speed,_that.bearing);case SimulatorEvent_SpeedChanged() when speedChanged != null:
return speedChanged(_that.oldSpeed,_that.newSpeed);case SimulatorEvent_PhaseChanged() when phaseChanged != null:
return phaseChanged(_that.oldPhase,_that.newPhase);case SimulatorEvent_TrajectorySwitched() when trajectorySwitched != null:
return trajectorySwitched(_that.index,_that.trajectoryId);case SimulatorEvent_CheckpointReached() when checkpointReached != null:
return checkpointReached(_that.checkpoint);case SimulatorEvent_AllCheckpointsCompleted() when allCheckpointsCompleted != null:
return allCheckpointsCompleted();case SimulatorEvent_GeofenceEntered() when geofenceEntered != null:
return geofenceEntered();case SimulatorEvent_GeofenceExited() when geofenceExited != null:
return geofenceExited();case SimulatorEvent_ForbiddenZoneEntered() when forbiddenZoneEntered != null:
return forbiddenZoneEntered(_that.zoneIndex);case SimulatorEvent_ForbiddenZoneExited() when forbiddenZoneExited != null:
return forbiddenZoneExited(_that.zoneIndex);case SimulatorEvent_ErrorOccurred() when errorOccurred != null:
return errorOccurred(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SimulatorEvent_Started extends SimulatorEvent {
  const SimulatorEvent_Started(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_Started);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SimulatorEvent.started()';
}


}




/// @nodoc


class SimulatorEvent_Paused extends SimulatorEvent {
  const SimulatorEvent_Paused(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_Paused);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SimulatorEvent.paused()';
}


}




/// @nodoc


class SimulatorEvent_Resumed extends SimulatorEvent {
  const SimulatorEvent_Resumed(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_Resumed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SimulatorEvent.resumed()';
}


}




/// @nodoc


class SimulatorEvent_Stopped extends SimulatorEvent {
  const SimulatorEvent_Stopped({required this.reason}): super._();
  

 final  StopReason reason;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_StoppedCopyWith<SimulatorEvent_Stopped> get copyWith => _$SimulatorEvent_StoppedCopyWithImpl<SimulatorEvent_Stopped>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_Stopped&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'SimulatorEvent.stopped(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_StoppedCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_StoppedCopyWith(SimulatorEvent_Stopped value, $Res Function(SimulatorEvent_Stopped) _then) = _$SimulatorEvent_StoppedCopyWithImpl;
@useResult
$Res call({
 StopReason reason
});




}
/// @nodoc
class _$SimulatorEvent_StoppedCopyWithImpl<$Res>
    implements $SimulatorEvent_StoppedCopyWith<$Res> {
  _$SimulatorEvent_StoppedCopyWithImpl(this._self, this._then);

  final SimulatorEvent_Stopped _self;
  final $Res Function(SimulatorEvent_Stopped) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(SimulatorEvent_Stopped(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as StopReason,
  ));
}


}

/// @nodoc


class SimulatorEvent_SensorDataUpdated extends SimulatorEvent {
  const SimulatorEvent_SensorDataUpdated({required this.data}): super._();
  

 final  SensorData data;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_SensorDataUpdatedCopyWith<SimulatorEvent_SensorDataUpdated> get copyWith => _$SimulatorEvent_SensorDataUpdatedCopyWithImpl<SimulatorEvent_SensorDataUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_SensorDataUpdated&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'SimulatorEvent.sensorDataUpdated(data: $data)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_SensorDataUpdatedCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_SensorDataUpdatedCopyWith(SimulatorEvent_SensorDataUpdated value, $Res Function(SimulatorEvent_SensorDataUpdated) _then) = _$SimulatorEvent_SensorDataUpdatedCopyWithImpl;
@useResult
$Res call({
 SensorData data
});




}
/// @nodoc
class _$SimulatorEvent_SensorDataUpdatedCopyWithImpl<$Res>
    implements $SimulatorEvent_SensorDataUpdatedCopyWith<$Res> {
  _$SimulatorEvent_SensorDataUpdatedCopyWithImpl(this._self, this._then);

  final SimulatorEvent_SensorDataUpdated _self;
  final $Res Function(SimulatorEvent_SensorDataUpdated) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(SimulatorEvent_SensorDataUpdated(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as SensorData,
  ));
}


}

/// @nodoc


class SimulatorEvent_PositionUpdated extends SimulatorEvent {
  const SimulatorEvent_PositionUpdated({required this.position, required this.speed, required this.bearing}): super._();
  

 final  GeoPoint position;
 final  double speed;
 final  double bearing;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_PositionUpdatedCopyWith<SimulatorEvent_PositionUpdated> get copyWith => _$SimulatorEvent_PositionUpdatedCopyWithImpl<SimulatorEvent_PositionUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_PositionUpdated&&(identical(other.position, position) || other.position == position)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.bearing, bearing) || other.bearing == bearing));
}


@override
int get hashCode => Object.hash(runtimeType,position,speed,bearing);

@override
String toString() {
  return 'SimulatorEvent.positionUpdated(position: $position, speed: $speed, bearing: $bearing)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_PositionUpdatedCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_PositionUpdatedCopyWith(SimulatorEvent_PositionUpdated value, $Res Function(SimulatorEvent_PositionUpdated) _then) = _$SimulatorEvent_PositionUpdatedCopyWithImpl;
@useResult
$Res call({
 GeoPoint position, double speed, double bearing
});




}
/// @nodoc
class _$SimulatorEvent_PositionUpdatedCopyWithImpl<$Res>
    implements $SimulatorEvent_PositionUpdatedCopyWith<$Res> {
  _$SimulatorEvent_PositionUpdatedCopyWithImpl(this._self, this._then);

  final SimulatorEvent_PositionUpdated _self;
  final $Res Function(SimulatorEvent_PositionUpdated) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? position = null,Object? speed = null,Object? bearing = null,}) {
  return _then(SimulatorEvent_PositionUpdated(
position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as GeoPoint,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,bearing: null == bearing ? _self.bearing : bearing // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class SimulatorEvent_SpeedChanged extends SimulatorEvent {
  const SimulatorEvent_SpeedChanged({required this.oldSpeed, required this.newSpeed}): super._();
  

 final  double oldSpeed;
 final  double newSpeed;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_SpeedChangedCopyWith<SimulatorEvent_SpeedChanged> get copyWith => _$SimulatorEvent_SpeedChangedCopyWithImpl<SimulatorEvent_SpeedChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_SpeedChanged&&(identical(other.oldSpeed, oldSpeed) || other.oldSpeed == oldSpeed)&&(identical(other.newSpeed, newSpeed) || other.newSpeed == newSpeed));
}


@override
int get hashCode => Object.hash(runtimeType,oldSpeed,newSpeed);

@override
String toString() {
  return 'SimulatorEvent.speedChanged(oldSpeed: $oldSpeed, newSpeed: $newSpeed)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_SpeedChangedCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_SpeedChangedCopyWith(SimulatorEvent_SpeedChanged value, $Res Function(SimulatorEvent_SpeedChanged) _then) = _$SimulatorEvent_SpeedChangedCopyWithImpl;
@useResult
$Res call({
 double oldSpeed, double newSpeed
});




}
/// @nodoc
class _$SimulatorEvent_SpeedChangedCopyWithImpl<$Res>
    implements $SimulatorEvent_SpeedChangedCopyWith<$Res> {
  _$SimulatorEvent_SpeedChangedCopyWithImpl(this._self, this._then);

  final SimulatorEvent_SpeedChanged _self;
  final $Res Function(SimulatorEvent_SpeedChanged) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? oldSpeed = null,Object? newSpeed = null,}) {
  return _then(SimulatorEvent_SpeedChanged(
oldSpeed: null == oldSpeed ? _self.oldSpeed : oldSpeed // ignore: cast_nullable_to_non_nullable
as double,newSpeed: null == newSpeed ? _self.newSpeed : newSpeed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class SimulatorEvent_PhaseChanged extends SimulatorEvent {
  const SimulatorEvent_PhaseChanged({required this.oldPhase, required this.newPhase}): super._();
  

 final  MovementPhase oldPhase;
 final  MovementPhase newPhase;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_PhaseChangedCopyWith<SimulatorEvent_PhaseChanged> get copyWith => _$SimulatorEvent_PhaseChangedCopyWithImpl<SimulatorEvent_PhaseChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_PhaseChanged&&(identical(other.oldPhase, oldPhase) || other.oldPhase == oldPhase)&&(identical(other.newPhase, newPhase) || other.newPhase == newPhase));
}


@override
int get hashCode => Object.hash(runtimeType,oldPhase,newPhase);

@override
String toString() {
  return 'SimulatorEvent.phaseChanged(oldPhase: $oldPhase, newPhase: $newPhase)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_PhaseChangedCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_PhaseChangedCopyWith(SimulatorEvent_PhaseChanged value, $Res Function(SimulatorEvent_PhaseChanged) _then) = _$SimulatorEvent_PhaseChangedCopyWithImpl;
@useResult
$Res call({
 MovementPhase oldPhase, MovementPhase newPhase
});




}
/// @nodoc
class _$SimulatorEvent_PhaseChangedCopyWithImpl<$Res>
    implements $SimulatorEvent_PhaseChangedCopyWith<$Res> {
  _$SimulatorEvent_PhaseChangedCopyWithImpl(this._self, this._then);

  final SimulatorEvent_PhaseChanged _self;
  final $Res Function(SimulatorEvent_PhaseChanged) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? oldPhase = null,Object? newPhase = null,}) {
  return _then(SimulatorEvent_PhaseChanged(
oldPhase: null == oldPhase ? _self.oldPhase : oldPhase // ignore: cast_nullable_to_non_nullable
as MovementPhase,newPhase: null == newPhase ? _self.newPhase : newPhase // ignore: cast_nullable_to_non_nullable
as MovementPhase,
  ));
}


}

/// @nodoc


class SimulatorEvent_TrajectorySwitched extends SimulatorEvent {
  const SimulatorEvent_TrajectorySwitched({required this.index, required this.trajectoryId}): super._();
  

 final  BigInt index;
 final  String trajectoryId;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_TrajectorySwitchedCopyWith<SimulatorEvent_TrajectorySwitched> get copyWith => _$SimulatorEvent_TrajectorySwitchedCopyWithImpl<SimulatorEvent_TrajectorySwitched>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_TrajectorySwitched&&(identical(other.index, index) || other.index == index)&&(identical(other.trajectoryId, trajectoryId) || other.trajectoryId == trajectoryId));
}


@override
int get hashCode => Object.hash(runtimeType,index,trajectoryId);

@override
String toString() {
  return 'SimulatorEvent.trajectorySwitched(index: $index, trajectoryId: $trajectoryId)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_TrajectorySwitchedCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_TrajectorySwitchedCopyWith(SimulatorEvent_TrajectorySwitched value, $Res Function(SimulatorEvent_TrajectorySwitched) _then) = _$SimulatorEvent_TrajectorySwitchedCopyWithImpl;
@useResult
$Res call({
 BigInt index, String trajectoryId
});




}
/// @nodoc
class _$SimulatorEvent_TrajectorySwitchedCopyWithImpl<$Res>
    implements $SimulatorEvent_TrajectorySwitchedCopyWith<$Res> {
  _$SimulatorEvent_TrajectorySwitchedCopyWithImpl(this._self, this._then);

  final SimulatorEvent_TrajectorySwitched _self;
  final $Res Function(SimulatorEvent_TrajectorySwitched) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,Object? trajectoryId = null,}) {
  return _then(SimulatorEvent_TrajectorySwitched(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as BigInt,trajectoryId: null == trajectoryId ? _self.trajectoryId : trajectoryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SimulatorEvent_CheckpointReached extends SimulatorEvent {
  const SimulatorEvent_CheckpointReached({required this.checkpoint}): super._();
  

 final  Checkpoint checkpoint;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_CheckpointReachedCopyWith<SimulatorEvent_CheckpointReached> get copyWith => _$SimulatorEvent_CheckpointReachedCopyWithImpl<SimulatorEvent_CheckpointReached>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_CheckpointReached&&(identical(other.checkpoint, checkpoint) || other.checkpoint == checkpoint));
}


@override
int get hashCode => Object.hash(runtimeType,checkpoint);

@override
String toString() {
  return 'SimulatorEvent.checkpointReached(checkpoint: $checkpoint)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_CheckpointReachedCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_CheckpointReachedCopyWith(SimulatorEvent_CheckpointReached value, $Res Function(SimulatorEvent_CheckpointReached) _then) = _$SimulatorEvent_CheckpointReachedCopyWithImpl;
@useResult
$Res call({
 Checkpoint checkpoint
});




}
/// @nodoc
class _$SimulatorEvent_CheckpointReachedCopyWithImpl<$Res>
    implements $SimulatorEvent_CheckpointReachedCopyWith<$Res> {
  _$SimulatorEvent_CheckpointReachedCopyWithImpl(this._self, this._then);

  final SimulatorEvent_CheckpointReached _self;
  final $Res Function(SimulatorEvent_CheckpointReached) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? checkpoint = null,}) {
  return _then(SimulatorEvent_CheckpointReached(
checkpoint: null == checkpoint ? _self.checkpoint : checkpoint // ignore: cast_nullable_to_non_nullable
as Checkpoint,
  ));
}


}

/// @nodoc


class SimulatorEvent_AllCheckpointsCompleted extends SimulatorEvent {
  const SimulatorEvent_AllCheckpointsCompleted(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_AllCheckpointsCompleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SimulatorEvent.allCheckpointsCompleted()';
}


}




/// @nodoc


class SimulatorEvent_GeofenceEntered extends SimulatorEvent {
  const SimulatorEvent_GeofenceEntered(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_GeofenceEntered);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SimulatorEvent.geofenceEntered()';
}


}




/// @nodoc


class SimulatorEvent_GeofenceExited extends SimulatorEvent {
  const SimulatorEvent_GeofenceExited(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_GeofenceExited);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SimulatorEvent.geofenceExited()';
}


}




/// @nodoc


class SimulatorEvent_ForbiddenZoneEntered extends SimulatorEvent {
  const SimulatorEvent_ForbiddenZoneEntered({required this.zoneIndex}): super._();
  

 final  BigInt zoneIndex;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_ForbiddenZoneEnteredCopyWith<SimulatorEvent_ForbiddenZoneEntered> get copyWith => _$SimulatorEvent_ForbiddenZoneEnteredCopyWithImpl<SimulatorEvent_ForbiddenZoneEntered>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_ForbiddenZoneEntered&&(identical(other.zoneIndex, zoneIndex) || other.zoneIndex == zoneIndex));
}


@override
int get hashCode => Object.hash(runtimeType,zoneIndex);

@override
String toString() {
  return 'SimulatorEvent.forbiddenZoneEntered(zoneIndex: $zoneIndex)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_ForbiddenZoneEnteredCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_ForbiddenZoneEnteredCopyWith(SimulatorEvent_ForbiddenZoneEntered value, $Res Function(SimulatorEvent_ForbiddenZoneEntered) _then) = _$SimulatorEvent_ForbiddenZoneEnteredCopyWithImpl;
@useResult
$Res call({
 BigInt zoneIndex
});




}
/// @nodoc
class _$SimulatorEvent_ForbiddenZoneEnteredCopyWithImpl<$Res>
    implements $SimulatorEvent_ForbiddenZoneEnteredCopyWith<$Res> {
  _$SimulatorEvent_ForbiddenZoneEnteredCopyWithImpl(this._self, this._then);

  final SimulatorEvent_ForbiddenZoneEntered _self;
  final $Res Function(SimulatorEvent_ForbiddenZoneEntered) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? zoneIndex = null,}) {
  return _then(SimulatorEvent_ForbiddenZoneEntered(
zoneIndex: null == zoneIndex ? _self.zoneIndex : zoneIndex // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class SimulatorEvent_ForbiddenZoneExited extends SimulatorEvent {
  const SimulatorEvent_ForbiddenZoneExited({required this.zoneIndex}): super._();
  

 final  BigInt zoneIndex;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_ForbiddenZoneExitedCopyWith<SimulatorEvent_ForbiddenZoneExited> get copyWith => _$SimulatorEvent_ForbiddenZoneExitedCopyWithImpl<SimulatorEvent_ForbiddenZoneExited>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_ForbiddenZoneExited&&(identical(other.zoneIndex, zoneIndex) || other.zoneIndex == zoneIndex));
}


@override
int get hashCode => Object.hash(runtimeType,zoneIndex);

@override
String toString() {
  return 'SimulatorEvent.forbiddenZoneExited(zoneIndex: $zoneIndex)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_ForbiddenZoneExitedCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_ForbiddenZoneExitedCopyWith(SimulatorEvent_ForbiddenZoneExited value, $Res Function(SimulatorEvent_ForbiddenZoneExited) _then) = _$SimulatorEvent_ForbiddenZoneExitedCopyWithImpl;
@useResult
$Res call({
 BigInt zoneIndex
});




}
/// @nodoc
class _$SimulatorEvent_ForbiddenZoneExitedCopyWithImpl<$Res>
    implements $SimulatorEvent_ForbiddenZoneExitedCopyWith<$Res> {
  _$SimulatorEvent_ForbiddenZoneExitedCopyWithImpl(this._self, this._then);

  final SimulatorEvent_ForbiddenZoneExited _self;
  final $Res Function(SimulatorEvent_ForbiddenZoneExited) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? zoneIndex = null,}) {
  return _then(SimulatorEvent_ForbiddenZoneExited(
zoneIndex: null == zoneIndex ? _self.zoneIndex : zoneIndex // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class SimulatorEvent_ErrorOccurred extends SimulatorEvent {
  const SimulatorEvent_ErrorOccurred({required this.message}): super._();
  

 final  String message;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorEvent_ErrorOccurredCopyWith<SimulatorEvent_ErrorOccurred> get copyWith => _$SimulatorEvent_ErrorOccurredCopyWithImpl<SimulatorEvent_ErrorOccurred>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorEvent_ErrorOccurred&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SimulatorEvent.errorOccurred(message: $message)';
}


}

/// @nodoc
abstract mixin class $SimulatorEvent_ErrorOccurredCopyWith<$Res> implements $SimulatorEventCopyWith<$Res> {
  factory $SimulatorEvent_ErrorOccurredCopyWith(SimulatorEvent_ErrorOccurred value, $Res Function(SimulatorEvent_ErrorOccurred) _then) = _$SimulatorEvent_ErrorOccurredCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SimulatorEvent_ErrorOccurredCopyWithImpl<$Res>
    implements $SimulatorEvent_ErrorOccurredCopyWith<$Res> {
  _$SimulatorEvent_ErrorOccurredCopyWithImpl(this._self, this._then);

  final SimulatorEvent_ErrorOccurred _self;
  final $Res Function(SimulatorEvent_ErrorOccurred) _then;

/// Create a copy of SimulatorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SimulatorEvent_ErrorOccurred(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SimulatorUpdate {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorUpdate&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'SimulatorUpdate(field0: $field0)';
}


}

/// @nodoc
class $SimulatorUpdateCopyWith<$Res>  {
$SimulatorUpdateCopyWith(SimulatorUpdate _, $Res Function(SimulatorUpdate) __);
}


/// Adds pattern-matching-related methods to [SimulatorUpdate].
extension SimulatorUpdatePatterns on SimulatorUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SimulatorUpdate_Event value)?  event,TResult Function( SimulatorUpdate_SensorData value)?  sensorData,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SimulatorUpdate_Event() when event != null:
return event(_that);case SimulatorUpdate_SensorData() when sensorData != null:
return sensorData(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SimulatorUpdate_Event value)  event,required TResult Function( SimulatorUpdate_SensorData value)  sensorData,}){
final _that = this;
switch (_that) {
case SimulatorUpdate_Event():
return event(_that);case SimulatorUpdate_SensorData():
return sensorData(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SimulatorUpdate_Event value)?  event,TResult? Function( SimulatorUpdate_SensorData value)?  sensorData,}){
final _that = this;
switch (_that) {
case SimulatorUpdate_Event() when event != null:
return event(_that);case SimulatorUpdate_SensorData() when sensorData != null:
return sensorData(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SimulatorEvent field0)?  event,TResult Function( SensorData field0)?  sensorData,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SimulatorUpdate_Event() when event != null:
return event(_that.field0);case SimulatorUpdate_SensorData() when sensorData != null:
return sensorData(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SimulatorEvent field0)  event,required TResult Function( SensorData field0)  sensorData,}) {final _that = this;
switch (_that) {
case SimulatorUpdate_Event():
return event(_that.field0);case SimulatorUpdate_SensorData():
return sensorData(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SimulatorEvent field0)?  event,TResult? Function( SensorData field0)?  sensorData,}) {final _that = this;
switch (_that) {
case SimulatorUpdate_Event() when event != null:
return event(_that.field0);case SimulatorUpdate_SensorData() when sensorData != null:
return sensorData(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class SimulatorUpdate_Event extends SimulatorUpdate {
  const SimulatorUpdate_Event(this.field0): super._();
  

@override final  SimulatorEvent field0;

/// Create a copy of SimulatorUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorUpdate_EventCopyWith<SimulatorUpdate_Event> get copyWith => _$SimulatorUpdate_EventCopyWithImpl<SimulatorUpdate_Event>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorUpdate_Event&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'SimulatorUpdate.event(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $SimulatorUpdate_EventCopyWith<$Res> implements $SimulatorUpdateCopyWith<$Res> {
  factory $SimulatorUpdate_EventCopyWith(SimulatorUpdate_Event value, $Res Function(SimulatorUpdate_Event) _then) = _$SimulatorUpdate_EventCopyWithImpl;
@useResult
$Res call({
 SimulatorEvent field0
});


$SimulatorEventCopyWith<$Res> get field0;

}
/// @nodoc
class _$SimulatorUpdate_EventCopyWithImpl<$Res>
    implements $SimulatorUpdate_EventCopyWith<$Res> {
  _$SimulatorUpdate_EventCopyWithImpl(this._self, this._then);

  final SimulatorUpdate_Event _self;
  final $Res Function(SimulatorUpdate_Event) _then;

/// Create a copy of SimulatorUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(SimulatorUpdate_Event(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as SimulatorEvent,
  ));
}

/// Create a copy of SimulatorUpdate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SimulatorEventCopyWith<$Res> get field0 {
  
  return $SimulatorEventCopyWith<$Res>(_self.field0, (value) {
    return _then(_self.copyWith(field0: value));
  });
}
}

/// @nodoc


class SimulatorUpdate_SensorData extends SimulatorUpdate {
  const SimulatorUpdate_SensorData(this.field0): super._();
  

@override final  SensorData field0;

/// Create a copy of SimulatorUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SimulatorUpdate_SensorDataCopyWith<SimulatorUpdate_SensorData> get copyWith => _$SimulatorUpdate_SensorDataCopyWithImpl<SimulatorUpdate_SensorData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SimulatorUpdate_SensorData&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'SimulatorUpdate.sensorData(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $SimulatorUpdate_SensorDataCopyWith<$Res> implements $SimulatorUpdateCopyWith<$Res> {
  factory $SimulatorUpdate_SensorDataCopyWith(SimulatorUpdate_SensorData value, $Res Function(SimulatorUpdate_SensorData) _then) = _$SimulatorUpdate_SensorDataCopyWithImpl;
@useResult
$Res call({
 SensorData field0
});




}
/// @nodoc
class _$SimulatorUpdate_SensorDataCopyWithImpl<$Res>
    implements $SimulatorUpdate_SensorDataCopyWith<$Res> {
  _$SimulatorUpdate_SensorDataCopyWithImpl(this._self, this._then);

  final SimulatorUpdate_SensorData _self;
  final $Res Function(SimulatorUpdate_SensorData) _then;

/// Create a copy of SimulatorUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(SimulatorUpdate_SensorData(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as SensorData,
  ));
}


}

// dart format on
