import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'car_listing_success_screen.dart';
import 'navigation_helper.dart';
import 'list_car_bloc.dart';
import 'list_car_event.dart';
import 'sidebar.dart';
import 'list_car_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rental_app/constants/locations.dart';

String? selectedLocation;

DateTime? _availableFrom;
DateTime? _availableTo;

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class ListCarScreen extends StatefulWidget {
  const ListCarScreen({super.key});

  @override
  State<ListCarScreen> createState() => _ListCarScreenState();
}

class _ListCarScreenState extends State<ListCarScreen> {
  final TextEditingController _carNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _daysController = TextEditingController(
    text: "3",
  ); // Default to 3 days
  int _selectedSeater = 4; // Default to 4 seats
  final List<int> _seaterOptions = [
    2,
    4,
    5,
    7,
    8,
  ]; // Common car seating options
  int _selectedKms = 1000;
  final List<int> _kmsoptions = [1000, 2000, 3000, 40000, 5000];
  bool _isLoading = false; // Add this flag to control initial loading state
  bool _isFormLoading = true; // for initial load

  @override
  void initState() {
    super.initState();
    // Simulate loading for 1.5 seconds to show the animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      {
        setState(() {
          _isFormLoading = false;
        });
      }
    });
  }

  Future<void> _pickImages() async {
    final pickedImages = await _picker.pickMultiImage();

    if (pickedImages.isNotEmpty) {
      setState(() {
        _selectedImages = pickedImages;
      });
    }
  }

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Form fields
  String _transmission = 'Automatic';
  List<XFile> _selectedImages = [];
  final List<Map<String, dynamic>> _rules = [
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
    {
      'title': 'No Smoking Policy',
      'description':
          'Smoking inside the rental vehicle is strictly prohibited. Violation of this policy will result in a cleaning fee of up to RS. 2000',
    },
    {
      'title': 'Fuel Policy',
      'description':
          'The car must be returned with the same fuel level as at the time of pickup. Failure to do so will result in additional refueling charges.',
    },
  ];

  // Transmission options
  final List<String> _transmissionOptions = ['Automatic', 'Manual'];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ListCarBloc(),
      child: BlocConsumer<ListCarBloc, ListCarState>(
        listener: (context, state) {
          if (state is ListCarSuccess) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const CarListingSuccessScreen(),
              ),
            );
          } else if (state is ListCarError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return Scaffold(
            key: _scaffoldKey,
            drawer: SideBar(
              onClose: () => _scaffoldKey.currentState?.closeDrawer(),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(Icons.menu, size: 20),
                          ),
                        ),
                        const Text(
                          'Rental',
                          style: TextStyle(
                            fontFamily: 'Conthrax',
                            color: Color(0xFFCCFF00),
                            fontSize: 21,
                          ),
                        ),
                        FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              );
                            }

                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            if (userData == null) {
                              return const CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.white),
                              );
                            }

                            final firstName =
                                userData['first_name'] as String? ?? '';
                            final lastName =
                                userData['last_name'] as String? ?? '';
                            final initials =
                                (firstName.isNotEmpty ? firstName[0] : '') +
                                (lastName.isNotEmpty ? lastName[0] : '');

                            return CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[700],
                              child: Text(
                                initials.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Main content
                  Expanded(
                    child:
                        _isFormLoading ||
                                state is ListCarLoading ||
                                _isLoading // Check both conditions
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(seconds: 1),
                                    curve: Curves.linear,
                                    builder: (context, value, child) {
                                      return Transform.rotate(
                                        angle: value * 6.28, // 2 * pi
                                        child: child,
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/images/wheel.jpg',
                                      width: 80,
                                      height: 80,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Preparing listing form",
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 30),
                                    // Title - Car image removed as requested
                                    const Text(
                                      'List your car today !',
                                      style: TextStyle(
                                        fontSize: 27,
                                        fontFamily: 'Conthrax',
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFCCFF00),
                                                    ),
                                                  ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter car name (make and model)';
                                              }
                                              return null;
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
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
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
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter rental price';
                                              }
                                              if (double.tryParse(value) ==
                                                  null) {
                                                return 'Please enter a valid number';
                                              }
                                              if (double.parse(value) <= 0) {
                                                return 'Price must be greater than zero';
                                              }
                                              return null;
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

                                          DropdownButtonFormField<String>(
                                            value: selectedLocation,
                                            items:
                                                karachiAreas.map((area) {
                                                  return DropdownMenuItem(
                                                    value: area,
                                                    child: Text(area),
                                                  );
                                                }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                selectedLocation = value;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please select a location';
                                              }
                                              return null;
                                            },
                                            decoration: const InputDecoration(
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFCCFF00),
                                                    ),
                                                  ),
                                            ),
                                            dropdownColor: Colors.black,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),

                                          const SizedBox(height: 16),

                                          // Number of Seats (Seater)
                                          const Text(
                                            '* Number of Seats :',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          DropdownButtonFormField<int>(
                                            value: _selectedSeater,
                                            dropdownColor: Colors.grey[900],
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: const InputDecoration(
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFCCFF00),
                                                    ),
                                                  ),
                                            ),
                                            items:
                                                _seaterOptions.map((int value) {
                                                  return DropdownMenuItem<int>(
                                                    value: value,
                                                    child: Text('$value seats'),
                                                  );
                                                }).toList(),
                                            onChanged: (int? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  _selectedSeater = newValue;
                                                });
                                              }
                                            },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'Please select number of seats';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          // Number of Seats (Seater)
                                          const Text(
                                            '* Kilometers:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          DropdownButtonFormField<int>(
                                            value: _selectedKms,
                                            dropdownColor: Colors.grey[900],
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: const InputDecoration(
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFCCFF00),
                                                    ),
                                                  ),
                                            ),
                                            items:
                                                _kmsoptions.map((int value) {
                                                  return DropdownMenuItem<int>(
                                                    value: value,
                                                    child: Text('$value kms'),
                                                  );
                                                }).toList(),
                                            onChanged: (int? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  _selectedKms = newValue;
                                                });
                                              }
                                            },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'Please select  kms driven';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          // Days Available
                                          const Text(
                                            '* Days Available :',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          TextFormField(
                                            controller: _daysController,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: 'e.g. 3',
                                              hintStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFCCFF00),
                                                    ),
                                                  ),
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter days available';
                                              }
                                              if (int.tryParse(value) == null) {
                                                return 'Please enter a valid number';
                                              }
                                              if (int.parse(value) <= 0) {
                                                return 'Days must be greater than zero';
                                              }
                                              return null;
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
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFCCFF00),
                                                    ),
                                                  ),
                                            ),
                                            items:
                                                _transmissionOptions.map((
                                                  String value,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
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
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Color(0xFFCCFF00),
                                                    ),
                                                  ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter owner name';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),

                                          const Text(
                                            '* Availability (Date Range)',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          Row(
                                            children: [
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    DateTime?
                                                    picked = await showDatePicker(
                                                      context: context,
                                                      initialDate:
                                                          DateTime.now(),
                                                      firstDate: DateTime.now(),
                                                      lastDate: DateTime(2100),
                                                      builder: (
                                                        context,
                                                        child,
                                                      ) {
                                                        return Theme(
                                                          data: ThemeData.dark().copyWith(
                                                            colorScheme:
                                                                const ColorScheme.dark(
                                                                  primary: Color(
                                                                    0xFFCCFF00,
                                                                  ),
                                                                  onPrimary:
                                                                      Colors
                                                                          .black,
                                                                  surface:
                                                                      Colors
                                                                          .black,
                                                                  onSurface:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                          ),
                                                          child: child!,
                                                        );
                                                      },
                                                    );
                                                    if (picked != null) {
                                                      setState(() {
                                                        _availableFrom = picked;
                                                        if (_availableTo !=
                                                                null &&
                                                            _availableTo!
                                                                .isBefore(
                                                                  _availableFrom!,
                                                                )) {
                                                          _availableTo = null;
                                                        }
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.grey,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _availableFrom == null
                                                          ? 'Available From'
                                                          : 'From: ${_availableFrom!.toLocal().toString().split(' ')[0]}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    DateTime?
                                                    picked = await showDatePicker(
                                                      context: context,
                                                      initialDate:
                                                          _availableFrom ??
                                                          DateTime.now(),
                                                      firstDate:
                                                          _availableFrom ??
                                                          DateTime.now(),
                                                      lastDate: DateTime(2100),
                                                      builder: (
                                                        context,
                                                        child,
                                                      ) {
                                                        return Theme(
                                                          data: ThemeData.dark().copyWith(
                                                            colorScheme:
                                                                const ColorScheme.dark(
                                                                  primary: Color(
                                                                    0xFFCCFF00,
                                                                  ),
                                                                  onPrimary:
                                                                      Colors
                                                                          .black,
                                                                  surface:
                                                                      Colors
                                                                          .black,
                                                                  onSurface:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                          ),
                                                          child: child!,
                                                        );
                                                      },
                                                    );
                                                    if (picked != null) {
                                                      setState(() {
                                                        _availableTo = picked;
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Colors.grey,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _availableTo == null
                                                          ? 'Available To'
                                                          : 'To: ${_availableTo!.toLocal().toString().split(' ')[0]}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 24),

                                          // Car Images
                                          const SizedBox(height: 8),

                                          // Image upload buttons
                                          // Image picker button
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: _pickImages,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF2E2E2E,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.photo_library,
                                                ),
                                                label: const Text(
                                                  'Upload Car Images',
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Display selected images
                                          if (_selectedImages.isNotEmpty)
                                            SizedBox(
                                              height: 100,
                                              child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount:
                                                    _selectedImages.length,
                                                itemBuilder: (context, index) {
                                                  return FutureBuilder(
                                                    future:
                                                        _selectedImages[index]
                                                            .readAsBytes(),
                                                    builder: (
                                                      context,
                                                      snapshot,
                                                    ) {
                                                      if (snapshot.connectionState ==
                                                              ConnectionState
                                                                  .done &&
                                                          snapshot.hasData) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 4.0,
                                                              ),
                                                          child: Image.memory(
                                                            snapshot.data!,
                                                            width: 100,
                                                            height: 100,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        );
                                                      } else {
                                                        return Container(
                                                          width: 100,
                                                          height: 100,
                                                          color:
                                                              Colors.grey[800],
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          const SizedBox(height: 24),
                                          // Submit button
                                          Center(
                                            child: ElevatedButton(
                                              onPressed:
                                                  () => _submitForm(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFCCFF00,
                                                ),
                                                foregroundColor: Colors.black,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 40,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
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
                          onTap:
                              () => NavigationHelper.handleBottomNavigation(
                                context,
                                0,
                              ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.home, color: Colors.grey, size: 24),
                              Text(
                                'home',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap:
                              () => NavigationHelper.handleBottomNavigation(
                                context,
                                1,
                              ),
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
                          onTap:
                              () => NavigationHelper.handleBottomNavigation(
                                context,
                                2,
                              ),
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
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
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
        },
      ),
    );
  }

  void _submitForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final carName = _carNameController.text.trim();
    final rentalPrice = double.tryParse(_priceController.text.trim()) ?? 0;
    final location = selectedLocation!;
    final ownerName = _ownerNameController.text.trim();
    final days = int.tryParse(_daysController.text.trim()) ?? 3;

    if (_availableFrom == null || _availableTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select availability dates')),
      );
      return;
    }
    BlocProvider.of<ListCarBloc>(context).add(
      SubmitCarListing(
        carName: carName,
        rentalPrice: rentalPrice,
        location: location,
        transmission: _transmission,
        ownerName: ownerName,
        selectedImages: _selectedImages,
        rules: _rules,
        availableFrom: _availableFrom!,
        availableTo: _availableTo!,
        isAvailable: true, // Explicitly set to true when listing a new car
        seater: _selectedSeater, // Add the seater field
        kms: _selectedKms,
        days: days, // Add the days field
      ),
    );
  }
}
