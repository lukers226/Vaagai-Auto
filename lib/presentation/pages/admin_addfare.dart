import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vaagaiauto/data/services/fare_service.dart';
import 'dart:developer' as developer;

class AddFarePage extends StatefulWidget {
  const AddFarePage({super.key});

  @override
  AddFarePageState createState() => AddFarePageState();
}

class AddFarePageState extends State<AddFarePage> {
  final TextEditingController _baseFareController = TextEditingController();
  final TextEditingController _perKmRateController = TextEditingController();
  final TextEditingController _waiting60Controller = TextEditingController();

  bool _isLoading = false;
  bool _isUpdating = false;
  bool _hasExistingFare = false;

  @override
  void initState() {
    super.initState();
    _logInfo('AddFarePage initialized (Admin System)');
    _loadExistingSystemFare();
  }

  // Logging methods
  void _logInfo(String message) {
    developer.log(message, name: 'AddFarePage', level: 800);
  }

  void _logError(String message, [Object? error]) {
    developer.log(message, name: 'AddFarePage', level: 1000, error: error);
  }

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _safeToString(dynamic value) {
    if (value == null) return '';
    double numValue = _safeToDouble(value);
    if (numValue == 0.0) return '';
    // Show decimal places if needed
    if (numValue == numValue.toInt()) {
      return numValue.toStringAsFixed(0); // Show whole numbers
    } else {
      return numValue.toString(); // Show with decimals
    }
  }

  Future<void> _loadExistingSystemFare() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      _logInfo('Loading existing system fare...');
      final result = await FareService.getSystemFare();
      
      if (!mounted) return;
      
      _logInfo('Load result: $result');
      
      if (result['success'] && result['data'] != null) {
        final fareData = result['data'] as Map<String, dynamic>;
        
        setState(() {
          _hasExistingFare = true;
        });
        
        // Load values into controllers, empty if 0
        _baseFareController.text = _safeToString(fareData['baseFare']);
        _perKmRateController.text = _safeToString(fareData['perKmRate']);
        _waiting60Controller.text = _safeToString(fareData['waiting60min']);
        
        _logInfo('Loaded existing system fare data');
      } else {
        if (!mounted) return;
        
        setState(() {
          _hasExistingFare = false;
        });
        // Keep all fields empty for first time
        _baseFareController.text = '';
        _perKmRateController.text = '';
        _waiting60Controller.text = '';
        
        _logInfo('No existing system fare found, keeping fields empty');
      }
    } catch (e) {
      _logError('Error loading existing system fare', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading fare data'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  void dispose() {
    _baseFareController.dispose();
    _perKmRateController.dispose();
    _waiting60Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _hasExistingFare ? 'Update Fare' : 'Add Fare',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading fare details...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Header
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.black, Colors.black],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_taxi, color: Colors.white, size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fare Configuration',
                                style: GoogleFonts.lato(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      color: Colors.yellow,
                      onRefresh: _loadExistingSystemFare,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Base Fare Section
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.currency_rupee,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Base Fare',
                                          style: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _baseFareController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: 'Enter amount',
                                        prefixText: '₹ ',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Per Km Rate Section
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.route,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Per Km Rate',
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _perKmRateController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                        LengthLimitingTextInputFormatter(6),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: 'Rate per km',
                                        prefixText: '₹ ',
                                        suffixText: '/km',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Waiting Charge Section (60 Minutes Only)
                            Container(
                              margin: const EdgeInsets.only(bottom: 30),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange[300]!, Colors.orange[400]!],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.orange[600]!, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                    spreadRadius: 3,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Waiting Charge',
                                        style: GoogleFonts.lato(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.hourglass_full,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '60 Minutes',
                                                  style: GoogleFonts.lato(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  'Per Hour Rate',
                                                  style: GoogleFonts.lato(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: _waiting60Controller,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(4),
                                          ],
                                          decoration: InputDecoration(
                                            hintText: 'Enter fare',
                                            hintStyle: const TextStyle(color: Colors.grey),
                                            prefixText: '₹ ',
                                            prefixStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Colors.white, width: 2),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Colors.white, width: 2),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Colors.white, width: 3),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Update Button
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.yellow[600]!, Colors.yellow[400]!],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.yellow.withValues(alpha: 0.3),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isUpdating ? null : _updateSystemFares,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: _isUpdating
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _hasExistingFare ? 'Updating...' : 'Creating...',
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _hasExistingFare ? 'Update Fares' : 'Create Fares',
                                        style: GoogleFonts.lato(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _updateSystemFares() async {
    _logInfo('Update system fares button pressed');
    
    // Validate base fare
    if (_baseFareController.text.isEmpty) {
      _showSnackBar('Please enter base fare', Colors.red);
      return;
    }

    final baseFare = double.tryParse(_baseFareController.text);
    if (baseFare == null || baseFare <= 0) {
      _showSnackBar('Base fare must be a valid positive number', Colors.red);
      return;
    }

    // Validate per km rate
    if (_perKmRateController.text.isEmpty) {
      _showSnackBar('Please enter per kilometer rate', Colors.red);
      return;
    }

    final perKmRate = double.tryParse(_perKmRateController.text);
    if (perKmRate == null || perKmRate <= 0) {
      _showSnackBar('Per kilometer rate must be a valid positive number', Colors.red);
      return;
    }

    if (perKmRate > 1000) {
      _showSnackBar('Per kilometer rate cannot exceed ₹1000', Colors.red);
      return;
    }

    // Validate 60 minute waiting charge
    if (_waiting60Controller.text.isEmpty) {
      _showSnackBar('Please enter 60 minutes waiting charge', Colors.red);
      return;
    }

    final waiting60min = double.tryParse(_waiting60Controller.text);
    if (waiting60min == null || waiting60min < 0) {
      _showSnackBar('60 minutes waiting charge must be a valid non-negative number', Colors.red);
      return;
    }

    if (!mounted) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      _logInfo('Attempting to save system fare');
      _logInfo('System fare data to save: baseFare: $baseFare, perKmRate: $perKmRate, waiting60min: $waiting60min');

      final result = await FareService.updateOrCreateSystemFare(
        baseFare: baseFare,
        perKmRate: perKmRate,
        waiting60min: waiting60min,
      );

      if (!mounted) return;

      _logInfo('Save result: $result');

      if (result['success']) {
        setState(() {
          _hasExistingFare = true;
        });
        
        _showSnackBar('✅ ${result['message']}', Colors.green);
        
        // Refresh data to show updated values
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _loadExistingSystemFare();
        }
        
      } else {
        _showSnackBar('❌ ${result['message']}', Colors.red);
      }
    } catch (e) {
      _logError('Exception during system fare save', e);
      
      if (mounted) {
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}
