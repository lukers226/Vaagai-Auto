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
  final TextEditingController _perKmRateController = TextEditingController(); // NEW FIELD
  final TextEditingController _waiting5Controller = TextEditingController();
  final TextEditingController _waiting10Controller = TextEditingController();
  final TextEditingController _waiting15Controller = TextEditingController();
  final TextEditingController _waiting20Controller = TextEditingController();
  final TextEditingController _waiting25Controller = TextEditingController();
  final TextEditingController _waiting30Controller = TextEditingController();

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
    // For perKmRate, show decimal places if needed
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
        _perKmRateController.text = _safeToString(fareData['perKmRate']); // NEW FIELD
        _waiting5Controller.text = _safeToString(fareData['waiting5min']);
        _waiting10Controller.text = _safeToString(fareData['waiting10min']);
        _waiting15Controller.text = _safeToString(fareData['waiting15min']);
        _waiting20Controller.text = _safeToString(fareData['waiting20min']);
        _waiting25Controller.text = _safeToString(fareData['waiting25min']);
        _waiting30Controller.text = _safeToString(fareData['waiting30min']);
        
        _logInfo('Loaded existing system fare data with perKmRate');
      } else {
        if (!mounted) return;
        
        setState(() {
          _hasExistingFare = false;
        });
        // Keep all fields empty for first time
        _baseFareController.text = '';
        _perKmRateController.text = ''; // NEW FIELD
        _waiting5Controller.text = '';
        _waiting10Controller.text = '';
        _waiting15Controller.text = '';
        _waiting20Controller.text = '';
        _waiting25Controller.text = '';
        _waiting30Controller.text = '';
        
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
    _perKmRateController.dispose(); // NEW FIELD
    _waiting5Controller.dispose();
    _waiting10Controller.dispose();
    _waiting15Controller.dispose();
    _waiting20Controller.dispose();
    _waiting25Controller.dispose();
    _waiting30Controller.dispose();
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
                                        LengthLimitingTextInputFormatter(4), // Max 4 digits
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

                            // NEW: Per Km Rate Section
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
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Allow decimals up to 2 places
                                        LengthLimitingTextInputFormatter(6), // Max 6 characters (e.g., 999.99)
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

                            // Waiting Charges Header
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.black, Colors.black],
                                ),
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
                                  const Icon(Icons.access_time, color: Colors.white, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Waiting Charges',
                                    style: GoogleFonts.lato(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Waiting Charges List
                            _buildWaitingChargeItem('5 Minutes', _waiting5Controller),
                            _buildWaitingChargeItem('10 Minutes', _waiting10Controller),
                            _buildWaitingChargeItem('15 Minutes', _waiting15Controller),
                            _buildWaitingChargeItem('20 Minutes', _waiting20Controller),
                            _buildWaitingChargeItem('25 Minutes', _waiting25Controller),
                            _buildWaitingChargeItem('30 Minutes', _waiting30Controller),

                            const SizedBox(height: 30),

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

  Widget _buildWaitingChargeItem(String duration, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  Icons.timer,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  duration,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3), // Max 3 digits for waiting charges
              ],
              decoration: InputDecoration(
                hintText: 'Enter fare',
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

    if (!mounted) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      _logInfo('Attempting to save system fare');
      
      // Parse waiting charges, default to 0 if empty
      final waiting5min = double.tryParse(_waiting5Controller.text.isEmpty ? '0' : _waiting5Controller.text) ?? 0.0;
      final waiting10min = double.tryParse(_waiting10Controller.text.isEmpty ? '0' : _waiting10Controller.text) ?? 0.0;
      final waiting15min = double.tryParse(_waiting15Controller.text.isEmpty ? '0' : _waiting15Controller.text) ?? 0.0;
      final waiting20min = double.tryParse(_waiting20Controller.text.isEmpty ? '0' : _waiting20Controller.text) ?? 0.0;
      final waiting25min = double.tryParse(_waiting25Controller.text.isEmpty ? '0' : _waiting25Controller.text) ?? 0.0;
      final waiting30min = double.tryParse(_waiting30Controller.text.isEmpty ? '0' : _waiting30Controller.text) ?? 0.0;
      
      _logInfo('System fare data to save: baseFare: $baseFare, perKmRate: $perKmRate, waiting5min: $waiting5min, waiting10min: $waiting10min, waiting15min: $waiting15min, waiting20min: $waiting20min, waiting25min: $waiting25min, waiting30min: $waiting30min');

      final result = await FareService.updateOrCreateSystemFare(
        baseFare: baseFare,
        perKmRate: perKmRate, // NEW FIELD
        waiting5min: waiting5min,
        waiting10min: waiting10min,
        waiting15min: waiting15min,
        waiting20min: waiting20min,
        waiting25min: waiting25min,
        waiting30min: waiting30min,
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
