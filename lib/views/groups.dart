import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';
import 'package:mouaz_app_018/tamplates/navbarM.dart';
import 'package:mouaz_app_018/tamplates/onchoosebard.dart';
import 'package:mouaz_app_018/tamplates/searchM.dart';
import 'package:mouaz_app_018/views/accounts_edit.dart';
import 'package:mouaz_app_018/views/groups_edit.dart';

class Groups extends StatelessWidget {
  const Groups({super.key});
  static List localdata = [];
  static List<Map> notifierlist = [
    {'notifier': notifierGroupsdata, 'model': 'groups'},
    {'notifier': notifierAccountgroupsEdit, 'model': 'groups'},
    {'notifier': notifierAccountsdata, 'model': 'accounts'},
  ];
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (d) {
        MmM.searchcontroller.text = '';
      },
      child: FutureM(
          refnotifier: notifierGroupsdata,
          model: 'groups',
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
        'width': 400.0,
        'label': 'الاسم',
        'sortby': 'groupname',
      },
    ];
    Groups.localdata = basedata;
    Groups.localdata = ref.watch(notifierGroupsdata);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            title: const Text("إدارة المجموعات"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
            leading: const Hero(
                tag: 'groups_herotag', child: Icon(Icons.groups, size: 40)),
          ),
          body: Stack(children: [
            Groups.localdata.isEmpty
                ? const Center(
                    child: Text("لا يوجد بيانات لعرضها"),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        SearchM(
                            searchcontroller: searchcontroller,
                            refnotifier: notifierGroupsdata,
                            searchrange: const ['groupname', 'users']),
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
                                          refnotifier: notifierGroupsdata),
                                      OnChooseBar(
                                        localdata: Groups.localdata,
                                        ref: ref,
                                        notifierlist: Groups.notifierlist,
                                        searchcontroller: searchcontroller,
                                        name: 'groupname',
                                        model: 'groups',
                                      ),
                                      Expanded(
                                          child: SingleChildScrollView(
                                              child: datacolumns(
                                                  ctx: context,
                                                  maincolumns: maincolumns,
                                                  ref: ref,
                                                  refnotifier:
                                                      notifierGroupsdata)))
                                    ])))
                      ]),
            NavBarMrightside(
              icon: Icons.add,
              label: "إضافة مجموعة جديدة",
              function: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                for (var i in GroupsE.localdata.sublist(0, 3)) {
                  i['controller'].text = '';
                  i['hint'] = '';
                }
                GroupsE.localdata[3]['value'] = true;
                return const GroupsE(
                  groupusers: [],
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
                      ...Groups.localdata.map((e) => {
                            ...e,
                            'users':
                                StlFunction.getidfromasstr(source: e['users'])
                          })
                    ];
                    StlFunction.createExcel(
                        pagename: 'groups',
                        data: data.any((element) => element['choose'])
                            ? data
                                .where((element) => element['choose'])
                                .toList()
                            : data,
                        headers: [
                          'id',
                          'groupname',
                          'notification',
                          'chat_id',
                          'api_token',
                          'users'
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
                          'groupname',
                          'notification',
                          'chat_id',
                          'api_token',
                          'users'
                        ],
                        emptyroles: [1],
                        erroremptyrole: 'بعض الحقول لايمكن ان تكون فارغة',
                        createbulkfunction: (data) async {
                          return await StlFunction.createbulkgroups(
                              notifierlist: Groups.notifierlist,
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
            ))
      ],
    );
  }

  datacolumns({maincolumns, ref, refnotifier, required ctx}) {
    return Column(children: [
      ...Groups.localdata
          .where((element) => element['search'])
          .map((e) => Padding(
                padding: const EdgeInsets.only(top: 3, bottom: 3),
                child: GestureDetector(
                  onLongPress: () {
                    ref
                        .read(refnotifier.notifier)
                        .chooseitem(index: Groups.localdata.indexOf(e));
                  },
                  onTap: () {
                    Groups.localdata.any((element) => element['choose'])
                        ? ref
                            .read(refnotifier.notifier)
                            .chooseitem(index: Groups.localdata.indexOf(e))
                        : null;
                  },
                  child: Container(
                    width: 500,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          e['choose'] ? Colors.redAccent : Colors.greenAccent,
                          Colors.transparent
                        ]),
                        border: const Border(bottom: BorderSide())),
                    child: ExpansionTile(
                      trailing: IconButton(
                          onPressed: () {
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) {
                              GroupsE.localdata[0]['controller'].text =
                                  e['groupname'] ?? '';
                              GroupsE.localdata[1]['controller'].text =
                                  e['chat_id'] ?? '';
                              GroupsE.localdata[2]['controller'].text =
                                  e['api_token'] ?? '';
                              GroupsE.localdata[3]['value'] = e['notification'];
                              List users = StlFunction.convertfromstrtolist(
                                  source: e['users']);
                              return GroupsE(groupusers: users, mainE: e);
                            }));
                          },
                          icon: Icon(Icons.edit)),
                      title: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Hero(
                                tag: "${e['id']}",
                                child: const Icon(
                                  Icons.groups,
                                  color: Colors.blueGrey,
                                )),
                            ...maincolumns.sublist(0, 1).map((m) => SizedBox(
                                  width: m['width'],
                                  child: Text("# ${e[m['sortby']]}"),
                                )),
                            ...maincolumns.sublist(1).map((m) => SizedBox(
                                  width: m['width'] - 150,
                                  child: Text(e[m['sortby']].runtimeType == bool
                                      ? e[m['sortby']]
                                          ? "فعال"
                                          : "معطل"
                                      : "${e[m['sortby']]}"),
                                )),
                          ]),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 150),
                          child: ExpansionTile(
                            title: const Row(
                              children: [
                                Icon(Icons.group),
                                Text("الأعضاء"),
                              ],
                            ),
                            children: [users(ctx: ctx, e: e)],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 150),
                          child: ExpansionTile(
                              title: Row(
                            children: [
                              Icon(Icons.watch_later),
                              Text("التذكير"),
                            ],
                          )),
                        )
                      ],
                    ),
                  ),
                ),
              ))
    ]);
  }

  users({e, ctx}) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...StlFunction.convertfromstrtolist(source: e['users'])
              .map((e) => e.isNotEmpty
                  ? Row(
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            color: e
                                        .split(":")[1]
                                        .replaceAll("'", '')
                                        .substring(
                                            1,
                                            e
                                                    .split(":")[1]
                                                    .replaceAll("'", '')
                                                    .length -
                                                1)
                                        .split(',')[1]
                                        .trim() ==
                                    'True'
                                ? Colors.green
                                : Colors.grey),
                        TextButton(
                          onPressed: () async {
                            var mainE = await StlFunction.getsingledata(
                                ctx: ctx,
                                model: 'accounts',
                                id: e.substring(0, e.indexOf(":")));
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) {
                              AccountsE.localdata[0]['controller'].text =
                                  mainE[0]['fullname'] ?? '';
                              AccountsE.localdata[1]['controller'].text =
                                  mainE[0]['username'] ?? '';
                              AccountsE.localdata[2]['controller'].text =
                                  mainE[0]['email'] ?? '';
                              AccountsE.localdata[3]['controller'].text =
                                  mainE[0]['phone'] ?? '';
                              AccountsE.localdata[4]['controller'].text = '';
                              AccountsE.localdata[4]['hint'] = 'بدون تغيير';
                              AccountsE.localdata[5]['controller'].text = '';
                              AccountsE.localdata[5]['hint'] = 'بدون تغيير';
                              AccountsE.localdata[6]['selected'] =
                                  mainE[0]['admin'];
                              AccountsE.localdata[7]['value'] =
                                  mainE[0]['enable'];
                              List groups = StlFunction.convertfromstrtolist(
                                  source: mainE[0]['groups']);
                              return AccountsE(
                                usergroups: groups,
                                mainE: mainE[0],
                              );
                            }));
                          },
                          child: Text(
                            e
                                .split(":")[1]
                                .replaceAll("'", '')
                                .substring(
                                    1,
                                    e.split(":")[1].replaceAll("'", '').length -
                                        1)
                                .split(',')[0],
                            style: Theme.of(ctx).textTheme.bodyMedium!,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox())
        ],
      ),
    );
  }
}
