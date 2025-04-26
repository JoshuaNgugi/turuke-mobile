import 'package:flutter/material.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';

class FlockManagementScreen extends StatefulWidget {
  static const String routeName = '/flock-management';

  const FlockManagementScreen({super.key});

  @override
  State<FlockManagementScreen> createState() => _FlockManagementScreenState();
}

class _FlockManagementScreenState extends State<FlockManagementScreen> {
  List<Map<String, dynamic>> _flocks = [
    {'id': 1, 'breed': 'Isa Brown'},
    {'id': 2, 'breed': 'White Leghorn'},
    {'id': 3, 'breed': 'Rhode Island Red'},
  ];

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  void _showAddFlockDialog() {
    final _formKey = GlobalKey<FormState>();
    String _breed = '';
    DateTime _arrivalDate = DateTime.now();
    int _initialCount = 0, _ageWeeks = 0;

    Future<void> _addFlock({
      required String breed,
      required DateTime arrivalDate,
      required int initialCount,
      required int ageWeeks,
    }) async {
      final data = {
        'farm_id': 1, // Replace with auth context
        'breed': breed,
        'arrival_date': arrivalDate.toIso8601String().substring(0, 10),
        'initial_count': initialCount,
        'age_weeks': ageWeeks,
        'status': 'active',
      };
      try {
        // TODO
      } catch (e) {
        // TODO
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Flock'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Breed'),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (value) => _breed = value,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Arrival Date'),
                      readOnly: true,
                      controller: TextEditingController(
                        text: _arrivalDate.toIso8601String().substring(0, 10),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _arrivalDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) _arrivalDate = picked;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Initial Count'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged:
                          (value) => _initialCount = int.tryParse(value) ?? 0,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Age (Weeks)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged:
                          (value) => _ageWeeks = int.tryParse(value) ?? 0,
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
                  if (_formKey.currentState!.validate()) {
                    _addFlock(
                      breed: _breed,
                      arrivalDate: _arrivalDate,
                      initialCount: _initialCount,
                      ageWeeks: _ageWeeks,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flock Management')),
      drawer: AppNavigationDrawer(
        selectedRoute: FlockManagementScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: _flocks.length,
        itemBuilder: (context, index) {
          final flock = _flocks[index];
          return ListTile(
            leading: Icon(Icons.pets),
            title: Text(flock['breed']),
            subtitle: Text(
              'Current: ${flock['current_count']} | Status: ${flock['status']}',
            ),
            onTap: () {
              // TODO: Navigate to flock details or edit
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFlockDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
