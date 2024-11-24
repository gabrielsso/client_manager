
import 'package:app_gerenciamento_cliente/module/person_list/component/client_card.dart';
import 'package:app_gerenciamento_cliente/module/person_list/controller/person_list_controller.dart';
import 'package:app_gerenciamento_cliente/global/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonListView extends StatefulWidget {
  PersonListView({super.key});

  @override
  State<PersonListView> createState() => _PersonListViewState();
}

class _PersonListViewState extends State<PersonListView> {
  final controller = Get.find<PersonListController>();

  @override
  void initState() {
    super.initState();
    controller.startSyncData();
    controller.getPersons();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.secondary,
        title: const Text(
            "Gerenciamento de clientes",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500
            )
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                controller.startSyncData();
              },
              icon: const Icon(
                  Icons.cloud_download,
                  color: Colors.white,
              )
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ValueListenableBuilder(
                valueListenable: controller.showLoading,
                builder: (_, loading, __) {
                  if(loading) {
                    return const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                        ),
                      ),
                    );
                  } else {
                    return listPersons(size, theme);
                  }
                }
            )
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Get.toNamed("/add");
            if(result != null) {
              controller.getPersons();
            }
          },
          shape: const CircleBorder(),
          backgroundColor: theme.colorScheme.secondary,
          tooltip: 'Adicionar cliente',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget listPersons(Size size, ThemeData theme) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          controller.getPersons();
        },
        child: ValueListenableBuilder(
            valueListenable: controller.persons,
            builder: (ctx, data, __) {
              if(data.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                      height: size.height - Scaffold.of(ctx).appBarMaxHeight!,
                      alignment: Alignment.center,
                      child: Text(
                        'Sem clientes',
                        style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.black54
                        ),
                      )
                  ),
                );
              } else {
                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: data.length,
                    itemBuilder: (ctx, index) {
                      final person = data[index];
                      return ClientCard(
                          person: person,
                          onCardClickCallback: () async {
                            final retorno = await Get.toNamed(addPage, arguments: person);
                            if(retorno != null) {
                              controller.getPersons();
                            }
                          },
                          onConfirmCallback: () {
                            controller.deletePerson(person);
                          }
                      );
                    }
                );
              }
            }
        ),
      ),
    );
  }
}
