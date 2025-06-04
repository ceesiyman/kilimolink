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
  final bool useRealApi = false;
  String? selectedExpert;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    expertsFuture = useRealApi ? apiService.fetchExpertsFromApi() : apiService.fetchExperts();
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
        selectedTime = picked;
      });
    }
  }

  void _bookConsultation() async {
    if (selectedExpert == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an expert, date, and time')),
      );
      return;
    }

    try {
      final success = useRealApi
          ? await apiService.bookConsultationFromApi(
              selectedExpert!,
              selectedDate!.toIso8601String(),
              selectedTime!.format(context),
            )
          : await apiService.bookConsultation(
              selectedExpert!,
              selectedDate!.toIso8601String(),
              selectedTime!.format(context),
            );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Consultation booked successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking consultation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book a Consultation'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
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
                  return DropdownButton<String>(
                    isExpanded: true,
                    value: selectedExpert,
                    hint: Text('Choose an expert'),
                    items: experts.map((expert) {
                      return DropdownMenuItem<String>(
                        value: expert.name,
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
                    onPressed: () => _selectTime(context),
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