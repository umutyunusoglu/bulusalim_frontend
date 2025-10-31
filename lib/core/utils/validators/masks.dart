String maskPhone(String phone) {
  try {
    if (phone.length <= 4) return phone;
    final last = phone.substring(phone.length - 4);
    return '****$last';
  } catch (_) {
    return phone;
  }
}
