import 'responder.dart';

class DispatchWeights {
  DispatchWeights({this.skill = 40, this.eta = 25, this.availability = 20, this.workload = 15});
  int skill;
  int eta;
  int availability;
  int workload;
  int get total => skill + eta + availability + workload;
}

class RankedResponder {
  const RankedResponder({
    required this.responder,
    required this.skillMatch,
    required this.distanceM,
    required this.etaSec,
    required this.availabilityScore,
    required this.workloadScore,
    required this.total,
    required this.eligible,
    this.note,
  });

  final Responder responder;
  final double skillMatch; // 0..1
  final double distanceM;
  final int etaSec;
  final double availabilityScore; // 0..1
  final double workloadScore; // 0..1
  final double total; // 0..100
  final bool eligible;
  final String? note;
}
