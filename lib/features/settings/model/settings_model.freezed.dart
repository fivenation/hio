// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SettingsModel {
  double get mouseSensitivity => throw _privateConstructorUsedError;
  bool get fullscreen => throw _privateConstructorUsedError;
  int get resolutionIndex => throw _privateConstructorUsedError;
  KeyBindings get keyBindings => throw _privateConstructorUsedError;
  List<Resolution> get resolutions => throw _privateConstructorUsedError;

  /// Create a copy of SettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SettingsModelCopyWith<SettingsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsModelCopyWith<$Res> {
  factory $SettingsModelCopyWith(
          SettingsModel value, $Res Function(SettingsModel) then) =
      _$SettingsModelCopyWithImpl<$Res, SettingsModel>;
  @useResult
  $Res call(
      {double mouseSensitivity,
      bool fullscreen,
      int resolutionIndex,
      KeyBindings keyBindings,
      List<Resolution> resolutions});

  $KeyBindingsCopyWith<$Res> get keyBindings;
}

/// @nodoc
class _$SettingsModelCopyWithImpl<$Res, $Val extends SettingsModel>
    implements $SettingsModelCopyWith<$Res> {
  _$SettingsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mouseSensitivity = null,
    Object? fullscreen = null,
    Object? resolutionIndex = null,
    Object? keyBindings = null,
    Object? resolutions = null,
  }) {
    return _then(_value.copyWith(
      mouseSensitivity: null == mouseSensitivity
          ? _value.mouseSensitivity
          : mouseSensitivity // ignore: cast_nullable_to_non_nullable
              as double,
      fullscreen: null == fullscreen
          ? _value.fullscreen
          : fullscreen // ignore: cast_nullable_to_non_nullable
              as bool,
      resolutionIndex: null == resolutionIndex
          ? _value.resolutionIndex
          : resolutionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      keyBindings: null == keyBindings
          ? _value.keyBindings
          : keyBindings // ignore: cast_nullable_to_non_nullable
              as KeyBindings,
      resolutions: null == resolutions
          ? _value.resolutions
          : resolutions // ignore: cast_nullable_to_non_nullable
              as List<Resolution>,
    ) as $Val);
  }

  /// Create a copy of SettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $KeyBindingsCopyWith<$Res> get keyBindings {
    return $KeyBindingsCopyWith<$Res>(_value.keyBindings, (value) {
      return _then(_value.copyWith(keyBindings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SettingsModelImplCopyWith<$Res>
    implements $SettingsModelCopyWith<$Res> {
  factory _$$SettingsModelImplCopyWith(
          _$SettingsModelImpl value, $Res Function(_$SettingsModelImpl) then) =
      __$$SettingsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double mouseSensitivity,
      bool fullscreen,
      int resolutionIndex,
      KeyBindings keyBindings,
      List<Resolution> resolutions});

  @override
  $KeyBindingsCopyWith<$Res> get keyBindings;
}

/// @nodoc
class __$$SettingsModelImplCopyWithImpl<$Res>
    extends _$SettingsModelCopyWithImpl<$Res, _$SettingsModelImpl>
    implements _$$SettingsModelImplCopyWith<$Res> {
  __$$SettingsModelImplCopyWithImpl(
      _$SettingsModelImpl _value, $Res Function(_$SettingsModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mouseSensitivity = null,
    Object? fullscreen = null,
    Object? resolutionIndex = null,
    Object? keyBindings = null,
    Object? resolutions = null,
  }) {
    return _then(_$SettingsModelImpl(
      mouseSensitivity: null == mouseSensitivity
          ? _value.mouseSensitivity
          : mouseSensitivity // ignore: cast_nullable_to_non_nullable
              as double,
      fullscreen: null == fullscreen
          ? _value.fullscreen
          : fullscreen // ignore: cast_nullable_to_non_nullable
              as bool,
      resolutionIndex: null == resolutionIndex
          ? _value.resolutionIndex
          : resolutionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      keyBindings: null == keyBindings
          ? _value.keyBindings
          : keyBindings // ignore: cast_nullable_to_non_nullable
              as KeyBindings,
      resolutions: null == resolutions
          ? _value._resolutions
          : resolutions // ignore: cast_nullable_to_non_nullable
              as List<Resolution>,
    ));
  }
}

/// @nodoc

class _$SettingsModelImpl extends _SettingsModel {
  const _$SettingsModelImpl(
      {required this.mouseSensitivity,
      required this.fullscreen,
      required this.resolutionIndex,
      required this.keyBindings,
      required final List<Resolution> resolutions})
      : _resolutions = resolutions,
        super._();

  @override
  final double mouseSensitivity;
  @override
  final bool fullscreen;
  @override
  final int resolutionIndex;
  @override
  final KeyBindings keyBindings;
  final List<Resolution> _resolutions;
  @override
  List<Resolution> get resolutions {
    if (_resolutions is EqualUnmodifiableListView) return _resolutions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_resolutions);
  }

  @override
  String toString() {
    return 'SettingsModel(mouseSensitivity: $mouseSensitivity, fullscreen: $fullscreen, resolutionIndex: $resolutionIndex, keyBindings: $keyBindings, resolutions: $resolutions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsModelImpl &&
            (identical(other.mouseSensitivity, mouseSensitivity) ||
                other.mouseSensitivity == mouseSensitivity) &&
            (identical(other.fullscreen, fullscreen) ||
                other.fullscreen == fullscreen) &&
            (identical(other.resolutionIndex, resolutionIndex) ||
                other.resolutionIndex == resolutionIndex) &&
            (identical(other.keyBindings, keyBindings) ||
                other.keyBindings == keyBindings) &&
            const DeepCollectionEquality()
                .equals(other._resolutions, _resolutions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      mouseSensitivity,
      fullscreen,
      resolutionIndex,
      keyBindings,
      const DeepCollectionEquality().hash(_resolutions));

  /// Create a copy of SettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsModelImplCopyWith<_$SettingsModelImpl> get copyWith =>
      __$$SettingsModelImplCopyWithImpl<_$SettingsModelImpl>(this, _$identity);
}

abstract class _SettingsModel extends SettingsModel {
  const factory _SettingsModel(
      {required final double mouseSensitivity,
      required final bool fullscreen,
      required final int resolutionIndex,
      required final KeyBindings keyBindings,
      required final List<Resolution> resolutions}) = _$SettingsModelImpl;
  const _SettingsModel._() : super._();

  @override
  double get mouseSensitivity;
  @override
  bool get fullscreen;
  @override
  int get resolutionIndex;
  @override
  KeyBindings get keyBindings;
  @override
  List<Resolution> get resolutions;

  /// Create a copy of SettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SettingsModelImplCopyWith<_$SettingsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
