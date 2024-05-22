import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as df;
import 'package:mouaz_app_018/controllers/provider_mz.dart';
import 'package:mouaz_app_018/controllers/stlfunction.dart';
import 'package:mouaz_app_018/data/basicdata.dart';
import 'package:mouaz_app_018/tamplates/futureM.dart';

class TablesE extends StatelessWidget {
  const TablesE({super.key, this.mainE});
  final Map? mainE;

  static List groupslist = [];
  static List localdata = [
    {
      'type': 'tf',
      'label': 'عنوان الجدول',
      'controller': TextEditingController(),
      'keyboard': TextInputType.name,
      'validate_role': 'empty'
    },
    {
      'cells': [
        [
          {'id': 'a0-b0', 'controller': TextEditingController(text: "a0-b0")},
        ]
      ]
    }
  ];

  static List<Map> notifierlist = [
    {'notifier': notifierGroupsdata, 'model': 'groups'},
    {'notifier': notifierRemindsdata, 'model': 'reminds'},
    {'notifier': notifierRemindgroupsEdit, 'model': 'groups'},
  ];

  @override
  Widget build(BuildContext context) {
    return FutureM(
        refnotifier: notifierGroupsdata,
        model: 'groups',
        childWidget: (data) => MmM(
              mainE: mainE,
            ));
  }
}

class MmM extends ConsumerWidget {
  const MmM({
    super.key,
    this.mainE,
  });
  final Map? mainE;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TablesE.groupslist = ref.watch(notifierRemindgroupsEdit);
    TablesE.localdata = ref.watch(notifierTableEdit);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
            child: Scaffold(
                appBar: AppBar(
                  leading: mainE == null
                      ? const Icon(Icons.edit)
                      : Hero(
                          tag: '${mainE!['id']}',
                          child: const Icon(Icons.edit)),
                  title: Text(mainE == null ? "إنشاء جدول جديد" : "تعديل جدول"),
                  actions: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_forward))
                  ],
                ),
                body: TablesE.localdata.isEmpty
                    ? const Center(
                        child: Text("لا يوجد بيانات لعرضها"),
                      )
                    : datacolumns(
                        ref: ref,
                        refnotifier: notifierRemindsEdit,
                        ctx: context,
                      ))));
  }

  datacolumns({required WidgetRef ref, refnotifier, required ctx}) {
    GlobalKey<FormState> formkey = GlobalKey<FormState>();
    return Center(
      child: Form(
          key: formkey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...TablesE.localdata.sublist(0, 1).map((e) {
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
                SizedBox(height: 50),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                                onPressed: () {
                                  ref
                                      .read(notifierTableEdit.notifier)
                                      .column(op: 'add');
                                },
                                icon: Icon(Icons.add)),
                            Text("عمود"),
                            IconButton(
                                onPressed: () {
                                  ref
                                      .read(notifierTableEdit.notifier)
                                      .column(op: 'remove');
                                },
                                icon: Icon(Icons.remove)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                                onPressed: () {
                                  ref
                                      .read(notifierTableEdit.notifier)
                                      .row(op: 'add');
                                },
                                icon: Icon(Icons.add)),
                            Text("سطر"),
                            IconButton(
                                onPressed: () {
                                  ref
                                      .read(notifierTableEdit.notifier)
                                      .row(op: 'remove');
                                },
                                icon: Icon(Icons.remove)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: [],
                    )
                  ],
                ),
                Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(children: [
                        for (var b in TablesE.localdata[1]['cells'])
                          Row(
                            children: [
                              for (var a in b)
                                Container(
                                    color: Colors.black,
                                    width: 150,
                                    child: TextFormField(
                                      controller: a['controller'],
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder()),
                                    ))
                            ],
                          )
                      ]),
                    ),
                  ),
                )
              ],
            ),
          )),
    );
  }
}
