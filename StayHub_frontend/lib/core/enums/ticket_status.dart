enum TicketStatus {
  newTicket('NEW'),
  assigned('ASSIGNED'),
  processing('PROCESSING'),
  completed('COMPLETED'),
  pendingOwnerReview('PENDING_OWNER_REVIEW'),
  closed('CLOSED'),
  cancelled('CANCELLED');

  final String value;
  const TicketStatus(this.value);

  static TicketStatus fromString(String val) {
    return TicketStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TicketStatus.newTicket,
    );
  }
}
