import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salonapp/api/api_manager.dart';
import 'package:salonapp/model/customer.dart';
import 'package:salonapp/provider/booking.provider.dart';
import 'package:salonapp/services/helper.dart';
import 'Summary.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailPhoneController = TextEditingController();
  List<Customer> _customerList = [];
  List<Customer> _filteredCustomerList = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCustomers);
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailPhoneController.dispose();
    super.dispose();
  }

  void _fetchCustomers() async {
    try {
      List<Customer> customers = await apiManager.ListCustomer();
      setState(() {
        _customerList = customers;
        _filteredCustomerList = customers;
      });
    } catch (error) {
      print('Error fetching customers: $error');
    }
  }

  void _filterCustomers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomerList = _customerList.where((customer) {
        return customer.fullname.toLowerCase().contains(query) ||
            customer.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showCreateCustomerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search by Email or Phone'),
          content: TextField(
            controller: _emailPhoneController,
            decoration: const InputDecoration(
              labelText: 'Email or Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _emailPhoneController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_emailPhoneController.text.isNotEmpty) {
                  print('Search: ${_emailPhoneController.text}');
                  Navigator.pop(context);
                  _emailPhoneController.clear();
                  // You can add API call here to search or create customer
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter email or phone')),
                  );
                }
              },
              child: const Text('GO'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _showCreateCustomerDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Customer'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Customers',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _buildCustomerList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return _filteredCustomerList.isEmpty
        ? const Center(child: Text('No customers found'))
        : ListView.builder(
            itemCount: _filteredCustomerList.length,
            itemBuilder: (BuildContext context, int index) {
              Customer customer = _filteredCustomerList[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: getImage(customer.photo),
                      child: getImage(customer.photo) == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      customer.fullname,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Email: ${customer.email}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Set the selected customer when a customer name is clicked
                      Provider.of<BookingProvider>(context, listen: false)
                          .setCustomerDetails(customer.toJson());
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SummaryPage(), // Navigate to SchedulePage
                        ),
                      );
                      // Print the customer details to the console
                      // Navigate to the next page if needed
                    },
                  ),
                ),
              );
            },
          );
  }
}
