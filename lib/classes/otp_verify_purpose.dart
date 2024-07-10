import 'package:flutter/material.dart';

class OtpVerifyPurpose {
  const OtpVerifyPurpose(this.verifyPurposeName);

  final String verifyPurposeName;

  static const OtpVerifyPurpose FIRSTTIMELOGIN =
      OtpVerifyPurpose('firstTimeLogin');
  static const OtpVerifyPurpose REGISTRATION = OtpVerifyPurpose('registration');
  static const OtpVerifyPurpose CHANGEPASSWORD =
      OtpVerifyPurpose('changePassword');
  static const OtpVerifyPurpose RESETPASSWORD =
      OtpVerifyPurpose('resetPassword');
}
