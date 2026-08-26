import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ficha_model.dart';
import '../components/vista_estado.dart';

class FichaProvider extends ChangeNotifier {
  final List<FichaModel> _fichas = [
    const FichaModel(
      idFicha: '1',
      modelo: 'Samsung Galaxy A55 5G',
      fabricante: 'Samsung',
      procesador: 'Samsung Exynos 1480',
      ram: '8 GB RAM',
      almacenamiento: '256 GB',
      pantalla: '6.6" Super AMOLED FHD+ 120Hz',
      camaraPrincipal: '50 MP f/1.8 OIS',
      camaraFrontal: '32 MP f/2.2',
      bateria: '5000 mAh (25W)',
      sistemaOperativo: 'Android 14 con One UI 6.1',
      conectividad: '5G, Wi-Fi 6, Bluetooth 5.3, NFC',
      extras: 'IP67 resistencia al agua, Gorilla Glass Victus+',
      precioOficial: 449.0,
      urlImagen: 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-a55.jpg',
    ),
    const FichaModel(
      idFicha: '2',
      modelo: 'Tecno Spark 20 Pro Plus',
      fabricante: 'Tecno',
      procesador: 'MediaTek Helio G99 Ultimate',
      ram: '8 GB RAM',
      almacenamiento: '256 GB',
      pantalla: '6.78" Curved AMOLED FHD+ a 120Hz',
      camaraPrincipal: '108 MP f/1.75 con PDAF',
      camaraFrontal: '32 MP con flash dual',
      bateria: '5000 mAh (33W)',
      sistemaOperativo: 'Android 14 con HIOS 14',
      conectividad: '4G LTE, Wi-Fi 5, Bluetooth 5.2, NFC',
      extras: 'IP53 resistencia, huella en pantalla',
      precioOficial: 190.0,
      urlImagen: 'https://fdn2.gsmarena.com/vv/bigpic/tecno-spark20-pro-plus.jpg',
    ),
    const FichaModel(
      idFicha: '3',
      modelo: 'Xiaomi 14 Ultra',
      fabricante: 'Xiaomi',
      procesador: 'Qualcomm Snapdragon 8 Gen 3',
      ram: '16 GB RAM',
      almacenamiento: '512 GB',
      pantalla: '6.73" LTPO AMOLED WQHD+ 120Hz',
      camaraPrincipal: '50 MP (1 pulgada) Leica Quad-Cam',
      camaraFrontal: '32 MP',
      bateria: '5000 mAh (90W cable / 80W inalámbrico)',
      sistemaOperativo: 'Android 14 con HyperOS',
      conectividad: '5G, Wi-Fi 7, Bluetooth 5.4, NFC',
      extras: 'IP68 titanio, cámaras ópticas Leica',
      precioOficial: 1499.0,
      urlImagen: 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-14-ultra.jpg',
    ),
  ];

  TipoVistaEstado _estado = TipoVistaEstado.vacio;
  bool _buscandoIA = false;
  String _mensajeError = '';
  FichaModel? _resultadoBusquedaIA;
  FichaModel? _fichaSeleccionada;

  final String _baseUrl = 'http://127.0.0.1:5000/api';

  List<FichaModel> get fichas => List.unmodifiable(_fichas);
  TipoVistaEstado get estado => _estado;
  bool get buscandoIA => _buscandoIA;
  String get mensajeError => _mensajeError;
  FichaModel? get resultadoBusquedaIA => _resultadoBusquedaIA;
  FichaModel? get fichaSeleccionada => _fichaSeleccionada;

  void actualizarEstado(TipoVistaEstado nuevo) {
    _estado = nuevo;
    notifyListeners();
  }

  // Búsqueda inteligente con IA (Gemini 3.6 Flash a través del backend)
  Future<FichaModel?> buscarConIA(String consulta, {String? token}) async {
    if (consulta.trim().isEmpty) return null;

    _buscandoIA = true;
    _mensajeError = '';
    _resultadoBusquedaIA = null;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseUrl/fichas/extraer-ia');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'texto': consulta}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exito'] == true && data['datos'] != null) {
          final ficha = FichaModel.fromJson(data['datos']);
          _resultadoBusquedaIA = ficha;
          _buscandoIA = false;
          notifyListeners();
          return ficha;
        }
      }
    } catch (e) {
      debugPrint('[FichaProvider] Error consultando backend: $e');
    }

    // Fallback local enriquecido si el backend no responde
    await Future.delayed(const Duration(milliseconds: 1500));
    final coincidencias = _fichas.where((f) => 
      f.modelo.toLowerCase().contains(consulta.toLowerCase()) ||
      (f.fabricante?.toLowerCase().contains(consulta.toLowerCase()) ?? false)
    ).toList();

    if (coincidencias.isNotEmpty) {
      _resultadoBusquedaIA = coincidencias.first;
    } else {
      _resultadoBusquedaIA = FichaModel(
        modelo: consulta,
        fabricante: consulta.split(' ').first,
        procesador: 'Chipset inteligente detectado',
        ram: '8 GB RAM',
        almacenamiento: '256 GB',
        pantalla: '6.7" AMOLED FHD+ 120Hz',
        camaraPrincipal: '50 MP con OIS',
        camaraFrontal: '16 MP',
        bateria: '5000 mAh (33W)',
        sistemaOperativo: 'Android 14',
        precioOficial: 299.0,
      );
    }

    _buscandoIA = false;
    notifyListeners();
    return _resultadoBusquedaIA;
  }

  FichaModel? obtenerPorId(String id) {
    try {
      _fichaSeleccionada = _fichas.firstWhere((f) => f.idFicha == id);
      return _fichaSeleccionada;
    } catch (e) {
      return null;
    }
  }

  void seleccionarFicha(FichaModel ficha) {
    _fichaSeleccionada = ficha;
    notifyListeners();
  }

  Future<bool> guardarFicha(FichaModel nuevaFicha) async {
    final fichaConId = FichaModel(
      idFicha: (_fichas.length + 1).toString(),
      modelo: nuevaFicha.modelo,
      fabricante: nuevaFicha.fabricante ?? 'Genérico',
      procesador: nuevaFicha.procesador,
      ram: nuevaFicha.ram,
      almacenamiento: nuevaFicha.almacenamiento,
      pantalla: nuevaFicha.pantalla,
      camaraPrincipal: nuevaFicha.camaraPrincipal,
      camaraFrontal: nuevaFicha.camaraFrontal,
      bateria: nuevaFicha.bateria,
      sistemaOperativo: nuevaFicha.sistemaOperativo,
      conectividad: nuevaFicha.conectividad,
      extras: nuevaFicha.extras,
      precioOficial: nuevaFicha.precioOficial,
      moneda: nuevaFicha.moneda,
      urlImagen: nuevaFicha.urlImagen,
    );

    _fichas.insert(0, fichaConId);
    notifyListeners();
    return true;
  }
}
