import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:firstflutterapp/screens/post-creation/post-details.dart';
import 'package:firstflutterapp/screens/post-creation/post-creation-service.dart';

class UploadPhotoView extends StatefulWidget {
  const UploadPhotoView({super.key});

  @override
  UploadPhotoViewState createState() => UploadPhotoViewState();
}

class UploadPhotoViewState extends State<UploadPhotoView> {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  bool _isCapturing = false;
  final ImagePicker picker = ImagePicker();
  
  XFile? _xFile;
  File? _image;
  final PostCreationService _postCreationService = PostCreationService();

  // Instagram-style constants
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await _postCreationService.getAvailableCameras();
      if (_cameras.isNotEmpty) {
        _selectedCameraIndex = 0;
        await _setupCamera(_selectedCameraIndex);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'initialisation de la caméra: $e')),
      );
    }
  }

  Future<void> _setupCamera(int index) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    if (_cameras.isEmpty) return;

    _cameraController = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      
      
      if (kIsWeb) {
        // Sur le web, les limites de zoom ne sont pas disponibles
        _minAvailableZoom = 1.0;
        _maxAvailableZoom = 1.0;
      } else {
        _minAvailableZoom = await _cameraController!.getMinZoomLevel();
        _maxAvailableZoom = await _cameraController!.getMaxZoomLevel();
        _minAvailableExposureOffset = await _cameraController!.getMinExposureOffset();
        _maxAvailableExposureOffset = await _cameraController!.getMaxExposureOffset();
      }
                  
      _currentExposureOffset = 0.0;
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'initialisation de la caméra: $e')),
      );
    }
  }

  void _switchCamera() async {
    if (_cameras.length <= 1) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCamera(_selectedCameraIndex);
  }

  Future<void> _takePhoto() async {
    if (!_isCameraInitialized || _cameraController == null || _isCapturing) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _xFile = photo;
        if (!kIsWeb) {
          _image = File(photo.path);
        }
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _xFile = image;
          if (!kIsWeb) {
            _image = File(image.path);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  // Contrôle du zoom
  Future<void> _setZoomLevel(double value) async {
    try {
      await _cameraController?.setZoomLevel(value);
      setState(() {
        _currentZoomLevel = value;
      });
    } catch (e) {
      // Ignorer l'erreur - peut se produire si le zoom n'est pas pris en charge
    }
  }

  // Contrôle de l'exposition
  Future<void> _setExposureOffset(double value) async {
    try {
      await _cameraController?.setExposureOffset(value);
      setState(() {
        _currentExposureOffset = value;
      });
    } catch (e) {
      // Ignorer l'erreur - peut se produire si l'ajustement d'exposition n'est pas pris en charge
    }
  }

  void _continueToNextStep() {
    if (_xFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailsView(imageFile: _xFile!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez prendre ou sélectionner une image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _xFile != null
          ? _buildImagePreview()
          : _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // Fond noir pour un aspect Instagram
        Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
        ),
        
        // Aperçu de la caméra en plein écran
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
        
        // Contrôle du zoom
        Positioned(
          top: 60,
          right: 20,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Icon(Icons.zoom_in, color: Colors.white),
                    Container(
                      height: 150,
                      width: 30,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _currentZoomLevel,
                          min: _minAvailableZoom,
                          max: _maxAvailableZoom,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white30,
                          onChanged: (value) {
                            _setZoomLevel(value);
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.zoom_out, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Icon(Icons.brightness_6, color: Colors.white),
                    Container(
                      height: 150,
                      width: 30,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: _currentExposureOffset,
                          min: _minAvailableExposureOffset,
                          max: _maxAvailableExposureOffset,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white30,
                          onChanged: (value) {
                            _setExposureOffset(value);
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.brightness_4, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Contrôles en bas (bouton photo, etc.)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Boutons de contrôle
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: "galleryBtn",
                      onPressed: _pickImage,
                      backgroundColor: Colors.grey.shade800,
                      mini: true,
                      child: const Icon(Icons.photo_library, color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: _isCapturing ? null : _takePhoto,
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: _isCapturing ? Colors.grey : Colors.transparent,
                        ),
                        child: Center(
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: _isCapturing
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Container(),
                          ),
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: "switchBtn",
                      onPressed: _cameras.length <= 1 ? null : _switchCamera,
                      backgroundColor: Colors.grey.shade800,
                      mini: true,
                      child: const Icon(Icons.flip_camera_ios, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Bouton de fermeture
        Positioned(
          top: 40,
          left: 20,
          child: FloatingActionButton(
            heroTag: "closeBtn",
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impossible de revenir en arrière depuis cet écran')),
                );
              }
            },
            backgroundColor: Colors.black.withAlpha(128),
            mini: true,
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        // Fond noir
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
        ),
        
        // Image avec filtre en plein écran
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: kIsWeb
              ? Image.network(
                  _xFile!.path,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  _image!,
                  fit: BoxFit.cover,
                ),
        ),
        
        // Bouton "Utiliser cette image" avec style Instagram
        Positioned(
          bottom: 30,
          left: 30,
          right: 30,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: _continueToNextStep,
            child: const Text('Suivant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        
        // Bouton de retour
        Positioned(
          top: 40,
          left: 20,
          child: FloatingActionButton(
            heroTag: "backBtn",
            onPressed: () {
              setState(() {
                _xFile = null;
                _image = null;
              });
            },
            backgroundColor: Colors.black.withOpacity(0.5),
            mini: true,
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
