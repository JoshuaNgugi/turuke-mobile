import 'package:flutter/material.dart';
import 'package:turuke_app/screens/navigation_drawer.dart';

class EggCollectionScreen extends StatefulWidget {
  static const String routeName = '/egg-collection';
  const EggCollectionScreen({super.key});

  @override
  State<EggCollectionScreen> createState() => _EggCollectionScreenState();
}

class _EggCollectionScreenState extends State<EggCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _flockId;
  DateTime _date = DateTime.now();
  int _wholeEggs = 0, _brokenEggs = 0;
  List<Map<String, dynamic>> _flocks = [
    {'id': 1, 'breed': 'Isa Brown'},
    {'id': 2, 'breed': 'White Leghorn'},
    {'id': 3, 'breed': 'Rhode Island Red'},
  ];

  Future<void> _save() async {}

  void _onRouteSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Egg Collection')),
      drawer: AppNavigationDrawer(
        selectedRoute: EggCollectionScreen.routeName,
        onRouteSelected: _onRouteSelected,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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

                onChanged: (value) => setState(() => _flockId = value),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Date'),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                controller: TextEditingController(
                  text: _date.toIso8601String().substring(0, 10),
                ),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Whole Eggs'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged:
                    (value) =>
                        setState(() => _wholeEggs = int.tryParse(value) ?? 0),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Broken Eggs'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged:
                    (value) =>
                        setState(() => _brokenEggs = int.tryParse(value) ?? 0),
              ),
              SizedBox(height: 16),
              Text(
                'Total Eggs: ${_wholeEggs + _brokenEggs}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
