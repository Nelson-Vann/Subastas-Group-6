========================================================================
BASE DE DATOS: PLATAFORMA DE SUBASTAS PRIVADAS (SubastasPrivadas_DB)
========================================================================

DESCRIPCION GENERAL DEL PROYECTO:
---------------------------------
Este repositorio contiene la arquitectura completa de base de datos relacional
en SQL Server para la plataforma "SubastasPrivadas_DB", conformada por 25 tablas. 
El sistema contempla el ciclo completo de negocio: autenticacion, seguridad,
catalogo de articulos, motor de subastas, transacciones financieras, logistica,
calificaciones, disputas y auditoria.


ESTRUCTURA DE TABLAS Y RELACIONES POR MODULO:
---------------------------------------------

MODULO 1: ROLES, USUARIOS Y AUTENTICACION
-----------------------------------------
1. Roles
   - Llave Primaria: RolID
   - Relaciones: Se relaciona (1:N) con Usuarios.
2. Usuarios
   - Llave Primaria: UsuarioID
   - Llaves Foraneas: RolID -> Roles(RolID)
   - Relaciones: Se relaciona con Credenciales, HistorialSesiones, TokensRecuperacion,
     Articulos, Pujas, MetodosPago, Certificados, Ordenes, BilleteraVirtual, Direcciones,
     Notificaciones, Calificaciones, Disputas y LogsAuditoria.
3. Credenciales
   - Llave Primaria: CredencialID
   - Llaves Foraneas: UsuarioID -> Usuarios(UsuarioID) [1:1]
4. HistorialSesiones
   - Llave Primaria: SesionID
   - Llaves Foraneas: UsuarioID -> Usuarios(UsuarioID) [1:N]
5. TokensRecuperacion
   - Llave Primaria: TokenID
   - Llaves Foraneas: UsuarioID -> Usuarios(UsuarioID) [1:N]

MODULO 2: CATALOGO, CATEGORIAS Y ARTICULOS
------------------------------------------
6. Categorias
   - Llave Primaria: CategoriaID
   - Relaciones: Se relaciona (1:N) con Subcategorias.
7. Subcategorias
   - Llave Primaria: SubcategoriaID
   - Llaves Foraneas: CategoriaID -> Categorias(CategoriaID)
   - Relaciones: Se relaciona (1:N) con Articulos.
8. Articulos
   - Llave Primaria: ArticuloID
   - Llaves Foraneas: VendedorID -> Usuarios(UsuarioID), SubcategoriaID -> Subcategorias(SubcategoriaID)
   - Relaciones: Se relaciona (1:N) con ImagenesArticulo y Subastas.
9. ImagenesArticulo
   - Llave Primaria: ImagenID
   - Llaves Foraneas: ArticuloID -> Articulos(ArticuloID) [1:N]

MODULO 3: EVENTOS DE SUBASTA Y PUJAS
------------------------------------
10. Subastas
    - Llave Primaria: SubastaID
    - Llaves Foraneas: ArticuloID -> Articulos(ArticuloID)
    - Relaciones: Se relaciona (1:N) con Pujas, PujasAutomaticas, Favoritos y Certificados.
11. Pujas
    - Llave Primaria: PujaID
    - Llaves Foraneas: SubastaID -> Subastas(SubastaID), PostorID -> Usuarios(UsuarioID)
12. PujasAutomaticas
    - Llave Primaria: AutoPujaID
    - Llaves Foraneas: SubastaID -> Subastas(SubastaID), PostorID -> Usuarios(UsuarioID)
13. Favoritos
    - Llave Primaria: FavoritoID
    - Llaves Foraneas: UsuarioID -> Usuarios(UsuarioID), SubastaID -> Subastas(SubastaID)

MODULO 4: PAGOS, BILLETERA Y TRANSACCIONES
------------------------------------------
14. MetodosPago
    - Llave Primaria: MetodoPagoID
    - Llaves Foraneas: UsuarioID -> Usuarios(UsuarioID)
    - Relaciones: Se relaciona (1:N) con Transacciones.
15. Certificados
    - Llave Primaria: CertificadoID
    - Llaves Foraneas: SubastaID -> Subastas(SubastaID) [1:1], GanadorID -> Usuarios(UsuarioID)
    - Relaciones: Se relaciona (1:1) con Ordenes.
16. Ordenes
    - Llave Primaria: OrdenID
    - Llaves Foraneas: CertificadoID -> Certificados(CertificadoID), CompradorID -> Usuarios(UsuarioID)
    - Relaciones: Se relaciona (1:N) con Transacciones, Envios, Calificaciones y Disputas.
17. Transacciones
    - Llave Primaria: TransaccionID
    - Llaves Foraneas: OrdenID -> Ordenes(OrdenID), MetodoPagoID -> MetodosPago(MetodoPagoID)
18. BilleteraVirtual
    - Llave Primaria: BilleteraID
    - Llaves Foraneas: UsuarioID -> Usuarios(UsuarioID) [1:1]

MODULO 5: LOGISTICA, RECLAMOS Y AUDITORIA
-----------------------------------------
19. Direcciones
    - Llave Primaria: DireccionID
    - Llaves Foraneas: UsuarioID -> Usuarios(UsuarioID)
    - Relaciones: Se relaciona (1:N) con Envios.
20. Envios
    - Llave Primaria: EnvioID
    - Llaves Foraneas: OrdenID -> Ordenes(OrdenID) [1:1], DireccionID -> Direcciones(DireccionID)
21. Notificaciones
    - Llave Primaria: NotificacionID
    - Llaves Foraneas: UsuarioID -> Usuarios(UsuarioID)
22. Calificaciones
    - Llave Primaria: CalificacionID
    - Llaves Foraneas: OrdenID -> Ordenes(OrdenID) [1:1], CalificadorID -> Usuarios(UsuarioID), CalificadoID -> Usuarios(UsuarioID)
23. Disputas
    - Llave Primaria: DisputaID
    - Llaves Foraneas: OrdenID -> Ordenes(OrdenID), ReclamanteID -> Usuarios(UsuarioID)
24. LogsAuditoria
    - Llave Primaria: LogID
    - Llaves Foraneas: UsuarioID -> Usuarios(UsuarioID)
25. ParametrosSistema
    - Llave Primaria: ParametroID
    - Nota: Tabla de configuracion global en patron Clave-Valor (Aislada por diseno sin FKs).


ESTRUCTURA DE ARCHIVOS EN EL REPOSITORIO:
-----------------------------------------
- schema.sql                       : Script DDL completo de creacion de las 25 tablas e insercion de datos.
- diagrama.png                     : Diagrama Entidad-Relacion (ER) exportado desde SSMS.
- SubastasPrivadas-DB_README.txt   : Documentacion detallada del sistema en texto plano.


INSTRUCCIONES DE EJECUCION:
---------------------------
1. Abrir SQL Server Management Studio (SSMS).
2. Conectarse a la instancia activa de SQL Server.
3. Abrir y ejecutar el archivo "schema.sql" (Tecla F5).
4. El script recreara la base de datos "SubastasPrivadas_DB", sus 25 tablas, relaciones y datos de prueba.

========================================================================
