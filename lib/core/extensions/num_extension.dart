extension NumExtensions on num {
  double get toDouble => this.toDouble();
  int get toInt => this.toInt();
  Duration get seconds => Duration(seconds: this.toInt());
}
extension IntExtensions on int {
  double get toDouble => this.toDouble();
}

extension DoubleExtensions on double {
  int get toInt => this.toInt();
  num get numerate => this as num ;
}