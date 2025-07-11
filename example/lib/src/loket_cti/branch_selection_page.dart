import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sip_ua/sip_ua.dart';
import 'bloc/branch_bloc.dart';
import 'bloc/branch_event.dart';
import 'bloc/branch_state.dart';
import 'models/branch_model.dart';
import 'call_page.dart';

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
  }

  @override
  void dispose() {
    _branchBloc.close();
    super.dispose();
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
                    // HEADER
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Anita',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              Text('511611',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.circle, color: Colors.green, size: 12),
                              SizedBox(width: 4),
                              Text('Registered',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // CARD
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
                                    return Column(
                                      children: [
                                        DropdownButtonFormField<Branch>(
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          isExpanded: true,
                                          value: state.selectedBranch,
                                          items: state.branches
                                              .map((branch) => DropdownMenuItem(
                                                    value: branch,
                                                    child: Text(branch.name),
                                                  ))
                                              .toList(),
                                          onChanged: (branch) {
                                            if (branch != null) {
                                              context
                                                  .read<BranchBloc>()
                                                  .add(SelectBranch(branch));
                                            }
                                          },
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
                                              if (state.selectedBranch !=
                                                  null) {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/call-page',
                                                  arguments: {
                                                    'branch':
                                                        state.selectedBranch,
                                                  },
                                                );

                                                // Navigator.pushNamed(
                                                //     context, '/call-page',
                                                //     arguments: call);
                                              }
                                            },
                                            child: const Text(
                                              'Pilih Cabang',
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
