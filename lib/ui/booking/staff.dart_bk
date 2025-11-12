import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:salonapp/api/api_manager.dart';
import 'package:salonapp/model/staff.dart';
import 'package:salonapp/services/helper.dart';


class StaffPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staffs'),
      ),
      body: FutureBuilder<List<Staff>>(
        future: apiManager.ListStaff(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No staff found'));
          } else {
            final staffList = snapshot.data!;
            return Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: staffList.length,
                itemBuilder: (BuildContext context, int index) {
                  Staff staff = staffList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 30,
                          //backgroundImage: MemoryImage(base64Decode(staff.photo.split(',').last)),
                          backgroundImage: getImage(staff.photo),
                          child: getImage(staff.photo) == null
                              ? Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          staff.fullname,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Position: ${staff.position}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Handle tap on staff member
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
