import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Interpreter? interpreter;
  File? _image;
  String _result = "";

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> listAssets() async {
    var manifestContent = await rootBundle.loadString('AssetManifest.json');
    print("✅ Asset Manifest Content:");
    print(manifestContent);
  }

  Future<void> loadModel() async {
    listAssets();
    try {
      interpreter = await Interpreter.fromAsset('assets/model_eye.tflite');
      print("✅ Input tensor shape: ${interpreter!.getInputTensor(0).shape}");
      print("✅ Input tensor type: ${interpreter!.getInputTensor(0).type}");
      print("✅ Output tensor shape: ${interpreter!.getOutputTensor(0).shape}");
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      print("✅ Picked image path: ${pickedFile.path}");

      // Classify after picking
      classifyImage(File(pickedFile.path));
    } else {
      print("❌ No image selected.");
    }
  }



  Future<void> classifyImage(File imageFile) async {
    if (interpreter == null) {
      print("❌ Interpreter not initialized.");
      return;
    }

    // Load image bytes
    var bytes = await imageFile.readAsBytes();

    // Decode image
    img.Image? oriImage = img.decodeImage(bytes);
    if (oriImage == null) {
      print("❌ Failed to decode image.");
      return;
    }

    // Resize to 224x224
    img.Image resizedImage = img.copyResize(oriImage, width: 224, height: 224);

    // Prepare input as float32 normalized
    var input = List.generate(1, (i) => List.generate(224, (j) => List.generate(224, (k) => List.filled(3, 0.0))));
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    // Prepare output buffer for [1,2]
    var output = List.generate(1, (i) => List.filled(2, 0.0));

    // Run inference
    interpreter!.run(input, output);

    print("✅ Model raw output: $output");

    // 🔷 Label mapping and prediction
    List<String> labels = ['open eye', 'closed eye'];

    int predictedIndex = output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));
    double confidence = output[0][predictedIndex] * 100;
    String predictedLabel = labels[predictedIndex];

    print("✅predictedIndex: $predictedIndex Prediction: $predictedLabel with confidence ${confidence.toStringAsFixed(2)}%");

    // Update your UI
    setState(() {
      _result = "Prediction: $predictedLabel\nConfidence: ${confidence.toStringAsFixed(2)}%";
    });
  }



  // Future<void> classifyImage(File imageFile) async {
  //   if (interpreter == null) {
  //     print("❌ Interpreter not initialized.");
  //     return;
  //   }
  //
  //   // Load image bytes
  //   var bytes = await imageFile.readAsBytes();
  //
  //   // Decode image
  //   img.Image? oriImage = img.decodeImage(bytes);
  //   if (oriImage == null) {
  //     print("❌ Failed to decode image.");
  //     return;
  //   }
  //
  //   // Resize to 224x224
  //   img.Image resizedImage = img.copyResize(oriImage, width: 224, height: 224);
  //
  //   // Prepare input as float32 normalized
  //   var input = List.generate(1, (i) => List.generate(224, (j) => List.generate(224, (k) => List.filled(3, 0.0))));
  //   for (int y = 0; y < 224; y++) {
  //     for (int x = 0; x < 224; x++) {
  //       img.Pixel pixel = resizedImage.getPixel(x, y);
  //       input[0][y][x][0] = pixel.r / 255.0;
  //       input[0][y][x][1] = pixel.g / 255.0;
  //       input[0][y][x][2] = pixel.b / 255.0;
  //     }
  //   }
  //
  //   // Prepare output buffer for [1,2]
  //   var output = List.generate(1, (i) => List.filled(2, 0.0));
  //
  //   // Run inference
  //   interpreter!.run(input, output);
  //
  //   print("✅ Model output: $output");
  //
  //   setState(() {
  //     _result = output.toString();
  //   });
  // }


  // Future<void> classifyImage(File imageFile) async {
  //   if (interpreter == null) {
  //     print("❌ Interpreter not initialized.");
  //     return;
  //   }
  //
  //   // Load image bytes
  //   var bytes = await imageFile.readAsBytes();
  //
  //   // Decode image
  //   img.Image? oriImage = img.decodeImage(bytes);
  //   if (oriImage == null) {
  //     print("❌ Failed to decode image.");
  //     return;
  //   }
  //
  //   // Resize to 300x300
  //   img.Image resizedImage = img.copyResize(oriImage, width: 300, height: 300);
  //
  //   // Prepare input
  //   var input = List.generate(1, (i) => List.generate(300, (j) => List.generate(300, (k) => List.filled(3, 0))));
  //   for (int y = 0; y < 300; y++) {
  //     for (int x = 0; x < 300; x++) {
  //       img.Pixel pixel = resizedImage.getPixel(x, y);
  //       input[0][y][x][0] = pixel.r.toInt();
  //       input[0][y][x][1] = pixel.g.toInt();
  //       input[0][y][x][2] = pixel.b.toInt();
  //     }
  //   }
  //
  //   // Prepare outputs (example for SSD detection)
  //   Map<int, Object> outputs = {
  //     0: List.generate(1, (i) => List.generate(10, (j) => List.filled(4, 0.0))), // boxes
  //     1: List.generate(1, (i) => List.filled(10, 0.0)), // classes
  //     2: List.generate(1, (i) => List.filled(10, 0.0)), // scores
  //     3: List.filled(1, 0.0), // num_detections
  //   };
  //
  //   // Run inference
  //   interpreter!.runForMultipleInputs([input], outputs);
  //
  //   print("✅ Detection boxes: ${outputs[0]}");
  //   print("✅ Classes: ${outputs[1]}");
  //   print("✅ Scores: ${outputs[2]}");
  //   print("✅ Num detections: ${outputs[3]}");
  //
  //   setState(() {
  //     _result = outputs.toString();
  //   });
  // }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('TFLite Image Classification')),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _image != null
                    ? Image.file(_image!, height: 200)
                    : Text('No image selected.'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: pickImage,
                  child: Text('Pick Image & Classify'),
                ),
                SizedBox(height: 20),
                Text('Result: $_result'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
