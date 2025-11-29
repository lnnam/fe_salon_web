import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:salonappweb/model/staff.dart';
import 'package:salonappweb/services/helper.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'package:salonappweb/ui/booking/service.dart';

class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Stylist'),
      ),
      body: FutureBuilder<List<Staff>>(
        future: apiManager.ListStaff(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No staff found'));
          } else {
            final staffList = snapshot.data!;
            return Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: staffList.length,
                itemBuilder: (BuildContext context, int index) {
                  Staff staff = staffList[index];
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
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: getImage(staff.photo),
                          child: getImage(staff.photo) == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          staff.fullname,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          final bookingProvider = Provider.of<BookingProvider>(
                              context,
                              listen: false);
                          final isEditMode = bookingProvider.onbooking.editMode;

                          // Set staff in provider
                          bookingProvider.setStaff(staff.toJson());
                          print('✓ Staff selected: ${staff.fullname}');

                          if (isEditMode) {
                            // Editing mode: return to Summary page with updated staff
                            Navigator.pop(context);
                          } else {
                            // New booking mode: go to Service selection
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ServicePage()),
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
