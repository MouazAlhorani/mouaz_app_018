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
import 'package:url_launcher/url_launcher.dart';

class Reminds extends StatelessWidget {
  const Reminds({super.key});
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
    Reminds.localdata = basedata;
    Reminds.localdata = ref.watch(notifierRemindsdata);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            title: const Text("التذكير"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
            leading: const Hero(
                tag: 'reminds_herotag',
                child: Icon(Icons.watch_later_outlined, size: 40)),
          ),
          body: Stack(children: [
            Reminds.localdata.isEmpty
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
                          localdata: Reminds.localdata,
                          ref: ref,
                          notifierlist: Reminds.notifierlist,
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
                        IconButton(
                            onPressed: () async {
                              await StlFunction.telegram(context);
                            },
                            icon: Icon(Icons.telegram)),
                      ]),
            NavBarMrightside(
              icon: Icons.add,
              label: "إضافة تذكير جديد",
              function: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                for (var i in RemindsE.localdata.sublist(0, 4)) {
                  i['controller'].text = '';
                  i['hint'] = '';
                }
                RemindsE.localdata[4]['value'] = true;
                RemindsE.localdata[5]['expiredate'] = DateTime.now();
                RemindsE.localdata[7]['value'] = true;
                return const RemindsE(
                  remindgroups: [],
                );
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
                      ...Reminds.localdata.map((e) => {
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
                              notifierlist: Reminds.notifierlist,
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
    return GridView(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300),
        children: [
          ...Reminds.localdata.where((element) => element['search']).map((e) {
            List groups = StlFunction.convertfromstrtolist(source: e['groups']);
            return TweenM(
              type: 'translatey',
              begin: -100.0,
              end: 0.0,
              durationinmilli: Reminds.localdata.indexOf(e) * 50,
              child: Card(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                                onPressed: () {
                                  ref
                                      .read(notifierRemindsdata.notifier)
                                      .opencard(
                                          index: Reminds.localdata.indexOf(e));
                                },
                                child: Text("إغلاق")),
                            Hero(
                                tag: "${e['id']}",
                                child: const Icon(
                                  Icons.watch_later,
                                  color: Colors.blueGrey,
                                )),
                            TextButton(
                                onPressed: () {
                                  Navigator.push(ctx,
                                      MaterialPageRoute(builder: (_) {
                                    RemindsE.localdata[0]['controller'].text =
                                        e['remindname'] ?? '';
                                    RemindsE.localdata[1]['controller'].text =
                                        e['reminddesc'] ?? '';
                                    RemindsE.localdata[2]['controller'].text =
                                        e['remindbefor'].toString();
                                    RemindsE.localdata[3]['controller'].text =
                                        e['url'] ?? '';
                                    RemindsE.localdata[4]['value'] =
                                        e['remindtype'] == 'auto'
                                            ? true
                                            : false;
                                    RemindsE.localdata[5]['expiredate'] =
                                        e['expiredate'] != null
                                            ? DateTime.parse(e['expiredate'])
                                            : DateTime.now();
                                    RemindsE.localdata[7]['value'] =
                                        e['notification'];

                                    List groups =
                                        StlFunction.convertfromstrtolist(
                                            source: e['groups']);

                                    return RemindsE(
                                        mainE: e, remindgroups: groups);
                                  }));
                                },
                                child: Text("تعديل")),
                          ],
                        ),
                        FutureBuilder(
                            future: Future(() async =>
                                await StlFunction.proccesscontentwithurl(
                                    content: e['reminddesc'])),
                            builder: (_, snap) {
                              if (snap.hasData) {
                                List u = snap.data;
                                return Expanded(
                                  child: Center(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Directionality(
                                              textDirection: TextDirection.rtl,
                                              child:
                                                  SelectableText.rich(TextSpan(
                                                children: [
                                                  ...u.map((i) => i['v']
                                                      ? TextSpan(
                                                          style: Theme.of(ctx)
                                                              .textTheme
                                                              .bodyMedium!
                                                              .copyWith(
                                                                  decoration: TextDecoration
                                                                      .underline),
                                                          text: i['t'],
                                                          recognizer: TapGestureRecognizer()
                                                            ..onTap = () async =>
                                                                await launchUrl(
                                                                    Uri.parse(i[
                                                                        't'])))
                                                      : TextSpan(text: i['t']))
                                                ],
                                              )),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox();
                              }
                            }),
                        Text(
                          e['remindname'],
                          textDirection: TextDirection.ltr,
                        ),
                        ...groups.map((e) => Text(e.replaceAll("'", ''))),
                      ],
                    ),
                    GestureDetector(
                      onLongPress: () {
                        ref
                            .read(refnotifier.notifier)
                            .chooseitem(index: Reminds.localdata.indexOf(e));
                      },
                      onTap: () {
                        Reminds.localdata.any((element) => element['choose'])
                            ? ref
                                .read(refnotifier.notifier)
                                .chooseitem(index: Reminds.localdata.indexOf(e))
                            : ref
                                .read(notifierRemindsdata.notifier)
                                .opencard(index: Reminds.localdata.indexOf(e));
                      },
                      child: TweenM(
                        type: 'rotationZ',
                        begin: 0.0,
                        end: e['opencard'] ? 1.5 : 0.0,
                        durationinmilli: 300,
                        child: TweenM(
                          type: 'opacity',
                          begin: 0.0,
                          end: e['opencard'] ? 0.0 : 1.0,
                          durationinmilli: 300,
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      e['alertstatus']
                                          ? Colors.red
                                          : Colors.white,
                                      e['choose']
                                          ? Colors.blueAccent
                                          : Colors.white,
                                    ])),
                            child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 3, bottom: 3),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${e['remindname']}",
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                     e['expiredate']!=null?   df.DateFormat("yyyy-MM-dd HH:mm")
                                            .format(DateTime.parse(
                                                e['expiredate'])):"غير محدد",
                                        textDirection: TextDirection.ltr,
                                      ),
                                      Visibility(
                                        visible: e['remainingdays'] != null,
                                        child: Text(
                                          "${e['remainingdays']}",
                                          textDirection: TextDirection.ltr,
                                        ),
                                      )
                                    ],
                                  ),
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
        ]);
  }
}
