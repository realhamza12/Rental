// Updated list_car_screen.dart with cross-platform image handling
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'detail.dart';
import 'car_listing_success_screen.dart';
import 'package:cross_file/cross_file.dart';
import 'listing_page.dart';
import 'past_rentals_screen.dart';

class ListCarScreen extends StatefulWidget {
  const ListCarScreen({Key? key}) : super(key: key);

  @override
  State<ListCarScreen> createState() => _ListCarScreenState();
}

class _ListCarScreenState extends State<ListCarScreen> {
  final TextEditingController _carNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Form fields
  String _carName = ''; // Combined car make and model
  double _rentalPrice = 0;
  String _location = '';
  String _transmission = 'Automatic';
  String _ownerName = 'John Doe'; // In a real app, get from user profile
  List<XFile> _selectedImages = [];
  List<Map<String, dynamic>> _rules = [
    {
      'title': 'Valid Driver\'s License',
      'description':
          'Renter must possess a valid driver\'s license. A copy must be submitted before rental begins.',
    },
    {
      'title': 'Minimum Age Requirement',
      'description':
          'Renters must be at least 21 years old. Additional fees may apply for drivers under 25.',
    },
  ];

  bool _isLoading = false;
  String? _errorMessage;

  // Transmission options
  final List<String> _transmissionOptions = ['Automatic', 'Manual'];

  // Navigation handling
  void _handleNavigation(int index) {
    if (index == 0) {
      // Home tab - You can implement this later
      // Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } else if (index == 1) {
      // List Car tab - Reload current page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ListCarScreen()),
      );
    } else if (index == 2) {
      // Profile tab - You can implement this later
      // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
    }
  }

  // Submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Extract values
      _carName = _carNameController.text.trim();
      _rentalPrice = double.tryParse(_priceController.text.trim()) ?? 0;
      _location = _locationController.text.trim();
      _ownerName = _ownerNameController.text.trim();

      print(
        '📝 Form values: $_carName / $_location / $_rentalPrice / $_ownerName',
      );

      // Upload images to Firebase Storage
      List<String> imageUrls = [];

      for (var image in _selectedImages) {
        final ref = FirebaseStorage.instance.ref().child(
          'car_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        final uploadTask = await ref.putData(await image.readAsBytes());
        final url = await uploadTask.ref.getDownloadURL();
        imageUrls.add(url);
      }

      print('✅ Uploaded ${imageUrls.length} images');

      // Save data to Firestore
      await _saveCarToFirestore(imageUrls);

      print('✅ Firestore write complete');

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CarListingSuccessScreen(),
        ),
      );
    } catch (e) {
      print('❌ Error during submission: $e');

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to list car: $e')));
    }
  }

  // Upload images to Firebase Storage with improved error handling

  // Save car data to Firestore with improved error handling
  Future<void> _saveCarToFirestore(List<String> imageUrls) async {
    try {
      String ownerInitials =
          _ownerName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join();

      String carId = const Uuid().v4();

      Map<String, dynamic> carData = {
        'id': carId,
        'name': _carName,
        'type': _transmission,
        'price': _rentalPrice,
        'rating': 4.5, // Default or hardcoded rating
        'location': _location,
        'ownerInitials': ownerInitials,
        'ownerName': _ownerName,
        'images': imageUrls,
        'rules': _rules,
        'createdAt': FieldValue.serverTimestamp(),
        'transmission': _transmission,
      };

      print('🔥 Final car data being saved: $carData');

      await FirebaseFirestore.instance
          .collection('cars')
          .doc(carId)
          .set(carData);

      print('✅ Firestore write succeeded');
    } catch (e) {
      print('❌ Error in _saveCarToFirestore: $e');
      throw Exception('Failed to save car data: $e');
    }
  }

  // Show success dialog
  void _showSuccessScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const CarListingSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.grid_view, size: 20),
                  ),
                  const Text(
                    'Rental',
                    style: TextStyle(
                      color: Color(0xFFCCFF00),
                      fontFamily: 'BeVietnamPro',
                      fontSize: 24,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title - Car image removed as requested
                              const Text(
                                'List your car today',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'It takes ',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'less than 2',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFCCFF00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'minutes to list your car !',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Note about mandatory fields
                              const Text(
                                'note : fields marked with * are mandatory',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Car Name (Make and Model)
                                    const Text(
                                      '* Car Name (Make and Model):',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextFormField(
                                      controller: _carNameController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. Toyota Camry',
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFFCCFF00),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter car name (make and model)';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _carName = value!;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Daily Rental Price
                                    const Text(
                                      '* Daily Rental Price :',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextFormField(
                                      controller: _priceController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFFCCFF00),
                                          ),
                                        ),
                                        prefixText: '\$ ',
                                        prefixStyle: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter rental price';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        if (double.parse(value) <= 0) {
                                          return 'Price must be greater than zero';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _rentalPrice = double.parse(value!);
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Location
                                    const Text(
                                      '* Location :',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextFormField(
                                      controller: _locationController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFFCCFF00),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter location';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _location = value!;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Transmission
                                    const Text(
                                      '* Transmission (Manual / Automatic)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: _transmission,
                                      dropdownColor: Colors.grey[900],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFFCCFF00),
                                          ),
                                        ),
                                      ),
                                      items:
                                          _transmissionOptions.map((
                                            String value,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _transmission = newValue!;
                                        });
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Owner Name
                                    const Text(
                                      '* Owner Name :',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextFormField(
                                      controller: _ownerNameController,

                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFFCCFF00),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter owner name';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _ownerName = value!;
                                      },
                                    ),

                                    const SizedBox(height: 24),

                                    // Car Images
                                    const Text(
                                      '* Car Images (at least 2 required):',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Image upload buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [const SizedBox(width: 16)],
                                    ),

                                    const SizedBox(height: 16),

                                    // Display selected images

                                    // Error message
                                    if (_errorMessage != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),

                                    const SizedBox(height: 24),

                                    // Submit button
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: _submitForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFCCFF00,
                                          ),
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'List My Car',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
            ),

            // Bottom Navigation - Updated with onTap handlers
            // Bottom Navigation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.grey[900]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to Home
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListingPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.home, color: Colors.grey, size: 24),
                        Text(
                          'home',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Already on List Car screen, do nothing
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.compare_arrows,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        Text(
                          'List Car',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to Past Rentals
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PastRentalsScreen(),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.account_circle_outlined,
                          color: Colors.grey,
                          size: 24,
                        ),
                        Text(
                          'account',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
