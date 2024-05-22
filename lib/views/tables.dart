import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as df;
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/controllers/tween_mz.dart';
import 'package:mouaz_app_018/data/basicdata.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';
import 'package:mouaz_app_018/tamplates/navbarM.dart';
import 'package:mouaz_app_018/tamplates/onchoosebard.dart';
import 'package:mouaz_app_018/tamplates/searchM.dart';
import 'package:mouaz_app_018/views/reminds_edit.dart';
import 'package:mouaz_app_018/views/tables_edit.dart';
import 'package:url_launcher/url_launcher.dart';

class Tables extends StatelessWidget {
  const Tables({super.key});
  static List localdata = [];
  static List<Map> notifierlist = [
    {'notifier': notifierGroupsdata, 'model': 'groups'},
    {'notifier': notifierRemindsdata, 'model': 'reminds'},
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (d) {
        RemindM.searchcontroller.text = '';
      },
      child: FutureM(
          refnotifier: notifierRemindsdata,
          model: 'reminds',
          childWidget: (data) {
            return RemindM(basedata: data);
          }),
    );
  }
}

class RemindM extends ConsumerWidget {
  const RemindM({super.key, required this.basedata});
  final List basedata;
  static TextEditingController searchcontroller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Map> maincolumns = [
      {
        'width': 150.0,
        'label': 'المعرف',
        'sortby': 'id',
      },
      {
        'width': 250.0,
        'label': 'الاسم',
        'sortby': 'remindname',
      },
      {
        'width': 200.0,
        'label': 'تاريخ التذكير',
        'sortby': 'expiredate',
      },
    ];
    Tables.localdata = basedata;
    Tables.localdata = ref.watch(notifierRemindsdata);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            title: const Text("جداول"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
            leading: const Hero(
                tag: 'tables_herotag',
                child: Icon(Icons.watch_later_outlined, size: 40)),
          ),
          body: Stack(children: [
            Tables.localdata.isEmpty
                ? const Center(
                    child: Text("لا يوجد بيانات لعرضها"),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        SearchM(
                            searchcontroller: searchcontroller,
                            refnotifier: notifierRemindsdata,
                            searchrange: const [
                              'remindname',
                              'reminddesc',
                              'expiredate',
                              'remindtype',
                              'groups'
                            ]),
                        const SizedBox(
                          height: 10,
                        ),
                        OnChooseBar(
                          localdata: Tables.localdata,
                          ref: ref,
                          notifierlist: Tables.notifierlist,
                          searchcontroller: searchcontroller,
                          name: 'remindname',
                          model: 'reminds',
                        ),
                        Expanded(
                            child: datawidget(
                                ctx: context,
                                maincolumns: maincolumns,
                                ref: ref,
                                refnotifier: notifierRemindsdata)),
                      ]),
            NavBarMrightside(
              icon: Icons.add,
              label: "إضافة جدول جديد",
              function: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                // for (var i in RemindsE.localdata
                //     .where((element) => element['type'] == 'tf')) {
                //   i['controller'].text = '';
                //   i['hint'] = '';
                // }
                // RemindsE.localdata[4]['value'] = true;
                // RemindsE.localdata[5]['expiredate'] = DateTime.now();
                // RemindsE.localdata[7]['value'] = true;
                return const TablesE();
              })),
            ),
            NavBarMleftside(
              icon: Icons.settings,
              settingsitem: [
                {
                  'visible': kIsWeb,
                  'label': 'تصدير البيانات',
                  'icon': Icons.upload,
                  'action': () async {
                    List data = [
                      ...Tables.localdata.map((e) => {
                            ...e,
                            'groups':
                                StlFunction.getidfromasstr(source: e['groups'])
                          })
                    ];
                    StlFunction.createExcel(
                        pagename: 'reminds',
                        data: data.any((element) => element['choose'])
                            ? data
                                .where((element) => element['choose'])
                                .toList()
                            : data,
                        headers: [
                          'id',
                          'remindname',
                          'url',
                          'remindedesc',
                          'remindtype',
                          'expiredate',
                          'remindbefor',
                          'groups'
                        ],
                        ctx: context);
                  }
                },
                {
                  'visible': kIsWeb,
                  'label': 'استيراد البيانات',
                  'icon': Icons.download,
                  'action': () async {
                    await StlFunction.importexcel(
                        ctx: context,
                        headers: [
                          'id',
                          'remindname',
                          'url',
                          'remindedesc',
                          'remindtype',
                          'expiredate',
                          'remindbefor',
                          'groups'
                        ],
                        emptyroles: [1],
                        erroremptyrole: 'بعض الحقول لايمكن ان تكون فارغة',
                        createbulkfunction: (data) async {
                          return await StlFunction.createbulkreminds(
                              notifierlist: Tables.notifierlist,
                              ctx: context,
                              data: data.toString(),
                              ref: ref);
                        });
                  }
                }
              ],
            )
          ]),
        )));
  }

  datawidget({maincolumns, ref, refnotifier, required ctx}) {
    return Padding(
      padding: const EdgeInsets.only(right: 75),
      child: GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 175),
          children: [
            ...Tables.localdata.where((element) => element['search']).map((e) {
              List groups =
                  StlFunction.convertfromstrtolist(source: e['groups']);
              return TweenM(
                type: 'translatey',
                begin: -100.0,
                end: 0.0,
                durationinmilli: Tables.localdata.indexOf(e) * 50,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onLongPress: () {
                      ref
                          .read(refnotifier.notifier)
                          .chooseitem(index: Tables.localdata.indexOf(e));
                    },
                    onTap: () {
                      Tables.localdata.any((element) => element['choose'])
                          ? ref
                              .read(refnotifier.notifier)
                              .chooseitem(index: Tables.localdata.indexOf(e))
                          : showDialog(
                              context: ctx,
                              builder: (_) {
                                return AlertDialog(
                                  scrollable: true,
                                  title: Text(e['remindname']),
                                  content: Column(children: [
                                    reminddesccontent(e: e, ctx: ctx),
                                    Text(e['groups'].toString())
                                  ]),
                                  actions: [
                                    IconButton(
                                        onPressed: () {
                                          Navigator.push(ctx,
                                              MaterialPageRoute(builder: (_) {
                                            // RemindsE.localdata[0]['controller']
                                            //     .text = e['remindname'] ?? '';
                                            // RemindsE.localdata[1]['controller']
                                            //     .text = e['reminddesc'] ?? '';
                                            // RemindsE.localdata[2]['controller']
                                            //         .text =
                                            //     e['remindbefor'].toString();
                                            // RemindsE.localdata[3]['controller']
                                            //     .text = e['url'] ?? '';
                                            // RemindsE.localdata[4]['value'] =
                                            //     e['remindtype'] == 'auto'
                                            //         ? true
                                            //         : false;
                                            // RemindsE.localdata[5]
                                            //         ['expiredate'] =
                                            //     e['expiredate'] != null
                                            //         ? DateTime.parse(
                                            //             e['expiredate'])
                                            //         : DateTime.now();
                                            // RemindsE.localdata[7]['value'] =
                                            //     e['notification'];

                                            // List groups = StlFunction
                                            //     .convertfromstrtolist(
                                            //         source: e['groups']);

                                            return TablesE(mainE: e);
                                          }));
                                        },
                                        icon: Icon(Icons.edit))
                                  ],
                                );
                              });
                    },
                    child: Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 3),
                        child: Card(
                          color: e['choose'] ? Colors.blueGrey : Colors.white,
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 10,
                                  color: e['alertstatus']
                                      ? Colors.redAccent
                                      : Colors.green,
                                ),
                                Expanded(
                                  child: Text(
                                    e['remindname'].toString().length > 30
                                        ? "${e['remindname'].toString().substring(0, 30)}..."
                                        : e['remindname'],
                                  ),
                                ),
                                Divider(),
                                Expanded(
                                  child: Visibility(
                                    visible: e['remainingdays'] != null,
                                    child: Text(
                                      "${e['remainingdays']}",
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )),
                  ),
                ),
              );
            })
          ]),
    );
  }

  reminddesccontent({e, ctx}) {
    return FutureBuilder(
        future: Future(() async =>
            await StlFunction.proccesscontentwithurl(content: e['reminddesc'])),
        builder: (_, snap) {
          if (snap.hasData) {
            List u = snap.data;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectableText.rich(
                  textDirection: e['reminddesc']
                          .toString()
                          .split('')
                          .any((element) => element.contains(RegExp(r'[A-Z]')))
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  TextSpan(
                    children: [
                      ...u.map((i) => i['v']
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
                    ],
                  )),
            );
          } else {
            return const SizedBox();
          }
        });
  }
}
