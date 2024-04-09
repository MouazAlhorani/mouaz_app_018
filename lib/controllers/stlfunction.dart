import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mouaz_app_018/data/basicdata.dart';
import 'package:mouaz_app_018/data/shared_pref_mz.dart';
import 'package:mouaz_app_018/tamplates/dialog01.dart';
import 'package:mouaz_app_018/views/accounts_edit.dart';
import 'package:mouaz_app_018/views/dailytasks_edit.dart';
import 'package:mouaz_app_018/views/dailytasksreport_edit.dart';
import 'package:mouaz_app_018/views/emails_edit.dart';
import 'package:mouaz_app_018/views/groups_edit.dart';
import 'package:mouaz_app_018/views/help_edit.dart';
import 'package:mouaz_app_018/views/homepage.dart';
import 'package:mouaz_app_018/views/login.dart';
import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart' as df;
import 'package:mouaz_app_018/views/reminds_edit.dart';
import 'package:url_launcher/url_launcher.dart';

class StlFunction {
  static snackbar({ctx, msg, color}) {
    return ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      dismissDirection: DismissDirection.up,
      duration: const Duration(milliseconds: 2000),
    ));
  }

  static reqpuestGet({url, ctx}) async {
    try {
      var result = await http.get(Uri.parse(url));
      if (result.statusCode == 200) {
        return jsonDecode(result.body);
      } else {
        snackbar(
            ctx: ctx,
            msg: "لا يمكن الوصول للمخدم",
            color: Colors.deepOrangeAccent.withOpacity(0.5));
        return null;
      }
    } catch (e) {
      snackbar(ctx: ctx, msg: "$e");
    }
  }

  static requestPost({required String url, body, ctx}) async {
    try {
      var result = await http.post(
        Uri.parse(url),
        body: body,
      );
      if (result.statusCode == 200) {
        return jsonDecode(result.body);
      } else if (result.statusCode == 401) {
        snackbar(
            ctx: ctx,
            msg: "اسم المستخدم او كلمة المرور غير صحيحة",
            color: Colors.black.withOpacity(0.5));
        try {
          await logout(ctx: ctx);
        } catch (i) {}
        return null;
      } else if (result.statusCode == 400) {
        snackbar(
            ctx: ctx,
            msg: "${jsonDecode(result.body)['result']}",
            color: Colors.black.withOpacity(0.5));
        return null;
      } else if (result.statusCode == 403) {
        snackbar(
            ctx: ctx,
            msg: "لا تملك الصلاحيات المطلوبة",
            color: Colors.black.withOpacity(0.5));
        return null;
      }
    } catch (e) {
      snackbar(ctx: ctx, msg: "لا يمكن الوصول للمخدم");
    }
  }

  static checklogin({ctx, username, password, type}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.checklogin}",
        body: {'username': username, 'password': password});
    if (result != null) {
      if (result[0]['enable'] == false) {
        if (type == true) {
          snackbar(ctx: ctx, msg: "الحساب معطَّل");
        }
        return false;
      } else {
        await SharedPref.setloginfo(logininfolist: [username, password]);
        BasicData.userinfo = result;
        if (type != null) {
          Navigator.pushReplacement(
              ctx, MaterialPageRoute(builder: (_) => const HomePage()));
          return true;
        }
        return true;
      }
    }
  }

  static logout({ctx}) async {
    for (var i in LogIN.logininput) {
      i['controller'].text = '';
    }
    await SharedPref.removeloginfo();
    await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.logout}",
        body: {'id': "${BasicData.userinfo![0]['id']}"});
    return Navigator.pushReplacement(
        ctx, MaterialPageRoute(builder: (_) => const LogIN()));
  }

  static createExcel(
      {required List data, required List headers, pagename, required ctx}) {
    decriptpass(String text) {
      if (text.length == 1) {
        return text;
      } else {
        return text.substring(0, 1) + decriptpass(text.substring(2));
      }
    }

    xl.Excel excel = xl.Excel.createExcel();
    var sheet = excel.sheets['Sheet1'];

    for (var head in headers) {
      sheet!.cell(xl.CellIndex.indexByColumnRow(columnIndex: headers.indexOf(head), rowIndex: 0)).value =
          head.runtimeType == bool
              ? xl.BoolCellValue(head)
              : head.runtimeType == int
                  ? xl.IntCellValue(head)
                  : head.runtimeType == double
                      ? xl.DoubleCellValue(head)
                      : xl.TextCellValue(head);
    }
    for (var i in data) {
      sheet!
          .cell(xl.CellIndex.indexByColumnRow(
              columnIndex: 0, rowIndex: data.indexOf(i) + 1))
          .value = xl.TextCellValue(i['id'].toString());
      for (var j in i.values.toList().sublist(0, headers.length)) {
        sheet
                .cell(xl.CellIndex.indexByColumnRow(
                    columnIndex: i.values.toList().indexOf(j),
                    rowIndex: data.indexOf(i) + 1))
                .value =
            xl.TextCellValue(
                i.values.toList().indexOf(j) == 5 && pagename == 'accounts'
                    ? decriptpass(j).toString()
                    : j.toString() == 'null'
                        ? ''
                        : "$j");
        sheet.setColumnAutoFit(i.values.toList().indexOf(j));
      }
    }
    excel.save(
        fileName:
            "${pagename}_${df.DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now())}.xlsx");
  }

  static importexcel(
      {ctx, headers, emptyroles, erroremptyrole, createbulkfunction}) async {
    List checkheaders = [], data = [];
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    if (pickedFile != null) {
      var bytes = pickedFile.files.single.bytes;
      var excel = xl.Excel.decodeBytes(bytes!);
      check() {
        bool x = true;
        if (checkheaders.length != headers.length) {
          return false;
        } else {
          li:
          for (var i in headers) {
            if (i.toString() != checkheaders[headers.indexOf(i)].toString()) {
              x = false;
              break li;
            }
          }
          return x;
        }
      }

      try {
        ll:
        for (var row in excel.tables[excel.tables.keys.first]!.rows) {
          for (var i = 0;
              i < excel.tables[excel.tables.keys.first]!.maxColumns;
              i++) {
            checkheaders.add(row[i]!.value);
          }
          break ll;
        }
      } catch (o) {
        return null;
      }
      if (check()) {
        int x = 0;

        for (var row in excel.tables[excel.tables.keys.first]!.rows.skip(1)) {
          data.add({});
          for (var i = 0; i < headers.length; i++) {
            if (emptyroles != null && emptyroles.any((y) => row[y] == null)) {
              return showDialog(
                  context: ctx,
                  builder: (_) {
                    return AlertDialog(
                      content: Text(erroremptyrole),
                    );
                  });
            } else {
              data[x].addAll({headers[i]: row[i] == null ? '' : row[i]!.value});
            }
          }
          x++;
        }
        return showDialog(
            context: ctx,
            builder: (BuildContext context) {
              return DialogofimportM(
                createbulkfunction: createbulkfunction,
                headers: headers,
                data: data,
              );
            });
      } else {
        return showDialog(
            context: ctx,
            builder: (_) {
              return const AlertDialog(
                content: Text("الجدول غير مطابق للنموذج المطلوب"),
              );
            });
      }
    }
  }

  static getalldata({ctx, required model, reportdate}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.getalldata}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'model': model,
          'reportdate': model == 'dailytasksreports'
              ? reportdate == 'all'
                  ? 'all'
                  : reportdate == null
                      ? df.DateFormat("yyyy-MM-dd HH:mm").format(DateTime.now())
                      : df.DateFormat("yyyy-MM-dd HH:mm").format(reportdate)
              : ''
        });
    if (result != null) {
      if (result.isNotEmpty && result[0]['result'] == 'redirect_login') {
        return 'redirect_login';
      } else if (result.isNotEmpty &&
          result[0]['result'] == 'permission_error') {
        snackbar(color: Colors.redAccent, msg: "لا تملك صلاحيات", ctx: ctx);
        logout(ctx: ctx);
      } else {
        return result;
      }
    }
  }

  static getsingledata({ctx, required model, id}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.getsingledata}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'model': model,
          'id': id
        });
    if (result != null) {
      if (result.isNotEmpty && result[0]['result'] == 'redirect_login') {
        return 'redirect_login';
      } else {
        return result;
      }
    }
  }

  static createbulkusers(
      {ctx,
      data,
      required WidgetRef ref,
      required List<Map> notifierlist}) async {
    var result = await StlFunction.requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createbulkusers}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'records': data.toString()
        });
    if (result['result'] == 'done') {
      Navigator.pop(ctx);
      snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
    } else {
      Navigator.pop(ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
      return showDialog(
          context: ctx,
          builder: (_) {
            return AlertDialog(
              scrollable: true,
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("تم مع بعض الاخطاء"),
                Text(result['errors']
                    .toString()
                    .replaceAll('[', '')
                    .replaceAll(']', '')
                    .replaceAll(' ', '')
                    .replaceAll(',\'', '')
                    .replaceAll('<>', '\n'))
              ]),
            );
          });
    }
  }

  static createbulkgroups(
      {ctx,
      data,
      required WidgetRef ref,
      required List<Map> notifierlist}) async {
    var result = await StlFunction.requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createbulkgroups}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'records': data.toString()
        });
    if (result['result'] == 'done') {
      Navigator.pop(ctx);
      snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
    } else {
      Navigator.pop(ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
      return showDialog(
          context: ctx,
          builder: (_) {
            return AlertDialog(
              scrollable: true,
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("تم مع بعض الاخطاء"),
                Text(result['errors']
                    .toString()
                    .replaceAll('[', '')
                    .replaceAll(']', '')
                    .replaceAll(' ', '')
                    .replaceAll(',\'', '')
                    .replaceAll('<>', '\n'))
              ]),
            );
          });
    }
  }

  static createbulkhelps(
      {ctx, data, ref, required List<Map> notifierlist}) async {
    var result = await StlFunction.requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createbulkhelps}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'records': data.toString()
        });
    if (result['result'] == 'done') {
      Navigator.pop(ctx);
      snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
    } else {
      Navigator.pop(ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
      return showDialog(
          context: ctx,
          builder: (_) {
            return AlertDialog(
              scrollable: true,
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("تم مع بعض الاخطاء"),
                Text(result['errors']
                    .toString()
                    .replaceAll('[', '')
                    .replaceAll(']', '')
                    .replaceAll(' ', '')
                    .replaceAll(',\'', '')
                    .replaceAll('<>', '\n'))
              ]),
            );
          });
    }
  }

  static createbulktasks(
      {ctx, data, ref, required List<Map> notifierlist}) async {
    var result = await StlFunction.requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createbulktasks}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'records': data.toString()
        });
    if (result['result'] == 'done') {
      Navigator.pop(ctx);
      snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
    } else {
      Navigator.pop(ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
      return showDialog(
          context: ctx,
          builder: (_) {
            return AlertDialog(
              scrollable: true,
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("تم مع بعض الاخطاء"),
                Text(result['errors']
                    .toString()
                    .replaceAll('[', '')
                    .replaceAll(']', '')
                    .replaceAll(' ', '')
                    .replaceAll(',\'', '')
                    .replaceAll('<>', '\n'))
              ]),
            );
          });
    }
  }

  static createbulktasksReports(
      {ctx,
      data,
      required WidgetRef ref,
      required List<Map> notifierlist}) async {
    var result = await StlFunction.requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createbulkdailytasksreports}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'records': data.toString()
        });
    if (result['result'] == 'done') {
      Navigator.pop(ctx);
      snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
    } else {
      Navigator.pop(ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
      return showDialog(
          context: ctx,
          builder: (_) {
            return AlertDialog(
              scrollable: true,
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("تم مع بعض الاخطاء"),
                Text(result['errors']
                    .toString()
                    .replaceAll('[', '')
                    .replaceAll(']', '')
                    .replaceAll(' ', '')
                    .replaceAll(',\'', '')
                    .replaceAll('<>', '\n'))
              ]),
            );
          });
    }
  }

  static createbulkreminds(
      {ctx,
      data,
      required WidgetRef ref,
      required List<Map> notifierlist}) async {
    var result = await StlFunction.requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createbulkreminds}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'records': data.toString()
        });
    if (result['result'] == 'done') {
      Navigator.pop(ctx);
      snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
    } else {
      Navigator.pop(ctx);
      for (var i in notifierlist) {
        ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
      }
      return showDialog(
          context: ctx,
          builder: (_) {
            return AlertDialog(
              scrollable: true,
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("تم مع بعض الاخطاء"),
                Text(result['errors']
                    .toString()
                    .replaceAll('[', '')
                    .replaceAll(']', '')
                    .replaceAll(' ', '')
                    .replaceAll(',\'', '')
                    .replaceAll('<>', '\n'))
              ]),
            );
          });
    }
  }

  static createEdituser(
      {ctx, required WidgetRef ref, e, required List<Map> notifierlist}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createuser}",
        body: {
          'id': e != null ? "${e['id']}" : '',
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'newfullname': AccountsE.localdata[0]['controller'].text,
          'newusername': AccountsE.localdata[1]['controller'].text,
          'newemail': AccountsE.localdata[2]['controller'].text,
          'newphone': AccountsE.localdata[3]['controller'].text,
          'newpassword': AccountsE.localdata[4]['controller'].text,
          'newadmin': AccountsE.localdata[6]['selected'],
          'newenable': AccountsE.localdata[7]['value'] ? '1' : '0',
          'groups': AccountsE.localdata[8]['usergroups'].toString()
        });
    if (result != null) {
      if (result['result'] == 'done') {
        if (e != null && "${BasicData.userinfo![0]['id']}" == "${e['id']}") {
          await logout(ctx: ctx);
        } else {
          snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
          for (var i in notifierlist) {
            ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
          }
          Navigator.pop(ctx);
        }
      }
    }
  }

  static createEditgroup(
      {ctx, required WidgetRef ref, e, required List<Map> notifierlist}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.creategroup}",
        body: {
          'id': e != null ? "${e['id']}" : '',
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'newgroupname': GroupsE.localdata[0]['controller'].text,
          'newchatid': GroupsE.localdata[1]['controller'].text,
          'newapitoken': GroupsE.localdata[2]['controller'].text,
          'newnotification': GroupsE.localdata[3]['value'] ? '1' : '0',
          'users': GroupsE.localdata[4]['groupusers'].toString()
        });
    if (result != null) {
      if (result['result'] == 'done') {
        snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
        for (var i in notifierlist) {
          ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
        }
        Navigator.pop(ctx);
      }
    }
  }

  static createEdithelp(
      {ctx, required WidgetRef ref, e, required List<Map> notifierlist}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createhelp}",
        body: {
          'id': e != null ? "${e['id']}" : '',
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'newhelpname': HelpE.localdata[0]['controller'].text,
          'newhelpdesc': HelpE.localdata[1]['controller'].text,
        });
    if (result != null) {
      if (result['result'] == 'done') {
        snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
        for (var i in notifierlist) {
          ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
        }
        Navigator.pop(ctx);
      }
    }
  }

  static createEditdailytask(
      {ctx, required WidgetRef ref, e, required List<Map> notifierlist}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createtask}",
        body: {
          'id': e != null ? "${e['id']}" : '',
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'newtask': DailyTasksE.localdata[0]['controller'].text,
          'newtaskhelp':
              DailyTasksE.localdata[1]['selected'].toString().split(' ')[1],
        });
    if (result != null) {
      if (result['result'] == 'done') {
        snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
        for (var i in notifierlist) {
          ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
        }
        Navigator.pop(ctx);
      }
    }
  }

  static createEditEmailelement(
      {ctx, required WidgetRef ref, e, required List<Map> notifierlist}) async {
    String days = '';
    for (var i in EmailsE.localdata[2]['weekdays']) {
      if (i['choose'] == true) {
        days += '${i['day']}-';
      }
    }
    EmailsE.localdata[2]['weekdays'].last['day'].text.isNotEmpty
        ? days +=
            "customday:${EmailsE.localdata[2]['weekdays'].last['day'].text}"
        : null;
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createemailelement}",
        body: {
          'id': e != null ? "${e['id']}" : '',
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'name': EmailsE.localdata[0]['controller'].text,
          'error_def': EmailsE.localdata[1]['controller'].text,
          'error_except': EmailsE.localdata[2]['controller'].text,
          'days': days,
          'time':
              "${EmailsE.localdata[4]['selected'].hour}:${EmailsE.localdata[4]['selected'].minute}",
          'groups': EmailsE.localdata[5]['emailgroups'].toString()
        });
    if (result != null) {
      if (result['result'] == 'done') {
        snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
        for (var i in notifierlist) {
          ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
        }
        Navigator.pop(ctx);
      }
    }
  }

  static createEditdailytaskreport(
      {ctx, required WidgetRef ref, e, required List<Map> notifierlist}) async {
    String report = '';
    for (var i in DailyTasksReportsE.localdata) {
      report += "- ";
      report += i['check'] ? "_تم_" : "_لا_";
      report += '${i['task']}\n';
      i['controller'].text.isNotEmpty
          ? report += '_comment_${i['controller'].text}\n'
          : null;
    }
    DailyTasksReportsE.maincomment.text.isNotEmpty
        ? report += '_maincomment_${DailyTasksReportsE.maincomment.text}\n'
        : null;
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createdailytaskreport}",
        body: {
          'id': e != null ? "${e['id']}" : '',
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'createby': BasicData.userinfo![0]['fullname'],
          'report': report,
          'reportdate': df.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())
        });
    if (result != null) {
      if (result['result'] == 'done') {
        snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
        for (var i in notifierlist) {
          ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
        }
        Navigator.pop(ctx);
      }
    }
  }

  static telegram(ctx) async {
    await requestPost(
        ctx: ctx, url: "${BasicData.baseurl}${BasicData.telegram}", body: {});
  }

  static createEditremind(
      {ctx, required WidgetRef ref, e, required List<Map> notifierlist}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createremind}",
        body: {
          'id': e != null ? "${e['id']}" : '',
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'remindname': RemindsE.localdata[0]['controller'].text,
          'reminddesc': RemindsE.localdata[1]['controller'].text,
          'remindbefor': RemindsE.localdata[2]['controller'].text,
          'url': RemindsE.localdata[4]['value']
              ? RemindsE.localdata[3]['controller'].text
              : '',
          'remindtype': RemindsE.localdata[4]['value'] ? 'auto' : 'manual',
          'expiredate': RemindsE.localdata[4]['value']
              ? ''
              : df.DateFormat("yyyy-MM-dd HH:mm")
                  .format(RemindsE.localdata[5]['expiredate']),
          'groups': RemindsE.localdata[6]['remindgroups'].toString(),
          'notification': RemindsE.localdata[7]['value'] ? '1' : '0'
        });
    if (result != null) {
      if (result['result'] == 'done') {
        snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
        for (var i in notifierlist) {
          ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
        }
        Navigator.pop(ctx);
      }
    }
  }

  static createshowreportlog({ctx, reportid}) async {
    await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.createusershowreport}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'userid': "${BasicData.userinfo![0]['id']}",
          'reportid': reportid,
        });
  }

  static delete(
      {ctx,
      required WidgetRef ref,
      id,
      model,
      required List<Map> notifierlist}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.delete}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'model': model,
          'id': id
        });
    if (result != null) {
      if (result['result'] == 'done') {
        snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
        for (var i in notifierlist) {
          ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
        }
        Navigator.pop(ctx);
        Navigator.pop(ctx);
      }
    }
  }

  static deletebulk(
      {ctx,
      required WidgetRef ref,
      ids,
      model,
      required List<Map> notifierlist}) async {
    var result = await requestPost(
        ctx: ctx,
        url: "${BasicData.baseurl}${BasicData.deletebulk}",
        body: {
          'username': BasicData.userinfo![0]['username'],
          'password': BasicData.userinfo![0]['password'],
          'model': model,
          'ids': ids
        });
    if (result != null) {
      if (result['result'] == 'done') {
        snackbar(color: Colors.green, msg: "تمت العملية بنجاح", ctx: ctx);
        for (var i in notifierlist) {
          ref.read(i['notifier'].notifier).rebuild(i['model'], ctx);
        }
        Navigator.pop(ctx);
      }
    }
  }

  static proccesscontentwithurl({required String content}) async {
    List<Map> y = [];
    for (var i in content.split('\n')) {
      for (var j in i.split(' ')) {
        try {
          await canLaunchUrl(Uri.parse(j))
              ? y.add({"t": j, 'v': true})
              : y.add({"t": "$j ", 'v': false});
        } catch (o) {}
      }
      y.last['t'] = y.last['t'].trim();
      y.add({'t': '\n', 'v': false});
    }
    return y;
  }

  static showhelp({ctx, id}) async {
    showDialog(
        context: ctx,
        builder: (_) {
          String helpname;
          List<Map> helpdesc = [];
          return FutureBuilder(future: Future(() async {
            var result = await StlFunction.getsingledata(
                model: 'helps', ctx: ctx, id: id);
            helpdesc = await StlFunction.proccesscontentwithurl(
                content: result[0]['helpdesc']);
            return result;
          }), builder: (_, snap) {
            if (snap.hasData) {
              helpname = snap.data[0]['helpname'];

              return AlertDialog(
                  title: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(helpname),
                  ),
                  content: Directionality(
                    textDirection: TextDirection.ltr,
                    child: SelectableText.rich(TextSpan(children: [
                      ...helpdesc.map((i) => i['v']
                          ? TextSpan(
                              style: Theme.of(ctx)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      decoration: TextDecoration.underline),
                              text: i['t'],
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async =>
                                    await launchUrl(Uri.parse(i['t'])))
                          : TextSpan(text: i['t']))
                    ])),
                  ));
            } else {
              return const SizedBox();
            }
          });
        });
  }

  static List convertfromstrtolist({required String source}) {
    source = source.substring(1, source.length - 1);
    List items = source.split('},');
    for (var i in items) {
      items[items.indexOf(i)] = i
          .toString()
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll(": ", ":")
          .trim();
    }
    return items;
  }

  static String getidfromasstr({required String source}) {
    String mystring = '';
    for (var i in convertfromstrtolist(source: source)) {
      try {
        mystring += "${i.toString().substring(0, i.indexOf(':'))} | ";
      } catch (o) {}
    }
    return mystring;
  }
}
