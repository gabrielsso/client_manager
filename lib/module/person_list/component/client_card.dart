
import 'package:app_gerenciamento_cliente/global/constants.dart';
import 'package:app_gerenciamento_cliente/global/dto/person_dto.dart';
import 'package:app_gerenciamento_cliente/global/extension/extension_date_time.dart';
import 'package:app_gerenciamento_cliente/global/model/person_model.dart';
import 'package:app_gerenciamento_cliente/global/shared/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({super.key, required this.person, required this.onCardClickCallback, required this.onConfirmCallback, this.onCancelCallback});

  final Person person;
  final VoidCallback onCardClickCallback;
  final VoidCallback onConfirmCallback;
  final VoidCallback? onCancelCallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Slidable(
      startActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.26,
          children: [
            SlidableAction(
              onPressed: (ctx) {
                if(person.key != null) {
                  showYesOrNoDialog(
                      context,
                      size,
                      bodyText: msgDeletePerson,
                      onConfirmCallback: () {
                        Navigator.of(context).pop();
                        onConfirmCallback.call();
                      },
                      onCancelCallback: () {
                        Navigator.of(context).pop();
                        onCancelCallback?.call();
                      }
                  );
                }
              },
              icon: Icons.delete,
              spacing: 4,
              label: "Deletar",
              backgroundColor: Colors.red,
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(4),
            ),
          ]
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: !person.isValid ?
            theme.colorScheme.errorContainer : Colors.transparent,
            width: 2
          )
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if(person.key != null) {
              onCardClickCallback();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue
                  ),
                  child: Center(
                    child: Text(
                      person.name.substring(0,2).toUpperCase(),
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: theme.textTheme.bodyLarge?.fontSize
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${person.name}",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Email: ${person.email}",
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tel.: ${person.phone}",
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Data de Nasc.: ${DateTime.parse(person.birthDate!).formatDateFromIso}",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                if(!person.isValid)
                  Icon(Icons.error_outline_rounded, color: theme.colorScheme.errorContainer),
                const Icon(Icons.swipe_right, color: Colors.black38)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
