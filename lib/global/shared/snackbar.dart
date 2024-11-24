

import 'package:app_gerenciamento_cliente/global/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSnackbar({String? title, required String message}) {
    Get.snackbar(
        title ?? msgAttention,
        message,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black54,
        colorText: Colors.white
    );
}