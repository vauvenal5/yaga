abstract class Preference {
  String key;
  String title;
  bool enabled;

  Preference(this.key, this.title, {String prefix, this.enabled = true}) {
    if (prefix != null) {
      this.key = prefix + ":" + this.key;
    }
  }
}