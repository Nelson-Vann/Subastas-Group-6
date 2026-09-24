USE SubastasPrivadas_DB;
GO

PRINT '====================================================================';
PRINT 'LIMPIEZA DE DATOS PREVIOS Y CARGA MASIVA (SEED DATA)';
PRINT '====================================================================';

-- 0. LIMPIEZA DE TABLAS EN ORDEN INVERSO A SUS DEPENDENCIAS
DELETE FROM LogsAuditoria;
DELETE FROM Disputas;
DELETE FROM Calificaciones;
DELETE FROM Notificaciones;
DELETE FROM Envios;
DELETE FROM Direcciones;
DELETE FROM Transacciones;
DELETE FROM Ordenes;
DELETE FROM Certificados;
DELETE FROM MetodosPago;
DELETE FROM Favoritos;
DELETE FROM PujasAutomaticas;
DELETE FROM Pujas;
DELETE FROM Subastas;
DELETE FROM ImagenesArticulo;
DELETE FROM Articulos;
DELETE FROM Subcategorias;
DELETE FROM Categorias;
DELETE FROM TokensRecuperacion;
DELETE FROM HistorialSesiones;
DELETE FROM BilleteraVirtual;
DELETE FROM Credenciales;
DELETE FROM Usuarios;
DELETE FROM Roles;

-- Reestablecer contadores IDENTITY
DBCC CHECKIDENT ('Roles', RESEED, 0);
DBCC CHECKIDENT ('Usuarios', RESEED, 0);
DBCC CHECKIDENT ('Categorias', RESEED, 0);
DBCC CHECKIDENT ('Subcategorias', RESEED, 0);
DBCC CHECKIDENT ('Articulos', RESEED, 0);
DBCC CHECKIDENT ('Subastas', RESEED, 0);
DBCC CHECKIDENT ('Pujas', RESEED, 0);
DBCC CHECKIDENT ('Ordenes', RESEED, 0);
DBCC CHECKIDENT ('Certificados', RESEED, 0);
DBCC CHECKIDENT ('MetodosPago', RESEED, 0);
DBCC CHECKIDENT ('Direcciones', RESEED, 0);
GO

-- 1. Roles (IDs: 1=Admin, 2=Vendedor, 3=Comprador, 4=Auditor)
INSERT INTO Roles (NombreRol, Descripcion) VALUES 
('Administrador', 'Control total del sistema y gestion de parametros'),
('Vendedor', 'Usuario autorizado para publicar articulos en subasta'),
('Comprador', 'Cliente registrado para realizar ofertas'),
('Auditor', 'Revisor de transacciones, logistica y disputas');

-- 2. Usuarios
INSERT INTO Usuarios (RolID, Nombre, Apellido, Correo, Telefono, EstadoCuenta) VALUES
-- Administradores (IDs 1, 2)
(1, 'Nelson', 'Tajín', 'ntajin@subastas.com', '55551111', 'Activo'),
(1, 'Darvin', 'Sinay', 'dsinay@subastas.com', '55552222', 'Activo'),

-- Auditor (ID 3)
(4, 'Rafael', 'Zeta', 'rzeta@subastas.com', '55553333', 'Activo'),

-- Vendedores (IDs 4, 5, 6)
(2, 'Galeria', 'Arte & Historia', 'contacto@artegaleria.com', '22221111', 'Activo'),
(2, 'Importadora', 'Lujo GT', 'ventas@lujogt.com', '22222222', 'Activo'),
(2, 'Subastas', 'Exclusivas GT', 'contacto@subastasgt.com', '22223333', 'Activo'),

-- Compradores / Clientes (IDs 7 al 16)
(3, 'Hector', 'Luna', 'hluna@cliente.com', '55554444', 'Activo'),
(3, 'Carlos', 'Mendoza', 'cmendoza@cliente.com', '55555555', 'Activo'),
(3, 'Sofia', 'Ramirez', 'sramirez@cliente.com', '55556666', 'Activo'),
(3, 'Andrea', 'Gomez', 'agomez@cliente.com', '55557777', 'Activo'),
(3, 'Luis', 'Hernandez', 'lhernandez@cliente.com', '55558888', 'Activo'),
(3, 'Maria', 'Morales', 'mmorales@cliente.com', '55559999', 'Activo'),
(3, 'Javier', 'Lopez', 'jlopez@cliente.com', '55550000', 'Activo'),
(3, 'Lucia', 'Castillo', 'lcastillo@cliente.com', '55551234', 'Activo'),
(3, 'Diego', 'Alvarez', 'dalvarez@cliente.com', '55552345', 'Activo'),
(3, 'Elena', 'Velasquez', 'evelasquez@cliente.com', '55553456', 'Activo');

-- 3. Credenciales
INSERT INTO Credenciales (UsuarioID, PasswordHash, PasswordSalt) VALUES
(1, 'hash_nelson', 'salt_nelson'), (2, 'hash_darvin', 'salt_darvin'), (3, 'hash_rafael', 'salt_rafael'),
(4, 'hash_vendedor1', 'salt_v1'), (5, 'hash_vendedor2', 'salt_v2'), (6, 'hash_vendedor3', 'salt_v3'),
(7, 'hash_hector', 'salt_h'), (8, 'hash_carlos', 'salt_c'), (9, 'hash_sofia', 'salt_s'),
(10, 'hash_andrea', 'salt_a'), (11, 'hash_luis', 'salt_l'), (12, 'hash_maria', 'salt_m'),
(13, 'hash_javier', 'salt_j'), (14, 'hash_lucia', 'salt_lu'), (15, 'hash_diego', 'salt_d'),
(16, 'hash_elena', 'salt_e');

-- 4. BilleteraVirtual (Saldos para Compradores y Admins/Auditor)
INSERT INTO BilleteraVirtual (UsuarioID, SaldoDisponible, SaldoBloqueado) VALUES
(1, 0.00, 0.00), (2, 0.00, 0.00), (3, 0.00, 0.00),
(4, 0.00, 0.00), (5, 0.00, 0.00), (6, 0.00, 0.00),
(7, 50000.00, 0.00), (8, 120000.00, 0.00), (9, 85000.00, 0.00), (10, 45000.00, 0.00),
(11, 60000.00, 0.00), (12, 90000.00, 0.00), (13, 30000.00, 0.00), (14, 75000.00, 0.00),
(15, 110000.00, 0.00), (16, 95000.00, 0.00);

-- 5. HistorialSesiones
INSERT INTO HistorialSesiones (UsuarioID, DireccionIP, UserAgent, Exitoso) VALUES
(1, '192.168.1.10', 'Mozilla/5.0 (Windows NT 10.0)', 1),
(2, '192.168.1.11', 'Mozilla/5.0 (Windows NT 10.0)', 1),
(3, '192.168.1.12', 'Mozilla/5.0 (Windows NT 10.0)', 1),
(7, '190.56.20.15', 'Mozilla/5.0 (Macintosh)', 1),
(8, '186.15.10.4',  'Mozilla/5.0 (iPhone)', 1);

-- 6. TokensRecuperacion
INSERT INTO TokensRecuperacion (UsuarioID, TokenHash, FechaExpiracion, Utilizado) VALUES
(7, 'token_hash_hector', DATEADD(HOUR, 2, GETDATE()), 0),
(8, 'token_hash_carlos', DATEADD(HOUR, -1, GETDATE()), 1);

-- 7. Categorias
INSERT INTO Categorias (NombreCategoria, Descripcion) VALUES
('Arte y Antigüedades', 'Obras de arte clasico y objetos de coleccion historicos'),
('Vehículos Exclusivos', 'Autos clasicos, deportivos y de edicion limitada'),
('Relojería y Joyas', 'Relojes de alta gama y joyeria fina certificada'),
('Vinos y Licores', 'Botellas de cosecha especial y ediciones limitadas');

-- 8. Subcategorias
INSERT INTO Subcategorias (CategoriaID, NombreSubcategoria) VALUES
(1, 'Pinturas al Óleo'),
(1, 'Esculturas de Bronce'),
(2, 'Autos Clásicos de Colección'),
(2, 'Deportivos Modernos'),
(3, 'Relojes Suizos de Pulsera'),
(4, 'Vinos Gran Reserva');

-- 9. Articulos (Publicados por Vendedores IDs 4, 5, 6)
INSERT INTO Articulos (VendedorID, SubcategoriaID, Titulo, Descripcion, PrecioBase, EstadoConservacion) VALUES
(4, 1, 'Pintura Retrato del Siglo XVIII', 'Óleo sobre lienzo atribuido a escuela europea.', 15000.00, 'Excelente'),
(5, 3, 'Mustang Fastback 1967', 'Totalmente restaurado, motor V8 original.', 35000.00, 'Restaurado'),
(4, 5, 'Patek Philippe Calatrava Oro Rosa', 'Reloj automático con caja y papeles originales.', 22000.00, 'Como Nuevo'),
(6, 6, 'Château Margaux Cosecha 1982', 'Botella conservada en cava climatizada.', 3200.00, 'Sellado');

-- 10. ImagenesArticulo
INSERT INTO ImagenesArticulo (ArticuloID, URLImagen, EsPrincipal) VALUES
(1, 'https://subastas.com/img/art1_front.jpg', 1),
(2, 'https://subastas.com/img/mustang_side.jpg', 1),
(3, 'https://subastas.com/img/patek_dial.jpg', 1),
(4, 'https://subastas.com/img/wine_bottle.jpg', 1);

-- 11. Subastas
INSERT INTO Subastas (ArticuloID, FechaInicio, FechaFin, PrecioInicial, PrecioActual, IncrementoMinimo, Estado) VALUES
(1, GETDATE(), DATEADD(DAY, 5, GETDATE()), 15000.00, 17000.00, 1000.00, 'Activa'),
(2, GETDATE(), DATEADD(DAY, 3, GETDATE()), 35000.00, 39000.00, 2000.00, 'Activa'),
(3, DATEADD(DAY, -10, GETDATE()), DATEADD(DAY, -3, GETDATE()), 22000.00, 25000.00, 1000.00, 'Finalizada'),
(4, DATEADD(DAY, 1, GETDATE()), DATEADD(DAY, 8, GETDATE()), 3200.00, 3200.00, 200.00, 'Programada');

-- 12. Pujas (Realizadas por los Compradores: IDs 7 al 16)
INSERT INTO Pujas (SubastaID, PostorID, MontoOferta, FechaPuja) VALUES
(1, 7, 16000.00, DATEADD(HOUR, -5, GETDATE())),  -- Hector Luna
(1, 8, 17000.00, GETDATE()),                      -- Carlos Mendoza
(2, 9, 37000.00, DATEADD(HOUR, -2, GETDATE())),  -- Sofia Ramirez
(2, 10, 39000.00, GETDATE()),                     -- Andrea Gomez
(3, 11, 23000.00, DATEADD(DAY, -8, GETDATE())),  -- Luis Hernandez
(3, 8, 25000.00, DATEADD(DAY, -3, GETDATE()));   -- Carlos Mendoza (Ganador)

-- 13. PujasAutomaticas
INSERT INTO PujasAutomaticas (SubastaID, PostorID, MontoMaximo, Activo) VALUES
(1, 7, 20000.00, 1),
(2, 8, 45000.00, 1);

-- 14. Favoritos
INSERT INTO Favoritos (UsuarioID, SubastaID) VALUES
(7, 1), (8, 2), (9, 2), (10, 3);

-- 15. MetodosPago
INSERT INTO MetodosPago (UsuarioID, TipoMetodo, Proveedor, UltimosDigitos, EsPredeterminado) VALUES
(7, 'Tarjeta_Credito', 'BAC Credomatic', '4321', 1),
(8, 'Tarjeta_Debito', 'Banco Industrial', '8765', 1),
(9, 'Transferencia_Bancaria', 'Banrural', '1092', 1);

-- 16. Certificados (Carlos Mendoza ID=8 como ganador)
INSERT INTO Certificados (SubastaID, GanadorID, MontoFinal) VALUES
(3, 8, 25000.00);

-- 17. Ordenes
INSERT INTO Ordenes (CertificadoID, CompradorID, MontoSubtotal, MontoComision, MontoTotal, EstadoOrden) VALUES
(1, 8, 25000.00, 1250.00, 26250.00, 'Pagado');

-- 18. Transacciones
INSERT INTO Transacciones (OrdenID, MetodoPagoID, Monto, EstadoTransaccion, CodigoAutorizacion) VALUES
(1, 2, 26250.00, 'Aprobada', 'AUTH987654321');

-- 19. Direcciones
INSERT INTO Direcciones (UsuarioID, DireccionTexto, Ciudad, Departamento, CodigoPostal) VALUES
(7, '10a Calle 5-20 Zona 14', 'Guatemala', 'Guatemala', '01014'),
(8, 'Avenida Las Américas 12-45 Zona 13', 'Guatemala', 'Guatemala', '01013'),
(9, '5a Avenida 3-12', 'Antigua Guatemala', 'Sacatepéquez', '03001');

-- 20. Envios
INSERT INTO Envios (OrdenID, DireccionID, EmpresaTransporte, NumeroRastreo, EstadoEnvio, FechaEnvio) VALUES
(1, 2, 'DHL Express', 'DHL-GT-998877', 'En_Transito', GETDATE());

-- 21. Notificaciones
INSERT INTO Notificaciones (UsuarioID, Titulo, Mensaje) VALUES
(8, '¡Felicidades! Ganaste la subasta', 'Has ganado el reloj Patek Philippe Calatrava.'),
(7, 'Subasta superada', 'Otra persona ha realizado una oferta superior.');

-- 22. Calificaciones
INSERT INTO Calificaciones (OrdenID, CalificadorID, CalificadoID, Puntuacion, Comentario) VALUES
(1, 8, 4, 5, 'Excelente vendedor, articulo en perfectas condiciones.');

-- 23. Disputas
INSERT INTO Disputas (OrdenID, ReclamanteID, Motivo, Descripcion, EstadoDisputa) VALUES
(1, 8, 'Demora en envío', 'El envío tardó 2 días más de lo previsto.', 'Cerrada');

-- 24. LogsAuditoria
INSERT INTO LogsAuditoria (UsuarioID, Accion, TablaAfectada, Detalle) VALUES
(1, 'CARGA_INICIAL', 'Sistema', 'Carga masiva ejecutada por Administrador Nelson Tajín.'),
(2, 'CONFIGURACION', 'Parametros', 'Parametros del sistema verificados por Administrador Darvin Sinay.'),
(3, 'AUDITORIA', 'Transacciones', 'Auditoria de ordenes realizada por Auditor Rafael Zeta.');

-- 25. ParametrosSistema
IF NOT EXISTS (SELECT 1 FROM ParametrosSistema WHERE Clave = 'PorcentajeComision')
    INSERT INTO ParametrosSistema (Clave, Valor, Descripcion) VALUES ('PorcentajeComision', '0.05', 'Porcentaje de comision');

IF NOT EXISTS (SELECT 1 FROM ParametrosSistema WHERE Clave = 'IntentosMaximosLogin')
    INSERT INTO ParametrosSistema (Clave, Valor, Descripcion) VALUES ('IntentosMaximosLogin', '3', 'Intentos fallidos permitidos');

PRINT '--------------------------------------------------------------------';
PRINT '¡CARGA MASIVA FINALIZADA CON ÉXITO!';
PRINT '====================================================================';
GO