/// enum 의 `.name` 문자열로 값을 역조회. 일치 항목 없거나 null 이면 [fallback] 반환.
T enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
