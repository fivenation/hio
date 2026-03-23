class GameSettings {
  static double mouseSensitivity = 0.008;

  static void setMouseSensitivity(double value) {
    mouseSensitivity = value.clamp(0.002, 0.03);
  }
}
