import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Météo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0C1224),
      ),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String city = "";
  Map<String, dynamic>? weatherData;
  final String apiKey =
      'c77b620170a24242bdd140558243103'; 
  bool isTextFieldVisible = false;

  void fetchWeather() async {
    final url = Uri.parse(
        'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$city&days=7&aqi=yes&alerts=yes&lang=fr');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Décodage de la réponse en UTF-8
      final decodedResponse = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        weatherData = decodedResponse;
      });
    } else {
      print('Erreur lors de la récupération des données météo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Météo'),
        backgroundColor: Color(0xFF0C1224),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              if (isTextFieldVisible)
                Column(
                  children: [
                    TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Saisissez une ville...',
                        suffixIcon: IconButton(
                          onPressed: () {
                            if (city.isNotEmpty) {
                              fetchWeather();
                            } else {
                              _showAlert(context);
                            }
                          },
                          icon: Icon(Icons.search),
                        ),
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Color(0xFF1D2340),
                      ),
                      onChanged: (value) {
                        city = value;
                      },
                    ),
                  ],
                ),
              SizedBox(height: 20),
              weatherData != null
                  ? buildWeatherInfo()
                  : Center(
                      child: Text('Entrez une ville pour afficher la météo.',
                          style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
      ),
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              isTextFieldVisible = !isTextFieldVisible;
            });
          },
          backgroundColor: Color(0xFF567DF4),
          child: Icon(isTextFieldVisible ? Icons.close : Icons.search),
        ),
      ),
    );
  }

  void _showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Champ obligatoire'),
          content: Text('Saisissez une ville...'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildWeatherInfo() {
    final location = weatherData!['location'];
    final current = weatherData!['current'];
    final forecast = weatherData!['forecast']['forecastday'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${location['name']}, ${location['country']}',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 10),
        Text(
          'Aujourd\'hui à ${location['localtime']}',
          style: TextStyle(color: Colors.white54),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${current['temp_c']}°C',
                  style: TextStyle(fontSize: 64, color: Colors.white),
                ),
                Text(current['condition']['text'],
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ],
            ),
            Column(
              children: [
                Image.network(
                  'https:${current['condition']['icon']}',
                  width: 60,
                  height: 60,
                ),
                Text('↑: ${forecast[0]['day']['maxtemp_c']}°C',
                    style: TextStyle(color: Colors.white)),
                Text('↓: ${forecast[0]['day']['mintemp_c']}°C',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
        SizedBox(height: 20),
        buildHourlyForecast(forecast[0]),
        SizedBox(height: 15),
        buildWeeklyForecast(forecast),
      ],
    );
  }

  Widget buildHourlyForecast(dynamic dayForecast) {
    List<dynamic> hours = dayForecast['hour'];

    return Container(
      padding: EdgeInsets.only(top: 15, bottom: 15, left: 5),
      decoration: BoxDecoration(
        color: Color(0xFF1D2340),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: hours
              .map<Widget>((hour) {
                return Container(
                  width: 80,
                  child: Column(
                    children: [
                      Text('${hour['time'].split(' ')[1]}',
                          style: TextStyle(color: Colors.white)),
                      SizedBox(height: 7.5),
                      Image.network(
                        'https:${hour['condition']['icon']}',
                        width: 40,
                        height: 40,
                      ),
                      SizedBox(height: 3),
                      Text('${hour['temp_c']}°C',
                          style: TextStyle(color: Colors.white)),
                      SizedBox(height: 3),
                      Text('${hour['chance_of_rain']}%',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              })
              .toList()
              .map((widget) {
                return Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: widget,
                );
              })
              .toList(),
        ),
      ),
    );
  }

  Widget buildWeeklyForecast(List<dynamic> forecast) {
    List<String> joursSemaine = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

    return Column(
      children: forecast.map<Widget>((day) {
        DateTime date = DateTime.parse(day['date']);
        String jourSemaine = joursSemaine[date.weekday % 7];
        String formattedDate = DateFormat('dd/MM/yyyy').format(date); 

        return Container(
          padding: EdgeInsets.all(15),
          margin: EdgeInsets.only(bottom: 8.5),
          decoration: BoxDecoration(
            color: Color(0xFF1D2340),
            borderRadius: BorderRadius.circular(12.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jourSemaine,
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  Image.network(
                    'https:${day['day']['condition']['icon']}',
                    width: 40,
                    height: 40,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('↑: ${day['day']['maxtemp_c']}°C',
                          style: TextStyle(color: Colors.white)),
                      Text('↓: ${day['day']['mintemp_c']}°C',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
