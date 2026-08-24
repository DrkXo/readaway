import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mupdf/mupdf.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:window_manager/window_manager.dart';

import '../../../flavors.dart';
import '../../features/settings/domain/models/reader_preferences.dart';
import '../error/errors.dart';
import '../theme/theme.dart';

part 'app_lyfecycle_manager.dart';
part 'logging_service.dart';
part 'lookup/lookup_service.dart';
part 'mupdf_service.dart';
part 'storage/hive/app_storage_service.dart';
part 'storage/hive/hive_config_service.dart';
part 'theme_service.dart';
part 'window_service.dart';
part 'http/http_service.dart';
part 'isolate_service.dart';
