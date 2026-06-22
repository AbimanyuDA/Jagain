class PejabatDashboardRepository {
  static ({String level, String? provinsi, String? kota}) parseWilayah(
      String wilayah) {
    final parts = wilayah.split(' -> ');
    switch (parts.length) {
      case >= 3:
        return (level: 'kota', provinsi: parts[1], kota: parts[0]);
      case 2:
        return (level: 'provinsi', provinsi: parts[0], kota: null);
      default:
        return (level: 'pusat', provinsi: null, kota: null);
    }
  }
}
