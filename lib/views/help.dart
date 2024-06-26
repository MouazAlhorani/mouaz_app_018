import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/controllers/tween_mz.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';
import 'package:mouaz_app_018/tamplates/navbarM.dart';
import 'package:mouaz_app_018/tamplates/onchoosebard.dart';
import 'package:mouaz_app_018/tamplates/searchM.dart';
import 'package:mouaz_app_018/views/help_edit.dart';
import 'package:url_launcher/url_launcher.dart';

class Help extends StatelessWidget {
  const Help({super.key});
  static List localdata = [];
  static List<Map> notifierlist = [
    {'notifier': notifierHelpdata, 'model': 'helps'},
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (d) {
        HelpM.searchcontroller.text = '';
      },
      child: FutureM(
          refnotifier: notifierHelpdata,
          model: 'helps',
          childWidget: (data) {
            return HelpM(basedata: data);
          }),
    );
  }
}

class HelpM extends ConsumerWidget {
  const HelpM({super.key, required this.basedata});
  final List basedata;
  static TextEditingController searchcontroller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Map> maincolumns = [
      {
        'width': 100.0,
        'label': 'المعرف',
        'sortby': 'id',
      },
      {
        'width': 400.0,
        'label': 'الاسم',
        'sortby': 'helpname',
      }
    ];
    Help.localdata = basedata;
    Help.localdata = ref.watch(notifierHelpdata);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            title: const Text("ملفات المساعدة"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
            leading: const Hero(
                tag: 'help_herotag', child: Icon(Icons.help, size: 40)),
          ),
          body: Stack(children: [
            Help.localdata.isEmpty
                ? const Center(
                    child: Text("لا يوجد بيانات لعرضها"),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        SearchM(
                            searchcontroller: searchcontroller,
                            refnotifier: notifierHelpdata,
                            searchrange: const ['helpname', 'helpdesc']),
                        const SizedBox(
                          height: 10,
                        ),
                        OnChooseBar(
                          localdata: Help.localdata,
                          ref: ref,
                          notifierlist: Help.notifierlist,
                          searchcontroller: searchcontroller,
                          name: 'helpname',
                          model: 'helps',
                        ),
                        Expanded(
                            child: datawidget(
                                ctx: context,
                                maincolumns: maincolumns,
                                ref: ref,
                                refnotifier: notifierHelpdata))
                      ]),
            NavBarMrightside(
              icon: Icons.add,
              label: "إضافة ملف جديد",
              function: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                for (var i in HelpE.localdata) {
                  i['controller'].text = '';
                  i['hint'] = '';
                }
                return const HelpE();
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
                    StlFunction.createExcel(
                        pagename: 'helps',
                        data: Help.localdata.any((element) => element['choose'])
                            ? Help.localdata
                                .where((element) => element['choose'])
                                .toList()
                            : Help.localdata,
                        headers: [
                          'id',
                          'helpname',
                          'helpdesc',
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
                          'helpname',
                          'helpdesc',
                        ],
                        createbulkfunction: (data) async {
                          return await StlFunction.createbulkhelps(
                              notifierlist: Help.notifierlist,
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
              maxCrossAxisExtent: 150),
          children: [
            ...Help.localdata.where((element) => element['search']).map((e) =>
                TweenM(
                  type: 'translatey',
                  begin: -100.0,
                  end: 0.0,
                  durationinmilli: Help.localdata.indexOf(e) * 50,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onLongPress: () {
                        ref
                            .read(refnotifier.notifier)
                            .chooseitem(index: Help.localdata.indexOf(e));
                      },
                      onTap: () {
                        Help.localdata.any((element) => element['choose'])
                            ? ref
                                .read(refnotifier.notifier)
                                .chooseitem(index: Help.localdata.indexOf(e))
                            : showDialog(
                                context: ctx,
                                builder: (_) {
                                  return AlertDialog(
                                    scrollable: true,
                                    title: Text(e['helpname']),
                                    content: helpdesccontent(e: e, ctx: ctx),
                                    actions: [
                                      IconButton(
                                          onPressed: () {
                                            Navigator.push(ctx,
                                                MaterialPageRoute(builder: (_) {
                                              HelpE.localdata[0]['controller']
                                                  .text = e['helpname'] ?? '';
                                              HelpE.localdata[1]['controller']
                                                  .text = e['helpdesc'] ?? '';
                                              return HelpE(mainE: e);
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
                            elevation: 6,
                            shadowColor:
                                e['choose'] ? Colors.red : Colors.blue.shade100,
                            child: Center(
                              child: Text(
                                e['helpname'],
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )),
                    ),
                  ),
                ))
          ]),
    );
  }

  helpdesccontent({e, ctx}) {
    return FutureBuilder(
        future: Future(() async =>
            await StlFunction.proccesscontentwithurl(content: e['helpdesc'])),
        builder: (_, snap) {
          if (snap.hasData) {
            List u = snap.data;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectableText.rich(
                  textDirection: e['helpdesc']
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
