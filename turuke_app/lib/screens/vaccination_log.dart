import 'package:flutter/material.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';

class VaccinationLogScreen extends StatefulWidget {
  static const String routeName = '/vaccination-log';

  const VaccinationLogScreen({super.key});

  @override
  State<VaccinationLogScreen> createState() => _VaccinationLogScreenState();
}

class _VaccinationLogScreenState extends State<VaccinationLogScreen> {
  List<Map<String, dynamic>> _vaccinations = [];
  List<Map<String, dynamic>> _flocks = [
    {'id': 1, 'breed': 'Isa Brown'},
    {'id': 2, 'breed': 'White Leghorn'},
    {'id': 3, 'breed': 'Rhode Island Red'},
  ];

  Future<void> _addVaccination({
    required int flockId,
    required String vaccineName,
    required DateTime vaccinationDate,
    String? notes,
  }) async {
    final data = {
      'flock_id': flockId,
      'vaccine_name': vaccineName,
      'vaccination_date': vaccinationDate.toIso8601String().substring(0, 10),
      if (notes != null) 'notes': notes,
    };
    try {} catch (e) {}
  }

  void _showAddVaccinationDialog() {
    final _formKey = GlobalKey<FormState>();
    int? _flockId;
    String _vaccineName = '';
    DateTime _vaccinationDate = DateTime.now();
    String _notes = '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Vaccination'),
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
                      decoration: InputDecoration(labelText: 'Vaccine Name'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => _vaccineName = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Vaccination Date',
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: _vaccinationDate.toIso8601String().substring(
                          0,
                          10,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _vaccinationDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) _vaccinationDate = picked;
                      },
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
                    _addVaccination(
                      flockId: _flockId!,
                      vaccineName: _vaccineName,
                      vaccinationDate: _vaccinationDate,
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
      appBar: AppBar(title: Text('Vaccination Log')),
      drawer: AppNavigationDrawer(
        selectedRoute: VaccinationLogScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: _vaccinations.length,
        itemBuilder: (context, index) {
          final vaccination = _vaccinations[index];
          return ListTile(
            leading: Icon(Icons.vaccines),
            title: Text(vaccination['vaccine_name']),
            subtitle: Text(
              'Flock: ${vaccination['flock_id']} | Date: ${vaccination['vaccination_date']}',
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVaccinationDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
