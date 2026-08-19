import 'package:flutter/material.dart';
import '../components/vista_estado.dart';
import '../components/tarjeta_ficha.dart';
import '../theme/tokens_app.dart';

class ListadoFichasScreen extends StatefulWidget {
  const ListadoFichasScreen({super.key});

  @override
  State<ListadoFichasScreen> createState() => _ListadoFichasScreenState();
}

class _ListadoFichasScreenState extends State<ListadoFichasScreen> {
  TipoVistaEstado? _estado;
  List<Map<String, String>> _fichas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _estado = TipoVistaEstado.cargando;
    });
    
    // Simulamos una latencia de red
    await Future.delayed(const Duration(seconds: 2));

    // Simulando que los datos llegaron con xito (cambia esto a TipoVistaEstado.error o vacio para probar)
    setState(() {
      _estado = null;
      _fichas = [
        {'modelo': 'Galaxy S24 Ultra', 'fabricante': 'Samsung', 'procesador': 'Snapdragon 8 Gen 3'},
        {'modelo': 'iPhone 15 Pro Max', 'fabricante': 'Apple', 'procesador': 'A17 Pro'},
        {'modelo': 'Pixel 8 Pro', 'fabricante': 'Google', 'procesador': 'Tensor G3'},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TokensApp>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catlogo de Dispositivos'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_estado != null) {
              return VistaEstado(
                tipo: _estado!,
                mensaje: _estado == TipoVistaEstado.cargando 
                    ? 'Cargando dispositivos...' 
                    : (_estado == TipoVistaEstado.error ? 'Hubo un error de conexin' : 'No hay dispositivos registrados'),
                onReintentar: _cargarDatos,
              );
            }

            // Comportamiento responsivo: cuadricula si hay espacio, lista si es estrecho
            final bool esAncho = constraints.maxWidth > 600;

            return GridView.builder(
              padding: EdgeInsets.all(tokens.espacioBase * 2),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: esAncho ? 2 : 1,
                mainAxisExtent: esAncho ? 120 : null,
                crossAxisSpacing: tokens.espacioBase * 2,
                mainAxisSpacing: tokens.espacioBase * 2,
                childAspectRatio: esAncho ? 1 : 3, 
              ),
              itemCount: _fichas.length,
              itemBuilder: (context, index) {
                final ficha = _fichas[index];
                return TarjetaFicha(
                  modelo: ficha['modelo']!,
                  fabricante: ficha['fabricante']!,
                  procesador: ficha['procesador'],
                  compacta: !esAncho, // Si no es ancho, la mostramos compacta
                  onPulsar: () {
                    // Solo como log o delegacin de intencin
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Seleccionado: ${ficha['modelo']}')),
                    );
                  },
                  accionFinal: Semantics(
                    label: 'Marcar ${ficha['modelo']} como favorito',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {},
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
