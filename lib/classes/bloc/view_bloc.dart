import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'view_event.dart';
part 'view_state.dart';

class ViewBloc extends Bloc<ViewEvent, ViewState> {
  ViewBloc() : super(ViewInitial()) {
    on<ViewEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
