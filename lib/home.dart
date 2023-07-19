import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const modelPath = 'assets/models/mobilenet_quant.tflite';
  static const labelsPath = 'assets/models/labels.txt';

  Future<File>? imageFile;
  File? _image;
  String? result = '';
  ImagePicker? imagePicker;

  selectPhotoFromGallery() async {
    XFile? pickedFile =
        await imagePicker!.pickImage(source: ImageSource.gallery);
    _image = File(pickedFile!.path);
    setState(() {
      _image;
    });
  }

  capturePhotoWithCamera() async {
    XFile? pickedFile =
        await imagePicker!.pickImage(source: ImageSource.camera);
    _image = File(pickedFile!.path);
    setState(() {
      _image;
    });
  }

  loadDataModeFiles() async {
    final interpreter = await tfl.Interpreter.fromAsset(
      modelPath,
      options: tfl.InterpreterOptions()..threads = 1,
    );

    // String? output = await TfLiteType.loadModel(
    //     model: 'assets/model_unquant.tflite',
    //     labels: 'assets/labels.txt',
    //     numThreads: 1,
    //     isAsset: true,
    //     useGpuDelegate: false);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
