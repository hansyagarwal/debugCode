import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp_debug/classes/bloc/bloc/otp_bloc.dart';
import 'package:otp_debug/classes/bloc/bloc/registration_bloc.dart';
import 'package:otp_debug/classes/bloc/bloc/user_bloc.dart';
import 'package:otp_debug/classes/models/sent_otp_bean.dart';
import 'package:otp_debug/classes/nui_navigator.dart';
import 'package:otp_debug/classes/otp_option.dart';
import 'package:otp_debug/classes/otp_verify_purpose.dart';
import 'package:otp_debug/classes/registration_bean.dart';
import 'package:otp_debug/classes/models/send_otp_bean.dart';
import 'package:otp_debug/classes/ui_theme.dart';
import 'package:otp_debug/classes/user_profile_bean.dart';
import 'package:otp_debug/custom_timer.dart';
import 'package:otp_debug/screens/base_screen.dart';
import 'package:otp_debug/screens/new_password_screen.dart';
import 'package:otp_debug/screens/success_screen.dart';

class OnboardingOtpScreen extends StatefulWidget {
  OnboardingOtpScreen(
      {Key? key,
      required this.mobileNo,
      required this.userId,
      required this.email,
      required this.password,
      this.userProfileBean,
      this.registrationBean,
      this.option = OtpOption.PHONE,
      this.otpVerifyPurpose = OtpVerifyPurpose.FIRSTTIMELOGIN})
      : super(key: key);
  String mobileNo;
  String userId;
  String email;
  String password;
  // For Login
  UserProfileBean? userProfileBean;
  // For Registration
  RegistrationBean? registrationBean;
  OtpOption option;
  OtpVerifyPurpose otpVerifyPurpose;

  @override
  State<OnboardingOtpScreen> createState() => _OnboardingOtpScreenState();
}

class _OnboardingOtpScreenState extends State<OnboardingOtpScreen> {
  final uiTheme = UITheme(
    accentBlue: UIColorPair(light: Color(0xFF1E88E5), dark: Color(0xFF0D47A1)),
    darkBlue: UIColorPair(light: Color(0xFF1565C0), dark: Color(0xFF0D47A1)),
    greyTwo: UIColorPair(light: Color(0xFFBDBDBD), dark: Color(0xFF616161)),
    red: UIColorPair(light: Color(0xFFD32F2F), dark: Color(0xFFB71C1C)),
  );

  late RegistrationBloc _registrationBloc;
  late UserBloc _userBloc;
  late OTPBloc _otpBloc;
  late SendOTPBean _sendOTPBean;
  SentOTPBean? _sentOTPBean;
  late String errorText;
  String? activationErrorText;
  late OtpFieldController _otpFieldController;
  bool countingDown = false;

  @override
  void initState() {
    super.initState();
    errorText = "";
    _registrationBloc = RegistrationBloc();
    _otpBloc = OTPBloc();
    _userBloc = UserBloc();
    _otpFieldController = OtpFieldController(onVerify: (otpValue) {
      verifyOTP(otpValue);
    });
    _sendOTPBean = SendOTPBean(
        mobileNo: widget.mobileNo,
        userId: widget.userId,
        option: widget.option.optionName,
        email: widget.email);

    if (kReleaseMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _initSendOtp();
      });
    }
  }

  _initSendOtp() async {
    //TODO: Currently By Pass OTP, OTP Integration Testing Successful. Uncomment this before compile
    final loadingDialog = ViewBloc.showLoadingDialog(context,
        "${mtl("otpSending")}${StringUtil.maskString(widget.mobileNo)}");
    dynamic result = await _otpBloc.sendOtp(_sendOTPBean);
    await Future.delayed(const Duration(milliseconds: 80));
    loadingDialog.dismiss(() {});
    // If OTP sent successful, it will return SentOTPBean else it's a error message
    if (result.runtimeType == SentOTPBean) {
      _sentOTPBean = result;
      setState(() {
        countingDown = true;
        errorText = "";
      });
    } else {
      setState(() {
        errorText = result.toString();
      });
    }
  }

  // In debug mode, no OTP is required.
  Future<void> verifyOTP(String otpValue) async {
    bool verifyResult = true;
    // If it's in release mode, this should be execute to verify the OTP
    if (kReleaseMode) {
      final loadingDialog =
          ViewBloc.showLoadingDialog(context, mtl("otpVerifying"));
      verifyResult = await _otpBloc.verifyOtp(
          otpValue,
          _sendOTPBean.userId,
          _sentOTPBean ??
              SentOTPBean(
                  otpRefNo: "", resendIntervalInMins: 0, otpMaxReattempt: 0),
          context, (errMsg) {
        setState(() {
          errorText = errMsg;
        });
      });
      await Future.delayed(const Duration(milliseconds: 2000));
      loadingDialog.dismiss(() {});
    }
    // In debug mode, this checking will always true
    if (verifyResult || kDebugMode) {
      await ViewBloc.showSuccessDialogForAwhile(context,
          successMessage: mtl("otpVerified"));
      //After verification success, different process for firs-time login and registration
      if (widget.otpVerifyPurpose.verifyPurposeName ==
          OtpVerifyPurpose.REGISTRATION.verifyPurposeName) {
        processForRegistration();
      } else if (widget.otpVerifyPurpose.verifyPurposeName ==
          OtpVerifyPurpose.FIRSTTIMELOGIN.verifyPurposeName) {
        processForFirstTimeLogin();
      } else if (widget.otpVerifyPurpose.verifyPurposeName ==
          OtpVerifyPurpose.CHANGEPASSWORD.verifyPurposeName) {
        processForChangePassword();
      } else {
        processForResetPassword();
      }
    } else {
      //Verification failed, delete all the text field and re-enter
      _otpFieldController.verifyUnsuccessful();
    }
  }

  Future<void> processForRegistration() async {
    bool isCustomer = widget.registrationBean?.isCustomer ?? false;
    if (!isCustomer) {
      final result = await _registrationBloc.sendValidationEmail(
          _sendOTPBean.userId, _sendOTPBean.email, context);
      if (result) {
        final completed = await ViewBloc.showAlertDialog(context,
            title:
                "${mtl("verifyEmailSuccess")} ${_sendOTPBean.email ?? ""}\n${mtl("verifyEmailSuccess2")}",
            illustration: loadSvg("pictogram/email.svg", color: null),
            positiveText: mtl("okButton"), onPressedPositive: () {
          NUINavigator.popWithResult(context, true);
        });
        if (completed) {
          NUINavigator.popAllAndPush(context, const BaseScreen());
        }
        return;
      } else {
        await Future.delayed(const Duration(milliseconds: 80));
        NUINavigator.popAllAndPush(context, const BaseScreen());
        return;
      }
    } else {
      final result = await _registrationBloc.accountActivation(
          _sendOTPBean.userId, _sendOTPBean.email ?? "", context);
      if (result) {
        await Future.delayed(const Duration(milliseconds: 80));
        NUINavigator.push(
            context,
            SuccessScreen(
                title: mtl("regisSuccess"),
                description: mtl("regisSuccessDesc"),
                illus: loadSvg("pictogram/correct_tick.svg", color: null),
                popAll: true) as Widget);
      } else {
        // Account activation failed, redirect to base screen
        await Future.delayed(const Duration(milliseconds: 80));
        NUINavigator.popAllAndPush(context, const BaseScreen());
      }
    }
  }

  Future<void> processForFirstTimeLogin() async {
    //First time login, user will only be saved once OTP success
    UserProfileBean? userProfileBean = widget.userProfileBean;
    if (userProfileBean != null) {
      try {
        await _userBloc.saveUserToDB(userProfileBean);
        await _userBloc.saveToken(
            userProfileBean.loginAccessToken?.accessToken ?? "",
            userProfileBean.loginAccessToken?.refreshToken ?? "",
            userProfileBean.loginAccessToken?.expiresIn ?? 0);
        _userBloc.changeIPushUserId();
        await Future.delayed(const Duration(milliseconds: 80));
        // await ViewBloc.showSuccessDialogForAwhile(context, successMessage: mtl("loginSuccessDialog"));
        NUINavigator.push(
            context, SuccessScreen(title: mtl("verifySuccess"), popAll: true) as Widget);
      } catch (e) {
        logNUI("Otp Screen", "First-time Login Error : $e");
        await ViewBloc.showFailedDialogForAwhile(
          context,
          errorMessage: mtl("loginUnsuccessfulDialog"),
        );
        NUINavigator.popAllAndPush(context, const BaseScreen());
      }
    }
  }

  Future<void> processForResetPassword() async {
    NUINavigator.popAndPush(
        context,
        NewPasswordScreen(
          isFirstStep: false,
          userId: widget.userId,
        ));
  }

  Future<void> processForChangePassword() async {
    NUINavigator.popAndPush(
        context,
        NewPasswordScreen(
            isFirstStep: false,
            userId: widget.userId,
            inAppChangePassword: true));
  }

  Future<bool> showTerminateDialog() async {
    final result = await ViewBloc.showAlertDialog(context,
        title:
            "${mtl("otpTerminateDialog")} ${widget.otpVerifyPurpose.name} ${mtl("otpTerminateDialog2")}",
        positiveText: mtl("yes"),
        onPressedPositive: () {
          NUINavigator.popWithResult(context, true);
        },
        negativeText: mtl("no"),
        onPressedNegative: () {
          NUINavigator.popWithResult(context, false);
        });
    return result;
  }

  String mtl(String title) {
    return title;
  }

  bool isNullOrEmpty(String str) {
    return str.isEmpty || str == null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showTerminateDialog();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppColors.BackgroundWhite,
            body: Column(
              children: [
                BackToolbar(
                  title: Text(
                    mtl("verification"),
                    style:
                        uiTheme.font(size: 18, colorPair: uiTheme.accentBlue),
                    textAlign: TextAlign.center,
                  ),
                  withShadow: true,
                  withStatusBar: true,
                  backButton: true,
                  backIcon: Icon(Icons.arrow_back_rounded,
                      color: uiTheme.color(uiTheme.accentBlue)),
                  onPressed: () async {
                    final result = await showTerminateDialog();
                    if (result) {
                      NUINavigator.pop(context);
                    }
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.otpVerifyPurpose.verifyPurposeName} ${mtl("verification")}",
                            style: uiTheme.font(
                                size: 18, colorPair: uiTheme.darkBlue),
                          ),
                          const Divider(height: 16),
                          Text(mtl("otpDesc"),
                              style: uiTheme.font(
                                  size: 16, colorPair: uiTheme.greyTwo)),
                          const Divider(height: 30),
                          Text(isNullOrEmpty(errorText) ? "" : errorText,
                              style: uiTheme.font(
                                  size: 14, colorPair: uiTheme.red)),
                          const Divider(height: 8),
                          OtpField(
                            otpFieldController: _otpFieldController,
                          ),
                          const Divider(height: 15),
                          Visibility(
                              visible: countingDown,
                              child: Text(
                                  "OTP has been sent to ${StringUtil.maskString(widget.mobileNo)}.",
                                  style: uiTheme.font(
                                      size: 14, colorPair: uiTheme.darkBlue))),
                          const Divider(height: 30),
                          Align(
                            alignment: Alignment.center,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                text: '${mtl("otpDidNotGetCode")}  ',
                                style: uiTheme.font(
                                    size: 18, colorPair: uiTheme.darkBlue),
                                children: [
                                  TextSpan(
                                    text: mtl("otpResend"),
                                    style: uiTheme.font(
                                        size: 18,
                                        color: countingDown
                                            ? uiTheme
                                                .color(uiTheme.accentBlue)
                                                .withOpacity(0.3)
                                            : uiTheme
                                                .color(uiTheme.accentBlue)),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = countingDown
                                          ? null
                                          : () async {
                                              await _initSendOtp();
                                            },
                                  )
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 8),
                          Visibility(
                              visible: countingDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Resend in ",
                                      style: uiTheme.font(
                                          size: 14,
                                          colorPair: uiTheme.darkBlue)),
                                  CustomTimer(
                                    seconds: 305,
                                    onFinished: () {
                                      countingDown = false;
                                      setState(() {});
                                    },
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

class AppColors {
  static const BackgroundWhite = Colors.white;
}

class StringUtil {
  static String maskString(String str) {
    return str;
  }
}
