class Ppe {
  Ppe._();

  static const required = <String>[
    'helmet',
    'glasses',
    'gloves',
    'shoes',
    'safety-vest',
  ];

  static const safe = 'SAFE';
  static const notSafe = 'NOT_SAFE';
  static const offline = 'OFFLINE';

  static String thai(String key) {
    switch (key.trim().toLowerCase().replaceAll('_', '-')) {
      case 'helmet':
        return 'หมวกนิรภัย';
      case 'glasses':
        return 'แว่นตานิรภัย';
      case 'gloves':
        return 'ถุงมือนิรภัย';
      case 'shoes':
        return 'รองเท้านิรภัย';
      case 'safety-vest':
      case 'vest':
        return 'เสื้อสะท้อนแสง';
      default:
        return key;
    }
  }
}
