-- ==============================================================================
-- Certamen 2 - Inteligencia de Negocios (Mueblería Albarrán)
-- Script 02: Creación de la Base de Datos Dimensional (Albarran_DW)
-- Motor: Microsoft SQL Server 2022
-- Metodología: Ralph Kimball (Esquema Estrella)
-- ==============================================================================

-- 1. Creación de la Base de Datos Dimensional
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Albarran_DW')
BEGIN
    CREATE DATABASE Albarran_DW;
    PRINT '>> Base de datos Albarran_DW creada exitosamente.';
END
ELSE
BEGIN
    PRINT '>> La base de datos Albarran_DW ya existe.';
END
GO

USE Albarran_DW;
GO

-- 2. Limpieza de tablas previas (en orden inverso de dependencias FK)
IF OBJECT_ID(N'dbo.Fact_Ventas', N'U') IS NOT NULL DROP TABLE dbo.Fact_Ventas;
IF OBJECT_ID(N'dbo.Dim_Tiempo', N'U') IS NOT NULL DROP TABLE dbo.Dim_Tiempo;
IF OBJECT_ID(N'dbo.Dim_Cliente', N'U') IS NOT NULL DROP TABLE dbo.Dim_Cliente;
IF OBJECT_ID(N'dbo.Dim_Empleado', N'U') IS NOT NULL DROP TABLE dbo.Dim_Empleado;
IF OBJECT_ID(N'dbo.Dim_Producto', N'U') IS NOT NULL DROP TABLE dbo.Dim_Producto;
IF OBJECT_ID(N'dbo.Dim_Sucursal', N'U') IS NOT NULL DROP TABLE dbo.Dim_Sucursal;
GO

-- ==============================================================================
-- 3. Creación de Tablas Dimensionales
-- ==============================================================================

-- 3.1 Dim_Cliente
CREATE TABLE dbo.Dim_Cliente (
    Cliente_SK          INT IDENTITY(1,1) NOT NULL,
    Cliente_BK          INT NOT NULL,
    Nombre_Completo     VARCHAR(150) NOT NULL,
    Sexo                VARCHAR(20) NOT NULL,
    Fecha_Nacimiento    DATE NULL,
    Estado_Civil        VARCHAR(50) NULL,
    CONSTRAINT PK_Dim_Cliente PRIMARY KEY CLUSTERED (Cliente_SK)
);
GO

-- 3.2 Dim_Empleado (Desnormaliza Cargo)
CREATE TABLE dbo.Dim_Empleado (
    Empleado_SK         INT IDENTITY(1,1) NOT NULL,
    Empleado_BK         INT NOT NULL,
    Nombre_Completo     VARCHAR(150) NOT NULL,
    Nombre_Cargo        VARCHAR(100) NOT NULL,
    Sueldo_Base         NUMERIC(12,2) NULL,
    Fecha_Contrato      DATE NULL,
    CONSTRAINT PK_Dim_Empleado PRIMARY KEY CLUSTERED (Empleado_SK)
);
GO

-- 3.3 Dim_Producto (Desnormaliza Categoría)
CREATE TABLE dbo.Dim_Producto (
    Producto_SK         INT IDENTITY(1,1) NOT NULL,
    Producto_BK         INT NOT NULL,
    Nombre_Producto     VARCHAR(100) NOT NULL,
    Nombre_Categoria    VARCHAR(100) NOT NULL,
    Precio_Catalogo     NUMERIC(12,2) NOT NULL,
    Descripcion         VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Dim_Producto PRIMARY KEY CLUSTERED (Producto_SK)
);
GO

-- 3.4 Dim_Sucursal (Desnormaliza Comuna)
CREATE TABLE dbo.Dim_Sucursal (
    Sucursal_SK         INT IDENTITY(1,1) NOT NULL,
    Sucursal_BK         INT NOT NULL,
    Nombre_Sucursal     VARCHAR(100) NOT NULL,
    Nombre_Comuna       VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Dim_Sucursal PRIMARY KEY CLUSTERED (Sucursal_SK)
);
GO

-- 3.5 Dim_Tiempo (Clave numérica en formato YYYYMMDD)
CREATE TABLE dbo.Dim_Tiempo (
    Fecha_SK            INT NOT NULL,
    Fecha               DATE NOT NULL,
    Anio                INT NOT NULL,
    Semestre            TINYINT NOT NULL,
    Trimestre           TINYINT NOT NULL,
    Mes                 TINYINT NOT NULL,
    Nombre_Mes          NVARCHAR(20) NOT NULL,
    Dia                 TINYINT NOT NULL,
    Dia_Semana          TINYINT NOT NULL,
    Nombre_Dia_Semana   NVARCHAR(20) NOT NULL,
    Es_Fin_De_Semana    BIT NOT NULL,
    CONSTRAINT PK_Dim_Tiempo PRIMARY KEY CLUSTERED (Fecha_SK)
);
GO

-- ==============================================================================
-- 4. Creación de la Tabla de Hechos (Fact_Ventas)
-- ==============================================================================
CREATE TABLE dbo.Fact_Ventas (
    Venta_SK            BIGINT IDENTITY(1,1) NOT NULL,
    Fecha_SK            INT NOT NULL,
    Cliente_SK          INT NOT NULL,
    Empleado_SK         INT NOT NULL,
    Producto_SK         INT NOT NULL,
    Sucursal_SK         INT NOT NULL,
    Venta_ID            INT NOT NULL, -- Dimensión Degenerada (ID transacción origen)
    Cantidad            INT NOT NULL,
    Precio_Unitario     NUMERIC(12,2) NOT NULL,
    Monto_Bruto         NUMERIC(14,2) NOT NULL,
    Porcentaje_Descuento NUMERIC(5,4) NOT NULL CONSTRAINT DF_Fact_Ventas_Descuento DEFAULT 0.0,
    Monto_Descuento     NUMERIC(14,2) NOT NULL CONSTRAINT DF_Fact_Ventas_MontoDesc DEFAULT 0.0,
    Monto_Neto          NUMERIC(14,2) NOT NULL,
    CONSTRAINT PK_Fact_Ventas PRIMARY KEY CLUSTERED (Venta_SK),
    CONSTRAINT FK_Fact_Ventas_Dim_Tiempo FOREIGN KEY (Fecha_SK) REFERENCES dbo.Dim_Tiempo(Fecha_SK),
    CONSTRAINT FK_Fact_Ventas_Dim_Cliente FOREIGN KEY (Cliente_SK) REFERENCES dbo.Dim_Cliente(Cliente_SK),
    CONSTRAINT FK_Fact_Ventas_Dim_Empleado FOREIGN KEY (Empleado_SK) REFERENCES dbo.Dim_Empleado(Empleado_SK),
    CONSTRAINT FK_Fact_Ventas_Dim_Producto FOREIGN KEY (Producto_SK) REFERENCES dbo.Dim_Producto(Producto_SK),
    CONSTRAINT FK_Fact_Ventas_Dim_Sucursal FOREIGN KEY (Sucursal_SK) REFERENCES dbo.Dim_Sucursal(Sucursal_SK)
);
GO

-- ==============================================================================
-- 5. Índices Analíticos No Agrupados para Optimización de Consultas (OLAP)
-- ==============================================================================
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_Fecha_SK ON dbo.Fact_Ventas(Fecha_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_Cliente_SK ON dbo.Fact_Ventas(Cliente_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_Empleado_SK ON dbo.Fact_Ventas(Empleado_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_Producto_SK ON dbo.Fact_Ventas(Producto_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_Sucursal_SK ON dbo.Fact_Ventas(Sucursal_SK);
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_Venta_ID ON dbo.Fact_Ventas(Venta_ID);
GO

-- ==============================================================================
-- 6. Inserción de Miembros Desconocidos / Sin Información (SK = -1)
-- Best practice de Ralph Kimball para manejo de nulos en integridad referencial
-- ==============================================================================

-- 6.1 Dim_Cliente (-1)
SET IDENTITY_INSERT dbo.Dim_Cliente ON;
INSERT INTO dbo.Dim_Cliente (Cliente_SK, Cliente_BK, Nombre_Completo, Sexo, Fecha_Nacimiento, Estado_Civil)
VALUES (-1, -1, 'Cliente No Informado', 'No Informado', NULL, 'No Informado');
SET IDENTITY_INSERT dbo.Dim_Cliente OFF;
GO

-- 6.2 Dim_Empleado (-1)
SET IDENTITY_INSERT dbo.Dim_Empleado ON;
INSERT INTO dbo.Dim_Empleado (Empleado_SK, Empleado_BK, Nombre_Completo, Nombre_Cargo, Sueldo_Base, Fecha_Contrato)
VALUES (-1, -1, 'Empleado No Informado', 'Sin Cargo', NULL, NULL);
SET IDENTITY_INSERT dbo.Dim_Empleado OFF;
GO

-- 6.3 Dim_Producto (-1)
SET IDENTITY_INSERT dbo.Dim_Producto ON;
INSERT INTO dbo.Dim_Producto (Producto_SK, Producto_BK, Nombre_Producto, Nombre_Categoria, Precio_Catalogo, Descripcion)
VALUES (-1, -1, 'Producto No Informado', 'Sin Categoría', 0.0, 'Sin descripción');
SET IDENTITY_INSERT dbo.Dim_Producto OFF;
GO

-- 6.4 Dim_Sucursal (-1)
SET IDENTITY_INSERT dbo.Dim_Sucursal ON;
INSERT INTO dbo.Dim_Sucursal (Sucursal_SK, Sucursal_BK, Nombre_Sucursal, Nombre_Comuna)
VALUES (-1, -1, 'Sucursal No Informada', 'Sin Comuna');
SET IDENTITY_INSERT dbo.Dim_Sucursal OFF;
GO

-- 6.5 Dim_Tiempo (-1)
INSERT INTO dbo.Dim_Tiempo (Fecha_SK, Fecha, Anio, Semestre, Trimestre, Mes, Nombre_Mes, Dia, Dia_Semana, Nombre_Dia_Semana, Es_Fin_De_Semana)
VALUES (-1, '1900-01-01', 1900, 1, 1, 1, N'No Informado', 1, 1, N'No Informado', 0);
GO

PRINT '>> Modelo dimensional Albarran_DW creado exitosamente con sus tablas, restricciones, índices y miembros desconocidos.';
GO
