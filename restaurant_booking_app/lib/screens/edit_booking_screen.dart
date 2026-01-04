import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/booking_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/auth_provider.dart';
import '../models/booking.dart';
import '../models/menu_package.dart';

class EditBookingScreen extends StatefulWidget {
  final String bookingId;

  const EditBookingScreen({super.key, required this.bookingId});

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventDateController = TextEditingController();
  final _eventTimeController = TextEditingController();
  final _guestsController = TextEditingController();
  bool _isLoading = false;
  Booking? _booking;
  double _totalPrice = 0.0;
  double _pricePerGuest = 0.0;
  double _serviceCharges = 0.0;

  // Service customization options
  bool _decorations = false;
  bool _photography = false;
  bool _liveMusic = false;
  bool _premiumBar = false;

  final Map<String, double> _servicePrices = {
    'decorations': 500.0,
    'photography': 800.0,
    'liveMusic': 1200.0,
    'premiumBar': 600.0,
  };

  int? _selectedPackageId;
  List<MenuPackage> _availablePackages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _guestsController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _eventDateController.dispose();
    _eventTimeController.dispose();
    _guestsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load available packages
    final menuProvider = context.read<MenuProvider>();
    await menuProvider.fetchPackages();

    final bookingProvider = context.read<BookingProvider>();
    final booking = await bookingProvider.getBookingById(
      int.parse(widget.bookingId),
    );

    if (booking != null) {
      final package = await menuProvider.getPackageById(booking.packageId);

      // Parse service customizations
      Map<String, dynamic>? customizations;
      if (booking.serviceCustomizations != null) {
        try {
          customizations = jsonDecode(booking.serviceCustomizations!);
        } catch (e) {
          print('Error parsing customizations: $e');
        }
      }

      setState(() {
        _booking = booking;
        _availablePackages = menuProvider.packages;
        // Only set selectedPackageId if it exists in available packages
        if (_availablePackages.any((p) => p.id == booking.packageId)) {
          _selectedPackageId = booking.packageId;
        } else if (_availablePackages.isNotEmpty) {
          _selectedPackageId = _availablePackages.first.id;
        }
        _eventDateController.text = booking.eventDate;
        _eventTimeController.text = booking.eventTime;
        _guestsController.text = booking.numberOfGuests.toString();
        _pricePerGuest = package?.pricePerGuest ?? 0.0;

        if (customizations != null) {
          _decorations = customizations['decorations'] ?? false;
          _photography = customizations['photography'] ?? false;
          _liveMusic = customizations['liveMusic'] ?? false;
          _premiumBar = customizations['premiumBar'] ?? false;
        }

        _calculateTotal();
      });
    }
  }

  void _calculateTotal() {
    final guests = int.tryParse(_guestsController.text) ?? 0;
    double serviceCharges = 0.0;

    if (_decorations) serviceCharges += _servicePrices['decorations']!;
    if (_photography) serviceCharges += _servicePrices['photography']!;
    if (_liveMusic) serviceCharges += _servicePrices['liveMusic']!;
    if (_premiumBar) serviceCharges += _servicePrices['premiumBar']!;

    setState(() {
      _serviceCharges = serviceCharges;
      _totalPrice = (guests * _pricePerGuest) + serviceCharges;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _eventDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _eventTimeController.text = picked.format(context);
    }
  }

  Future<void> _handleUpdate() async {
    if (_booking == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final bookingProvider = context.read<BookingProvider>();

    // Create JSON string for service customizations
    final Map<String, dynamic> customizations = {
      'decorations': _decorations,
      'photography': _photography,
      'liveMusic': _liveMusic,
      'premiumBar': _premiumBar,
    };

    final updatedBooking = _booking!.copyWith(
      packageId: _selectedPackageId ?? _booking!.packageId,
      eventDate: _eventDateController.text,
      eventTime: _eventTimeController.text,
      numberOfGuests: int.parse(_guestsController.text),
      totalPrice: _totalPrice,
      serviceCustomizations: jsonEncode(customizations),
    );

    final success = await bookingProvider.updateBooking(updatedBooking);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking updated successfully!')),
      );
      // Check user role to determine redirect
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser?.role == 'admin') {
        context.go('/admin');
      } else {
        context.go('/user/reservations');
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update booking')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Booking'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(title: const Text('Edit Booking'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking #${_booking!.id}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User ID: ${_booking!.userId}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  if (_availablePackages.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<int>(
                      value: _selectedPackageId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Menu Package',
                        prefixIcon: const Icon(Icons.restaurant_menu),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _availablePackages.map((package) {
                        return DropdownMenuItem(
                          value: package.id,
                          child: Text(
                            '${package.name} - \$${package.pricePerGuest.toStringAsFixed(0)}/guest',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (packageId) {
                        final package = _availablePackages.firstWhere(
                          (p) => p.id == packageId,
                        );
                        setState(() {
                          _selectedPackageId = packageId;
                          _pricePerGuest = package.pricePerGuest;
                          _calculateTotal();
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a package';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _eventDateController,
                    decoration: InputDecoration(
                      labelText: 'Event Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    readOnly: true,
                    onTap: _selectDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an event date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _eventTimeController,
                    decoration: InputDecoration(
                      labelText: 'Event Time',
                      prefixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    readOnly: true,
                    onTap: _selectTime,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an event time';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _guestsController,
                    decoration: InputDecoration(
                      labelText: 'Number of Guests',
                      prefixIcon: const Icon(Icons.people),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of guests';
                      }
                      final guests = int.tryParse(value);
                      if (guests == null || guests <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Service Customizations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('Event Decorations'),
                          subtitle: Text(
                            '\$${_servicePrices['decorations']!.toStringAsFixed(0)}',
                          ),
                          value: _decorations,
                          onChanged: (value) {
                            setState(() {
                              _decorations = value ?? false;
                              _calculateTotal();
                            });
                          },
                        ),
                        CheckboxListTile(
                          title: const Text('Professional Photography'),
                          subtitle: Text(
                            '\$${_servicePrices['photography']!.toStringAsFixed(0)}',
                          ),
                          value: _photography,
                          onChanged: (value) {
                            setState(() {
                              _photography = value ?? false;
                              _calculateTotal();
                            });
                          },
                        ),
                        CheckboxListTile(
                          title: const Text('Live Music Band'),
                          subtitle: Text(
                            '\$${_servicePrices['liveMusic']!.toStringAsFixed(0)}',
                          ),
                          value: _liveMusic,
                          onChanged: (value) {
                            setState(() {
                              _liveMusic = value ?? false;
                              _calculateTotal();
                            });
                          },
                        ),
                        CheckboxListTile(
                          title: const Text('Premium Bar Service'),
                          subtitle: Text(
                            '\$${_servicePrices['premiumBar']!.toStringAsFixed(0)}',
                          ),
                          value: _premiumBar,
                          onChanged: (value) {
                            setState(() {
                              _premiumBar = value ?? false;
                              _calculateTotal();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Package Cost:'),
                            Text(
                              '\$${((int.tryParse(_guestsController.text) ?? 0) * _pricePerGuest).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        if (_serviceCharges > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Service Charges:'),
                              Text('\$${_serviceCharges.toStringAsFixed(2)}'),
                            ],
                          ),
                          const Divider(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Price:',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${_totalPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final authProvider = context.read<AuthProvider>();
                            if (authProvider.currentUser?.role == 'admin') {
                              context.go('/admin');
                            } else {
                              context.go('/user/reservations');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleUpdate,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
