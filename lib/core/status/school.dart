import 'package:punklorde/common/models/school.dart';
import 'package:signals/signals.dart';

final Signal<SchoolModel?> currentSchool = signal<SchoolModel?>(null);
