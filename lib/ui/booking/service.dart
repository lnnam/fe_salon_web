import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salonapp/api/api_manager.dart';
import 'package:salonapp/model/service.dart';
import 'package:salonapp/services/helper.dart';
import 'package:salonapp/provider/booking.provider.dart';
import 'package:salonapp/ui/booking/staff.dart';
import 'calendar.dart'; // Import SchedulePage
import 'summary.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Treatments'),
      ),
      body: FutureBuilder<List<Service>>(
        future: apiManager.ListServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No services found'));
          } else {
            final serviceList = snapshot.data!;
            return Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: serviceList.length,
                itemBuilder: (BuildContext context, int index) {
                  Service service = serviceList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Text(
                          service.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          // Handle tap on service

                          final bookingProvider = Provider.of<BookingProvider>(
                              context,
                              listen: false);
                          final isEditMode =
                              bookingProvider.onbooking?.editMode ?? false;

                          // Set staff
                          bookingProvider.setService(service.toJson());

                          if (isEditMode) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SummaryPage()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const StaffPage()),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
