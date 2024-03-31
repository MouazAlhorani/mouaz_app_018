import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as df;
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/data/basicdata.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';

class RemindsE extends StatelessWidget {
  const RemindsE({super.key, this.mainE, required this.remindgroups});
  final Map? mainE;
  final List remindgroups;
  static List groupslist = [];
  static List localdata = [
    {
      'type': 'tf',
      'label': 'الاسم',
      'controller': TextEditingController(),
      'keyboard': TextInputType.name,
      'validate_role': 'empty'
    },
    {
      'type': 'tf',
      'label': 'التفاصيل',
      'controller': TextEditingController(),
      'keyboard': TextInputType.multiline
    },
    {
      'type': 'tf',
      'label': 'ارسال التذكير قبل',
      'controller': TextEditingController(),
      'keyboard': TextInputType.number,
    },
    {
      'type': 'tf',
      'label': 'url',
      'controller': TextEditingController(),
      'keyboard': TextInputType.name,
      'validate_role': 'empty'
    },
    {'value': true, 'name': 'type'},
    {'expiredate': DateTime.now()},
    {'remindgroups': []},
    {'value': true, 'name': 'notification'},
  ];

  static List<Map> notifierlist = [
    {'notifier': notifierGroupsdata, 'model': 'groups'},
    {'notifier': notifierRemindsdata, 'model': 'reminds'},
    {'notifier': notifierRemindgroupsEdit, 'model': 'groups'},
  ];

  @override
  Widget build(BuildContext context) {
    localdata[6]['remindgroups'] = [
      ...remindgroups.map((e) {
        try {
          return e.substring(0, e.indexOf(":"));
        } catch (t) {
          return e;
        }
      })
    ];

    return FutureM(
        refnotifier: notifierGroupsdata,
        model: 'groups',
        childWidget: (data) => MmM(
              groupslist: data,
              mainE: mainE,
              remindgroups: remindgroups,
            ));
  }
}

class MmM extends ConsumerWidget {
  const MmM(
      {super.key,
      this.mainE,
      required this.groupslist,
      required this.remindgroups});
  final Map? mainE;
  final List groupslist;
  final List remindgroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    RemindsE.groupslist = [
      ...groupslist.map((e) => {...e, 'choose': false})
    ];

    RemindsE.groupslist = ref.watch(notifierRemindgroupsEdit);
    RemindsE.localdata = ref.watch(notifierRemindsEdit);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            leading: mainE == null
                ? const Icon(Icons.edit)
                : Hero(tag: '${mainE!['id']}', child: const Icon(Icons.edit)),
            title: Text(mainE == null ? "إنشاء تذكير جديد" : "تعديل تذكير"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
          ),
          body: RemindsE.localdata.isEmpty
              ? const Center(
                  child: Text("لا يوجد بيانات لعرضها"),
                )
              : SingleChildScrollView(
                  child: datacolumns(
                      ref: ref,
                      refnotifier: notifierRemindsEdit,
                      ctx: context,
                      remindgroups: RemindsE.localdata[6]['remindgroups'])),
        )));
  }

  datacolumns(
      {required WidgetRef ref,
      refnotifier,
      required ctx,
      required List remindgroups}) {
    GlobalKey<FormState> formkey = GlobalKey<FormState>();
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 500,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Form(
                      key: formkey,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ...RemindsE.localdata.sublist(0, 3).map((e) {
                              return SizedBox(
                                width: 500,
                                child: TextFormField(
                                  style: Theme.of(ctx).textTheme.bodyMedium,
                                  maxLines: e['maxlines'] ?? 1,
                                  validator: (value) {
                                    switch (e['validate_role']) {
                                      case 'empty':
                                        if (e['controller'].text != null &&
                                            e['controller']
                                                .text
                                                .trim()
                                                .isEmpty) {
                                          return "لا يمكن ان يكون الحقل فارغا";
                                        }
                                    }
                                    return null;
                                  },
                                  textAlign: TextAlign.center,
                                  controller: e['controller'],
                                  obscureText: e['obscuretext'] ?? false,
                                  keyboardType: e['keyboard'],
                                  decoration: InputDecoration(
                                    label: Text(e['label']),
                                    hintText: e['hint'],
                                  ),
                                ),
                              );
                            }),
                            Visibility(
                              visible: RemindsE.localdata[4]['value'],
                              child: SizedBox(
                                width: 500,
                                child: TextFormField(
                                  style: Theme.of(ctx).textTheme.bodyMedium,
                                  maxLines:
                                      RemindsE.localdata[3]['maxlines'] ?? 1,
                                  validator: (value) {
                                    if (RemindsE.localdata[3]['controller']
                                                .text !=
                                            null &&
                                        RemindsE.localdata[3]['controller'].text
                                            .trim()
                                            .isEmpty) {
                                      return "لا يمكن ان يكون الحقل فارغا";
                                    } else if (!RemindsE
                                        .localdata[3]['controller'].text
                                        .toString()
                                        .toLowerCase()
                                        .startsWith("https://")) {
                                      return "عنوان غير صالح .. مثال : https://google.com";
                                    }
                                    return null;
                                  },
                                  textAlign: TextAlign.center,
                                  controller: RemindsE.localdata[3]
                                      ['controller'],
                                  obscureText: RemindsE.localdata[3]
                                          ['obscuretext'] ??
                                      false,
                                  keyboardType: RemindsE.localdata[3]
                                      ['keyboard'],
                                  decoration: InputDecoration(
                                    label: Text(RemindsE.localdata[3]['label']),
                                    hintText: RemindsE.localdata[3]['hint'],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )),
                  SizedBox(
                    width: 500,
                    child: Row(
                      children: [
                        Switch.adaptive(
                            value: RemindsE.localdata[4]['value'],
                            onChanged: (x) {
                              ref
                                  .read(refnotifier.notifier)
                                  .switchkey(x: x, index: 4);
                            }),
                        Text(RemindsE.localdata[4]['value']
                            ? "تلقائي _ تجديد شهادة"
                            : "يدوي"),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: !RemindsE.localdata[4]['value'],
                    child: Row(
                      children: [
                        Text("تحديد تاريخ التذكير"),
                        TextButton(
                            onPressed: () async {
                              await ref
                                  .read(notifierRemindsEdit.notifier)
                                  .setdate(
                                      ctx: ctx, index: 5, label: 'expiredate');
                            },
                            child: Text(df.DateFormat("yyyy-MM-dd")
                                .format(RemindsE.localdata[5]['expiredate'])))
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 500,
                    child: Row(
                      children: [
                        Switch.adaptive(
                            value: RemindsE.localdata[7]['value'],
                            onChanged: (x) {
                              ref
                                  .read(refnotifier.notifier)
                                  .switchkey(x: x, index: 7);
                            }),
                        Text(RemindsE.localdata[7]['value']
                            ? "الإشعارات مفعلة"
                            : "الإشعارات معطلة"),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: RemindsE.groupslist.isNotEmpty,
                    child: ExpansionTile(
                      title: const Text("إضافة الى مجموعة"),
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text("المتاح"),
                            Text("الحالي"),
                          ],
                        ),
                        const Divider(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: 200,
                              height: 250,
                              decoration: BoxDecoration(border: Border.all()),
                              child: ListView(
                                children: [
                                  ...RemindsE.groupslist.map((e) => Visibility(
                                        visible: !RemindsE.localdata[6]
                                                ['remindgroups']
                                            .any((y) => y == "${e['id']}"),
                                        child: Card(
                                          color: e['choose']
                                              ? Colors.blueGrey
                                              : Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: GestureDetector(
                                              onTap: () {
                                                ref
                                                    .read(
                                                        notifierRemindgroupsEdit
                                                            .notifier)
                                                    .choose(
                                                        index: RemindsE
                                                            .groupslist
                                                            .indexOf(e));
                                              },
                                              child: MouseRegion(
                                                  cursor:
                                                      SystemMouseCursors.click,
                                                  child: Text(
                                                      "${e['groupname']}")),
                                            ),
                                          ),
                                        ),
                                      ))
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                    onPressed: () {
                                      ref
                                          .read(notifierRemindsEdit.notifier)
                                          .movetoselected(
                                              index: 6,
                                              label: 'remindgroups',
                                              clname: 'groupname',
                                              itelmist: RemindsE.groupslist
                                                  .where((element) =>
                                                      element['choose']));
                                      ref
                                          .read(
                                              notifierRemindgroupsEdit.notifier)
                                          .movei();
                                    },
                                    icon: const Icon(
                                        Icons.swipe_left_alt_rounded)),
                                IconButton(
                                    onPressed: () {
                                      ref
                                          .read(notifierRemindsEdit.notifier)
                                          .movetoavailble(
                                              index: 6,
                                              label: 'remindgroups',
                                              clname: 'groupname',
                                              itelmist: RemindsE.groupslist
                                                  .where((element) =>
                                                      element['choose'])
                                                  .toList());
                                      ref
                                          .read(
                                              notifierRemindgroupsEdit.notifier)
                                          .movei();
                                    },
                                    icon: const Icon(
                                        Icons.swipe_right_alt_rounded)),
                              ],
                            ),
                            Container(
                              width: 200,
                              height: 250,
                              decoration: BoxDecoration(border: Border.all()),
                              child: ListView(
                                children: [
                                  ...RemindsE.groupslist.map((e) => Visibility(
                                      visible: RemindsE.localdata[6]
                                              ['remindgroups']
                                          .any((y) => y == "${e['id']}"),
                                      child: GestureDetector(
                                        onTap: () => ref
                                            .read(notifierRemindgroupsEdit
                                                .notifier)
                                            .choose(
                                                index: RemindsE.groupslist
                                                    .indexOf(e)),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Card(
                                            color: e['choose']
                                                ? Colors.blueGrey
                                                : Colors.white,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text("${e['groupname']}"),
                                            ),
                                          ),
                                        ),
                                      )))
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const Divider(),
                  TextButton.icon(
                      onPressed: () async {
                        if (formkey.currentState!.validate()) {
                          await StlFunction.createEditremind(
                              notifierlist: RemindsE.notifierlist,
                              ctx: ctx,
                              ref: ref,
                              e: mainE);
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("حفظ"))
                ],
              ),
              Visibility(
                visible: mainE != null &&
                    "${BasicData.userinfo![0]['id']}" != "${mainE!['id']}",
                child: Positioned(
                    left: 0.0,
                    child: Container(
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.redAccent])),
                      child: IconButton(
                        onPressed: () => showDialog(
                            context: ctx,
                            builder: (_) => AlertDialog(
                                  title: const Text(
                                      "هل أنت متأكد من حذف التذكير؟"),
                                  actions: [
                                    IconButton(
                                        onPressed: () async =>
                                            await StlFunction.delete(
                                                notifierlist:
                                                    RemindsE.notifierlist,
                                                ctx: ctx,
                                                ref: ref,
                                                model: 'reminds',
                                                id: "${mainE!['id']}"),
                                        icon: const Icon(Icons.delete_forever))
                                  ],
                                )),
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ),
                      ),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
