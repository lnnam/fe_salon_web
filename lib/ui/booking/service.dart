import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salonappweb/api/api_manager.dart';
import 'package:salonappweb/model/service.dart';
import 'package:salonappweb/provider/booking.provider.dart';
import 'staff.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Treatments'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<Service>>(
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
              return Center(
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        children: List.generate(
                          serviceList.length,
                          (index) {
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
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey[300],
                                    child: const Icon(Icons.spa,
                                        size: 24, color: Colors.black54),
                                  ),
                                  title: Text(
                                    service.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 18),
                                  onTap: () {
                                    final bookingProvider =
                                        Provider.of<BookingProvider>(context,
                                            listen: false);
                                    final isEditMode =
                                        bookingProvider.onbooking.editMode;

                                    print('========== SERVICE PAGE ==========');
                                    print(
                                        '🏄 EditMode at Service: $isEditMode');
                                    print(
                                        '📝 Service selected: ${service.name}');
                                    print('==================================');

                                    // Set service in provider
                                    bookingProvider
                                        .setService(service.toJson());

                                    if (isEditMode) {
                                      // Editing mode: return to Summary page with updated service
                                      print(
                                          '📝 Popping back to Summary (editMode=true)');
                                      Navigator.pop(context);
                                    } else {
                                      // New booking mode: go to Staff selection
                                      print(
                                          '📝 Going to Staff (editMode=false)');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const StaffPage()),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
