class SentOTPBean {
  final String otpRefNo;
  final int resendIntervalInMins;
  final int otpMaxReattempt;
  SentOTPBean({
    required this.otpRefNo,
    required this.resendIntervalInMins,
    required this.otpMaxReattempt,
  });
}