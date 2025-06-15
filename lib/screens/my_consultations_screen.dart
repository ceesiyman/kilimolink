import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/consultation_model.dart';
import '../service/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'expert_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class MyConsultationsScreen extends StatefulWidget {
  final bool isExpertView;
  
  const MyConsultationsScreen({Key? key, this.isExpertView = false}) : super(key: key);
  
  @override
  _MyConsultationsScreenState createState() => _MyConsultationsScreenState();
}

class _MyConsultationsScreenState extends State<MyConsultationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Consultation>> _consultationsFuture;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  void _loadConsultations() {
    print('Loading consultations - isExpertView: ${widget.isExpertView}');
    if (widget.isExpertView) {
      print('Loading expert consultations');
      _consultationsFuture = _apiService.fetchMyExpertConsultationsFromApi();
    } else {
      print('Loading farmer consultations');
      _consultationsFuture = _apiService.fetchMyConsultationsFromApi();
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MarketScreen()),
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ExpertScreen()),
        (route) => false,
      );
    } else if (index == 3) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CommunityScreen()),
        (route) => false,
      );
    } else if (index == 4) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
        (route) => false,
      );
    }
  }

  void _refreshConsultations() {
    setState(() {
      _loadConsultations();
    });
  }

  Future<void> _acceptConsultation(Consultation consultation) async {
    try {
      // Show dialog to get expert notes
      final expertNotes = await _showExpertNotesDialog();
      if (expertNotes == null) return; // User cancelled

      final result = await _apiService.acceptConsultationFromApi(
        consultation.id,
        expertNotes: expertNotes,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the consultations list
      _refreshConsultations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept consultation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineConsultation(Consultation consultation) async {
    try {
      // Show dialog to get decline reason
      final declineReason = await _showDeclineReasonDialog();
      if (declineReason == null) return; // User cancelled

      final result = await _apiService.declineConsultationFromApi(
        consultation.id,
        declineReason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the consultations list
      _refreshConsultations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline consultation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeConsultation(Consultation consultation) async {
    try {
      final result = await _apiService.completeConsultationFromApi(consultation.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the consultations list
      _refreshConsultations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete consultation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showExpertNotesDialog() async {
    final TextEditingController notesController = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Expert Notes (Optional)'),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            hintText: 'Enter any notes for the farmer...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, notesController.text.trim()),
            child: Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showDeclineReasonDialog() async {
    final TextEditingController reasonController = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline Consultation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for declining this consultation:'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter decline reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please provide a decline reason')),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Decline'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      print('Attempting to call original number: "$phoneNumber"');
      
      // Request phone permission
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone permission is required to make calls'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      // Use the phone number exactly as it comes from the API
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone app. Number: $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error making phone call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    try {
      print('Attempting to send SMS to original number: "$phoneNumber"');
      
      // Request SMS permission
      var status = await Permission.sms.status;
      if (!status.isGranted) {
        status = await Permission.sms.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SMS permission is required to send messages'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      // Use the phone number exactly as it comes from the API
      final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch SMS app. Number: $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error sending SMS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending SMS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isExpertView ? 'My Expert Consultations' : 'My Consultations'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshConsultations,
          ),
        ],
      ),
      body: FutureBuilder<List<Consultation>>(
        future: _consultationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error in MyConsultationsScreen: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading consultations',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshConsultations,
                    child: Text('Try Again'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No consultations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final consultations = snapshot.data!;
          return ListView.builder(
            itemCount: consultations.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final consultation = consultations[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.isExpertView 
                                ? 'Consultation with ${consultation.farmer?.name ?? 'Unknown Farmer'}'
                                : 'Consultation with ${consultation.expert.name}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: consultation.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              consultation.status.toUpperCase(),
                              style: TextStyle(
                                color: consultation.statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${consultation.formattedDate} at ${consultation.formattedTime}',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        consultation.description,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (consultation.expertNotes != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'Expert Notes: ${consultation.expertNotes}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (consultation.declineReason != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'Decline Reason: ${consultation.declineReason}',
                          style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      
                      // Action buttons for experts
                      if (widget.isExpertView) ...[
                        SizedBox(height: 16),
                        _buildExpertActionButtons(consultation),
                      ],
                      
                      // Action buttons for farmers
                      if (!widget.isExpertView) ...[
                        SizedBox(height: 16),
                        _buildFarmerActionButtons(consultation),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildExpertActionButtons(Consultation consultation) {
    switch (consultation.status.toLowerCase()) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _acceptConsultation(consultation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Accept'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _declineConsultation(consultation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Decline'),
              ),
            ),
          ],
        );
      
      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _completeConsultation(consultation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Mark as Completed'),
              ),
            ),
          ],
        );
      
      case 'completed':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Consultation Completed',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      
      case 'declined':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Consultation Declined',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildFarmerActionButtons(Consultation consultation) {
    switch (consultation.status.toLowerCase()) {
      case 'accepted':
        // Get expert phone number from the consultation
        final expertPhoneNumber = consultation.expert.phoneNumber ?? '';
        
        print('Expert phone number: "$expertPhoneNumber"');
        print('Expert data: ${consultation.expert.toJson()}');
        
        if (expertPhoneNumber.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Expert:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(expertPhoneNumber),
                      icon: Icon(Icons.call, color: Colors.white),
                      label: Text('Call Expert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendSMS(expertPhoneNumber),
                      icon: Icon(Icons.message, color: Colors.white),
                      label: Text('Send SMS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Expert phone number not available',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      
      case 'completed':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Consultation Completed',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      
      case 'declined':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Consultation Declined',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      
      default:
        return SizedBox.shrink();
    }
  }
} 