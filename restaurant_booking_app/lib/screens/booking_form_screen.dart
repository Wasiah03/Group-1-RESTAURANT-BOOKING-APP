import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/menu_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../models/booking.dart';

class BookingFormScreen extends StatefulWidget {
  final String packageId;

  const BookingFormScreen({super.key, required this.packageId});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventDateController = TextEditingController();
  final _eventTimeController = TextEditingController();
  final _guestsController = TextEditingController();
  bool _isLoading = false;
  double _totalPrice = 0.0;
  double _pricePerGuest = 0.0;
  double _serviceCharges = 0.0;
  String _packageName = '';

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

  @override
  void initState() {
    super.initState();
    _loadPackage();
    _guestsController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _eventDateController.dispose();
    _eventTimeController.dispose();
    _guestsController.dispose();
    super.dispose();
  }

  Future<void> _loadPackage() async {
    final menuProvider = context.read<MenuProvider>();
    final package = await menuProvider.getPackageById(
      int.parse(widget.packageId),
    );
    if (package != null) {
      setState(() {
        _packageName = package.name;
        _pricePerGuest = package.pricePerGuest;
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    // Create JSON string for service customizations
    final Map<String, dynamic> customizations = {
      'decorations': _decorations,
      'photography': _photography,
      'liveMusic': _liveMusic,
      'premiumBar': _premiumBar,
    };

    final booking = Booking(
      userId: authProvider.currentUser!.id!,
      packageId: int.parse(widget.packageId),
      eventDate: _eventDateController.text,
      eventTime: _eventTimeController.text,
      numberOfGuests: int.parse(_guestsController.text),
      totalPrice: _totalPrice,
      status: 'pending',
      serviceCustomizations: jsonEncode(customizations),
    );

    final success = await bookingProvider.addBooking(booking);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking created successfully!')),
      );
      context.go('/user');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create booking')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(title: const Text('Book Event'), centerTitle: true),
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
                    _packageName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_pricePerGuest.toStringAsFixed(2)} per guest',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
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
                          onPressed: () => context.pop(),
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
                          onPressed: _isLoading ? null : _handleSubmit,
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
                              : const Text('Submit Booking'),
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
