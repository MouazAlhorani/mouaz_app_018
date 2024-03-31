import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/data/basicdata.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';
import 'package:mouaz_app_018/tamplates/navbarM.dart';
import 'package:mouaz_app_018/tamplates/searchM.dart';
import 'package:mouaz_app_018/views/dailytasks.dart';
import 'package:mouaz_app_018/views/dailytasksreport_edit.dart';
import 'package:mouaz_app_018/views/help_edit.dart';
import 'package:intl/intl.dart' as df;

class DailyTasksReports extends StatelessWidget {
  const DailyTasksReports({super.key});
  static List localdata = [], userreportsshow = [];
  static DateTime reportdate = DateTime.now();
  static int x = 1;
  static List<Map> notifierlist = [
    {'notifier': notifierDailyTasksReportdata, 'model': 'dailytasksreports'},
  ];
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (d) {
        DailyTasksReportsM.searchcontroller.text = '';
      },
      child: FutureM(
          refnotifier: notifierDailyTasksReportdata,
          model: 'dailytasksreports',
          childWidget: (data) {
            return DailyTasksReportsM(
              basedata: data,
              usersrepoertsshow: userreportsshow,
            );
          }),
    );
  }
}

class DailyTasksReportsM extends ConsumerWidget {
  const DailyTasksReportsM(
      {super.key, required this.basedata, required this.usersrepoertsshow});
  final List basedata, usersrepoertsshow;
  static TextEditingController searchcontroller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DailyTasksReports.localdata = basedata;
    DailyTasksReports.localdata = ref.watch(notifierDailyTasksReportdata);
    DailyTasksReports.reportdate =
        ref.watch(notifierDailyTasksReportdataSetDate);
    return PopScope(
      onPopInvoked: (did) {
        ref.read(notifierDailyTasksReportdataSetDate.notifier).setdefault();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            title: const Text("التقارير اليومية"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
            leading: const Hero(
                tag: 'dailytasksreport_herotag',
                child: Icon(Icons.report, size: 40)),
          ),
          body: Stack(children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton.icon(
                  onPressed: () async {
                    DailyTasksReports.reportdate = await ref
                        .read(notifierDailyTasksReportdataSetDate.notifier)
                        .setdate(ctx: context);
                    try {
                      await ref
                          .read(notifierDailyTasksReportdata.notifier)
                          .rebuild('dailytasksreports', context,
                              reportdate: DailyTasksReports.reportdate);
                    } catch (e) {}
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    df.DateFormat("yyyy-MM-dd")
                        .format(DailyTasksReports.reportdate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  )),
            ),
            DailyTasksReports.localdata.isEmpty
                ? const Center(
                    child: Text("لا يوجد بيانات لعرضها"),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        SearchM(
                            searchcontroller: searchcontroller,
                            refnotifier: notifierDailyTasksReportdata,
                            searchrange: const ['report', 'createby']),
                        const SizedBox(
                          height: 10,
                        ),
                        Expanded(
                            child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: SingleChildScrollView(
                                              child: datacolumns(
                                                  ctx: context,
                                                  ref: ref,
                                                  refnotifier:
                                                      notifierDailyTasksReportdata)))
                                    ])))
                      ]),
            NavBarMrightside(
              icon: Icons.add,
              label: "إنشاء تقرير جديد",
              function: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                for (var i in HelpE.localdata) {
                  i['controller'].text = '';
                  i['hint'] = '';
                }
                return const DailyTasksReportsE();
              })),
            ),
            NavBarMleftside(
              icon: Icons.settings,
              settingsitem: [
                {
                  'visible': true,
                  'label': 'المهام اليومية',
                  'icon': Icons.task,
                  'action': () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DailyTasks()))
                },
                {
                  'visible':
                      kIsWeb && BasicData.userinfo![0]['admin'] == 'superadmin',
                  'label': 'تصدير البيانات',
                  'icon': Icons.upload,
                  'action': () async {
                    StlFunction.createExcel(
                        pagename: 'dailytasksreports',
                        data: await StlFunction.getalldata(
                            ctx: context,
                            model: 'dailytasksreports',
                            reportdate: 'all'),
                        headers: [
                          'id',
                          'report',
                          'reportdate',
                          'lastupdate',
                          'createby',
                        ],
                        ctx: context);
                  }
                },
                {
                  'visible':
                      kIsWeb && BasicData.userinfo![0]['admin'] == 'superadmin',
                  'label': 'استيراد البيانات',
                  'icon': Icons.download,
                  'action': () async {
                    await StlFunction.importexcel(
                        ctx: context,
                        headers: [
                          'id',
                          'report',
                          'reportdate',
                          'lastupdate',
                          'createby',
                        ],
                        createbulkfunction: (data) async {
                          return await StlFunction.createbulktasksReports(
                              notifierlist: DailyTasksReports.notifierlist,
                              ctx: context,
                              data: data.toString(),
                              ref: ref);
                        });
                  }
                }
              ],
            )
          ]),
        )),
      ),
    );
  }

  datacolumns({required WidgetRef ref, refnotifier, required ctx}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        ...DailyTasksReports.localdata
            .where((element) => element['search'])
            .map((e) {
          String maincomment = '';
          String report = e['report'];
          if (e['report'].toString().contains("_maincomment_")) {
            maincomment = e['report'].split('_maincomment_')[1];
            report = e['report'].split('_maincomment_')[0];
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: MouseRegion(
              child: Container(
                decoration: BoxDecoration(border: Border.all()),
                width: 500,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...report.split("\n").map((e) {
                        if (e.contains('تم')) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                              Expanded(child: Text(e.substring(6)))
                            ],
                          );
                        } else {
                          return e.contains('لا')
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.close,
                                      color: Colors.redAccent,
                                    ),
                                    Expanded(child: Text(e.substring(6)))
                                  ],
                                )
                              : Row(
                                  children: [
                                    SizedBox(
                                      width: 50,
                                    ),
                                    Expanded(
                                        child: Text(
                                      e.replaceAll('_comment_', ''),
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationStyle:
                                                  TextDecorationStyle.dashed),
                                    )),
                                  ],
                                );
                        }
                      }),
                      Divider(),
                      Row(
                        children: [
                          SizedBox(
                            width: 50,
                          ),
                          Expanded(
                            child: Text(
                              maincomment,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      decoration: TextDecoration.underline,
                                      decorationStyle:
                                          TextDecorationStyle.double),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: SizedBox(
                          width: 200,
                          child: Card(
                            color: Colors.yellowAccent.withOpacity(0.6),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(e['createby']),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      df.DateFormat('yyyy-MM-dd HH:mm').format(
                                          DateTime.parse(e['reportdate'])),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
              ),
            ),
          );
        })
      ]),
    );
  }
}
