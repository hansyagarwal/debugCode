part of 'registration_bloc.dart';

@immutable
sealed class RegistrationEvent {}

class SendVerificationEmailEvent extends RegistrationEvent{}

class AccountActivationEvent extends RegistrationEvent{}
