import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/tamplates/navbarM.dart';
import 'package:mouaz_app_018/views/accounts.dart';
import 'package:mouaz_app_018/views/accounts_edit.dart';
import 'package:mouaz_app_018/views/dailytasks.dart';
import 'package:mouaz_app_018/views/dailytasks_edit.dart';
import 'package:mouaz_app_018/views/dailytasksreport.dart';
import 'package:mouaz_app_018/views/dailytasksreport_edit.dart';
import 'package:mouaz_app_018/views/emails.dart';
import 'package:mouaz_app_018/views/emails_edit.dart';
import 'package:mouaz_app_018/views/groups.dart';
import 'package:mouaz_app_018/views/groups_edit.dart';
import 'package:mouaz_app_018/views/help.dart';
import 'package:mouaz_app_018/views/help_edit.dart';
import 'package:mouaz_app_018/views/homepage.dart';
import 'package:mouaz_app_018/views/login.dart';
import 'package:mouaz_app_018/views/logo.dart';
import 'package:mouaz_app_018/views/reminds.dart';
import 'package:mouaz_app_018/views/reminds_edit.dart';

class IconAnimatNotifier extends StateNotifier<bool> {
  IconAnimatNotifier({required this.custom}) : super(custom);
  final custom;
  onhover() {
    state = true;
  }

  onexit() {
    state = false;
  }

  ontap() {
    state = state == true ? false : true;
  }
}

var notifierlogo = StateNotifierProvider<IconAnimatNotifier, bool>(
    (ref) => IconAnimatNotifier(custom: LoGoMz.logo));
var notifiershowsettingsHomepage =
    StateNotifierProvider<IconAnimatNotifier, bool>(
        (ref) => IconAnimatNotifier(custom: HomePage.mysettingshow));
var notifierrightbuttonNav = StateNotifierProvider<IconAnimatNotifier, bool>(
    (ref) => IconAnimatNotifier(custom: NavBarMrightside.itemanimation));
var notifierleftbuttonNav = StateNotifierProvider<IconAnimatNotifier, bool>(
    (ref) => IconAnimatNotifier(custom: NavBarMleftside.itemanimation));

class RebuildListMapNotifier extends StateNotifier<List> {
  RebuildListMapNotifier({required this.custom}) : super(custom);
  final List custom;

  rebuild(model, ctx, {reportdate}) async {
    state = await StlFunction.getalldata(
        model: model, ctx: ctx, reportdate: reportdate);
    state = [
      ...state.map((e) => {
            ...e,
            'choose': false,
            'visible': true,
          })
    ];
  }

  rebuildlocal() {
    state = [...state];
  }

  swappasswordstatus({index}) {
    state = [
      ...state.sublist(0, index),
      state[index] = {
        ...state[index],
        'suffix_icon': state[index]['suffix_icon'] == Icons.visibility
            ? Icons.visibility_off
            : Icons.visibility,
        'obscuretext': state[index]['obscuretext'] ? false : true
      },
      ...state.sublist(index + 1)
    ];
  }

  chooseitemdromdopdown({x, index}) {
    state = [
      ...state.sublist(0, index),
      state[index] = {...state[index], 'selected': x},
      ...state.sublist(index + 1)
    ];
  }

  switchkey({x, index}) {
    state = [
      ...state.sublist(0, index),
      state[index] = {...state[index], 'value': x},
      ...state.sublist(index + 1)
    ];
  }

  checkbox({x, index}) {
    state = [
      ...state.sublist(0, index),
      state[index] = {...state[index], 'check': x},
      ...state.sublist(index + 1)
    ];
  }

  choose({index}) {
    state = [
      ...state.sublist(0, index),
      state[index] = {
        ...state[index],
        'choose': state[index]['choose'] ? false : true
      },
      ...state.sublist(index + 1)
    ];
  }

  chooseinside({index, name, subindex, x}) {
    state = [
      ...state.sublist(0, index),
      state[index] = {
        name: [
          ...state[index][name].sublist(0, subindex),
          {...state[index][name][subindex], 'choose': x ? true : false},
          ...state[index][name].sublist(subindex + 1)
        ]
      },
      ...state.sublist(index + 1)
    ];
  }

  movetoselected({index, label, itelmist, clname}) {
    for (var i in itelmist) {
      if (!state[index][label].contains("${i['id']}")) {
        state[index][label] = [...state[index][label], "${i['id']}"];
      }
      state[index][label] = state[index][label].where((y) => y != '').toList();
    }
  }

  movei() {
    state = [
      ...state.map((e) => {...e, 'choose': false})
    ];
  }

  movetoavailble({index, subundex, label, required List itelmist, clname}) {
    try {
      for (var i in itelmist) {
        state[index][label] = [
          ...state[index][label].where((t) => "${i['id']}" != t),
        ];
      }
      state[index][label] = state[index][label].where((y) => y != '').toList();
    } catch (t) {}
  }

  addcomment({index}) {
    state = [
      ...state.sublist(0, index),
      state[index] = {
        ...state[index],
        'comment': state[index]['comment'] ? false : true
      },
      ...state.sublist(index + 1)
    ];
  }

  onhovermainitem({index}) {
    try {
      state = [
        ...custom.sublist(0, index),
        custom[index] = {...custom[index], 'choose': true},
        ...custom.sublist(index + 1)
      ];
    } catch (e) {
      null;
    }
  }

  onexitmainitem({index}) {
    try {
      state = [
        ...custom.sublist(0, index),
        custom[index] = {...custom[index], 'choose': false},
        ...custom.sublist(index + 1)
      ];
    } catch (e) {
      null;
    }
  }

  deleteitem({index}) {
    state = [...state.skip(index)];
  }

  settime({index, label, ctx}) async {
    TimeOfDay? time =
        await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
    if (time != null) {
      state = [
        ...state.sublist(0, index),
        {...state[index], label: time},
        ...state.sublist(index + 1)
      ];
    }
  }

  setdate({index, label, ctx}) async {
    DateTime? date = await showDatePicker(
        context: ctx,
        initialDate: state[index][label] ?? DateTime.now(),
        firstDate: DateTime.parse("2024-01-01"),
        lastDate: DateTime.parse("2025-01-01"));
    if (date != null) {
      state = [
        ...state.sublist(0, index),
        {...state[index], label: date},
        ...state.sublist(index + 1)
      ];
    }
  }
}

var notifierswaphiddenpassLogin =
    StateNotifierProvider<RebuildListMapNotifier, List>(
        (ref) => RebuildListMapNotifier(custom: LogIN.logininput));

var notifierAccountsEdit = StateNotifierProvider<RebuildListMapNotifier, List>(
    (ref) => RebuildListMapNotifier(custom: AccountsE.localdata));

var notifierAccountgroupsEdit =
    StateNotifierProvider<RebuildListMapNotifier, List>(
        (ref) => RebuildListMapNotifier(custom: AccountsE.groupslist));

var notifierGroupsEdit = StateNotifierProvider<RebuildListMapNotifier, List>(
    (ref) => RebuildListMapNotifier(custom: GroupsE.localdata));

var notifierGroupaccountsEdit =
    StateNotifierProvider<RebuildListMapNotifier, List>(
        (ref) => RebuildListMapNotifier(custom: GroupsE.userslist));

var notifierHelpEdit = StateNotifierProvider<RebuildListMapNotifier, List>(
    (ref) => RebuildListMapNotifier(custom: HelpE.localdata));

var notifierDailyTasksEdit =
    StateNotifierProvider<RebuildListMapNotifier, List>(
        (ref) => RebuildListMapNotifier(custom: DailyTasksE.localdata));

var notifierDailyTasksReportsEdit =
    StateNotifierProvider<RebuildListMapNotifier, List>(
        (ref) => RebuildListMapNotifier(custom: DailyTasksReportsE.localdata));

var notifierRemindsEdit = StateNotifierProvider<RebuildListMapNotifier, List>(
    (ref) => RebuildListMapNotifier(custom: RemindsE.localdata));

var notifierRemindgroupsEdit =
    StateNotifierProvider<RebuildListMapNotifier, List>(
        (ref) => RebuildListMapNotifier(custom: RemindsE.groupslist));

var notifiermainitemsHomepage =
    StateNotifierProvider<RebuildListMapNotifier, List>(
        (ref) => RebuildListMapNotifier(custom: HomePage.mainitems));

var notifierEmailsEdit = StateNotifierProvider<RebuildListMapNotifier, List>(
    (ref) => RebuildListMapNotifier(custom: EmailsE.localdata));

var notifierEmailgroupsEdit =
    StateNotifierProvider<RebuildListMapNotifier, List>(
        (ref) => RebuildListMapNotifier(custom: EmailsE.groupslist));

// RebuildMainApp__
class RebuildLocalDataNotifier extends StateNotifier<List> {
  RebuildLocalDataNotifier({required this.custom}) : super(custom);
  final List custom;

  rebuild(model, ctx, {reportdate}) async {
    state = model == 'dailytasksreports'
        ? await StlFunction.getalldata(
            model: model, ctx: ctx, reportdate: reportdate)
        : await StlFunction.getalldata(model: model, ctx: ctx);

    state = [
      ...state.map((o) => {
            ...o,
            'choose': false,
            'search': true,
            'sorted': true,
            'opencard': false
          }),
    ];
    return state;
  }

  opencard({index}) {
    state = [
      ...state.sublist(0, index).map((e) => {...e, 'opencard': false}),
      state[index] = {
        ...state[index],
        'opencard': state[index]['opencard'] == true ? false : true
      },
      ...state.sublist(index + 1).map((e) => {...e, 'opencard': false}),
    ];
  }

  chooseitem({index}) {
    state = [
      ...state.sublist(0, index).map((e) => e),
      state[index] = {
        ...state[index],
        'choose': state[index]['choose'] == true ? false : true
      },
      ...state.sublist(index + 1).map((e) => e),
    ];
  }

  chooseallitemsfromsearch() {
    state = [
      ...state.where((i) => i['search']).map((e) => {
            ...e,
            'choose': state
                    .where((element) => element['search'])
                    .every((element) => element['choose'])
                ? false
                : true
          }),
      ...state.where((i) => i['search'] == false).map((e) => e),
    ];
  }

  chooseallitems() {
    state = [
      ...state.map((e) => {
            ...e,
            'search': true,
            'choose': state.every((element) => element['choose']) ? false : true
          }),
    ];
  }

  search({required String word, required List<String>? searchrange}) {
    if (word.isEmpty) {
      state = [
        ...state.map((e) => {...e, 'search': true})
      ];
    } else {
      state = [
        ...state.map((e) => {...e, 'search': false})
      ];
      state = [
        ...state.map((e) => {
              ...e,
              'search': searchrange!.any((element) => e[element]
                  .toString()
                  .toLowerCase()
                  .contains(word.toLowerCase()))
            })
      ];
    }
  }

  sort({sortby}) {
    state = [...state.map((e) => e)];

    if (sortby == 'id') {
      !state.any((element) => element['sorted'])
          ? state.sort((a, b) => a[sortby].compareTo(b[sortby]))
          : state.sort((a, b) => b[sortby].compareTo(a[sortby]));
      state = [
        ...state.map((element) =>
            {...element, 'sorted': element['sorted'] ? false : true})
      ];
    } else {
      !state.any((element) => element['sorted'])
          ? state.sort((a, b) => "${a[sortby]}".compareTo("${b[sortby]}"))
          : state.sort((a, b) => "${b[sortby]}".compareTo("${a[sortby]}"));
      state = [
        ...state.map((element) =>
            {...element, 'sorted': element['sorted'] ? false : true})
      ];
    }
  }
}

var notifierAccountsdata =
    StateNotifierProvider<RebuildLocalDataNotifier, List>(
        (ref) => RebuildLocalDataNotifier(custom: Accounts.localdata));
var notifierEmailsdata = StateNotifierProvider<RebuildLocalDataNotifier, List>(
    (ref) => RebuildLocalDataNotifier(custom: Emails.localdata));
var notifierGroupsdata = StateNotifierProvider<RebuildLocalDataNotifier, List>(
    (ref) => RebuildLocalDataNotifier(custom: Groups.localdata));
var notifierHelpdata = StateNotifierProvider<RebuildLocalDataNotifier, List>(
    (ref) => RebuildLocalDataNotifier(custom: Help.localdata));
var notifierDailyTasksdata =
    StateNotifierProvider<RebuildLocalDataNotifier, List>(
        (ref) => RebuildLocalDataNotifier(custom: DailyTasks.localdata));
var notifierDailyTasksReportdata =
    StateNotifierProvider<RebuildLocalDataNotifier, List>(
        (ref) => RebuildLocalDataNotifier(custom: DailyTasksReports.localdata));
var notifierRemindsdata = StateNotifierProvider<RebuildLocalDataNotifier, List>(
    (ref) => RebuildLocalDataNotifier(custom: Reminds.localdata));

class SetDate extends StateNotifier<DateTime> {
  SetDate({required this.custom}) : super(custom);
  final DateTime custom;
  setdate({ctx}) async {
    DateTime? selecteddate = await showDatePicker(
        context: ctx,
        firstDate: DateTime.parse('2024-01-01'),
        lastDate: DateTime.parse('2025-01-01'));
    if (selecteddate != null) {
      state = selecteddate;
      return selecteddate;
    } else {
      state = DateTime.now();
      return DateTime.now();
    }
  }

  setdefault() {
    state = DateTime.now();
  }
}

var notifierDailyTasksReportdataSetDate =
    StateNotifierProvider<SetDate, DateTime>(
        (ref) => SetDate(custom: DailyTasksReports.reportdate));
