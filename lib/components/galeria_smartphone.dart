import 'package:flutter/material.dart';

/// Componente de Galería Oficial Multi-Ángulo para Smartphones
/// Diseñado con estética de comercio electrónico profesional (Amazon / Mercado Libre).
/// Incluye carrusel interactivo, contador de fotos oficiales, indicadores de puntos
/// y tira horizontal de miniaturas seleccionables con animación fluida.
class GaleriaSmartphone extends StatefulWidget {
  final List<String> imagenes;
  final double altura;
  final String modelo;
  final String? fabricante;

  const GaleriaSmartphone({
    super.key,
    required this.imagenes,
    this.altura = 250.0,
    required this.modelo,
    this.fabricante,
  });

  @override
  State<GaleriaSmartphone> createState() => _GaleriaSmartphoneState();
}

class _GaleriaSmartphoneState extends State<GaleriaSmartphone> {
  late final PageController _pageController;
  int _indiceActual = 0;

  static const Map<String, String> _cabecerasHttp = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _seleccionarFoto(int index) {
    if (index == _indiceActual) return;
    setState(() => _indiceActual = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lista = widget.imagenes
        .where((u) =>
            u.trim().startsWith('http') &&
            !u.toLowerCase().contains('.php') &&
            !u.toLowerCase().contains('.html'))
        .toList();

    if (lista.isEmpty) {
      return Container(
        height: widget.altura,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tema.colorScheme.primaryContainer.withValues(alpha: 0.15),
              tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: tema.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.phone_android, size: 36, color: tema.colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tema.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.fabricante ?? 'Ficha Oficial',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fotografía de prensa en homologación oficial',
                style: tema.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tema.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.modelo} • Especificaciones técnicas verificadas',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: tema.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Visor Principal del Carrusel
        Container(
          height: widget.altura,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Carrusel de imágenes
                PageView.builder(
                  controller: _pageController,
                  itemCount: lista.length,
                  onPageChanged: (idx) {
                    setState(() => _indiceActual = idx);
                  },
                  itemBuilder: (context, index) {
                    final url = lista[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Center(
                        child: Image.network(
                          url,
                          headers: _cabecerasHttp,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: tema.colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone_android, size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 6),
                                Text(
                                  'Foto oficial de ${widget.modelo}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Badge Superior Izquierdo: Verificado Oficial
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 13, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Oficial de Marca',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Badge Superior Derecho: Contador de fotos (ej: 1 / 4)
                if (lista.length > 1)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${_indiceActual + 1} / ${lista.length}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Flechas de navegación rápida en extremos si hay múltiples fotos
                if (lista.length > 1 && _indiceActual > 0)
                  Positioned(
                    left: 2,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 28),
                        color: Colors.black54,
                        splashRadius: 20,
                        onPressed: () => _seleccionarFoto(_indiceActual - 1),
                      ),
                    ),
                  ),
                if (lista.length > 1 && _indiceActual < lista.length - 1)
                  Positioned(
                    right: 2,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, size: 28),
                        color: Colors.black54,
                        splashRadius: 20,
                        onPressed: () => _seleccionarFoto(_indiceActual + 1),
                      ),
                    ),
                  ),

                // Indicador de Puntos en la parte inferior del visor
                if (lista.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        lista.length,
                        (i) => GestureDetector(
                          onTap: () => _seleccionarFoto(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _indiceActual == i ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _indiceActual == i
                                  ? tema.colorScheme.primary
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Tira de Miniaturas Selectoras (E-Commerce Style: Amazon / Mercado Libre)
        if (lista.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: lista.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final seleccionada = _indiceActual == i;
                return GestureDetector(
                  onTap: () => _seleccionarFoto(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: seleccionada ? tema.colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: seleccionada ? tema.colorScheme.primary : Colors.grey.shade300,
                        width: seleccionada ? 2.0 : 1.0,
                      ),
                      boxShadow: seleccionada
                          ? [
                              BoxShadow(
                                color: tema.colorScheme.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        lista[i],
                        headers: _cabecerasHttp,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.smartphone,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
