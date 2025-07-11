import '../models/branch_model.dart';

abstract class BranchEvent {}

class LoadBranches extends BranchEvent {}

class SelectBranch extends BranchEvent {
  final Branch branch;

  SelectBranch(this.branch);
}
