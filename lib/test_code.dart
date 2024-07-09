import 'package:flutter/material.dart';
import 'package:otp_debug/model/login_model.dart';
import 'package:otp_debug/model/registration_model.dart';

// Define enums for OtpOption and OtpVerifyPurpose
enum OtpOption { PHONE }

enum OtpVerifyPurpose {
  FIRSTTIMELOGIN,
  REGISTRATION,
  CHANGEPASSWORD,
  RESETPASSWORD
}

class OnboardingOtpScreen extends StatefulWidget {
  final String mobileNo;
  final String userId;
  final String email;
  final String password;
  final UserProfileBean? userProfileBean;
  final RegistrationBean? registrationBean;
  final OtpOption option;
  final OtpVerifyPurpose otpVerifyPurpose;

  OnboardingOtpScreen({
    Key? key,
    required this.mobileNo,
    required this.userId,
    required this.email,
    required this.password,
    this.userProfileBean,
    this.registrationBean,
    this.option = OtpOption.PHONE,
    this.otpVerifyPurpose = OtpVerifyPurpose.FIRSTTIMELOGIN,
  }) : super(key: key);

  @override
  State<OnboardingOtpScreen> createState() => _OnboardingOtpScreenState();
}

class _OnboardingOtpScreenState extends State<OnboardingOtpScreen> {
  late RegistrationBloc _registrationBloc;
  late UserBloc _userBloc;
  late OTPBloc _otpBloc;
  late SendOTPBean _sendOTPBean;
  SentOTPBean? _sentOTPBean;
  String errorText = "";
  late OtpFieldController _otpFieldController;
  bool countingDown = false;

  @override
  void initState() {
    super.initState();
    _registrationBloc = RegistrationBloc();
    _otpBloc = OTPBloc();
    _userBloc = UserBloc();
    _otpFieldController = OtpFieldController(onVerify: verifyOTP);
    _sendOTPBean = SendOTPBean(
      mobileNo: widget.mobileNo,
      userId: widget.userId,
      option: widget.option.optionName,
      email: widget.email,
    );

    // Initialize OTP sending only in release mode
    if (kReleaseMode) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _initSendOtp();
      });
    }
  }

  @override
  void dispose() {
    _registrationBloc.close();
    _otpBloc.close();
    _userBloc.close();
    super.dispose();
  }

  Future<void> _initSendOtp() async {
    try {
      final loadingDialog =
          ViewBloc.showLoadingDialog(context, "Sending OTP...");
      final result = await _otpBloc.sendOtp(_sendOTPBean);
      loadingDialog.dismiss(() {});

      if (result is SentOTPBean) {
        setState(() {
          _sentOTPBean = result;
          countingDown = true;
          errorText = "";
        });
      } else {
        setState(() {
          errorText = result.toString();
        });
      }
    } catch (e) {
      setState(() {
        errorText = "Failed to send OTP: $e";
      });
    }
  }

  Future<void> verifyOTP(String otpValue) async {
    try {
      bool verifyResult = true;

      // Verify OTP only in release mode
      if (kReleaseMode) {
        final loadingDialog =
            ViewBloc.showLoadingDialog(context, "Verifying OTP...");
        verifyResult = await _otpBloc.verifyOtp(
          otpValue,
          _sendOTPBean.userId,
          _sentOTPBean ??
              SentOTPBean(
                  otpRefNo: "", resendIntervalInMins: 0, otpMaxReattempt: 0),
          context,
          (errMsg) {
            setState(() {
              errorText = errMsg;
            });
          },
        );
        loadingDialog.dismiss(() {});
      }

      if (verifyResult || kDebugMode) {
        await ViewBloc.showSuccessDialogForAwhile(context,
            successMessage: "OTP Verified!");

        // Perform different actions based on otpVerifyPurpose
        switch (widget.otpVerifyPurpose) {
          case OtpVerifyPurpose.REGISTRATION:
            await processForRegistration();
            break;
          case OtpVerifyPurpose.FIRSTTIMELOGIN:
            await processForFirstTimeLogin();
            break;
          case OtpVerifyPurpose.CHANGEPASSWORD:
            await processForChangePassword();
            break;
          case OtpVerifyPurpose.RESETPASSWORD:
            await processForResetPassword();
            break;
        }
      } else {
        _otpFieldController.verifyUnsuccessful();
      }
    } catch (e) {
      setState(() {
        errorText = "Failed to verify OTP: $e";
      });
    }
  }

  Future<void> processForRegistration() async {
    try {
      bool isCustomer = widget.registrationBean?.isCustomer ?? false;
      if (!isCustomer) {
        final result = await _registrationBloc.sendValidationEmail(
          _sendOTPBean.userId,
          _sendOTPBean.email ?? "",
          context,
        );

        if (result) {
          await ViewBloc.showAlertDialog(
            context,
            title: "Email Verification",
            content: "Verification email sent successfully.",
            positiveText: "OK",
            onPressedPositive: () {
              Navigator.pop(context, true);
            },
          );
          Navigator.pop(context);
        } else {
          Navigator.pop(context);
        }
      } else {
        final result = await _registrationBloc.accountActivation(
          _sendOTPBean.userId,
          _sendOTPBean.email ?? "",
          context,
        );

        if (result) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SuccessScreen(
                title: "Registration Success",
                description: "Your account has been successfully registered.",
              ),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        errorText = "Failed to process registration: $e";
      });
    }
  }

  Future<void> processForFirstTimeLogin() async {
    try {
      if (widget.userProfileBean != null) {
        await _userBloc.saveUserToDB(widget.userProfileBean!);
        await _userBloc.saveToken(
          widget.userProfileBean!.loginAccessToken?.accessToken ?? "",
          widget.userProfileBean!.loginAccessToken?.refreshToken ?? "",
          widget.userProfileBean!.loginAccessToken?.expiresIn ?? 0,
        );
        _userBloc.changeIPushUserId();

        await ViewBloc.showSuccessDialogForAwhile(
          context,
          successMessage: "First-time login successful!",
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(
              title: "Verification Success",
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorText = "Failed first-time login: $e";
      });
    }
  }

  Future<void> processForResetPassword() async {
    Navigator.popAndPush(
      context,
      MaterialPageRoute(
        builder: (context) => NewPasswordScreen(
          isFirstStep: false,
          userId: widget.userId,
        ),
      ),
    );
  }

  Future<void> processForChangePassword() async {
    Navigator.popAndPush(
      context,
      MaterialPageRoute(
        builder: (context) => NewPasswordScreen(
          isFirstStep: false,
          userId: widget.userId,
          inAppChangePassword: true,
        ),
      ),
    );
  }

  Future<bool> showTerminateDialog() async {
    final result = await ViewBloc.showAlertDialog(
      context,
      title: "Confirmation",
      content: "Are you sure you want to terminate?",
      positiveText: "Yes",
      onPressedPositive: () {
        Navigator.pop(context, true);
      },
      negativeText: "No",
      onPressedNegative: () {
        Navigator.pop(context, false);
      },
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: showTerminateDialog,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Verification"),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              final result = await showTerminateDialog();
              if (result) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "${widget.otpVerifyPurpose.toString().split('.').last} Verification",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "Enter the OTP sent to ${widget.mobileNo}.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              Text(
                errorText,
                style: TextStyle(fontSize: 14, color: Colors.red),
              ),
              SizedBox(height: 8),
              OtpField(
                otpFieldController: _otpFieldController,
              ),
              SizedBox(height: 15),
              Visibility(
                visible: countingDown,
                child: Text(
                  "OTP has been sent to ${widget.mobileNo}.",
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
              SizedBox(height: 30),
              Align(
                alignment: Alignment.center,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'Didn\'t get the code? ',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                    children: [
                      TextSpan(
                        text: "Resend OTP",
                        style: TextStyle(
                          fontSize: 18,
                          color: countingDown
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.blue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = countingDown
                              ? null
                              : () async {
                                  await _initSendOtp();
                                },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Visibility(
                visible: countingDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Resend in ",
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    CustomTimer(
                      seconds: 305,
                      onFinished: () {
                        setState(() {
                          countingDown = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
