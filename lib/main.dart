import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Classify(),
    );
  }
}

class Classify extends StatefulWidget {
  const Classify({Key key}) : super(key: key);

  @override
  State<Classify> createState() => _ClassifyState();
}

class _ClassifyState extends State<Classify> with TickerProviderStateMixin {

  XFile _image;

  double imageWidth;
  double imageHeight;
  bool busy = false;
  double containerHeight = 0;

  List _recognitions;
  final ImagePicker _picker = ImagePicker();

  AnimationController _controller;
  // static const List<IconData> icons = [Icons.camera_alt, Icons.image];

  // final Map<String, int> _ingredients = {};
  String _selected0 = "";
  String _selected1 = "";
  String val0 = "";
  String val1 = "";

  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  @override
  void initState() {
    super.initState();
    busy = true;

    loadModel().then((val) {
      setState(() {
        busy = false;
      });
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  loadModel() async {
    Tflite.close();
    try {
      String res = await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
      ) ?? '';
    } on PlatformException {
      debugPrint("Failed to load the model");
    }
  }

  selectFromImagePicker({ bool fromCamera}) async {
    XFile pickedFile = fromCamera
        ? await _picker.pickImage(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.gallery);
    var image = XFile(pickedFile.path);
    if (image == null) return;
    setState(() {
      busy = true;
    });
    predictImage(image);
  }

  predictImage(XFile image) async {
    if (image == null) return;

    _setLoading(true);

    // Convert XFile to File
    File imageFile = File(image.path);

    await classify(image);

    FileImage(imageFile)
        .resolve(const ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        imageWidth = info.image.width.toDouble();
        imageHeight = info.image.height.toDouble();
      });
    })));

    setState(() {
      _image = image;
      busy = false;
    });

    _setLoading(false);
  }

  classify(XFile image) async {
    var recognitions = await Tflite.runModelOnImage(
        path: image.path, // required
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 2, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
    );
    setState(() {
      _recognitions = recognitions ?? [];
      debugPrint('$_recognitions');

      if(_recognitions[0]['label'].toString()=="BLUR") {

        _selected0 = "BLUR";
        val0 = '${(_recognitions[0]["confidence"] * 100).toStringAsFixed(0)}%';
      }
      else{
        _selected0 = '';
        val0 = '${(100-(_recognitions[0]["confidence"] * 100)).toStringAsFixed(0)}%';
      }

      if(_recognitions[0]['label'].toString()=="SHARP") {

        _selected1 = "SHARP";
        val1 = '${(_recognitions[0]["confidence"] * 100).toStringAsFixed(0)}%';
      }
      else{
        _selected1 = "";
        val1 = '${(100-(_recognitions[0]["confidence"] * 100)).toStringAsFixed(0)}%';
      }


    });
  }

  _imagePreview(XFile image) {
    _controller.reverse();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 7,
          child: ListView(
            children: <Widget>[
              Image.file(File(image.path)),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Image Class',
                    style:
                    TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recognitions.length,
                itemBuilder: (context, index) {
                  return Card(
                      child: RadioListTile<String>(
                          activeColor: Theme.of(context).primaryColor,
                          groupValue: _selected0,
                          value: "BLUR",

                          onChanged: (String value) {

                          },

                          title: const Text("BLUR",
                              style: TextStyle(fontSize: 16.0)),
                          subtitle: Text(
                              val0)));


                },
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recognitions.length,
                itemBuilder: (context, index) {
                  return Card(
                      child: RadioListTile<String>(
                          activeColor: Theme.of(context).primaryColor,
                          groupValue: _selected1,
                          value: "SHARP",
                          onChanged: (String value) {
                          },
                          title: const Text("SHARP",
                              style: TextStyle(fontSize: 16.0)),
                          subtitle: Text(
                              val1)));


                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      progressIndicator:
      SpinKitWanderingCubes(color: Theme.of(context).primaryColor),
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Blur Detect'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.image, color: Theme.of(context).secondaryHeaderColor),
                onPressed: () {
                  selectFromImagePicker(fromCamera: false);
                },
              ),
              IconButton(
                icon: Icon(Icons.camera_alt,
                    color: Theme.of(context).secondaryHeaderColor),
                onPressed: () {
                  selectFromImagePicker(fromCamera: true);
                },
              ),
            ],
            backgroundColor: Colors.blue,
            elevation: 0.0,
          ),
          body: _content(_image)),
    );
  }


  _content(XFile image) {
    if (image == null) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.image, size: 100.0, color: Colors.grey),
            ),
            Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No Image',
                      style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                )),
            Center(
              child: Text('Please take or select a photo for blur detection.',
                  style: TextStyle(color: Colors.grey)),
            )
          ]);
    } else {
      return _imagePreview(image);
//      return Container();
    }
  }
}


