class SendOTPBean {
  final String mobileNo;
  final String userId;
  final String option;
  final String email;
  SendOTPBean({
    required this.mobileNo,
    required this.userId,
    required this.option,
    required this.email,
  });
}