import '../models/branch_model.dart';

abstract class BranchState {}

class BranchInitial extends BranchState {}

class BranchLoading extends BranchState {}

class BranchLoaded extends BranchState {
  final List<Branch> branches;
  final Branch? selectedBranch;

  BranchLoaded({
    required this.branches,
    this.selectedBranch,
  });
}

class BranchError extends BranchState {
  final String message;

  BranchError(this.message);
}
