import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fichaai_mobile/screens/listado_fichas_screen.dart';
import 'package:fichaai_mobile/providers/ficha_provider.dart';
import 'package:fichaai_mobile/providers/auth_provider.dart';
import 'package:fichaai_mobile/services/connectivity_service.dart';
import 'package:fichaai_mobile/services/sync_service.dart';
import 'package:fichaai_mobile/models/ficha_model.dart';
import 'package:fichaai_mobile/components/vista_estado.dart';
import 'package:fichaai_mobile/theme/tokens_app.dart';

class MockFichaProvider extends Mock implements FichaProvider {}
class MockAuthProvider extends Mock implements AuthProvider {}
class MockConnectivity extends Mock implements ConnectivityService {}
class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockFichaProvider mockFichaProvider;
  late MockAuthProvider mockAuthProvider;
  late MockConnectivity mockConnectivity;
  late MockSyncService mockSyncService;

  setUp(() {
    mockFichaProvider = MockFichaProvider();
    mockAuthProvider = MockAuthProvider();
    mockConnectivity = MockConnectivity();
    mockSyncService = MockSyncService();

    when(() => mockFichaProvider.fichas).thenReturn([]);
    when(() => mockFichaProvider.mensajeError).thenReturn('');
    when(() => mockFichaProvider.ultimaSincronizacion).thenReturn(DateTime.now());
    when(() => mockFichaProvider.estado).thenReturn(TipoVistaEstado.cargando);
    
    when(() => mockAuthProvider.estaAutenticado).thenReturn(true);
    when(() => mockAuthProvider.usuario).thenReturn('TestUser');
    
    when(() => mockConnectivity.estaConectado).thenReturn(true);
    
    when(() => mockSyncService.sincronizando).thenReturn(false);
    when(() => mockSyncService.operacionesPendientes).thenReturn(0);
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [
          TokensApp(
            espacioBase: 8,
            radioTarjeta: 12,
            duracionTransicion: Duration(milliseconds: 200),
          )
        ],
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<FichaProvider>.value(value: mockFichaProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<ConnectivityService>.value(value: mockConnectivity),
          ChangeNotifierProvider<SyncService>.value(value: mockSyncService),
        ],
        child: const ListadoFichasScreen(),
      ),
    );
  }

  group('ListadoFichasScreen Component Tests', () {
    testWidgets('Muestra lista de datos cuando hay datos', (WidgetTester tester) async {
      when(() => mockFichaProvider.estado).thenReturn(TipoVistaEstado.cargando);
      when(() => mockFichaProvider.fichas).thenReturn([
        FichaModel(idFicha: '1', modelo: 'Modelo Test A', fabricante: 'Fab A'),
        FichaModel(idFicha: '2', modelo: 'Modelo Test B', fabricante: 'Fab B'),
      ]);

      await tester.pumpWidget(buildTestableWidget());
      
      expect(find.text('Modelo Test A'), findsOneWidget);
      expect(find.text('Modelo Test B'), findsOneWidget);
    });
  });
}
