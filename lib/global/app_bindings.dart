

import 'package:app_gerenciamento_cliente/global/repository/person_repository.dart';
import 'package:app_gerenciamento_cliente/module/person_list/controller/person_list_controller.dart';
import 'package:get/get.dart';

class AppBindings implements Bindings {

  AppBindings();

  void repositories() {
    Get.lazyPut(() => PersonRepository(), fenix: true);
  }

  void controllers() {
    Get.lazyPut(() => PersonListController(Get.find<PersonRepository>()), fenix: true);
  }

  @override
  void dependencies() {
    repositories();
    controllers();
  }

}