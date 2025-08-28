import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vaagaiauto/data/services/fare_service.dart';

class AddFarePage extends StatefulWidget {
  final String currentUserId;

  const AddFarePage({super.key, required this.currentUserId});

  @override
  AddFarePageState createState() => AddFarePageState();
}

class AddFarePageState extends State<AddFarePage> {
  final TextEditingController _baseFareController = TextEditingController();
  final TextEditingController _waiting5Controller = TextEditingController();
  final TextEditingController _waiting10Controller = TextEditingController();
  final TextEditingController _waiting15Controller = TextEditingController();
  final TextEditingController _waiting20Controller = TextEditingController();
  final TextEditingController _waiting25Controller = TextEditingController();
  final TextEditingController _waiting30Controller = TextEditingController();

  bool _isLoading = false;
  bool _isUpdating = false;
  bool _hasExistingFare = false;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    print('AddFarePage initialized with userId: ${widget.currentUserId}');
    _loadExistingFare();
  }

  // Helper method to safely convert dynamic values to double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // Helper method to safely convert dynamic values to string for text controllers
  String _safeToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  Future<void> _loadExistingFare() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Loading fare data...';
    });

    try {
      print('Loading existing fare for userId: ${widget.currentUserId}');
      final result = await FareService.getFareByUserId(widget.currentUserId);
      
      print('Load result: $result');
      
      if (result['success'] && result['data'] != null) {
        final fareData = result['data'] as Map<String, dynamic>;
        setState(() {
          _hasExistingFare = true;
          _debugInfo = 'Existing fare loaded successfully';
        });
        
        // Safely convert dynamic values to strings for text controllers
        _baseFareController.text = _safeToString(fareData['baseFare']);
        _waiting5Controller.text = _safeToString(fareData['waiting5min']);
        _waiting10Controller.text = _safeToString(fareData['waiting10min']);
        _waiting15Controller.text = _safeToString(fareData['waiting15min']);
        _waiting20Controller.text = _safeToString(fareData['waiting20min']);
        _waiting25Controller.text = _safeToString(fareData['waiting25min']);
        _waiting30Controller.text = _safeToString(fareData['waiting30min']);
        
        print('Loaded existing fare data: $fareData');
      } else {
        setState(() {
          _hasExistingFare = false;
          _debugInfo = 'No existing fare found - creating new';
        });
        // Set default values for new fare
        _waiting5Controller.text = '0';
        _waiting10Controller.text = '0';
        _waiting15Controller.text = '0';
        _waiting20Controller.text = '0';
        _waiting25Controller.text = '0';
        _waiting30Controller.text = '0';
        
        print('No existing fare found, using default values');
      }
    } catch (e) {
      print('Error loading existing fare: $e');
      setState(() {
        _debugInfo = 'Error loading fare: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading fare data: $e'),
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

  Future<void> _testDatabaseConnection() async {
    setState(() {
      _debugInfo = 'Testing database connection...';
    });

    try {
      final result = await FareService.testConnection();
      setState(() {
        _debugInfo = 'DB Test: ${result['success'] ? 'SUCCESS' : 'FAILED'} - ${result['message'] ?? 'Unknown'}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database Test: ${result['success'] ? 'Connected' : 'Failed'}'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      print('Database test result: $result');
    } catch (e) {
      setState(() {
        _debugInfo = 'DB Test Error: $e';
      });
      print('Database test error: $e');
    }
  }

  @override
  void dispose() {
    _baseFareController.dispose();
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
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _testDatabaseConnection,
            tooltip: 'Test DB Connection',
          ),
        ],
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
                    SizedBox(height: 20),
                    Text(
                      'Loading fare details...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_debugInfo.isNotEmpty) ...[
                      SizedBox(height: 10),
                      Text(
                        _debugInfo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              )
            : Column(
                children: [
                  // Header
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black, Colors.black],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_taxi, color: Colors.white, size: 30),
                            SizedBox(width: 15),
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
                                  Text(
                                    _hasExistingFare 
                                        ? 'Update your fare rates & waiting charges'
                                        : 'Set base fare & waiting charges',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_hasExistingFare)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'CONFIGURED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (_debugInfo.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'Debug: $_debugInfo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      color: Colors.yellow,
                      onRefresh: _loadExistingFare,
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // User ID Debug Info
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person, color: Colors.blue[600], size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'User ID: ${widget.currentUserId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Base Fare Section
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
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
                                        SizedBox(width: 8),
                                        Text(
                                          'Base Fare *',
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
                                      ],
                                      decoration: InputDecoration(
                                        hintText: 'Enter amount',
                                        prefixText: '₹ ',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: EdgeInsets.symmetric(
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
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black, Colors.black],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    spreadRadius: 1,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Waiting Charges (Optional)',
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

                            SizedBox(height: 30),

                            // Test Connection Button
                            Container(
                              width: double.infinity,
                              height: 40,
                              margin: EdgeInsets.only(bottom: 10),
                              child: OutlinedButton(
                                onPressed: _testDatabaseConnection,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Test Database Connection',
                                  style: TextStyle(color: Colors.blue),
                                ),
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
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isUpdating ? null : _updateFares,
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
                                          SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
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

                            SizedBox(height: 20),
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
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
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
                SizedBox(width: 8),
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
              ],
              decoration: InputDecoration(
                hintText: 'Enter fare',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
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

  Future<void> _updateFares() async {
    print('Update fares button pressed');
    
    // Validate if at least base fare is entered
    if (_baseFareController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter base fare'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Safely parse base fare
    final baseFare = double.tryParse(_baseFareController.text);
    if (baseFare == null || baseFare <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Base fare must be a valid positive number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
      _debugInfo = 'Saving fare data...';
    });

    try {
      print('Attempting to save fare with userId: ${widget.currentUserId}');
      
      // Safely parse all values with fallback to 0.0
      final waiting5min = double.tryParse(_waiting5Controller.text.isEmpty ? '0' : _waiting5Controller.text) ?? 0.0;
      final waiting10min = double.tryParse(_waiting10Controller.text.isEmpty ? '0' : _waiting10Controller.text) ?? 0.0;
      final waiting15min = double.tryParse(_waiting15Controller.text.isEmpty ? '0' : _waiting15Controller.text) ?? 0.0;
      final waiting20min = double.tryParse(_waiting20Controller.text.isEmpty ? '0' : _waiting20Controller.text) ?? 0.0;
      final waiting25min = double.tryParse(_waiting25Controller.text.isEmpty ? '0' : _waiting25Controller.text) ?? 0.0;
      final waiting30min = double.tryParse(_waiting30Controller.text.isEmpty ? '0' : _waiting30Controller.text) ?? 0.0;
      
      print('Fare data to save:');
      print('  baseFare: $baseFare');
      print('  waiting5min: $waiting5min');
      print('  waiting10min: $waiting10min');
      print('  waiting15min: $waiting15min');
      print('  waiting20min: $waiting20min');
      print('  waiting25min: $waiting25min');
      print('  waiting30min: $waiting30min');

      final result = await FareService.updateOrCreateFare(
        userId: widget.currentUserId,
        baseFare: baseFare,
        waiting5min: waiting5min,
        waiting10min: waiting10min,
        waiting15min: waiting15min,
        waiting20min: waiting20min,
        waiting25min: waiting25min,
        waiting30min: waiting30min,
      );

      print('Save result: $result');

      if (result['success']) {
        setState(() {
          _hasExistingFare = true;
          _debugInfo = 'Fare saved successfully!';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Refresh the data to confirm it was saved
        await Future.delayed(Duration(seconds: 1));
        await _loadExistingFare();
        
      } else {
        setState(() {
          _debugInfo = 'Save failed: ${result['message']}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Exception during fare save: $e');
      setState(() {
        _debugInfo = 'Exception: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}
