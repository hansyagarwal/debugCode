import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'otp_event.dart';
part 'otp_state.dart';

class OTPBloc extends Bloc<OTPEvent, OTPState> {
  OTPBloc() : super(OtpInitial()) {
    on<OTPEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
