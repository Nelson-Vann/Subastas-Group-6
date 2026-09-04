========================================================================
BASE DE DATOS: PLATAFORMA DE SUBASTAS PRIVADAS (SubastasPrivadas_DB)
========================================================================

DESCRIPCION DEL PROYECTO:
-------------------------
Este repositorio contiene el script DDL de creacion y carga inicial de datos,
junto con la documentacion del modelo relacional desarrollado en SQL Server
para la gestion de subastas privadas.


ENTIDADES PRINCIPALES:
----------------------
1. Usuarios: Almacena la informacion de postores, vendedores y administradores.
2. Categorias: Clasificacion general de los lotes y bienes a subastar.
3. Articulos: Catalogo de bienes o lotes registrados por los vendedores.
4. Subastas: Registro de eventos de subasta activos, fechas de vigencia y precio actual.
5. Pujas: Historial detallado de ofertas en tiempo real enviadas por los postores.
6. Certificados: Documentacion y codigo unico de verificacion emitido al ganador.


ESTRUCTURA DE ARCHIVOS EN EL REPOSITORIO:
-----------------------------------------
- schema.sql    : Script SQL para crear la base de datos, tablas, relaciones e insertar datos.
- diagrama.png  : Captura de pantalla del Diagrama Entidad-Relacion (ER).
- README.txt    : Documentacion general del proyecto en texto plano.


INSTRUCCIONES DE EJECUCION:
---------------------------
1. Abrir SQL Server Management Studio (SSMS).
2. Conectarse a la instancia local de SQL Server.
3. Abrir el archivo "schema.sql".
4. Ejecutar el script (Tecla F5).

========================================================================
