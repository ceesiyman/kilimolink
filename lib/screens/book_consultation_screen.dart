import 'package:flutter/material.dart';
import '../model/expert_model.dart';
import '../service/api_service.dart';

class BookConsultationScreen extends StatefulWidget {
  @override
  _BookConsultationScreenState createState() => _BookConsultationScreenState();
}

class _BookConsultationScreenState extends State<BookConsultationScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Expert>> expertsFuture;
  Expert? selectedExpert;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  void _loadExperts() {
    setState(() {
      expertsFuture = apiService.fetchExpertsFromApi();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          picked.hour,
          picked.minute,
        );
        selectedTime = picked;
      });
    }
  }

  void _bookConsultation() async {
    if (selectedExpert == null || selectedDate == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final consultation = await apiService.bookConsultationFromApi(
        expertId: selectedExpert!.id,
        consultationDate: selectedDate!,
        description: _descriptionController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consultation booked successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book a Consultation'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select an Expert',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  FutureBuilder<List<Expert>>(
                    future: expertsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        final experts = snapshot.data!;
                        return DropdownButton<Expert>(
                          isExpanded: true,
                          value: selectedExpert,
                          hint: Text('Choose an expert'),
                          items: experts.map((expert) {
                            return DropdownMenuItem<Expert>(
                              value: expert,
                              child: Text(expert.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedExpert = value;
                            });
                          },
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Select Date and Time',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () => _selectDate(context),
                          child: Text(
                            selectedDate == null
                                ? 'Select Date'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: selectedDate == null ? null : () => _selectTime(context),
                          child: Text(
                            selectedTime == null
                                ? 'Select Time'
                                : selectedTime!.format(context),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Describe your consultation needs',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: _bookConsultation,
                    child: Text(
                      'Book Consultation',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}