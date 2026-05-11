import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

void main() => runApp(MaterialApp(home: CatDogClassifier()));

class CatDogClassifier extends StatefulWidget {
  @override
  _CatDogClassifierState createState() => _CatDogClassifierState();
}

class _CatDogClassifierState extends State<CatDogClassifier> {
  Interpreter? _interpreter;
  File? _image;
  String _result = "Aucun résultat";
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  // Charger le modèle .tflite depuis les assets
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print("Modèle chargé avec succès");
    } catch (e) {
      print("Erreur lors du chargement du modèle: $e");
    }
  }

  // Prétraitement de l'image (Redimensionnement + Normalisation)
  Uint8List _imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = pixel.r*1.0;
        buffer[pixelIndex++] = pixel.g*1.0;
        buffer[pixelIndex++] = pixel.b*1.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  /*Future<void> _classifyImage(File image) async {
    if (_interpreter == null) return;

    setState(() => _loading = true);

    Uint8List bytes = await image.readAsBytes();
    img.Image? oriImg = img.decodeImage(bytes);
    img.Image resizedImg = img.copyResize(oriImg!, width: 180, height: 180);

    var input = _imageToByteListFloat32(resizedImg, 180);
    var inputShape = [1, 180, 180, 3];

    var output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    var inputTensor = input.buffer.asFloat32List().reshape(inputShape);
    _interpreter!.run(inputTensor, output);

    
    // if output[0][0] is > output[0][1], it's the first class (cat)
    setState(() {
      _result = output[0][0] > output[0][1] ? "C'est un Chat !" : "C'est un Chien !";
      _loading = false;
    });
  }*/

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
      });
      _classifyImage(imageFile);
    }
  }

  double sigmoid(double x) => 1 / (1 + exp(-x));

  Future<void> _classifyImage(File image) async {
    if (_interpreter == null) {
      print("⚠️ Interpreter is null!");
      return;
    }

    setState(() => _loading = true);

    Uint8List bytes = await image.readAsBytes();
    img.Image? oriImg = img.decodeImage(bytes);
    
    if (oriImg == null) {
      print("⚠️ Could not decode image!");
      setState(() { _result = "Error, invalid image"; _loading = false; });
      return;
    }

    img.Image resizedImg = img.copyResize(oriImg, width: 180, height: 180);
    var testPixel = resizedImg.getPixel(0, 0);
    print("Pixel r=${testPixel.r}, g=${testPixel.g}, b=${testPixel.b}");
    print("Pixel r*255=${testPixel.r * 255}");
    var inputTensor = _imageToByteListFloat32(resizedImg, 180).buffer.asFloat32List().reshape([1, 180, 180, 3]);
    var output = List.filled(1, 0.0).reshape([1, 1]);

    print("Input shape: ${_interpreter!.getInputTensor(0).shape}");
    print("Output shape: ${_interpreter!.getOutputTensor(0).shape}");

    _interpreter!.run(inputTensor, output);

    print("Raw output: ${output}");  // 👈 key line

    setState(() {
      double confidence = sigmoid(output[0][0]);
      String label = confidence > 0.5 ? "It's a dog" : "It's a cat";
      String percent = confidence > 0.5 ? ((confidence) * 100).toStringAsFixed(1) : ((1-confidence) * 100).toStringAsFixed(1);
      _result = "$label ($percent%)";
      _loading = false;
    });
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cat vs Dog classification")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null 
                ? Image.file(_image!, height: 250) 
                : Icon(Icons.image, size: 150, color: Colors.grey),
            SizedBox(height: 30),
            _loading 
                ? CircularProgressIndicator() 
                : Text(_result, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text("Camera"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text("Gallery"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}