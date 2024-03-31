import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/data/basicdata.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';

class AccountsE extends StatelessWidget {
  const AccountsE(
      {super.key, this.mainE, this.selfedit = false, required this.usergroups});
  final Map? mainE;
  final bool selfedit;
  final List usergroups;
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
      'label': 'اسم المستخدم',
      'controller': TextEditingController(),
      'keyboard': TextInputType.name,
      'validate_role': 'empty'
    },
    {
      'type': 'tf',
      'label': 'الايميل',
      'controller': TextEditingController(),
      'keyboard': TextInputType.emailAddress
    },
    {
      'type': 'tf',
      'label': 'موبايل',
      'controller': TextEditingController(),
      'keyboard': TextInputType.phone
    },
    {
      'type': 'tf',
      'label': 'كلمة المرور',
      'hint': '',
      'obscuretext': true,
      'suffix_icon': Icons.visibility,
      'controller': TextEditingController(),
      'keyboard': TextInputType.visiblePassword,
      'validate_role': 'empty_if_not_e'
    },
    {
      'type': 'tf',
      'label': 'تأكيد كلمة المرور',
      'hint': '',
      'obscuretext': true,
      'suffix_icon': Icons.visibility,
      'controller': TextEditingController(),
      'keyboard': TextInputType.visiblePassword,
      'validate_role': 'not_eq_prev'
    },
    {
      'type': 'dropdown_permit',
      'selected': 'user',
    },
    {
      'type': 'enable',
      'value': true,
    },
    {'usergroups': []}
  ];

  static List<Map> notifierlist = [
    {'notifier': notifierGroupsdata, 'model': 'groups'},
    {'notifier': notifierGroupaccountsEdit, 'model': 'accounts'},
    {'notifier': notifierAccountsdata, 'model': 'accounts'},
    {'notifier': notifierAccountgroupsEdit, 'model': 'groups'},
  ];

  @override
  Widget build(BuildContext context) {
    localdata[8]['usergroups'] = [
      ...usergroups.map((e) {
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
              usergroups: usergroups,
            ));
  }
}

class MmM extends ConsumerWidget {
  const MmM(
      {super.key,
      this.mainE,
      this.selfedit = false,
      required this.groupslist,
      required this.usergroups});
  final Map? mainE;
  final bool selfedit;
  final List groupslist;
  final List usergroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AccountsE.groupslist = [
      ...groupslist.map((e) => {...e, 'choose': false})
    ];

    AccountsE.groupslist = ref.watch(notifierAccountgroupsEdit);
    AccountsE.localdata = ref.watch(notifierAccountsEdit);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            leading: mainE == null
                ? const Icon(Icons.edit)
                : Hero(tag: '${mainE!['id']}', child: const Icon(Icons.edit)),
            title: Text(mainE == null ? "إنشاء حساب جديد" : "تعديل حساب"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward))
            ],
          ),
          body: AccountsE.localdata.isEmpty
              ? const Center(
                  child: Text("لا يوجد بيانات لعرضها"),
                )
              : SingleChildScrollView(
                  child: datacolumns(
                      ref: ref,
                      refnotifier: notifierAccountsEdit,
                      ctx: context,
                      usergroups: AccountsE.localdata[8]['usergroups'])),
        )));
  }

  datacolumns(
      {required WidgetRef ref,
      refnotifier,
      required ctx,
      required List usergroups}) {
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
                          ...AccountsE.localdata
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

                                    case 'not_eq_prev':
                                      if (e['controller'].text !=
                                          AccountsE
                                              .localdata[AccountsE.localdata
                                                      .indexOf(e) -
                                                  1]['controller']
                                              .text) {
                                        return "كلمات المرور غير متطابقة";
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
                                                  index: AccountsE.localdata
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
                Visibility(
                  visible: !selfedit,
                  child: SizedBox(
                    width: 400,
                    child: Row(
                      children: [
                        const Text("اختيار الصلاحيات : "),
                        DropdownButton(
                            value: AccountsE.localdata[6]['selected'],
                            items: [
                              ...[
                                'user',
                                'admin',
                                'superadmin'
                              ].map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      style: Theme.of(ctx).textTheme.bodyMedium,
                                    ),
                                  ))
                            ],
                            onChanged: (x) {
                              ref
                                  .read(refnotifier.notifier)
                                  .chooseitemdromdopdown(x: x, index: 6);
                            })
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: !selfedit,
                  child: SizedBox(
                    width: 400,
                    child: Row(
                      children: [
                        Switch.adaptive(
                            value: AccountsE.localdata[7]['value'],
                            onChanged: (x) {
                              ref
                                  .read(refnotifier.notifier)
                                  .switchkey(x: x, index: 7);
                            }),
                        Text(AccountsE.localdata[7]['value']
                            ? "الحساب فعال"
                            : "الحساب معطل"),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Visibility(
                  visible: AccountsE.groupslist.isNotEmpty && selfedit == false,
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
                                ...AccountsE.groupslist.map((e) => Visibility(
                                      visible: !AccountsE.localdata[8]
                                              ['usergroups']
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
                                                      notifierAccountgroupsEdit
                                                          .notifier)
                                                  .choose(
                                                      index: AccountsE
                                                          .groupslist
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
                                        .read(notifierAccountsEdit.notifier)
                                        .movetoselected(
                                            index: 8,
                                            label: 'usergroups',
                                            clname: 'groupname',
                                            itelmist: AccountsE.groupslist
                                                .where((element) =>
                                                    element['choose']));
                                    ref
                                        .read(
                                            notifierAccountgroupsEdit.notifier)
                                        .movei();
                                  },
                                  icon:
                                      const Icon(Icons.swipe_left_alt_rounded)),
                              IconButton(
                                  onPressed: () {
                                    ref
                                        .read(notifierAccountsEdit.notifier)
                                        .movetoavailble(
                                            index: 8,
                                            label: 'usergroups',
                                            clname: 'groupname',
                                            itelmist: AccountsE.groupslist
                                                .where((element) =>
                                                    element['choose'])
                                                .toList());
                                    ref
                                        .read(
                                            notifierAccountgroupsEdit.notifier)
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
                                ...AccountsE.groupslist.map((e) => Visibility(
                                    visible: AccountsE.localdata[8]
                                            ['usergroups']
                                        .any((y) => y == "${e['id']}"),
                                    child: GestureDetector(
                                      onTap: () => ref
                                          .read(notifierAccountgroupsEdit
                                              .notifier)
                                          .choose(
                                              index: AccountsE.groupslist
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
                            notifierlist: AccountsE.notifierlist,
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
                                    const Text("هل أنت متأكد من حذف الحساب؟"),
                                actions: [
                                  IconButton(
                                      onPressed: () async =>
                                          await StlFunction.delete(
                                              notifierlist:
                                                  AccountsE.notifierlist,
                                              ctx: ctx,
                                              ref: ref,
                                              model: 'accounts',
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
