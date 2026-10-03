import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/responder.dart';

/// Seeded DEMO accounts. Names are placeholders ("Student 01", "Responder 01");
/// no real LBRCE staff or student data is used.
class DemoSeed {
  DemoSeed._();

  static const _depts = ['CSE', 'CSE', 'ECE', 'EEE', 'Mechanical', 'Civil', 'CSE', 'ECE', 'CSE', 'EEE'];

  static List<AppUser> users() {
    final list = <AppUser>[
      AppUser(
        id: 'admin',
        name: 'LBRCE Admin',
        email: DemoCredentials.admin.email,
        password: DemoCredentials.admin.password,
        role: UserRole.admin,
        department: 'Emergency Operations',
      ),
    ];
    for (var i = 0; i < 10; i++) {
      final n = (i + 1).toString().padLeft(2, '0');
      list.add(AppUser(
        id: 'student$n',
        name: 'Student $n',
        email: DemoCredentials.students[i].email,
        password: DemoCredentials.studentPassword,
        role: UserRole.student,
        department: _depts[i],
      ));
    }
    for (var i = 0; i < 5; i++) {
      final n = (i + 1).toString().padLeft(2, '0');
      list.add(AppUser(
        id: 'u_responder${i + 1}',
        name: 'Responder $n',
        email: DemoCredentials.responders[i].email,
        password: DemoCredentials.responderPassword,
        role: UserRole.responder,
        department: 'Campus Emergency Response Team',
      ));
    }
    return list;
  }

  static List<Responder> responders() => [
        Responder(
          id: 'R01', userId: 'u_responder1', name: 'Responder 01', type: 'Medical / First Aid',
          skills: [Skill.medical, Skill.firstAid], status: ResponderStatus.available, x: 540, y: 470, resolvedToday: 6,
        ),
        Responder(
          id: 'R02', userId: 'u_responder2', name: 'Responder 02', type: 'Security',
          skills: [Skill.security, Skill.firstAid], status: ResponderStatus.available, x: 470, y: 630, resolvedToday: 4,
        ),
        Responder(
          id: 'R03', userId: 'u_responder3', name: 'Responder 03', type: 'Fire Safety',
          skills: [Skill.fireSafety, Skill.disasterResponse], status: ResponderStatus.available, x: 260, y: 140, resolvedToday: 3,
        ),
        Responder(
          id: 'R04', userId: 'u_responder4', name: 'Responder 04', type: 'Electrical',
          skills: [Skill.electrical, Skill.fireSafety], status: ResponderStatus.available, x: 220, y: 300, resolvedToday: 2,
        ),
        Responder(
          id: 'R05', userId: 'u_responder5', name: 'Responder 05', type: 'Disaster Response',
          skills: [Skill.disasterResponse, Skill.firstAid, Skill.security], status: ResponderStatus.available, x: 740, y: 280, resolvedToday: 5,
        ),
      ];
}
