enum RoomStatus {
  trong('TRONG'),
  daThue('DA_THUE'),
  baoTri('BAO_TRI'),
  dongCua('DONG_CUA'),
  cleaningTurnover('CLEANING_TURNOVER'),
  choKichHoat('CHO_KICH_HOAT'),
  choDuyet('CHO_DUYET');

  final String value;
  const RoomStatus(this.value);

  static RoomStatus fromString(String val) {
    return RoomStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => RoomStatus.trong,
    );
  }
}
