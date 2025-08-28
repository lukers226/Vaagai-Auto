import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vaagaiauto/data/services/fare_service.dart';

class AddFarePage extends StatefulWidget {
  final String currentUserId; // Pass current user ID when navigating to this page

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

  @override
  void initState() {
    super.initState();
    _loadExistingFare();
  }

  Future<void> _loadExistingFare() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FareService.getFareByUserId(widget.currentUserId);
      
      if (result['success'] && result['data'] != null) {
        final fareData = result['data'];
        setState(() {
          _hasExistingFare = true;
        });
        
        _baseFareController.text = fareData['baseFare'].toString();
        _waiting5Controller.text = fareData['waiting5min'].toString();
        _waiting10Controller.text = fareData['waiting10min'].toString();
        _waiting15Controller.text = fareData['waiting15min'].toString();
        _waiting20Controller.text = fareData['waiting20min'].toString();
        _waiting25Controller.text = fareData['waiting25min'].toString();
        _waiting30Controller.text = fareData['waiting30min'].toString();
      } else {
        setState(() {
          _hasExistingFare = false;
        });
        // Set default values for new fare
        _waiting5Controller.text = '0';
        _waiting10Controller.text = '0';
        _waiting15Controller.text = '0';
        _waiting20Controller.text = '0';
        _waiting25Controller.text = '0';
        _waiting30Controller.text = '0';
      }
    } catch (e) {
      print('Error loading existing fare: $e');
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
                    child: Row(
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

                            SizedBox(height: 30),

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

    // Validate base fare is not zero
    if (double.tryParse(_baseFareController.text) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Base fare cannot be zero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final result = await FareService.updateOrCreateFare(
        userId: widget.currentUserId,
        baseFare: double.parse(_baseFareController.text.isEmpty ? '0' : _baseFareController.text),
        waiting5min: double.parse(_waiting5Controller.text.isEmpty ? '0' : _waiting5Controller.text),
        waiting10min: double.parse(_waiting10Controller.text.isEmpty ? '0' : _waiting10Controller.text),
        waiting15min: double.parse(_waiting15Controller.text.isEmpty ? '0' : _waiting15Controller.text),
        waiting20min: double.parse(_waiting20Controller.text.isEmpty ? '0' : _waiting20Controller.text),
        waiting25min: double.parse(_waiting25Controller.text.isEmpty ? '0' : _waiting25Controller.text),
        waiting30min: double.parse(_waiting30Controller.text.isEmpty ? '0' : _waiting30Controller.text),
      );

      if (result['success']) {
        setState(() {
          _hasExistingFare = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Invalid input values'),
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
