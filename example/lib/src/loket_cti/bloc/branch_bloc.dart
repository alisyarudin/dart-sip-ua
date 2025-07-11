import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/branch_model.dart';
import 'branch_event.dart';
import 'branch_state.dart';

// Simulasi JSON static (mock data)
final List<Map<String, dynamic>> _mockJson = [
  {
    "id": 21,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Medan Kota",
    "extension": "1801",
    "password": "password-1801",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 22,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Batam Nagoya",
    "extension": "1802",
    "password": "password-1802",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 23,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Palembang",
    "extension": "1803",
    "password": "password-1803",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 24,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Serang",
    "extension": "1804",
    "password": "password-1804",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 25,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Yogyakarta",
    "extension": "1805",
    "password": "password-1805",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 26,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Surabaya Karimunjawa",
    "extension": "1806",
    "password": "password-1806",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 27,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Pontianak",
    "extension": "1807",
    "password": "password-1807",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 28,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Makassar",
    "extension": "1808",
    "password": "password-1808",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 29,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Bali Denpasar",
    "extension": "1809",
    "password": "password-1809",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 32,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "112113",
    "tech": "pjsip",
    "display_name": "Jasnita Testing",
    "extension": "1810",
    "password": "password-1810",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 32,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "114995166153942763324085775247703",
    "tech": "pjsip",
    "display_name": "CALL PROVIDER",
    "extension": "9100000",
    "password": "password-9100000",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 32,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "1810",
    "tech": "pjsip",
    "display_name": "CALL PROVIDER11",
    "extension": "9100000",
    "password": "password-9100000",
    "created_at": null,
    "updated_at": null
  },
  {
    "id": 33,
    "client_id": "175JMO",
    "server": "https://issb.jasnita.co.id",
    "port": "5066",
    "protocol": "wss",
    "add_to_pbx": "1",
    "destination_call": "02150882930",
    "tech": "pjsip",
    "display_name": "Bekasi Cikarang",
    "extension": "1811",
    "password": "password-1811",
    "created_at": null,
    "updated_at": null
  }
];

class BranchBloc extends Bloc<BranchEvent, BranchState> {
  BranchBloc() : super(BranchInitial()) {
    on<LoadBranches>(_onLoadBranches);
    on<SelectBranch>(_onSelectBranch);
  }

  Future<void> _onLoadBranches(
      LoadBranches event, Emitter<BranchState> emit) async {
    emit(BranchLoading());
    await Future.delayed(const Duration(milliseconds: 500)); // Simulasi loading

    final branches = _mockJson.map((e) => Branch.fromJson(e)).toList();
    emit(BranchLoaded(branches: branches, selectedBranch: branches.first));
  }

  void _onSelectBranch(SelectBranch event, Emitter<BranchState> emit) {
    if (state is BranchLoaded) {
      final current = state as BranchLoaded;
      emit(BranchLoaded(
          branches: current.branches, selectedBranch: event.branch));
    }
  }
}
