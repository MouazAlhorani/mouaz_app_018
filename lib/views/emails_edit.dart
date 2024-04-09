import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/data/basicdata.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';
import 'package:intl/intl.dart' as df;

class EmailsE extends StatelessWidget {
  const EmailsE(
      {super.key,
      this.mainE,
      this.selfedit = false,
      required this.emailgroups});
  final Map? mainE;
  final bool selfedit;
  final List emailgroups;
  static List groupslist = [], weekdays = [];
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
      'maxlines': 3,
      'label': 'معرفات الأخطاء',
      'controller': TextEditingController(),
      'keyboard': TextInputType.multiline,
      'validate_role': 'empty'
    },
    {
      'type': 'tf',
      'maxlines': 3,
      'label': 'المستثنى من معرفات الأخطاء',
      'controller': TextEditingController(),
      'keyboard': TextInputType.multiline,
      'validate_role': 'empty'
    },
    {
      'type': '',
      'weekdays': [
        {'day': 'friday', 'choose': false},
        {'day': 'satarday', 'choose': false},
        {'day': 'sunday', 'choose': false},
        {'day': 'monday', 'choose': false},
        {'day': 'tuesday', 'choose': false},
        {'day': 'wednasday', 'choose': false},
        {'day': 'thursday', 'choose': false},
        {'day': TextEditingController(text: '1'), 'choose': false}
      ]
    },
    {
      'type': 'time_hours',
      'selected': TimeOfDay.now(),
    },
    {'emailgroups': []},
  ];

  static List<Map> notifierlist = [
    {'notifier': notifierGroupsdata, 'model': 'groups'},
    {'notifier': notifierEmailsdata, 'model': 'emails'},
    {'notifier': notifierEmailgroupsEdit, 'model': 'groups'},
  ];

  @override
  Widget build(BuildContext context) {
    localdata[5]['emailgroups'] = [
      ...emailgroups.map((e) {
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
              selfedit: selfedit,
              mainE: mainE,
              emailgroups: emailgroups,
            ));
  }
}

class MmM extends ConsumerWidget {
  const MmM(
      {super.key,
      this.mainE,
      this.selfedit = false,
      required this.groupslist,
      required this.emailgroups});
  final Map? mainE;
  final bool selfedit;
  final List groupslist;
  final List emailgroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    EmailsE.groupslist = [
      ...groupslist.map((e) => {...e, 'choose': false})
    ];

    EmailsE.groupslist = ref.watch(notifierEmailgroupsEdit);
    EmailsE.localdata = ref.watch(notifierEmailsEdit);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            leading: mainE == null
                ? const Icon(Icons.edit)
                : Hero(tag: '${mainE!['id']}', child: const Icon(Icons.edit)),
            title: Text(mainE == null ? "إنشاء إيميل جديد" : "تعديل إيميل"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
          ),
          body: EmailsE.localdata.isEmpty
              ? const Center(
                  child: Text("لا يوجد بيانات لعرضها"),
                )
              : SingleChildScrollView(
                  child: datacolumns(
                      ref: ref,
                      refnotifier: notifierEmailsEdit,
                      ctx: context,
                      emailgroups: EmailsE.localdata[5]['emailgroups'])),
        )));
  }

  datacolumns(
      {required WidgetRef ref,
      refnotifier,
      required ctx,
      required List emailgroups}) {
    GlobalKey<FormState> formkey = GlobalKey<FormState>();
    return Center(
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
                          ...EmailsE.localdata
                              .where((element) => element['type'] == 'tf')
                              .map((e) {
                            return SizedBox(
                              width: 500,
                              child: TextFormField(
                                style: Theme.of(ctx).textTheme.bodyMedium,
                                maxLines: e['maxlines'] ?? 1,
                                validator: (value) {
                                  switch (e['validate_role']) {
                                    case 'empty':
                                      if (e['controller'].text != null &&
                                          e['controller'].text.trim().isEmpty) {
                                        return "لا يمكن ان يكون الحقل فارغا";
                                      }
                                    case 'empty_if_not_e':
                                      if (mainE == null &&
                                          e['controller'].text != null &&
                                          e['controller'].text.isEmpty) {
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
                                  suffix: e['suffix_icon'] == null
                                      ? null
                                      : IconButton(
                                          onPressed: () => ref
                                              .read(refnotifier.notifier)
                                              .swappasswordstatus(
                                                  index: EmailsE.localdata
                                                      .indexOf(e)),
                                          icon: Icon(e['suffix_icon'])),
                                  label: Text(e['label']),
                                  hintText: e['hint'],
                                ),
                              ),
                            );
                          })
                        ],
                      ),
                    )),
                const Divider(),
                Visibility(
                  visible: EmailsE.groupslist.isNotEmpty && selfedit == false,
                  child: ExpansionTile(
                    title: const Text("تحديد أيام وصول الايميل"),
                    children: [
                      ...EmailsE.localdata[3]['weekdays']
                          .sublist(
                              0, EmailsE.localdata[3]['weekdays'].length - 2)
                          .map((e) => Row(
                                children: [
                                  Checkbox(
                                      value: e['choose'],
                                      onChanged: (x) {
                                        ref
                                            .read(notifierEmailsEdit.notifier)
                                            .chooseinside(
                                                x: x,
                                                index: 3,
                                                name: 'weekdays',
                                                subindex: EmailsE.localdata[3]
                                                        ['weekdays']
                                                    .indexOf(e));
                                      }),
                                  Text("${e['day']}")
                                ],
                              )),
                      TextFormField(
                          decoration: InputDecoration(
                              helperText:
                                  "تحديد يوم مخصص من الشهر مثل 15 او 12"),
                          textAlign: TextAlign.center,
                          controller:
                              EmailsE.localdata[3]['weekdays'].last['day'])
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text("وقت وصول الايميل"),
                      TextButton(
                          onPressed: () {
                            ref
                                .read(notifierEmailsEdit.notifier)
                                .settime(ctx: ctx, label: 'selected', index: 4);
                          },
                          child: Text(
                            "${EmailsE.localdata[4]['selected'].hour}:${EmailsE.localdata[4]['selected'].minute}",
                            textDirection: TextDirection.ltr,
                          ))
                    ],
                  ),
                ),
                Divider(),
                Visibility(
                  visible: EmailsE.groupslist.isNotEmpty,
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
                                ...EmailsE.groupslist.map((e) => Visibility(
                                      visible: !EmailsE.localdata[5]
                                              ['emailgroups']
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
                                                  .read(notifierEmailgroupsEdit
                                                      .notifier)
                                                  .choose(
                                                      index: EmailsE.groupslist
                                                          .indexOf(e));
                                            },
                                            child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child:
                                                    Text("${e['groupname']}")),
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
                                        .read(notifierEmailsEdit.notifier)
                                        .movetoselected(
                                            index: 5,
                                            label: 'emailgroups',
                                            clname: 'groupname',
                                            itelmist: EmailsE.groupslist.where(
                                                (element) =>
                                                    element['choose']));
                                    ref
                                        .read(notifierEmailgroupsEdit.notifier)
                                        .movei();
                                  },
                                  icon:
                                      const Icon(Icons.swipe_left_alt_rounded)),
                              IconButton(
                                  onPressed: () {
                                    ref
                                        .read(notifierEmailsEdit.notifier)
                                        .movetoavailble(
                                            index: 5,
                                            label: 'emailgroups',
                                            clname: 'groupname',
                                            itelmist: EmailsE.groupslist
                                                .where((element) =>
                                                    element['choose'])
                                                .toList());
                                    ref
                                        .read(notifierEmailgroupsEdit.notifier)
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
                                ...EmailsE.groupslist.map((e) => Visibility(
                                    visible: EmailsE.localdata[5]['emailgroups']
                                        .any((y) => y == "${e['id']}"),
                                    child: GestureDetector(
                                      onTap: () => ref
                                          .read(
                                              notifierEmailgroupsEdit.notifier)
                                          .choose(
                                              index: EmailsE.groupslist
                                                  .indexOf(e)),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Card(
                                          color: e['choose']
                                              ? const Color.fromRGBO(
                                                  96, 125, 139, 1)
                                              : Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
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
                        await StlFunction.createEdituser(
                            notifierlist: EmailsE.notifierlist,
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
                                title:
                                    const Text("هل أنت متأكد من حذف الإيميل؟"),
                                actions: [
                                  IconButton(
                                      onPressed: () async =>
                                          await StlFunction.delete(
                                              notifierlist:
                                                  EmailsE.notifierlist,
                                              ctx: ctx,
                                              ref: ref,
                                              model: 'emails',
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
    );
  }
}
