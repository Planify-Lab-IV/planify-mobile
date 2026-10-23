import 'package:flutter_riverpod/flutter_riverpod.dart';

const registeredHomeGroupsTabIndex = 1;

final registeredHomeSelectedTabProvider = StateProvider<int>((ref) => 0);
