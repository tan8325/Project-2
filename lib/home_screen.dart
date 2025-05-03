import 'package:flutter/material.dart';
import 'package:weather/weather.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController cityController = TextEditingController();
  WeatherFactory wf = WeatherFactory(
    "3cf8c02c50784904939cbd726aa14c35",
  ); // API key
  Weather? currentWeather;
  String cityName = 'Atlanta'; // initial city name

  String get currentTemp =>
      currentWeather?.temperature?.fahrenheit?.toStringAsFixed(1) ?? '--';
  String get currentCondition => currentWeather?.weatherDescription ?? '--';

  // placeholders for the UI
  final List<Map<String, dynamic>> _weatherData = [
    {'time': 'Now', 'temp': '--', 'icon': Icons.wb_sunny_rounded},
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
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData([String city = "Atlanta"]) async {
    try {
      final weather = await wf.currentWeatherByCityName(city);
      List<Weather> forecast = await wf.fiveDayForecastByCityName(cityName);

      Map<String, Map<String, dynamic>> dailyData = {};
      for (var day in forecast) {
        if (day.date == null) continue;

        String dayName = _getDayName(day.date!.weekday);
        double? tempMax = day.tempMax?.fahrenheit;
        double? tempMin = day.tempMin?.fahrenheit;

        if (tempMax == null || tempMin == null)
          continue; // skips record if temps missing

        if (!dailyData.containsKey(dayName)) {
          // Creates new entry
          dailyData[dayName] = {
            'high': tempMax,
            'low': tempMin,
            'icon': getWeatherIcon(day.weatherMain),
          };
        } else {
          // Gets the estimated max and min temperature for the day
          dailyData[dayName]!['high'] =
              (dailyData[dayName]!['high'] as double).compareTo(tempMax) < 0
                  ? tempMax
                  : dailyData[dayName]!['high'];
          dailyData[dayName]!['low'] =
              (dailyData[dayName]!['low'] as double).compareTo(tempMin) > 0
                  ? tempMin
                  : dailyData[dayName]!['low'];
        }
      }

      List<Map<String, dynamic>> hourlyData = [];
      int hoursFilled = 0;
      for (var hour in forecast) {
        if (hour.date == null) continue;
        if (hoursFilled >= 5) break;

        // Get the hour in 12-hour format
        int hourNum = hour.date!.hour;
        String period = hourNum < 12 ? 'AM' : 'PM';
        int hour12 = hourNum % 12 == 0 ? 12 : hourNum % 12;
        String time = '$hour12$period';

        double? temp = hour.temperature?.fahrenheit;
        if (temp == null) continue;

        // Add the hour data to the list
        hourlyData.add({
          'time': time,
          'temp': temp.toStringAsFixed(1),
          'icon': getWeatherIcon(hour.weatherMain),
        });
        hoursFilled++;
      }

      setState(() {
        cityName = city;
        currentWeather = weather;

        _dailyForecast.clear();
        int count = 0;
        dailyData.forEach((day, data) {
          if (count >= 7) return;

          _dailyForecast.add({
            'day': day,
            'high': (data['high'] as double).toStringAsFixed(1),
            'low': (data['low'] as double).toStringAsFixed(1),
            'icon': data['icon'],
          });
          count++;
        });
        _weatherData.clear();
        _weatherData.add({
          'time': 'Now',
          'temp': currentTemp,
          'icon': getWeatherIcon(currentWeather?.weatherMain),
        });
        _weatherData.addAll(hourlyData);
      });
    } catch (e) {}
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  // Get weather icon
  Map<String, dynamic> getWeatherIcon(String? condition) {
    if (condition == null) return {'icon': Icons.cloud, 'color': Colors.white};

    condition = condition.toLowerCase();
    if (condition.contains('rain')) {
      return {'icon': Icons.cloud, 'color': Colors.grey};
    } else if (condition.contains('cloud')) {
      return {'icon': Icons.cloud, 'color': Colors.white};
    } else if (condition.contains('clear')) {
      return {'icon': Icons.sunny, 'color': Colors.yellow};
    } else if (condition.contains('sunny')) {
      return {'icon': Icons.sunny, 'color': Colors.yellow};
    } else if (condition.contains('snow')) {
      return {'icon': Icons.snowing, 'color': Colors.white};
    } else if (condition.contains('fog')) {
      return {'icon': Icons.foggy, 'color': Colors.grey};
    } else if (condition.contains('mist')) {
      return {'icon': Icons.foggy, 'color': Colors.grey};
    } else {
      return {'icon': Icons.cloud, 'color': Colors.white};
    }
  }

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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityController,
                      decoration: InputDecoration(
                        hintText: 'Search for a city',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search),
                    iconSize: 30,
                    onPressed: () {
                      String city = cityController.text.trim();
                      if (city.isNotEmpty) {
                        fetchWeatherData(city);
                        cityController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),
            Text(
              cityName,
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
                      Builder(
                        builder: (_) {
                          final weatherIcon = getWeatherIcon(
                            currentWeather?.weatherMain,
                          );
                          return Icon(
                            weatherIcon['icon'],
                            size: 100,
                            color: weatherIcon['color'],
                          );
                        },
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
                        '${currentTemp}°',
                        style: TextStyle(
                          fontSize: 75,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentCondition,
                        style: TextStyle(
                          fontSize: 25,
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
                      final weatherIcon = data['icon']['icon'];
                      final iconColor = data['icon']['color'];
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(weatherIcon, color: iconColor),
                            Text(
                              '${data['temp']}°',
                              style: TextStyle(
                                fontSize: 20,
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
                  final weatherIcon = data['icon']['icon'];
                  final iconColor = data['icon']['color'];

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
                            child: Icon(weatherIcon, color: iconColor),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Text(
                              '${data['low']}°/${data['high']}°',
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
