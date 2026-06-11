import 'dart:io';

import 'package:flutter/material.dart';

class UploadFoto extends StatefulWidget {
  const UploadFoto({super.key});

  @override
  State<UploadFoto> createState() => _UploadFotoState();
}

class _UploadFotoState extends State<UploadFoto> {
  //variable inisialisation
  //1 FormController
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  // 2 Transaksional
  File? foto;
  String? fotoPath;
  bool isLoading = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(),
    );
    
  }
}