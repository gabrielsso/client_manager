
import 'package:app_gerenciamento_cliente/global/constants.dart';
import 'package:flutter/material.dart';

void showYesOrNoDialog(BuildContext context, Size deviceSize, {String title = msgAttention, required String bodyText, required Function() onConfirmCallback, required Function() onCancelCallback}) {
  showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            title,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                decoration: TextDecoration.none
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  bodyText,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                      fontSize: 20,
                      decoration: TextDecoration.none
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                        onPressed: onCancelCallback,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.errorContainer,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)
                            )
                        ),
                        child: const Text(
                          'Não',
                          style: TextStyle(
                              color: Colors.white
                          ),
                        )
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                        onPressed: onConfirmCallback,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)
                            )
                        ),
                        child: Text(
                          'Sim',
                          style: TextStyle(
                              color: Colors.white
                          ),
                        )
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      }
  );
}