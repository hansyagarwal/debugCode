class LoginAccessToken {
  LoginAccessToken(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresIn});

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
}
