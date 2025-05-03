import 'package:flutter/material.dart';
import 'package:weather/weather.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController cityController = TextEditingController();
  WeatherFactory wf = WeatherFactory("3cf8c02c50784904939cbd726aa14c35");
  Weather? currentWeather;
  String cityName = 'Atlanta';
  final List<Map<String, dynamic>> _weatherData = [];
  final List<Map<String, dynamic>> _dailyForecast = [];

  String get currentTemp =>
      currentWeather?.temperature?.fahrenheit?.toStringAsFixed(0) ?? '--';
  String get currentCondition => currentWeather?.weatherDescription ?? '--';

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData([String city = "Atlanta"]) async {
    try {
      final weather = await wf.currentWeatherByCityName(city);
      List<Weather> forecast = await wf.fiveDayForecastByCityName(city);

      Map<String, Map<String, dynamic>> dailyData = {};
      for (var day in forecast) {
        if (day.date == null) continue;
        String dayName = _getDayName(day.date!.weekday);
        double? tempMax = day.tempMax?.fahrenheit;
        double? tempMin = day.tempMin?.fahrenheit;
        if (tempMax == null || tempMin == null) continue;

        dailyData.putIfAbsent(dayName, () => {
              'high': tempMax,
              'low': tempMin,
              'icon': getWeatherIcon(day.weatherMain),
            });

        dailyData.update(dayName, (prev) {
          return {
            'high': tempMax > prev['high'] ? tempMax : prev['high'],
            'low': tempMin < prev['low'] ? tempMin : prev['low'],
            'icon': prev['icon'],
          };
        });
      }

      List<Map<String, dynamic>> hourlyData = [];
      DateTime now = DateTime.now();
      int hoursFilled = 0;

      for (var hour in forecast) {
        if (hour.date == null) continue;
        if (hour.date!.isBefore(now)) continue;
        if (hoursFilled >= 7) break;

        int hourNum = hour.date!.hour;
        String period = hourNum < 12 ? 'AM' : 'PM';
        int hour12 = hourNum % 12 == 0 ? 12 : hourNum % 12;
        String time = hoursFilled == 0 ? 'Now' : '$hour12 $period';
        double? temp = hour.temperature?.fahrenheit;
        if (temp == null) continue;

        hourlyData.add({
          'time': time,
          'temp': temp.toStringAsFixed(0),
          'icon': hoursFilled == 0
              ? getWeatherIcon(weather.weatherMain)['icon']
              : getWeatherIcon(hour.weatherMain)['icon'],
        });

        hoursFilled++;
      }

      setState(() {
        cityName = city;
        currentWeather = weather;
        _weatherData
          ..clear()
          ..addAll(hourlyData);
        _dailyForecast.clear();
        int count = 0;
        dailyData.forEach((day, data) {
          if (count < 7) {
            _dailyForecast.add({
              'day': day,
              'high': (data['high'] as double).toStringAsFixed(0),
              'low': (data['low'] as double).toStringAsFixed(0),
              'icon': data['icon']['icon'],
            });
            count++;
          }
        });
      });
    } catch (e) {
      print("Error fetching weather: $e");
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return days[weekday - 1];
  }

  Map<String, dynamic> getWeatherIcon(String? condition) {
    if (condition == null) {
      return {'icon': Icons.cloud, 'color': Colors.grey[700]};
    }

    condition = condition.toLowerCase();
    if (condition.contains('rain')) {
      return {'icon': Icons.cloudy_snowing, 'color': Colors.blueGrey};
    } else if (condition.contains('cloud')) {
      return {'icon': Icons.cloud_rounded, 'color': Colors.grey[700]};
    } else if (condition.contains('clear') || condition.contains('sunny')) {
      return {'icon': Icons.wb_sunny_rounded, 'color': Colors.amber};
    } else if (condition.contains('snow')) {
      return {'icon': Icons.ac_unit, 'color': Colors.lightBlue};
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return {'icon': Icons.foggy, 'color': Colors.grey};
    } else {
      return {'icon': Icons.cloud, 'color': Colors.grey[700]};
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        decoration: InputDecoration(
                          hintText: 'Search for a city',
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[300],
                          hintStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search,
                          size: 30,
                          color: isDark ? Colors.white : Colors.black),
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
              const SizedBox(height: 20),
              Text(
                cityName,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Icon(
                    getWeatherIcon(currentWeather?.weatherMain)['icon'],
                    size: 100,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$currentTemp°',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    currentCondition,
                    style: TextStyle(
                      fontSize: 20,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildHourlyForecast(isDark),
              const SizedBox(height: 16),
              _buildDailyForecast(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _weatherData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _weatherData[index];
          final bool isNow = index == 0;
          return _buildHourlyItem(item, isNow, isDark);
        },
      ),
    );
  }

  Widget _buildHourlyItem(Map<String, dynamic> item, bool isNow, bool isDark) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isNow ? Colors.grey[500] : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(item['time'],
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
          Icon(item['icon'],
              size: 22, color: isDark ? Colors.white : Colors.black),
          Text('${item['temp']}°',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildDailyForecast(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(_dailyForecast.length, (index) {
          final item = _dailyForecast[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    item['day'],
                    style: TextStyle(
                      fontSize: 20,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  item['icon'],
                  size: 28,
                  color: isDark ? Colors.white : Colors.grey[700],
                ),
                const SizedBox(width: 16),
                Text(
                  '${item['high']}°  ${item['low']}°',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
