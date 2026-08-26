class FichaModel {
  final String? idFicha;
  final String modelo;
  final String? fabricante;
  final String? procesador;
  final String? ram;
  final String? almacenamiento;
  final String? pantalla;
  final String? camaraPrincipal;
  final String? camaraFrontal;
  final String? bateria;
  final String? sistemaOperativo;
  final String? conectividad;
  final String? extras;
  final double? precioOficial;
  final String moneda;
  final String? urlImagen;

  const FichaModel({
    this.idFicha,
    required this.modelo,
    this.fabricante,
    this.procesador,
    this.ram,
    this.almacenamiento,
    this.pantalla,
    this.camaraPrincipal,
    this.camaraFrontal,
    this.bateria,
    this.sistemaOperativo,
    this.conectividad,
    this.extras,
    this.precioOficial,
    this.moneda = 'USD',
    this.urlImagen,
  });

  factory FichaModel.fromJson(Map<String, dynamic> json) {
    return FichaModel(
      idFicha: json['id_ficha']?.toString(),
      modelo: json['modelo'] ?? 'Dispositivo desconocido',
      fabricante: json['fabricante'],
      procesador: json['procesador'],
      ram: json['ram'],
      almacenamiento: json['almacenamiento'],
      pantalla: json['pantalla'],
      camaraPrincipal: json['camara_principal'],
      camaraFrontal: json['camara_frontal'],
      bateria: json['bateria'],
      sistemaOperativo: json['sistema_operativo'],
      conectividad: json['conectividad'],
      extras: json['extras'],
      precioOficial: json['precio_oficial'] != null
          ? double.tryParse(json['precio_oficial'].toString())
          : null,
      moneda: json['moneda'] ?? 'USD',
      urlImagen: json['url_imagen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idFicha != null) 'id_ficha': idFicha,
      'modelo': modelo,
      if (fabricante != null) 'fabricante': fabricante,
      if (procesador != null) 'procesador': procesador,
      if (ram != null) 'ram': ram,
      if (almacenamiento != null) 'almacenamiento': almacenamiento,
      if (pantalla != null) 'pantalla': pantalla,
      if (camaraPrincipal != null) 'camara_principal': camaraPrincipal,
      if (camaraFrontal != null) 'camara_frontal': camaraFrontal,
      if (bateria != null) 'bateria': bateria,
      if (sistemaOperativo != null) 'sistema_operativo': sistemaOperativo,
      if (conectividad != null) 'conectividad': conectividad,
      if (extras != null) 'extras': extras,
      if (precioOficial != null) 'precio_oficial': precioOficial,
      'moneda': moneda,
      if (urlImagen != null) 'url_imagen': urlImagen,
    };
  }
}
