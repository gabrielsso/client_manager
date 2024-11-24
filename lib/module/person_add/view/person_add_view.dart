
import 'package:app_gerenciamento_cliente/global/repository/person_repository.dart';
import 'package:app_gerenciamento_cliente/module/person_add/controller/person_add_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonAddView extends StatefulWidget {
  PersonAddView({super.key});

  @override
  State<PersonAddView> createState() => _PersonAddViewState();
}

class _PersonAddViewState extends State<PersonAddView> {
  final controller = PersonAddController(Get.find<PersonRepository>());

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if(args != null) {
      controller.loadInfo(args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final focus = FocusScope.of(context);

    return GestureDetector(
      onTap: () {
        focus.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: theme.colorScheme.secondary,
          leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)
          ),
          title: const Text(
              "Cadastro de cliente",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500
              ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: controller.nomeTextController,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54, width: 2.0),
                            ),
                            labelText: 'Nome',
                            prefixIcon: Icon(Icons.account_circle_rounded)
                          ),
                          validator: (value) {
                            if(value == null || value.isEmpty) {
                              return 'Campo nome é obrigatório';
                            }

                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: controller.emailTextController,
                          decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black54, width: 2.0),
                              ),
                              labelText: 'Email',
                            prefixIcon: Icon(Icons.email_rounded)
                          ),
                          validator: (value) {
                            if(value == null || value.isEmpty) {
                              return 'Campo email é obrigatório';
                            } else if(!controller.validateEmail(value)) {
                              return 'Endereço de e-mail inválido';
                            }

                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: controller.telefoneTextController,
                          inputFormatters: [
                            controller.telefoneMask
                          ],
                          decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black54, width: 2.0),
                              ),
                              labelText: 'Telefone',
                              prefixIcon: Icon(Icons.phone)
                          ),
                          validator: (value) {
                            if(value == null || value.isEmpty) {
                              return 'Campo telefone é obrigatório';
                            } else if(!controller.telefoneMask.isFill()) {
                              return 'Número de telefone inválido';
                            }

                            return null;
                          },
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),
                        ValueListenableBuilder(
                            valueListenable: controller.nascimento,
                            builder: (_, data, __) {
                              return TextFormField(
                                controller: controller.nascimentoTextController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black54, width: 2.0),
                                    ),
                                    labelText: 'Data de nascimento',
                                    prefixIcon: Icon(Icons.calendar_month_rounded)
                                ),
                                validator: (value) {
                                  if(value == null || value.isEmpty) {
                                    return 'Campo data de nascimento é obrigatório';
                                  }

                                  return null;
                                },
                                onTap: () {
                                  _selectDate(context);
                                },
                              );
                            }
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () {
                      final validade = _formKey.currentState;
                      if(validade!.validate()) {
                        controller.sendPerson(onSuccessCallback: () {
                          Navigator.of(context).pop(true);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      backgroundColor: theme.colorScheme.secondary,
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                      )
                    ),
                    child: Text(
                        'Salvar',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white
                      )
                    )
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: controller.nascimento.value ?? DateTime.now(),
        firstDate: DateTime(1700),
        lastDate: DateTime.now());
    if (picked != null && picked != controller.nascimento.value) {
        controller.setDate(picked);
    }
  }
}
