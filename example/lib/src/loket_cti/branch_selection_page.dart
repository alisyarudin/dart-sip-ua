import 'package:dart_sip_ua_example/src/branch_storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sip_ua/sip_ua.dart';
import 'bloc/branch_bloc.dart';
import 'bloc/branch_event.dart';
import 'bloc/branch_state.dart';
import 'models/branch_model.dart';

class BranchSelectionPage extends StatefulWidget {
  final SIPUAHelper? helper;

  const BranchSelectionPage(this.helper, {Key? key}) : super(key: key);

  @override
  State<BranchSelectionPage> createState() => _BranchSelectionPageState();
}

class _BranchSelectionPageState extends State<BranchSelectionPage> {
  late final BranchBloc _branchBloc;

  @override
  void initState() {
    super.initState();
    _branchBloc = BranchBloc()..add(LoadBranches());

    _autoRegisterIfNeeded(); // ✅ tambahkan ini
  }

  Future<void> _autoRegisterIfNeeded() async {
    final savedBranch = await BranchStorageHelper.loadBranch();
    if (savedBranch != null) {
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/call-page',
          arguments: {'branch': savedBranch},
        );
      }
    }
  }

  @override
  void dispose() {
    _branchBloc.close();
    super.dispose();
  }

  void _showBranchSelectionSheet(
      BuildContext outerContext, List<Branch> branches) {
    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final branchBloc = BlocProvider.of<BranchBloc>(outerContext);
        final selectedBranch = branchBloc.state is BranchLoaded
            ? (branchBloc.state as BranchLoaded).selectedBranch
            : null;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Cabang',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: branches.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      final isSelected = selectedBranch?.id == branch.id;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: isSelected
                            ? Colors.blue.shade50
                            : Colors.transparent,
                        title: Text(
                          branch.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(outerContext).primaryColor
                                : Colors.black,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check,
                                color: Theme.of(outerContext).primaryColor)
                            : null,
                        onTap: () {
                          branchBloc.add(SelectBranch(branch));
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _branchBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 160,
                      left: 24,
                      right: 24,
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 32, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset('assets/logo_175.png', height: 80),
                              const SizedBox(height: 16),
                              const Text(
                                'Selamat Datang',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Silahkan memilih area cabang yang ingin anda hubungi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 24),
                              BlocBuilder<BranchBloc, BranchState>(
                                builder: (context, state) {
                                  if (state is BranchLoading) {
                                    return const CircularProgressIndicator();
                                  } else if (state is BranchLoaded) {
                                    final selected = state.selectedBranch;
                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () =>
                                              _showBranchSelectionSheet(
                                                  context, state.branches),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16, horizontal: 12),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade400),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Colors.grey.shade100,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  selected?.name ??
                                                      'Pilih Cabang',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: selected != null
                                                        ? Colors.black
                                                        : Colors.grey,
                                                  ),
                                                ),
                                                const Icon(
                                                    Icons.keyboard_arrow_down),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF2196F3),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              if (selected != null) {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/call-page',
                                                  arguments: {
                                                    'branch': selected,
                                                  },
                                                );
                                              }
                                            },
                                            child: const Text(
                                              'Panggil Cabang',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
