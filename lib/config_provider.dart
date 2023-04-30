/*
 * This file is part of the Klient (https://github.com/lolocomotive/klient)
 *
 * Copyright (C) 2022 lolocomotive
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:klient/api/color_provider.dart';
import 'package:klient/main.dart';
import 'package:klient/widgets/color_picker.dart';
import 'package:openid_client/openid_client.dart';
import 'package:scolengo_api/scolengo_api.dart';

class ConfigProvider {
  //TODO rewrite this with proper getters/setters
  static FlutterSecureStorage? _storage;
  static String? username;
  static bool? compact;
  static Credential? credentials;
  static School? school;
  static bool? notifMsgEnabled;
  static Brightness? enforcedBrightness;
  static bool demo = false;
  static ColorScheme? lightDynamic;
  static ColorScheme? darkDynamic;
  static Color? enforcedColor;

  static late HSLColor bgColor;

  static setTheme() {
    Color primary =
        enforcedColor ?? darkDynamic?.primary ?? lightDynamic?.primary ?? Colors.deepPurple;
    Brightness brightness =
        enforcedBrightness ?? SchedulerBinding.instance.window.platformBrightness;
    Color highlight = HSLColor.fromColor(primary)
        .withLightness(brightness == Brightness.light ? .6 : .8)
        .toColor()
        .withAlpha(80);
    Color splash = HSLColor.fromColor(primary).withLightness(.7).toColor().withAlpha(60);
    ColorScheme colorScheme;
    if (enforcedColor == null && lightDynamic != null && darkDynamic != null) {
      colorScheme = brightness == Brightness.light ? lightDynamic! : darkDynamic!;
    } else {
      colorScheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness);
    }

    bgColor = HSLColor.fromColor(colorScheme.background);
    if (brightness == Brightness.light) {
      bgColor = bgColor.withLightness(bgColor.lightness - .05).withSaturation(.3);
    } else {
      bgColor = bgColor.withLightness(bgColor.lightness - .01);
    }

    KlientApp.theme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true).copyWith(
      highlightColor: highlight,
      splashColor: splash,
      scaffoldBackgroundColor: colorScheme.background,
      snackBarTheme: const SnackBarThemeData(
        insetPadding: EdgeInsets.all(8),
        behavior: SnackBarBehavior.floating,
        width: 700,
      ),
    );
  }

  static setMessageNotifications(bool value, Function callback) {
    if (value == true) {
      if (Platform.isLinux) {
        notifMsgEnabled = true;
        getStorage()
            .write(key: 'notifications.messages', value: notifMsgEnabled! ? 'true' : 'false');
        callback();
        return;
      }

      FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
          .requestPermission()
          .then((success) {
        if (success == true) {
          notifMsgEnabled = true;
        } else {
          notifMsgEnabled = false;
        }
        getStorage()
            .write(key: 'notifications.messages', value: notifMsgEnabled! ? 'true' : 'false');
        callback();
      });
    } else {
      notifMsgEnabled = false;
      getStorage().write(key: 'notifications.messages', value: notifMsgEnabled! ? 'true' : 'false');
      callback();
    }
  }

  static FlutterSecureStorage getStorage() {
    if (_storage != null) return _storage!;
    _storage =
        const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    return _storage!;
  }

  static load() async {
    if (kDebugMode) {
      //getStorage().deleteAll();
    }
    try {
      print('Reading preferences');
      var data = await getStorage().readAll();

      compact = false;

      data.forEach((key, value) {
        if (kDebugMode) print('[Config] $key : $value');
        switch (key) {
          case 'credentials':
            credentials = Credential.fromJson(jsonDecode(value));
            break;
          case 'school':
            school = School.fromJson(jsonDecode(value));
            break;
          case 'username':
            username = value;
            break;
          case 'demoMode':
            demo = value == 'true';
            break;
          case 'display.compact':
            compact = value == 'true';
            break;
          case 'display.enforcedColor':
            if (int.parse(value) != -1) {
              enforcedColor = ColorPickerPageState.colors[int.parse(value)];
            }
            break;
          case 'display.enforcedBrightness':
            enforcedBrightness = value == 'light'
                ? Brightness.light
                : value == 'dark'
                    ? Brightness.dark
                    : null;
            break;
          case 'notifications.messages':
            if (Platform.isLinux) {
              notifMsgEnabled = value == 'true';
              break;
            }
            FlutterLocalNotificationsPlugin()
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
                .areNotificationsEnabled()
                .then((enabled) {
              notifMsgEnabled = value == 'true' && enabled == true;
            });
            break;
          case 'lessonColors':
            ColorProvider.init(value);
        }
      });
    } on PlatformException catch (_) {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      await getStorage().deleteAll();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  static setColor(Color? color) {
    enforcedColor = color;
    final int index;
    if (color == null) {
      index = -1;
    } else {
      index = ColorPickerPageState.colors.indexOf(color);
    }
    getStorage().write(key: 'display.enforcedColor', value: index.toString());
  }
}
