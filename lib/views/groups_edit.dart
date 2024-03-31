import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';

class GroupsE extends StatelessWidget {
  const GroupsE({super.key, this.mainE, required this.groupusers});
  final Map? mainE;
  final List groupusers;
  static List userslist = [];
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
      'label': 'chat_id for telegram msg',
      'controller': TextEditingController(),
      'keyboard': TextInputType.name,
    },
    {
      'type': 'tf',
      'label': 'api_token for telegram msg',
      'controller': TextEditingController(),
      'keyboard': TextInputType.emailAddress
    },
    {
      'type': 'notifications',
      'value': true,
    },
    {'groupusers': []}
  ];
  static List<Map> notifierlist = [
    {'notifier': notifierGroupsdata, 'model': 'groups'},
    {'notifier': notifierGroupaccountsEdit, 'model': 'accounts'},
    {'notifier': notifierAccountsdata, 'model': 'accounts'},
    {'notifier': notifierAccountgroupsEdit, 'model': 'groups'},
    {'notifier': notifierRemindgroupsEdit, 'model': 'groups'},
  ];
  @override
  Widget build(BuildContext context) {
    localdata[4]['groupusers'] = [
      ...groupusers.map((e) {
        try {
          return e.substring(0, e.indexOf(":"));
        } catch (t) {
          return e;
        }
      })
    ];

    return FutureM(
        refnotifier: notifierAccountsdata,
        model: 'accounts',
        childWidget: (data) => MmM(
              userslist: data,
              mainE: mainE,
              groupusers: groupusers,
            ));
  }
}

class MmM extends ConsumerWidget {
  const MmM(
      {super.key,
      this.mainE,
      required this.userslist,
      required this.groupusers});
  final Map? mainE;
  final List userslist;
  final List groupusers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GroupsE.userslist = [
      ...userslist.map((e) => {...e, 'choose': false})
    ];
    GroupsE.userslist = ref.watch(notifierGroupaccountsEdit);
    GroupsE.localdata = ref.watch(notifierGroupsEdit);
    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            leading: mainE == null
                ? const Icon(Icons.edit)
                : Hero(tag: '${mainE!['id']}', child: const Icon(Icons.edit)),
            title:
                Text(mainE == null ? "إنشاء مجموعة جديدة" : "تعديل المجموعة"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
          ),
          body: GroupsE.localdata.isEmpty
              ? const Center(
                  child: Text("لا يوجد بيانات لعرضها"),
                )
              : SingleChildScrollView(
                  child: datacolumns(
                      ref: ref, refnotifier: notifierGroupsEdit, ctx: context)),
        )));
  }

  datacolumns({required WidgetRef ref, refnotifier, required ctx}) {
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
                          ...GroupsE.localdata
                              .where((element) => element['type'] == 'tf')
                              .map((e) {
                            return SizedBox(
                              width: 400,
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
                                  label: Text(e['label']),
                                  hintText: e['hint'],
                                ),
                              ),
                            );
                          })
                        ],
                      ),
                    )),
                SizedBox(
                  width: 400,
                  child: Row(
                    children: [
                      Switch.adaptive(
                          value: GroupsE.localdata[3]['value'],
                          onChanged: (x) {
                            ref
                                .read(refnotifier.notifier)
                                .switchkey(x: x, index: 3);
                          }),
                      Text(GroupsE.localdata[3]['value']
                          ? "إشعارات التلغرام مفعلة"
                          : "إشعارات التلغرام معطلة"),
                    ],
                  ),
                ),
                const Divider(),
                Visibility(
                  visible: GroupsE.userslist.isNotEmpty,
                  child: ExpansionTile(
                    title: const Text("إضافة حساب"),
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
                                ...GroupsE.userslist.map((e) => Visibility(
                                      visible: !GroupsE.localdata[4]
                                              ['groupusers']
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
                                                      notifierGroupaccountsEdit
                                                          .notifier)
                                                  .choose(
                                                      index: GroupsE.userslist
                                                          .indexOf(e));
                                            },
                                            child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child:
                                                    Text("${e['fullname']}")),
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
                                        .read(notifierGroupsEdit.notifier)
                                        .movetoselected(
                                            index: 4,
                                            label: 'groupusers',
                                            clname: 'fullname',
                                            itelmist: GroupsE.userslist.where(
                                                (element) =>
                                                    element['choose']));
                                    ref
                                        .read(
                                            notifierGroupaccountsEdit.notifier)
                                        .movei();
                                  },
                                  icon:
                                      const Icon(Icons.swipe_left_alt_rounded)),
                              IconButton(
                                  onPressed: () {
                                    ref
                                        .read(notifierGroupsEdit.notifier)
                                        .movetoavailble(
                                            index: 4,
                                            label: 'groupusers',
                                            clname: 'fullname',
                                            itelmist: GroupsE.userslist
                                                .where((element) =>
                                                    element['choose'])
                                                .toList());
                                    ref
                                        .read(
                                            notifierGroupaccountsEdit.notifier)
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
                                ...GroupsE.userslist.map((e) => Visibility(
                                    visible: GroupsE.localdata[4]['groupusers']
                                        .any((y) => y == "${e['id']}"),
                                    child: GestureDetector(
                                      onTap: () => ref
                                          .read(notifierGroupaccountsEdit
                                              .notifier)
                                          .choose(
                                              index:
                                                  GroupsE.userslist.indexOf(e)),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Card(
                                          color: e['choose']
                                              ? Colors.blueGrey
                                              : Colors.white,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text("${e['fullname']}"),
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
                Divider(),
                TextButton.icon(
                    onPressed: () async {
                      if (formkey.currentState!.validate()) {
                        await StlFunction.createEditgroup(
                            notifierlist: GroupsE.notifierlist,
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
              visible: mainE != null,
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
                                    const Text("هل أنت متأكد من حذف المجموعة"),
                                actions: [
                                  IconButton(
                                      onPressed: () async =>
                                          await StlFunction.delete(
                                              notifierlist:
                                                  GroupsE.notifierlist,
                                              ctx: ctx,
                                              ref: ref,
                                              model: 'groups',
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
