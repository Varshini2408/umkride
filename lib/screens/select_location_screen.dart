import 'package:flutter/material.dart';
import 'dart:math' show cos, sqrt, asin, sin, pi, max;
import '../../history/history_screen.dart';
import '../models/booking_model.dart';
import 'select_vehicle_screen.dart';

class Place {
  final String name;
  final LatLngFake coordinates;
  final IconData? icon;
  Place(this.name, this.coordinates, {this.icon});
}

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> with SingleTickerProviderStateMixin {
  final BookingModel _booking = BookingModel();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  String _searchQuery = "";
  late AnimationController _animationController;

  double _mapLat = 6.160;
  double _mapLon = 102.280;
  double _zoom = 12000; 
  double _baseZoom = 12000;
  
  static const double gridStep = 0.005; 

  final List<Place> _availablePlaces = [
    Place("Universiti Malaysia Kelantan Kota", const LatLngFake(6.162, 102.288), icon: Icons.school),
    Place("Sultan Ismail Petra Airport", const LatLngFake(6.170, 102.292), icon: Icons.flight),
    Place("Kota Bharu City Center", const LatLngFake(6.125, 102.240), icon: Icons.location_city),
    Place("Kubang Kerian", const LatLngFake(6.095, 102.270)),
    Place("Mydin Tunjong", const LatLngFake(6.075, 102.235), icon: Icons.shopping_bag),
    Place("Pengkalan Chepa", const LatLngFake(6.155, 102.285)),
    Place("UMK Bachok Campus", const LatLngFake(6.000, 102.400), icon: Icons.school),
    Place("Pantai Cahaya Bulan", const LatLngFake(6.195, 102.260), icon: Icons.beach_access),
    Place("Senok Beach", const LatLngFake(6.170, 102.350), icon: Icons.wb_sunny),
  ];

  String _distanceText = "0.0 km";
  String _genderPreference = "ANY";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _initDefaultLocations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initDefaultLocations() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _booking.pickupLocation = _availablePlaces[0].name;
        _booking.pickupLatLng = _availablePlaces[0].coordinates;
        _booking.destinationLocation = _availablePlaces[1].name;
        _booking.destinationLatLng = _availablePlaces[1].coordinates;
        _updateMapFocus();
        _calculateFinalDistance();
        _isLoading = false;
      });
    });
  }

  void _updateMapFocus() {
    if (_booking.pickupLatLng != null && _booking.destinationLatLng != null) {
      setState(() {
        _mapLat = (_booking.pickupLatLng!.latitude + _booking.destinationLatLng!.latitude) / 2;
        _mapLon = (_booking.pickupLatLng!.longitude + _booking.destinationLatLng!.longitude) / 2;
        _zoom = 15000;
        _baseZoom = _zoom;
      });
    }
  }

  void _calculateFinalDistance() {
    if (_booking.pickupLatLng != null && _booking.destinationLatLng != null) {
      double d = _calculateDistance(
        _booking.pickupLatLng!.latitude, _booking.pickupLatLng!.longitude,
        _booking.destinationLatLng!.latitude, _booking.destinationLatLng!.longitude,
      );
      setState(() { 
        _booking.distance = d;
        _distanceText = "${d.toStringAsFixed(1)} km"; 
      });
    }
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _showPlacePicker(bool isPickup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          final filtered = _availablePlaces.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: isPickup ? 'Select pickup location...' : 'Where to?',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setModalState(() => _searchQuery = val),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
                    itemBuilder: (context, index) {
                      final place = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[100],
                          child: Icon(place.icon ?? Icons.location_on, color: Colors.blueGrey, size: 20),
                        ),
                        title: Text(place.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Kelantan, Malaysia"),
                        onTap: () {
                          setState(() {
                            if (isPickup) {
                              _booking.pickupLocation = place.name;
                              _booking.pickupLatLng = place.coordinates;
                            } else {
                              _booking.destinationLocation = place.name;
                              _booking.destinationLatLng = place.coordinates;
                            }
                            _updateMapFocus();
                            _calculateFinalDistance();
                            _searchQuery = "";
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (details) => _baseZoom = _zoom,
              onScaleUpdate: (details) {
                setState(() {
                  _zoom = (_baseZoom * details.scale).clamp(5000.0, 40000.0);
                  if (details.pointerCount == 1) {
                    _mapLon -= details.focalPointDelta.dx / _zoom;
                    _mapLat += details.focalPointDelta.dy / _zoom;
                  }
                });
              },
              child: CustomPaint(
                painter: GoogleMapPainter(
                  centerLat: _mapLat,
                  centerLon: _mapLon,
                  zoom: _zoom,
                  gridStep: gridStep,
                  poiList: _availablePlaces,
                ),
              ),
            ),
          ),
          if (!_isLoading && _booking.pickupLatLng != null && _booking.destinationLatLng != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) => CustomPaint(
                    painter: SimpleRoutePainter(
                      pickup: _booking.pickupLatLng!,
                      destination: _booking.destinationLatLng!,
                      centerLat: _mapLat,
                      centerLon: _mapLon,
                      zoom: _zoom,
                      animationValue: _animationController.value,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 50,
            left: 20,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
              ),
            ),
          ),
          // Zoom Buttons
          Positioned(
            right: 20,
            bottom: 320,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    setState(() {
                      _zoom = (_zoom * 1.3).clamp(5000.0, 40000.0);
                    });
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    setState(() {
                      _zoom = (_zoom / 1.3).clamp(5000.0, 40000.0);
                    });
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _locationRow(true, _booking.pickupLocation ?? "Pick location"),
                        const Padding(padding: EdgeInsets.only(left: 35), child: Divider(height: 20)),
                        _locationRow(false, _booking.destinationLocation ?? "Your destination"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Estimated Distance", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(_distanceText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Gender Preference
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Driver Preference",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _genderPreference = "ANY"),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: _genderPreference == "ANY" ? Colors.black : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.people, size: 16,
                                color: _genderPreference == "ANY" ? Colors.white : Colors.black),
                            const SizedBox(width: 6),
                            Text("Any Driver",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _genderPreference == "ANY" ? Colors.white : Colors.black)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _genderPreference = "FEMALE_ONLY"),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: _genderPreference == "FEMALE_ONLY" ? Colors.pink : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.woman, size: 16,
                                color: _genderPreference == "FEMALE_ONLY" ? Colors.white : Colors.black),
                            const SizedBox(width: 6),
                            Text("Female Only",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _genderPreference == "FEMALE_ONLY" ? Colors.white : Colors.black)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _booking.genderPreference = _genderPreference;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SelectVehicleScreen(booking: _booking)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('NEXT', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(bool isPickup, String text) {
    return InkWell(
      onTap: () => _showPlacePicker(isPickup),
      child: Row(
        children: [
          Icon(isPickup ? Icons.my_location : Icons.location_on, color: isPickup ? Colors.blue : Colors.red, size: 20),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: text.contains("Pick") || text.contains("destination") ? Colors.grey : Colors.black), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

Offset latLngToScreen(LatLngFake latLng, Size size, double centerLat, double centerLon, double zoom) {
  double dx = (latLng.longitude - centerLon) * zoom + (size.width / 2);
  double dy = (centerLat - latLng.latitude) * zoom + (size.height / 2 - 80); 
  return Offset(dx, dy);
}

class GoogleMapPainter extends CustomPainter {
  final double centerLat;
  final double centerLon;
  final double zoom;
  final double gridStep;
  final List<Place> poiList;

  GoogleMapPainter({required this.centerLat, required this.centerLon, required this.zoom, required this.gridStep, required this.poiList});

  @override
  void paint(Canvas canvas, Size size) {
    // Colors matching real Google Maps
    final paintLand = Paint()..color = const Color(0xFFF1F3F4);
    final paintWater = Paint()..color = const Color(0xFFAAD3DF);
    final paintParks = Paint()..color = const Color(0xFFD8F2D0);
    final paintRoadSecondary = Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final paintRoadMain = Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final paintRoadHighway = Paint()..color = const Color(0xFFFFFBD3)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final paintRoadOutline = Paint()..color = const Color(0xFFE5E5E5)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    // Draw Land
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintLand);

    // 1. Sea / Large Water Bodies
    Offset coastLine = latLngToScreen(const LatLngFake(6.19, 102.25), size, centerLat, centerLon, zoom);
    if (coastLine.dy > -100) {
      canvas.drawRect(Rect.fromLTRB(-500, -500, size.width + 500, coastLine.dy), paintWater);
    }

    // 2. Parks / Greenery
    Offset park1 = latLngToScreen(const LatLngFake(6.10, 102.32), size, centerLat, centerLon, zoom);
    canvas.drawCircle(park1, zoom/80, paintParks);
    
    // 3. Streets (Regular Grid)
    double latRange = (size.height / zoom) + 0.1;
    double lonRange = (size.width / zoom) + 0.1;
    double sLat = ((centerLat - latRange/2) / gridStep).floor() * gridStep;
    double eLat = ((centerLat + latRange/2) / gridStep).ceil() * gridStep;
    double sLon = ((centerLon - lonRange/2) / gridStep).floor() * gridStep;
    double eLon = ((centerLon + lonRange/2) / gridStep).ceil() * gridStep;

    // Secondary Roads (Grid)
    for (double lat = sLat; lat <= eLat; lat += gridStep) {
      Offset p1 = latLngToScreen(LatLngFake(lat, sLon - 0.1), size, centerLat, centerLon, zoom);
      Offset p2 = latLngToScreen(LatLngFake(lat, eLon + 0.1), size, centerLat, centerLon, zoom);
      canvas.drawLine(p1, p2, paintRoadOutline..strokeWidth = zoom/2000 + 1.5);
      canvas.drawLine(p1, p2, paintRoadSecondary..strokeWidth = zoom/2000);
    }
    for (double lon = sLon; lon <= eLon; lon += gridStep) {
      Offset p1 = latLngToScreen(LatLngFake(sLat - 0.1, lon), size, centerLat, centerLon, zoom);
      Offset p2 = latLngToScreen(LatLngFake(eLat + 0.1, lon), size, centerLat, centerLon, zoom);
      canvas.drawLine(p1, p2, paintRoadOutline..strokeWidth = zoom/2000 + 1.5);
      canvas.drawLine(p1, p2, paintRoadSecondary..strokeWidth = zoom/2000);
    }

    // 4. Main Highway (e.g., Jalan Sultan Yahya Petra)
    final highwayPath = Path();
    List<LatLngFake> highwayPts = [
      const LatLngFake(6.05, 102.25), const LatLngFake(6.12, 102.25), const LatLngFake(6.17, 102.27),
    ];
    Offset hStart = latLngToScreen(highwayPts[0], size, centerLat, centerLon, zoom);
    highwayPath.moveTo(hStart.dx, hStart.dy);
    for (var i = 1; i < highwayPts.length; i++) {
      Offset pos = latLngToScreen(highwayPts[i], size, centerLat, centerLon, zoom);
      highwayPath.lineTo(pos.dx, pos.dy);
    }
    canvas.drawPath(highwayPath, paintRoadOutline..strokeWidth = zoom/800 + 2);
    canvas.drawPath(highwayPath, paintRoadHighway..strokeWidth = zoom/800);

    // 5. POIs & Labels
    for (var poi in poiList) {
      Offset pos = latLngToScreen(poi.coordinates, size, centerLat, centerLon, zoom);
      if (pos.dx > 0 && pos.dx < size.width && pos.dy > 0 && pos.dy < size.height) {
        // Icon Dot
        canvas.drawCircle(pos, 4, Paint()..color = Colors.blueGrey.withOpacity(0.4));
        // Label
        TextPainter(
          text: TextSpan(
            text: poi.name, 
            style: TextStyle(color: Colors.blueGrey[800], fontSize: 10, fontWeight: FontWeight.w600, 
            shadows: const [Shadow(color: Colors.white, blurRadius: 2)])),
          textDirection: TextDirection.ltr,
        )..layout()..paint(canvas, pos + const Offset(8, -6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant GoogleMapPainter oldDelegate) => true;
}

class SimpleRoutePainter extends CustomPainter {
  final LatLngFake pickup;
  final LatLngFake destination;
  final double centerLat;
  final double centerLon;
  final double zoom;
  final double animationValue;

  SimpleRoutePainter({required this.pickup, required this.destination, required this.centerLat, required this.centerLon, required this.zoom, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    Offset start = latLngToScreen(pickup, size, centerLat, centerLon, zoom);
    Offset end = latLngToScreen(destination, size, centerLat, centerLon, zoom);

    // Draw Blue Route Line
    final paintRoute = Paint()..color = const Color(0xFF4285F4)..strokeWidth = zoom/400..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final paintShadow = Paint()..color = Colors.black.withOpacity(0.1)..strokeWidth = zoom/400 + 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    // Standard routing logic: simple bend
    Offset mid = Offset(end.dx, start.dy);
    path.lineTo(mid.dx, mid.dy);
    path.lineTo(end.dx, end.dy);

    canvas.drawPath(path, paintShadow);
    canvas.drawPath(path, paintRoute);

    // Animated dots
    final metrics = path.computeMetrics();
    for (var metric in metrics) {
      double pos = (animationValue * metric.length);
      var tangent = metric.getTangentForOffset(pos);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 4, Paint()..color = Colors.white);
      }
    }

    _drawMarker(canvas, start, const Color(0xFF4285F4));
    _drawMarker(canvas, end, const Color(0xFFEA4335));
  }

  void _drawMarker(Canvas canvas, Offset pos, Color color) {
    canvas.drawCircle(pos, 10, Paint()..color = color.withOpacity(0.2));
    canvas.drawCircle(pos, 6, Paint()..color = color);
    canvas.drawCircle(pos, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant SimpleRoutePainter oldDelegate) => true;
}
