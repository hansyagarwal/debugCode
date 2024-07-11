import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'registration_event.dart';
part 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {

  RegistrationBloc() : super(RegistrationInitial()) {
    on<SendVerificationEmailEvent>(sendValidationEmail as EventHandler<SendVerificationEmailEvent, RegistrationState>);
    on<AccountActivationEvent>(accountActivation as EventHandler<AccountActivationEvent, RegistrationState>);
  }

  bool sendValidationEmail(String userId,String email,BuildContext ctx){
    return true;
  }

  bool accountActivation(String userId, String s, BuildContext context){
    return true;
  }
}
