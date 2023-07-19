import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
        ),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const modelPath = 'assets/models/mobilenet_quant.tflite';
  static const labelsPath = 'assets/models/labels.txt';

  late final Interpreter interpreter;
  late final List<String> labels;

  Tensor? inputTensor;
  Tensor? outputTensor;

  final imagePicker = ImagePicker();
  String? imagePath;
  img.Image? image;

  Map<String, int>? classification;

  @override
  void initState() {
    super.initState();
    // Load model and labels from assets
    loadModel();
    loadLabels();
  }

  // Clean old results when press some take picture button
  void cleanResult() {
    imagePath = null;
    image = null;
    classification = null;
    setState(() {});
  }

  // Load model
  Future<void> loadModel() async {
    final options = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
    }

    // Use GPU Delegate
    // doesn't work on emulator
    // if (Platform.isAndroid) {
    //   options.addDelegate(GpuDelegateV2());
    // }

    // Use Metal Delegate
    if (Platform.isIOS) {
      options.addDelegate(GpuDelegate());
    }

    // Load model from assets
    interpreter = await Interpreter.fromAsset(modelPath, options: options);
    // Get tensor input shape [1, 224, 224, 3]
    inputTensor = interpreter.getInputTensors().first;
    // Get tensor output shape [1, 1001]
    outputTensor = interpreter.getOutputTensors().first;
    setState(() {});

    log('Interpreter loaded successfully');
  }

  // Load labels from assets
  Future<void> loadLabels() async {
    final labelTxt = await rootBundle.loadString(labelsPath);
    labels = labelTxt.split('\n');
  }

  // Process picked image
  Future<void> processImage() async {
    if (imagePath != null) {
      // Read image bytes from file
      final imageData = File(imagePath!).readAsBytesSync();

      // Decode image using package:image/image.dart (https://pub.dev/image)
      image = img.decodeImage(imageData);
      setState(() {});

      // Resize image for model input (Mobilenet use [224, 224])
      final imageInput = img.copyResize(
        image!,
        width: 224,
        height: 224,
      );

      // Get image matrix representation [224, 224, 3]
      final imageMatrix = List.generate(
        imageInput.height,
        (y) => List.generate(
          imageInput.width,
          (x) {
            final pixel = imageInput.getPixel(x, y);
            return [pixel.r, pixel.g, pixel.b];
          },
        ),
      );

      // Run model inference
      runInference(imageMatrix);
    }
  }

  // Run inference
  Future<void> runInference(
    List<List<List<num>>> imageMatrix,
  ) async {
    // Set tensor input [1, 224, 224, 3]
    final input = [imageMatrix];
    // Set tensor output [1, 1001]
    final output = [List<int>.filled(1001, 0)];

    // Run inference
    interpreter.run(input, output);

    // Get first output tensor
    final result = output.first;

    // Set classification map {label: points}
    classification = <String, int>{};

    for (var i = 0; i < result.length; i++) {
      if (result[i] != 0) {
        // Set label: points
        classification![labels[i]] = result[i];
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/rawezh.png'),
        backgroundColor: const Color(0xff141425),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              // color: Colors.black.withOpacity(0.5),
              // height: 300,
              alignment: Alignment.topCenter,
              child: imagePath != null
                  ? Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.file(File(imagePath!)),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 400,
              width: Get.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show model information
                  // Text(
                  //   'Input: (shape: ${inputTensor?.shape} type: ${inputTensor?.type})',
                  // ),
                  // Text(
                  //   'Output: (shape: ${outputTensor?.shape} type: ${outputTensor?.type})',
                  // ),
                  // const SizedBox(height: 8),
                  // // Show picked image information
                  // if (image != null) ...[
                  //   Text('Num channels: ${image?.numChannels}'),
                  //   Text(
                  //       'Bits per channel: ${image?.bitsPerChannel}'),
                  //   Text('Height: ${image?.height}'),
                  // Text('Width: ${image?.width}'),
                  // ],

                  const SizedBox(height: 24),
                  // Show classification result
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (classification != null)
                            ...(classification!.entries.toList()
                                  ..sort(
                                    (a, b) => a.value.compareTo(b.value),
                                  ))
                                .reversed
                                .map(
                              (e) {
                                return _buildList(key: e.key, value: e.value);
                                // return Container(
                                //   padding: const EdgeInsets.all(8),
                                //   color: Colors.orange.withOpacity(0.5),
                                //   child: Row(
                                //     children: [
                                //       Text('${e.key}: ${e.value}'),
                                //     ],
                                //   ),
                                // );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              cleanResult();
              final result = await imagePicker.pickImage(
                source: ImageSource.gallery,
              );

              imagePath = result?.path;
              setState(() {});
              processImage();
            },
            child: const Icon(Icons.add_a_photo),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () async {
              cleanResult();
              final result = await imagePicker.pickImage(
                source: ImageSource.camera,
              );

              imagePath = result?.path;
              setState(() {});
              processImage();
            },
            child: const Icon(Icons.camera),
          ),
        ],
      ),
    );
  }

  Container _buildList({required key, required value}) {
    return Container(
      height: 50,
      width: Get.width,
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text('$key: $value',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}
