import 'package:flutter_test/flutter_test.dart';
import 'package:fichaai_mobile/models/ficha_model.dart';

void main() {
  group('FichaModel Unit Tests', () {
    test('toJson incluye campos opcionales solo si no son nulos', () {
      final ficha = FichaModel(
        modelo: 'Test Model',
        precioOficial: 500.0,
      );
      
      final json = ficha.toJson();
      
      expect(json['modelo'], 'Test Model');
      expect(json['precio_oficial'], 500.0);
      expect(json.containsKey('fabricante'), isFalse);
      expect(json.containsKey('url_imagen'), isFalse);
    });

    test('fromJson asigna valores por defecto correctamente', () {
      final json = {
        'modelo': 'Test Model',
      };
      
      final ficha = FichaModel.fromJson(json);
      
      expect(ficha.modelo, 'Test Model');
      expect(ficha.moneda, 'USD'); // Valor por defecto
      expect(ficha.sincronizado, isTrue); // Valor por defecto
    });

    test('copyWith mantiene los valores originales si no se proporcionan nuevos', () {
      final ficha = FichaModel(
        modelo: 'Test Model',
        precioOficial: 500.0,
      );
      
      final copia = ficha.copyWith(precioOficial: 600.0);
      
      expect(copia.modelo, 'Test Model');
      expect(copia.precioOficial, 600.0);
      expect(copia.idLocal, ficha.idLocal); // Se mantiene
    });
  });
}
