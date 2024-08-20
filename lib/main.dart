import 'package:basic_crud/toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(title: 'Basic CRUD'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String dropdownvalue = "Create";
  var items = [
    "Create",
    "Read",
    "Update",
    "Delete",
  ];

  final CollectionReference collectionRef = FirebaseFirestore.instance.collection('employees');

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  void clearInputs() {
    _idController.clear();
    _nameController.clear();
  }

  Future<void> _createItem({required int id, required String name}) async {
    await collectionRef.add({'id': id, 'name': name});
    clearInputs();
    ToastMessages.success(context, text: "Employee Added Successfully");
  }

  Future<List<Map<String, dynamic>>> _readItems([int? id]) async {
    QuerySnapshot querySnapshot;
    if (id != null) {
      querySnapshot = await collectionRef.where('id', isEqualTo: id).get();
    } else {
      querySnapshot = await collectionRef.get();
    }
    clearInputs();
    
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> _updateItem(int id, String newName) async {
    QuerySnapshot querySnapshot = await collectionRef.where('id', isEqualTo: id).get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
      await collectionRef.doc(documentSnapshot.id).update({'name': newName});
      clearInputs();
      ToastMessages.success(context, text: "Employee Updated Successfully");
    } else {
      ToastMessages.error(context, text: "Employee with $id not found");
    }
  }

  Future<void> _deleteItem(int id) async {
    QuerySnapshot querySnapshot = await collectionRef.where('id', isEqualTo: id).get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
      await collectionRef.doc(documentSnapshot.id).delete();
      clearInputs();
      ToastMessages.success(context, text: "Employee Deleted Successfully");
    } else {
      ToastMessages.error(context, text: "Employee with $id not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Selected Operation: $dropdownvalue'),
            if (dropdownvalue == "Create") _buildCreateForm(),
            if (dropdownvalue == "Read") _buildReadForm(),
            if (dropdownvalue == "Update") _buildUpdateForm(),
            if (dropdownvalue == "Delete") _buildDeleteForm(),
          ],
        ),
      ),
      floatingActionButton: DropdownButton(
        value: dropdownvalue,
        icon: const Icon(Icons.keyboard_arrow_down),
        items: items.map((String item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (String? newValue) {
          clearInputs();
          setState(() {
            dropdownvalue = newValue!;
            clearInputs();
          });
        },
      ),
    );
  }

  Widget _buildCreateForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: 'Enter Employee ID',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Enter Employee Name',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final int id = int.parse(_idController.text.trim());
            final String name = _nameController.text.trim();
            if (id > 0 && name != "") {
              _createItem(id: id, name: name);
            } else {
              ToastMessages.error(context, text: "Id and name can not be empty");
            }
          },
          child: const Text("Create"),
        ),
      ],
    );
  }

  Widget _buildReadForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: 'Enter Employee ID (Leave empty to read all)',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            int? id = _idController.text.trim().isNotEmpty
                ? int.tryParse(_idController.text.trim())
                : null;
            List<Map<String, dynamic>> employees = await _readItems(id);
            employees.isEmpty
                ? ToastMessages.error(context, text: "No Employee Found with $id")
                : showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Employees'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: employees
                              .map((item) => Text('ID: ${item['id']} - Name: ${item['name']}'))
                              .toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          )
                        ],
                      );
                    },
                  );
          },
          child: const Text("Read"),
        ),
      ],
    );
  }

  Widget _buildUpdateForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: 'Enter Employee ID to Update',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Enter New Employee Name',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final int id = int.parse(_idController.text.trim());
            final String newName = _nameController.text.trim();
            _updateItem(id, newName);
          },
          child: const Text("Update"),
        ),
      ],
    );
  }

  Widget _buildDeleteForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: 'Enter Employee ID to Delete',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final int id = int.parse(_idController.text.trim());
            _deleteItem(id);
          },
          child: const Text("Delete"),
        ),
      ],
    );
  }
}
