import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';
import 'package:mouaz_app_018/tamplates/navbarM.dart';
import 'package:mouaz_app_018/tamplates/onchoosebard.dart';
import 'package:mouaz_app_018/tamplates/searchM.dart';
import 'package:mouaz_app_018/views/emails_edit.dart';

class Emails extends StatelessWidget {
  const Emails({super.key});
  static List localdata = [];
  static List<Map> notifierlist = [
    {'notifier': notifierEmailsdata, 'model': 'emails'},
  ];
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (d) {
        MmM.searchcontroller.text = '';
      },
      child: FutureM(
          refnotifier: notifierEmailsdata,
          model: 'emails',
          childWidget: (data) {
            return MmM(basedata: data);
          }),
    );
  }
}

class MmM extends ConsumerWidget {
  const MmM({super.key, required this.basedata});
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
        'width': 150.0,
        'label': 'الحالة',
        'sortby': 'case',
      },
      {
        'width': 150.0,
        'label': 'وقت الوصول',
        'sortby': 'arrival_time',
      },
      {
        'width': 200.0,
        'label': 'الاسم',
        'sortby': 'name',
      },
      {
        'width': 150.0,
        'label': 'الأيام',
        'sortby': 'days',
      },
      {
        'width': 150.0,
        'label': 'معرفات الأخطاء',
        'sortby': 'error_def',
      },
      {
        'width': 150.0,
        'label': 'وقت الوصول المتوقع',
        'sortby': 'expected_arrival_time',
      },
    ];
    Emails.localdata = basedata;
    Emails.localdata = ref.watch(notifierEmailsdata);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            title: const Text("تفقد الايميلات اليومية"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
            leading: const Hero(
                tag: 'emails_herotag',
                child: Icon(Icons.email_outlined, size: 40)),
          ),
          body: Stack(children: [
            Emails.localdata.isEmpty
                ? const Center(
                    child: Text("لا يوجد بيانات لعرضها"),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        SearchM(
                            searchcontroller: searchcontroller,
                            refnotifier: notifierEmailsdata,
                            searchrange: const [
                              'id',
                              'case',
                              'arrival_time',
                              'name',
                              'error_def',
                              'days',
                              'expected_arrival_time'
                            ]),
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
                                      maincolumnsrow(
                                          maincolumns: maincolumns,
                                          ref: ref,
                                          refnotifier: notifierEmailsdata),
                                      OnChooseBar(
                                        localdata: Emails.localdata,
                                        ref: ref,
                                        notifierlist: Emails.notifierlist,
                                        searchcontroller: searchcontroller,
                                        name: 'name',
                                        model: 'emails',
                                      ),
                                      Expanded(
                                          child: SingleChildScrollView(
                                              child: datacolumns(
                                                  ctx: context,
                                                  maincolumns: maincolumns,
                                                  ref: ref,
                                                  refnotifier:
                                                      notifierEmailsdata)))
                                    ])))
                      ]),
            NavBarMrightside(
              icon: Icons.add,
              label: "إضافة إيميل جديد",
              function: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                for (var i in EmailsE.localdata
                    .where((element) => element['type'] == 'tf')) {
                  i['controller'].text = '';
                  i['hint'] = '';
                }
                for (var i in EmailsE.localdata[3]['weekdays']) {
                  i['choose'] = true;
                }
                EmailsE.localdata[3]['weekdays'].last['day'].text = '1';
                EmailsE.localdata[4]['selected'] = TimeOfDay.now();
                return const EmailsE(
                  emailgroups: [],
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
                      ...Emails.localdata.map((e) => {
                            ...e,
                            'groups':
                                StlFunction.getidfromasstr(source: e['groups'])
                          })
                    ];
                    StlFunction.createExcel(
                        pagename: 'emails',
                        data: data.any((element) => element['choose'])
                            ? data
                                .where((element) => element['choose'])
                                .toList()
                            : data,
                        headers: [
                          'id',
                          'case',
                          'arrival_time',
                          'name',
                          'error_def',
                          'days',
                          'expected_arrival_time'
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
                          'case',
                          'arrival_time',
                          'name',
                          'error_def',
                          'days',
                          'expected_arrival_time'
                        ],
                        emptyroles: [3, 4, 5],
                        erroremptyrole: 'بعض الحقول لايمكن ان تكون فارغة',
                        createbulkfunction: (data) async {
                          return await StlFunction.createbulkusers(
                              notifierlist: Emails.notifierlist,
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

  maincolumnsrow({maincolumns, ref, refnotifier}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...maincolumns.map((e) => Container(
              decoration: const BoxDecoration(
                  color: Colors.amber,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        blurRadius: 0.6,
                        offset: Offset(-2, 3))
                  ],
                  borderRadius:
                      BorderRadius.only(bottomLeft: Radius.circular(5)),
                  border: Border(bottom: BorderSide(), left: BorderSide())),
              width: e['width'],
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {
                        ref
                            .read(refnotifier.notifier)
                            .sort(sortby: e['sortby']);
                      },
                      icon: const Icon(Icons.sort_by_alpha_rounded)),
                  Text(e['label']),
                ],
              ),
            )),
        Container(
          decoration: const BoxDecoration(
              color: Colors.amber,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey, blurRadius: 0.6, offset: Offset(-2, 3))
              ],
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(5)),
              border: Border(bottom: BorderSide(), left: BorderSide())),
          width: 150,
          child: Row(
            children: [
              IconButton(
                  onPressed: () {
                    ref.read(refnotifier.notifier).sort(sortby: 'groups');
                  },
                  icon: const Icon(Icons.sort_by_alpha_rounded)),
              const Text("المجموعات"),
            ],
          ),
        )
      ],
    );
  }

  datacolumns({maincolumns, ref, refnotifier, required ctx}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        ...Emails.localdata.where((element) => element['search']).map((e) =>
            Padding(
                padding: const EdgeInsets.only(top: 3, bottom: 3),
                child: GestureDetector(
                    onLongPress: () {
                      ref
                          .read(refnotifier.notifier)
                          .chooseitem(index: Emails.localdata.indexOf(e));
                    },
                    onTap: () {
                      Emails.localdata.any((element) => element['choose'])
                          ? ref
                              .read(refnotifier.notifier)
                              .chooseitem(index: Emails.localdata.indexOf(e))
                          : Navigator.push(ctx, MaterialPageRoute(builder: (_) {
                              List groups = StlFunction.convertfromstrtolist(
                                  source: e['groups']);
                              return EmailsE(mainE: e, emailgroups: groups);
                            }));
                    },
                    child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  e['choose']
                                      ? Colors.redAccent
                                      : e['enable']
                                          ? Colors.greenAccent
                                          : Colors.grey,
                                  Colors.transparent
                                ]),
                                border: const Border(bottom: BorderSide())),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Hero(
                                      tag: "${e['id']}",
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.blueGrey,
                                      )),
                                  ...maincolumns
                                      .sublist(0, 1)
                                      .map((m) => SizedBox(
                                            width: m['width'],
                                            child: Text("# ${e[m['sortby']]}"),
                                          )),
                                  ...maincolumns.sublist(1).map((m) => SizedBox(
                                        width: m['width'],
                                        child: Text(
                                            e[m['sortby']].runtimeType == bool
                                                ? e[m['sortby']]
                                                    ? "فعال"
                                                    : "معطل"
                                                : "${e[m['sortby']]}"),
                                      )),
                                  groups(e: e, ctx: ctx)
                                ]))))))
      ]),
    );
  }

  groups({e, ctx}) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...StlFunction.convertfromstrtolist(source: e['groups'])
              .map((e) => e.isNotEmpty
                  ? TextButton(
                      onPressed: () async {
                        var mainE = await StlFunction.getsingledata(
                            ctx: ctx,
                            model: 'emails',
                            id: e.substring(0, e.indexOf(":")));
                        Navigator.push(ctx, MaterialPageRoute(builder: (_) {
                          List groups = StlFunction.convertfromstrtolist(
                              source: mainE[0]['groups']);
                          return EmailsE(
                            emailgroups: groups,
                            mainE: mainE[0],
                          );
                        }));
                      },
                      child: Text(
                        e.split(":")[1].replaceAll("'", ''),
                        style: Theme.of(ctx).textTheme.bodyMedium!,
                      ),
                    )
                  : const SizedBox())
        ],
      ),
    );
  }
}
