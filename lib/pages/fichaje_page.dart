import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/logger_service.dart';
import 'registros_fichaje_page.dart';
import '../main.dart';

class FichajePage extends StatefulWidget {
  final String trabajadorId;
  final String email;

  const FichajePage({
    super.key,
    required this.trabajadorId,
    required this.email,
  });

  @override
  State<FichajePage> createState() => _FichajePageState();
}

class _FichajePageState extends State<FichajePage> {
  String? _empresaId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosTrabajador();
    if (kIsWeb) {
      _solicitarPermisosWeb();
    }
  }

  Future<void> _cargarDatosTrabajador() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: widget.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        setState(() {
          _empresaId = userData['empresaId'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _solicitarPermisosWeb() async {
    try {
      // Solicitar permisos de ubicación en web
      await geo.Geolocator.requestPermission();
      
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, habilita los servicios de ubicación en tu navegador'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error al solicitar permisos en web: $e');
    }
  }

  Future<geo.Position> _obtenerUbicacion() async {
    if (kIsWeb) {
      try {
        // En web, usar alta precisión
        return await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Si falla la alta precisión, intentar con precisión media
        return await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
      }
    } else {
      bool serviceEnabled;
      geo.LocationPermission permission;

      // Verificar si el servicio de ubicación está habilitado
      serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados.');
      }

      // Verificar permisos de ubicación
      permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('Los permisos de ubicación fueron denegados.');
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Los permisos de ubicación están permanentemente denegados.');
      }

      // Obtener la ubicación actual con alta precisión
      return await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    }
  }

  Future<String> _obtenerDireccion(double latitud, double longitud) async {
    try {
      print('Obteniendo dirección para: $latitud, $longitud');
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitud&lon=$longitud&zoom=18&addressdetails=1&namedetails=1&accept-language=es';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DPClock/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Respuesta de Nominatim: $data');
        
        if (data['address'] != null) {
          final address = data['address'];
          String street = '';
          String houseNumber = '';
          String locality = '';
          String postcode = '';
          
          // Obtener el número de la casa
          if (address['house_number'] != null) {
            houseNumber = address['house_number'];
          }
          
          // Obtener la calle
          if (address['road'] != null) {
            street = address['road'];
          } else if (address['pedestrian'] != null) {
            street = address['pedestrian'];
          } else if (address['footway'] != null) {
            street = address['footway'];
          } else if (address['residential'] != null) {
            street = address['residential'];
          } else if (address['path'] != null) {
            street = address['path'];
          } else if (address['track'] != null) {
            street = address['track'];
          }
          
          // Obtener la localidad
          if (address['city'] != null) {
            locality = address['city'];
          } else if (address['town'] != null) {
            locality = address['town'];
          } else if (address['village'] != null) {
            locality = address['village'];
          } else if (address['suburb'] != null) {
            locality = address['suburb'];
          }
          
          // Obtener el código postal
          if (address['postcode'] != null) {
            postcode = address['postcode'];
          }
          
          // Construir la dirección
          if (street.isNotEmpty) {
            String direccion = street;
            if (houseNumber.isNotEmpty) {
              direccion += ' $houseNumber';
            }
            if (locality.isNotEmpty) {
              direccion += ', $locality';
            }
            if (postcode.isNotEmpty) {
              direccion += ' ($postcode)';
            }
            print('Dirección encontrada: $direccion');
            return direccion;
          } else if (locality.isNotEmpty) {
            String direccion = locality;
            if (postcode.isNotEmpty) {
              direccion += ' ($postcode)';
            }
            print('Solo localidad encontrada: $direccion');
            return direccion;
          }
        }
      }
      
      print('No se pudo obtener una dirección válida de Nominatim');
      return 'Ubicación: ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
    } catch (e, stackTrace) {
      print('Error al obtener dirección: $e');
      print('Stack trace: $stackTrace');
      return 'Ubicación: ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
    }
  }

  Future<void> _registrarFichaje(String tipo) async {
    if (_empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener el ID de la empresa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Obtener la ubicación actual
      final position = await _obtenerUbicacion();
      
      // Obtener la dirección
      final direccion = await _obtenerDireccion(position.latitude, position.longitude);
      
      // Crear el mapa de ubicación
      final ubicacion = {
        'latitud': position.latitude,
        'longitud': position.longitude,
        'precision': position.accuracy,
        'altitud': position.altitude,
        'velocidad': position.speed,
        'velocidadPrecision': position.speedAccuracy,
        'direccion': position.heading,
        'direccionCompleta': direccion,
        'timestamp': Timestamp.now(),
      };

      // Crear el documento de fichaje
      final fichajeData = {
        'tipo': tipo,
        'fecha': Timestamp.now(),
        'trabajadorId': widget.trabajadorId,
        'empresaId': _empresaId,
        'ubicacion': ubicacion,
      };

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('empresas')
          .doc(_empresaId)
          .collection('trabajadores')
          .doc(widget.trabajadorId)
          .collection('fichajes')
          .add(fichajeData);

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichaje de $tipo registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a la página de registros después de un fichaje exitoso
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrosFichajePage(
            trabajadorId: widget.trabajadorId,
            empresaId: _empresaId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar fichaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fichaje'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegistrosFichajePage(
                    trabajadorId: widget.trabajadorId,
                    empresaId: _empresaId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _registrarFichaje('entrada'),
              icon: const Icon(Icons.login),
              label: const Text('Registrar Entrada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _registrarFichaje('salida'),
              icon: const Icon(Icons.logout),
              label: const Text('Registrar Salida'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 