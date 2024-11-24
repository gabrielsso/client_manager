import 'package:app_gerenciamento_cliente/global/app_bindings.dart';
import 'package:app_gerenciamento_cliente/global/color_scheme.dart';
import 'package:app_gerenciamento_cliente/global/constants.dart';
import 'package:app_gerenciamento_cliente/global/model/person_model.dart';
import 'package:app_gerenciamento_cliente/module/person_add/view/person_add_view.dart';
import 'package:app_gerenciamento_cliente/module/person_list/view/person_list_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  runApp(const AppClientManagement());
}

Future<void> initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(PersonAdapter());
  await Hive.openBox<Person>(hiveBoxName);
}

class AppClientManagement extends StatelessWidget {
  const AppClientManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HubClient',
      theme: ThemeData(
        colorScheme: appColorScheme,
        useMaterial3: true,
      ),
      initialRoute: homePage,
      getPages: [
        GetPage(name: homePage, page: () => PersonListView()),
        GetPage(name: addPage, page: () => PersonAddView()),
      ],
      initialBinding: AppBindings(),
    );
  }
}
