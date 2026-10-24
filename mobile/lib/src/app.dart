import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'api_service.dart';
import 'screens/live_tracking_screen.dart';
import 'session_controller.dart';
import 'services/push_service.dart';
import 'services/platform_bootstrap.dart';

part 'presentation/core.dart';
part 'presentation/launch_experience.dart';
part 'presentation/student.dart';
part 'presentation/student_home.dart';
part 'presentation/supervisor.dart';
part 'presentation/supervisor_bookings.dart';
part 'presentation/parent.dart';
part 'presentation/admin_tracking.dart';
part 'presentation/shared_widgets.dart';
part 'presentation/detail_pages.dart';
