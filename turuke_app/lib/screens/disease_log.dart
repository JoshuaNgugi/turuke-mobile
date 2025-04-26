import 'package:flutter/material.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';

class DiseaseLogScreen extends StatefulWidget {
  static const String routeName = '/disease-log';
  const DiseaseLogScreen({super.key});

  @override
  State<DiseaseLogScreen> createState() => _DiseaseLogScreenState();
}

class _DiseaseLogScreenState extends State<DiseaseLogScreen> {
  List<Map<String, dynamic>> _diseases = [];
  List<Map<String, dynamic>> _flocks = [
    {'id': 1, 'breed': 'Isa Brown'},
    {'id': 2, 'breed': 'White Leghorn'},
    {'id': 3, 'breed': 'Rhode Island Red'},
  ];

  Future<void> _addDisease({
    required int flockId,
    required String diseaseName,
    required DateTime diagnosisDate,
    required int affectedCount,
    String? notes,
  }) async {
    final data = {
      'flock_id': flockId,
      'disease_name': diseaseName,
      'diagnosis_date': diagnosisDate.toIso8601String().substring(0, 10),
      'affected_count': affectedCount,
      if (notes != null) 'notes': notes,
    };
    try {} catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved offline, will sync later')));
    }
  }

  void _showAddDiseaseDialog() {
    final _formKey = GlobalKey<FormState>();
    int? _flockId;
    String _diseaseName = '';
    DateTime _diagnosisDate = DateTime.now();
    int _affectedCount = 0;
    String _notes = '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Disease'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      hint: Text('Select Flock'),
                      value: _flockId,
                      items:
                          _flocks
                              .map<DropdownMenuItem<int>>(
                                (f) => DropdownMenuItem<int>(
                                  value: f['id'] as int,
                                  child: Text(f['breed']),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => _flockId = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Disease Name'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => _diseaseName = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Diagnosis Date'),
                      readOnly: true,
                      controller: TextEditingController(
                        text: _diagnosisDate.toIso8601String().substring(0, 10),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _diagnosisDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) _diagnosisDate = picked;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Affected Count'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged:
                          (value) => _affectedCount = int.tryParse(value) ?? 0,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                      ),
                      onChanged: (value) => _notes = value,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _flockId != null) {
                    _addDisease(
                      flockId: _flockId!,
                      diseaseName: _diseaseName,
                      diagnosisDate: _diagnosisDate,
                      affectedCount: _affectedCount,
                      notes: _notes.isEmpty ? null : _notes,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Disease Log')),
      drawer: AppNavigationDrawer(
        selectedRoute: DiseaseLogScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: _diseases.length,
        itemBuilder: (context, index) {
          final disease = _diseases[index];
          return ListTile(
            leading: Icon(Icons.sick),
            title: Text(disease['disease_name']),
            subtitle: Text(
              'Flock: ${disease['flock_id']} | Affected: ${disease['affected_count']}',
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDiseaseDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
