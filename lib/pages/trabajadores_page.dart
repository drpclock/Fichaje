import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trabajador.dart';
import '../models/empresa.dart';
import '../pages/registros_fichaje_page.dart';
import '../pages/register_worker_page.dart';

class TrabajadoresPage extends StatefulWidget {
  final List<Empresa> empresas;
  final Function(Trabajador) onTrabajadorAgregado;
  final Function(Trabajador) onTrabajadorEliminado;
  final String? empresaId;

  const TrabajadoresPage({
    super.key,
    required this.empresas,
    required this.onTrabajadorAgregado,
    required this.onTrabajadorEliminado,
    this.empresaId,
  });

  @override
  State<TrabajadoresPage> createState() => _TrabajadoresPageState();
}

class _TrabajadoresPageState extends State<TrabajadoresPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final List<Trabajador> _trabajadores = [];
  Empresa? _empresaSeleccionada;
  bool _mostrarPassword = false;
  bool _mostrarFormulario = false;

  @override
  void initState() {
    super.initState();
    if (widget.empresaId != null) {
      _empresaSeleccionada = widget.empresas.firstWhere(
        (empresa) => empresa.id == widget.empresaId,
        orElse: () => widget.empresas.first,
      );
    }
    _cargarTrabajadores();
  }

  Future<void> _cargarTrabajadores() async {
    try {
      final empresaId = _empresaSeleccionada?.id ?? widget.empresaId;
      if (empresaId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('trabajadores')
          .orderBy('fechaContratacion', descending: true)
          .get();

      if (!mounted) return;

      setState(() {
        _trabajadores.clear();
        _trabajadores.addAll(
          snapshot.docs.map((doc) => Trabajador.fromFirestore(doc)).toList(),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar trabajadores: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _guardarTrabajador() {
    if (_formKey.currentState!.validate() && _empresaSeleccionada != null) {
      final trabajador = Trabajador(
        id: '',
        nombre: _nombreController.text,
        apellidos: _apellidosController.text,
        dni: _dniController.text,
        telefono: _telefonoController.text,
        email: _emailController.text,
        password: _passwordController.text.isEmpty ? '123456' : _passwordController.text,
        empresaId: _empresaSeleccionada!.id,
        fechaContratacion: DateTime.now(),
      );
      widget.onTrabajadorAgregado(trabajador);
      _nombreController.clear();
      _apellidosController.clear();
      _dniController.clear();
      _telefonoController.clear();
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        _mostrarFormulario = false;
      });
      _cargarTrabajadores();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trabajador agregado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trabajadores'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          if (!_mostrarFormulario) ...[
            if (widget.empresaId == null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<Empresa>(
                  value: _empresaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Empresa',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.empresas.map((empresa) {
                    return DropdownMenuItem(
                      value: empresa,
                      child: Text(empresa.nombre),
                    );
                  }).toList(),
                  onChanged: (Empresa? value) {
                    setState(() {
                      _empresaSeleccionada = value;
                    });
                    _cargarTrabajadores();
                  },
                ),
              ),
            Expanded(
              child: _trabajadores.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay trabajadores registrados',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
                          columns: const [
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('Apellidos')),
                            DataColumn(label: Text('DNI')),
                            DataColumn(label: Text('Teléfono')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Fecha Contratación')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: _trabajadores.map((trabajador) {
                            return DataRow(
                              cells: [
                                DataCell(Text(trabajador.nombre)),
                                DataCell(Text(trabajador.apellidos)),
                                DataCell(Text(trabajador.dni)),
                                DataCell(Text(trabajador.telefono)),
                                DataCell(Text(trabajador.email)),
                                DataCell(Text(
                                  '${trabajador.fechaContratacion.day}/${trabajador.fechaContratacion.month}/${trabajador.fechaContratacion.year}'
                                )),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.history, color: Colors.blue),
                                        tooltip: 'Ver registros de fichaje',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => RegistrosFichajePage(
                                                trabajadorId: trabajador.id,
                                                empresaId: _empresaSeleccionada?.id ?? widget.empresaId ?? '',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Eliminar trabajador',
                                        onPressed: () => _eliminarTrabajador(trabajador),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.person_add,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<Empresa>(
                        value: _empresaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Empresa',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: widget.empresas.map((empresa) {
                          return DropdownMenuItem(
                            value: empresa,
                            child: Text(empresa.nombre),
                          );
                        }).toList(),
                        onChanged: (Empresa? value) {
                          setState(() {
                            _empresaSeleccionada = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor seleccione una empresa';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidosController,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese los apellidos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dniController,
                        decoration: const InputDecoration(
                          labelText: 'DNI',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el DNI';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el teléfono';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email (Usuario)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el email';
                          }
                          if (!value.contains('@')) {
                            return 'Por favor ingrese un email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mostrarPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _mostrarPassword = !_mostrarPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: !_mostrarPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _guardarTrabajador,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Trabajador'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _mostrarFormulario = false;
                          });
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: !_mostrarFormulario
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterWorkerPage(
                      companyId: _empresaSeleccionada?.id ?? '',
                      trabajadorId: '',
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _eliminarTrabajador(Trabajador trabajador) async {
    try {
      await widget.onTrabajadorEliminado(trabajador);
      _cargarTrabajadores();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar trabajador: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 