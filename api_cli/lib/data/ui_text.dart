// Stub — only used for display extensions; not needed for API testing.
class UiText {
  static String userFullName(String f, String l) => '$f $l';
  static String initialsFromParts(String f, String l) => '$f$l';
  static String nodeTypeLabel(String name) => name;

  static const String open = 'open';
  static const String inProgress = 'inProgress';
  static const String resolved = 'resolved';
  static const String closed = 'closed';
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String urgent = 'urgent';

  static const String textField = 'text';
  static const String number = 'number';
  static const String textArea = 'textarea';
  static const String dropdown = 'dropdown';
  static const String multiSelect = 'multiselect';
  static const String checkbox = 'checkbox';
  static const String radioGroup = 'radio';
  static const String datePicker = 'date';
  static const String timePicker = 'time';
  static const String fileUpload = 'file';
  static const String imageUpload = 'image';
  static const String colorPicker = 'color';
  static const String switchText = 'switch';
  static const String table = 'table';
  static const String rating = 'rating';
  static const String signature = 'signature';

  static const String string = 'string';
  static const String integer = 'integer';
  static const String float = 'float';
  static const String boolean = 'boolean';
  static const String date = 'date';
  static const String dateTime = 'dateTime';
  static const String file = 'file';
  static const String reference = 'reference';
}
