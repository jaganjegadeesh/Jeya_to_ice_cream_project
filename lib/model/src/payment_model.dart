class PaymentModel {
  final String date;
  final String paymentId;
  final String partyId;
  final String partyName;
  final String paymentType;
  final String credit;
  final String debit;
  final String createdDateTime;
  final String updateDateTime;

  PaymentModel({
    required this.date,
    required this.paymentId,
    required this.partyId,
    required this.partyName,
    required this.paymentType,
    required this.credit,
    required this.debit,
    required this.updateDateTime,
    required this.createdDateTime,
  });


   factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      date: json['date'] ?? '',
      paymentId: json['paymentId'] ?? '',
      partyId: json['partyId'] ?? '',
      partyName: json['partyName'] ?? '',
      paymentType: json['paymentType'] ?? '',
      credit: json['credit'] ?? '',
      debit: json['debit'] ?? '',
      updateDateTime: json['updateDateTime'] ?? '',
      createdDateTime: json['createdDateTime'] ?? '',
    );
  }
  
}
