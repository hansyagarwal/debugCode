import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'registration_bloc_event.dart';
part 'registration_bloc_state.dart';

class RegistrationBlocBloc extends Bloc<RegistrationBlocEvent, RegistrationBlocState> {
  RegistrationBlocBloc() : super(RegistrationBlocInitial()) {
    on<RegistrationBlocEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
