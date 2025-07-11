import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/branch_model.dart';
import 'branch_event.dart';
import 'branch_state.dart';

class BranchBloc extends Bloc<BranchEvent, BranchState> {
  BranchBloc() : super(BranchInitial()) {
    on<LoadBranches>(_onLoadBranches);
    on<SelectBranch>(_onSelectBranch);
  }

  void _onLoadBranches(LoadBranches event, Emitter<BranchState> emit) async {
    emit(BranchLoading());
    await Future.delayed(Duration(milliseconds: 500)); // Simulasi loading

    final branches = [
      Branch(id: '1', name: 'GRUS PUSAT INDONESIA'),
      Branch(id: '2', name: 'CABANG JAKARTA'),
      Branch(id: '3', name: 'CABANG BANDUNG'),
    ];

    emit(BranchLoaded(branches));
  }

  void _onSelectBranch(SelectBranch event, Emitter<BranchState> emit) {
    if (state is BranchLoaded) {
      final current = state as BranchLoaded;
      emit(BranchLoaded(current.branches, selectedBranch: event.branch));
    }
  }
}
