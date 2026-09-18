import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_services.dart';

void main() {
  runApp(Services(services: AppServices.demo(), child: const ZakerlyApp()));
}
