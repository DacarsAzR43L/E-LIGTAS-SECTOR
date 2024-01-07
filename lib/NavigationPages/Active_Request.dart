import 'package:flutter/material.dart';

class ActiveRequestCard {
  final String name;
  final String emergencyType;
  final String location;

  ActiveRequestCard({
    required this.name,
    required this.emergencyType,
    required this.location,
  });
}

class ActiveRequestScreen extends StatelessWidget {
  final List<ActiveRequestCard> activeRequestList = [
    ActiveRequestCard(name: 'John Doe', emergencyType: 'Medical', location: '123 Main St'),
    ActiveRequestCard(name: 'Jane Smith', emergencyType: 'Fire', location: '456 Oak Ave'),
    // Add more active request cards as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Reports'),
      ),
      body: ListView.builder(
        itemCount: activeRequestList.length,
        itemBuilder: (context, index) {
          return _buildActiveRequestCard(activeRequestList[index]);
        },
      ),
    );
  }

  Widget _buildActiveRequestCard(ActiveRequestCard activeRequestCard) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        leading: CircleAvatar(
          // Add logic to load or generate the circle avatar image
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(activeRequestCard.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Type: ${activeRequestCard.emergencyType}'),
            Text('Location: ${activeRequestCard.location}'),
          ],
        ),
        trailing: Icon(
          Icons.check,
          color: Colors.green,
          size: 30.0,
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ActiveRequestScreen(),
  ));
}
