import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _weatherData = [
    {'time': 'Now', 'temp': 72, 'icon': Icons.wb_sunny_rounded},
    {'time': '1 PM', 'temp': 75, 'icon': Icons.wb_sunny_rounded},
    {'time': '2 PM', 'temp': 78, 'icon': Icons.wb_sunny_rounded},
    {'time': '3 PM', 'temp': 80, 'icon': Icons.wb_sunny_rounded},
    {'time': '4 PM', 'temp': 82, 'icon': Icons.wb_sunny_rounded},
  ];
  final List<Map<String, dynamic>> _dailyForecast = [
    {'day': 'Tuesday', 'high': 70, 'low': 59, 'icon': Icons.wb_sunny_rounded},
    {'day': 'Wednesday', 'high': 72, 'low': 60, 'icon': Icons.wb_sunny_rounded},
    {'day': 'Thursday', 'high': 74, 'low': 62, 'icon': Icons.wb_sunny_rounded},
    {'day': 'Friday', 'high': 76, 'low': 64, 'icon': Icons.wb_sunny_rounded},
    {'day': 'Saturday', 'high': 78, 'low': 66, 'icon': Icons.wb_sunny_rounded},
    {'day': 'Sunday', 'high': 80, 'low': 68, 'icon': Icons.wb_sunny_rounded},
    {'day': 'Monday', 'high': 82, 'low': 70, 'icon': Icons.wb_sunny_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 207, 234, 251),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for a city',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Atlanta',
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.5),
                        ),
                      ),
                      Icon(
                        Icons.wb_sunny_rounded,
                        size: 100,
                        color: Colors.yellow,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '72°',
                        style: TextStyle(
                          fontSize: 75,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sunny',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              height: 120,
              decoration: (BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              )),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double itemWidth =
                      MediaQuery.of(context).size.width / _weatherData.length;

                  return ListView.builder(
                    itemCount: _weatherData.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final data = _weatherData[index];
                      return Container(
                        width: itemWidth,
                        decoration: BoxDecoration(
                          color:
                              index == 0
                                  ? const Color.fromARGB(255, 59, 152, 227)
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              data['time'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(data['icon'], size: 30, color: Colors.yellow),
                            Text(
                              '${data['temp']}°',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              '7-Day Forecast',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            Container(
              margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
              height: 275,
              decoration: (BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              )),
              child: ListView.builder(
                itemCount: _dailyForecast.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  final data = _dailyForecast[index];
                  return Container(
                    width: 100,
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(
                              textAlign: TextAlign.left,
                              data['day'],
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Icon(
                              data['icon'],
                              size: 30,
                              color: Colors.yellow,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Text(
                              '${data['high']}°/${data['low']}°',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
