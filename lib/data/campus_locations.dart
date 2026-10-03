import '../models/campus_location.dart';

/// Default campus locations for LBRCE.
///
/// Department names (CSE, IT, ECE, EEE, ME, CE, AI&DS) appear in official
/// lbrce.ac.in documents. Administrative block, auditorium, library and canteen
/// are mentioned in public descriptions of the campus. Everything else is a
/// generic DEMO LOCATION name. ALL positions are SIMULATED (schematic metres),
/// never real GPS coordinates. Admins can edit this list in Settings.
List<CampusLocation> defaultCampusLocations() => [
      CampusLocation(id: 'main_gate', name: 'Main Gate', x: 500, y: 655, risk: 6, w: 110, h: 34),
      CampusLocation(id: 'parking', name: 'Parking Area', x: 300, y: 610, risk: 5, w: 150, h: 60),
      CampusLocation(id: 'admin', name: 'Administrative Block', x: 500, y: 525, risk: 4, verifiedName: true, w: 150, h: 70),
      CampusLocation(id: 'library', name: 'Library', x: 700, y: 520, risk: 3, verifiedName: true, w: 110, h: 60),
      CampusLocation(id: 'auditorium', name: 'Auditorium', x: 300, y: 480, risk: 6, verifiedName: true, w: 130, h: 70),
      CampusLocation(id: 'seminar', name: 'Seminar Hall', x: 860, y: 520, risk: 4, w: 100, h: 56),
      CampusLocation(id: 'cse', name: 'CSE Department', x: 500, y: 370, risk: 6, verifiedName: true, w: 130, h: 70),
      CampusLocation(id: 'it', name: 'IT Department', x: 660, y: 370, risk: 5, verifiedName: true),
      CampusLocation(id: 'aids', name: 'AI&DS Department', x: 820, y: 370, risk: 5, verifiedName: true),
      CampusLocation(id: 'ece', name: 'ECE Department', x: 340, y: 370, risk: 5, verifiedName: true),
      CampusLocation(id: 'eee', name: 'EEE Department', x: 170, y: 370, risk: 6, verifiedName: true),
      CampusLocation(id: 'ece_lab', name: 'ECE Laboratory', x: 340, y: 250, risk: 7),
      CampusLocation(id: 'mech', name: 'Mechanical Engineering', x: 170, y: 200, risk: 6, verifiedName: true, w: 120, h: 70),
      CampusLocation(id: 'workshop', name: 'Workshop', x: 170, y: 80, risk: 8, w: 130, h: 60),
      CampusLocation(id: 'civil', name: 'Civil Engineering', x: 520, y: 220, risk: 5, verifiedName: true, w: 120, h: 64),
      CampusLocation(id: 'canteen', name: 'Canteen', x: 720, y: 220, risk: 5, verifiedName: true),
      CampusLocation(id: 'hostel', name: 'Hostel', x: 880, y: 110, risk: 6, w: 140, h: 80),
      CampusLocation(id: 'sports', name: 'Sports Ground', x: 520, y: 80, risk: 4, w: 200, h: 90),
    ];
