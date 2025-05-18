import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import '../services/logger_service.dart';

class RegistrosFichajePage extends StatefulWidget {
  final String? trabajadorId;
  final String? empresaId;

  const RegistrosFichajePage({
    super.key,
    this.trabajadorId,
    this.empresaId,
  });

  @override
  State<RegistrosFichajePage> createState() => _RegistrosFichajePageState();
}

class _RegistrosFichajePageState extends State<RegistrosFichajePage> {
  bool _sortAscending = true;
  int _sortColumnIndex = 0;
  bool _isExporting = false;
  Map<String, Map<String, dynamic>> fichajesAgrupados = {};

  void _sort<T>(Comparable<T> Function(Map<String, dynamic> d) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Future<void> _mostrarOpcionesExportacion(Map<String, Map<String, dynamic>> fichajesAgrupados) async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Obtener datos del trabajador
      final trabajadorDoc = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(widget.empresaId)
          .collection('trabajadores')
          .doc(widget.trabajadorId)
          .get();

      final trabajadorData = trabajadorDoc.data() as Map<String, dynamic>;

      // Crear el documento PDF
      final pdf = pw.Document();

      // Definir colores personalizados
      final primaryColor = PdfColor.fromHex('#2196F3'); // Azul Material
      final accentColor = PdfColor.fromHex('#FFC107'); // Amarillo Material
      final backgroundColor = PdfColor.fromHex('#F5F5F5'); // Gris claro
      final textColor = PdfColor.fromHex('#212121'); // Gris oscuro

      // Agregar una página al PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                color: backgroundColor,
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Encabezado con logo y título
                    pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'REGISTROS DE FICHAJE',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Datos del trabajador
                    pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.only(bottom: 10),
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: pw.Text(
                              'DATOS DEL TRABAJADOR',
                              style: pw.TextStyle(
                                color: primaryColor,
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 15),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('Nombre', trabajadorData['nombre'] ?? 'No disponible'),
                                    pw.SizedBox(height: 8),
                                    _buildInfoRow('DNI', trabajadorData['dni'] ?? 'No disponible'),
                                    pw.SizedBox(height: 8),
                                    _buildInfoRow('Email', trabajadorData['email'] ?? 'No disponible'),
                                  ],
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('Teléfono', trabajadorData['telefono'] ?? 'No disponible'),
                                    pw.SizedBox(height: 8),
                                    _buildInfoRow('Cargo', trabajadorData['cargo'] ?? 'No disponible'),
                                    pw.SizedBox(height: 8),
                                    _buildInfoRow('Departamento', trabajadorData['departamento'] ?? 'No disponible'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Tabla de registros
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      ),
                      child: pw.Table.fromTextArray(
                        context: context,
                        border: pw.TableBorder.all(
                          color: PdfColors.grey300,
                          width: 1,
                        ),
                        headerStyle: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                        headerDecoration: pw.BoxDecoration(
                          color: primaryColor,
                        ),
                        cellHeight: 35,
                        cellAlignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.center,
                          2: pw.Alignment.centerLeft,
                          3: pw.Alignment.center,
                          4: pw.Alignment.centerLeft,
                        },
                        headerPadding: const pw.EdgeInsets.all(8),
                        cellPadding: const pw.EdgeInsets.all(8),
                        headers: [
                          'Fecha',
                          'Hora Entrada',
                          'Dirección Entrada',
                          'Hora Salida',
                          'Dirección Salida',
                        ],
                        data: fichajesAgrupados.entries.map((entry) {
                          final fecha = entry.key;
                          final datos = entry.value;
                          final entrada = datos['entrada'] as DateTime?;
                          final salida = datos['salida'] as DateTime?;
                          
                          return [
                            fecha,
                            entrada != null ? '${entrada.hour}:${entrada.minute.toString().padLeft(2, '0')}' : '-',
                            datos['direccionEntrada'],
                            salida != null ? '${salida.hour}:${salida.minute.toString().padLeft(2, '0')}' : '-',
                            datos['direccionSalida'],
                          ];
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Obtener el directorio de descargas
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Guardar el PDF
      final String fileName = 'registros_fichaje_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo guardado en: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 100,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              color: PdfColor.fromHex('#757575'),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#212121'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de Fichaje'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isExporting ? null : () {
          if (fichajesAgrupados != null) {
            _mostrarOpcionesExportacion(fichajesAgrupados!);
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: _isExporting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.file_download, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('empresas')
            .doc(widget.empresaId)
            .collection('trabajadores')
            .doc(widget.trabajadorId)
            .collection('fichajes')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final fichajes = snapshot.data?.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList() ??
              [];

          if (fichajes.isEmpty) {
            return const Center(
              child: Text(
                'No hay registros de fichaje',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Agrupar fichajes por fecha
          fichajesAgrupados = {};
          for (var fichaje in fichajes) {
            final fecha = (fichaje['fecha'] as Timestamp).toDate();
            final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
            
            if (!fichajesAgrupados.containsKey(fechaStr)) {
              fichajesAgrupados[fechaStr] = {
                'entrada': null,
                'salida': null,
                'direccionEntrada': '',
                'direccionSalida': '',
              };
            }
            
            if (fichaje['tipo'] == 'entrada') {
              fichajesAgrupados[fechaStr]!['entrada'] = fecha;
              fichajesAgrupados[fechaStr]!['direccionEntrada'] = 
                  fichaje['ubicacion']?['direccionCompleta'] ?? 'No disponible';
            } else {
              fichajesAgrupados[fechaStr]!['salida'] = fecha;
              fichajesAgrupados[fechaStr]!['direccionSalida'] = 
                  fichaje['ubicacion']?['direccionCompleta'] ?? 'No disponible';
            }
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: const Text('Fecha'),
                      onSort: (columnIndex, ascending) {
                        _sort<String>((d) => d['fecha'], columnIndex, ascending);
                      },
                    ),
                    const DataColumn(
                      label: Text('Hora Entrada'),
                    ),
                    const DataColumn(
                      label: Text('Dirección Entrada'),
                    ),
                    const DataColumn(
                      label: Text('Hora Salida'),
                    ),
                    const DataColumn(
                      label: Text('Dirección Salida'),
                    ),
                  ],
                  rows: fichajesAgrupados.entries.map((entry) {
                    final fecha = entry.key;
                    final datos = entry.value;
                    final entrada = datos['entrada'] as DateTime?;
                    final salida = datos['salida'] as DateTime?;
                    
                    return DataRow(
                      cells: [
                        DataCell(Text(fecha)),
                        DataCell(Text(
                          entrada != null 
                              ? '${entrada.hour}:${entrada.minute.toString().padLeft(2, '0')}'
                              : '-',
                          style: TextStyle(
                            color: entrada != null ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                        DataCell(Text(datos['direccionEntrada'])),
                        DataCell(Text(
                          salida != null 
                              ? '${salida.hour}:${salida.minute.toString().padLeft(2, '0')}'
                              : '-',
                          style: TextStyle(
                            color: salida != null ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                        DataCell(Text(datos['direccionSalida'])),
                      ],
                    );
                  }).toList(),
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  showCheckboxColumn: false,
                  headingRowHeight: 50,
                  dataRowHeight: 50,
                  horizontalMargin: 20,
                  columnSpacing: 12,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  dataTextStyle: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 