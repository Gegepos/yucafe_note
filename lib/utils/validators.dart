class Validators {
  static String? username(String? value) {
    if (value == null || value.isEmpty) return '用户名不能为空';
    if (value.length > 50) return '用户名不超过50个字符';
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) return '用户名仅允许大小写字母和数字';
    return null;
  }

  static String? nickname(String? value) {
    if (value == null || value.isEmpty) return '昵称不能为空';
    if (!RegExp(r'^[\u4e00-\u9fa5A-Za-z]+$').hasMatch(value)) return '昵称仅允许中文和英文';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return '密码不能为空';
    if (value.length < 6 || value.length > 20) return '密码长度6-20位';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return '请确认密码';
    if (value != password) return '两次密码不一致';
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName不能为空';
    return null;
  }

  static String? positiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName不能为空';
    final n = double.tryParse(value);
    if (n == null || n < 0) return '$fieldName必须为非负数';
    return null;
  }
}
