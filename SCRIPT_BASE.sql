
CREATE TABLE ROL (
    IdRol SERIAL PRIMARY KEY,
    Descripcion VARCHAR(50),
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE PERMISO (
    IdPermiso SERIAL PRIMARY KEY,
    IdRol INT REFERENCES ROL(IdRol),
    NombreMenu VARCHAR(100),
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE PROVEEDOR (
    IdProveedor SERIAL PRIMARY KEY,
    Documento VARCHAR(50),
    RazonSocial VARCHAR(50),
    Correo VARCHAR(50),
    Telefono VARCHAR(50),
    Estado BOOLEAN,
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE CLIENTE (
    IdCliente SERIAL PRIMARY KEY,
    Documento VARCHAR(50),
    NombreCompleto VARCHAR(50),
    Correo VARCHAR(50),
    Telefono VARCHAR(50),
    Estado BOOLEAN,
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE USUARIO (
    IdUsuario SERIAL PRIMARY KEY,
    Documento VARCHAR(50),
    NombreCompleto VARCHAR(50),
    Correo VARCHAR(50),
    Clave VARCHAR(50),
    IdRol INT REFERENCES ROL(IdRol),
    Estado BOOLEAN default TRUE,
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE CATEGORIA (
    IdCategoria SERIAL PRIMARY KEY,
    Descripcion VARCHAR(100),
    Estado BOOLEAN,
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE PRODUCTO (
    IdProducto SERIAL PRIMARY KEY,
    Codigo VARCHAR(50),
    Nombre VARCHAR(50),
    Descripcion VARCHAR(50),
    IdCategoria INT REFERENCES CATEGORIA(IdCategoria),
    Stock INT NOT NULL DEFAULT 0,
    PrecioCompra DECIMAL(10,2) DEFAULT 0,
    PrecioVenta DECIMAL(10,2) DEFAULT 0,
    Estado BOOLEAN,
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE COMPRA (
    IdCompra SERIAL PRIMARY KEY,
    IdUsuario INT REFERENCES USUARIO(IdUsuario),
    IdProveedor INT REFERENCES PROVEEDOR(IdProveedor),
    TipoDocumento VARCHAR(50),
    NumeroDocumento VARCHAR(50),
    MontoTotal DECIMAL(10,2),
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE DETALLE_COMPRA (
    IdDetalleCompra SERIAL PRIMARY KEY,
    IdCompra INT REFERENCES COMPRA(IdCompra),
    IdProducto INT REFERENCES PRODUCTO(IdProducto),
    PrecioCompra DECIMAL(10,2) DEFAULT 0,
    PrecioVenta DECIMAL(10,2) DEFAULT 0,
    Cantidad INT,
    MontoTotal DECIMAL(10,2),
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE VENTA (
    IdVenta SERIAL PRIMARY KEY,
    IdUsuario INT REFERENCES USUARIO(IdUsuario),
    TipoDocumento VARCHAR(50),
    NumeroDocumento VARCHAR(50),
    DocumentoCliente VARCHAR(50),
    NombreCliente VARCHAR(100),
    MontoPago DECIMAL(10,2),
    MontoCambio DECIMAL(10,2),
    MontoTotal DECIMAL(10,2),
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE DETALLE_VENTA (
    IdDetalleVenta SERIAL PRIMARY KEY,
    IdVenta INT REFERENCES VENTA(IdVenta),
    IdProducto INT REFERENCES PRODUCTO(IdProducto),
    PrecioVenta DECIMAL(10,2),
    Cantidad INT,
    SubTotal DECIMAL(10,2),
    FechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE NEGOCIO (
    IdNegocio INT PRIMARY KEY,
    Nombre VARCHAR(60),
    RUC VARCHAR(60),
    Direccion VARCHAR(60),
    Logo BYTEA NULL
);

/*************************** CREACION DE PROCEDIMIENTOS ALMACENADOS ***************************/
/*--------------------------------------------------------------------------------------------*/


CREATE OR REPLACE FUNCTION SP_REGISTRARUSUARIO(
    IN p_Documento VARCHAR(50),
    IN p_NombreCompleto VARCHAR(100),
    IN p_Correo VARCHAR(100),
    IN p_Clave VARCHAR(100),
    IN p_IdRol INT,
    IN p_Estado BOOLEAN,
    OUT p_IdUsuarioResultado INT,
    OUT p_Mensaje VARCHAR(500)
)
RETURNS VOID AS $$
BEGIN
    p_IdUsuarioResultado := 0;
    p_Mensaje := '';

    IF NOT EXISTS (SELECT * FROM USUARIO WHERE Documento = p_Documento) THEN
        INSERT INTO usuario(Documento, NombreCompleto, Correo, Clave, IdRol, Estado)
        VALUES (p_Documento, p_NombreCompleto, p_Correo, p_Clave, p_IdRol, p_Estado);

        p_IdUsuarioResultado := currval(pg_get_serial_sequence('usuario', 'idusuario'));
    ELSE
        p_Mensaje := 'No se puede repetir el documento para más de un usuario';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SP_EDITARUSUARIO(
    IN p_IdUsuario INT,
    IN p_Documento VARCHAR(50),
    IN p_NombreCompleto VARCHAR(100),
    IN p_Correo VARCHAR(100),
    IN p_Clave VARCHAR(100),
    IN p_IdRol INT,
    IN p_Estado BOOLEAN,
    OUT p_Respuesta BOOLEAN,
    OUT p_Mensaje VARCHAR(500)
)
RETURNS VOID AS $$
BEGIN
    p_Respuesta := FALSE;
    p_Mensaje := '';

    IF NOT EXISTS (SELECT * FROM USUARIO WHERE Documento = p_Documento AND idusuario != p_IdUsuario) THEN
        UPDATE usuario SET
        Documento = p_Documento,
        NombreCompleto = p_NombreCompleto,
        Correo = p_Correo,
        Clave = p_Clave,
        IdRol = p_IdRol,
        Estado = p_Estado
        WHERE IdUsuario = p_IdUsuario;

        p_Respuesta := TRUE;
    ELSE
        p_Mensaje := 'No se puede repetir el documento para más de un usuario';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SP_ELIMINARUSUARIO(
    IN p_IdUsuario INT,
    OUT p_Respuesta BOOLEAN,
    OUT p_Mensaje VARCHAR(500)
)
RETURNS VOID AS $$
DECLARE
    pasoreglas BOOLEAN := TRUE;
BEGIN
    p_Respuesta := FALSE;
    p_Mensaje := '';

    IF EXISTS (SELECT * FROM COMPRA C 
        INNER JOIN USUARIO U ON U.IdUsuario = C.IdUsuario
        WHERE U.IDUSUARIO = p_IdUsuario) THEN
        pasoreglas := FALSE;
        p_Respuesta := FALSE;
        p_Mensaje := p_Mensaje || 'No se puede eliminar porque el usuario se encuentra relacionado a una COMPRA\n';
    END IF;

    IF EXISTS (SELECT * FROM VENTA V
        INNER JOIN USUARIO U ON U.IdUsuario = V.IdUsuario
        WHERE U.IDUSUARIO = p_IdUsuario) THEN
        pasoreglas := FALSE;
        p_Respuesta := FALSE;
        p_Mensaje := p_Mensaje || 'No se puede eliminar porque el usuario se encuentra relacionado a una VENTA\n';
    END IF;

    IF pasoreglas THEN
        DELETE FROM USUARIO WHERE IdUsuario = p_IdUsuario;
        p_Respuesta := TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql;

/* ---------- PROCEDIMIENTOS PARA CATEGORIA -----------------*/
CREATE OR REPLACE FUNCTION SP_REGISTRARUSUARIO(
    p_Documento VARCHAR(50),
    p_NombreCompleto VARCHAR(100),
    p_Correo VARCHAR(100),
    p_Clave VARCHAR(100),
    p_IdRol INT,
    p_Estado BOOLEAN
)
RETURNS RECORD AS $$
DECLARE
    p_IdUsuarioResultado INT;
    p_Mensaje VARCHAR(500);
BEGIN
    p_IdUsuarioResultado := 0;
    p_Mensaje := '';

    IF NOT EXISTS (SELECT * FROM USUARIO WHERE Documento = p_Documento) THEN
        INSERT INTO usuario(Documento, NombreCompleto, Correo, Clave, IdRol, Estado)
        VALUES (p_Documento, p_NombreCompleto, p_Correo, p_Clave, p_IdRol, p_Estado);

        p_IdUsuarioResultado := currval(pg_get_serial_sequence('usuario', 'idusuario'));
    ELSE
        p_Mensaje := 'No se puede repetir el documento para más de un usuario';
    END IF;

    RETURN p_IdUsuarioResultado, p_Mensaje;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SP_EDITARUSUARIO(
    p_IdUsuario INT,
    p_Documento VARCHAR(50),
    p_NombreCompleto VARCHAR(100),
    p_Correo VARCHAR(100),
    p_Clave VARCHAR(100),
    p_IdRol INT,
    p_Estado BOOLEAN
)
RETURNS RECORD AS $$
DECLARE
    p_Respuesta BOOLEAN;
    p_Mensaje VARCHAR(500);
BEGIN
    p_Respuesta := FALSE;
    p_Mensaje := '';

    IF NOT EXISTS (SELECT * FROM USUARIO WHERE Documento = p_Documento AND idusuario != p_IdUsuario) THEN
        UPDATE usuario SET
        Documento = p_Documento,
        NombreCompleto = p_NombreCompleto,
        Correo = p_Correo,
        Clave = p_Clave,
        IdRol = p_IdRol,
        Estado = p_Estado
        WHERE IdUsuario = p_IdUsuario;

        p_Respuesta := TRUE;
    ELSE
        p_Mensaje := 'No se puede repetir el documento para más de un usuario';
    END IF;

    RETURN p_Respuesta, p_Mensaje;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SP_ELIMINARUSUARIO(
    p_IdUsuario INT
)
RETURNS RECORD AS $$
DECLARE
    p_Respuesta BOOLEAN;
    p_Mensaje VARCHAR(500);
    pasoreglas BOOLEAN := TRUE;
BEGIN
    p_Respuesta := FALSE;
    p_Mensaje := '';

    IF EXISTS (SELECT * FROM COMPRA C 
        INNER JOIN USUARIO U ON U.IdUsuario = C.IdUsuario
        WHERE U.IDUSUARIO = p_IdUsuario) THEN
        pasoreglas := FALSE;
        p_Respuesta := FALSE;
        p_Mensaje := p_Mensaje || 'No se puede eliminar porque el usuario se encuentra relacionado a una COMPRA\n';
    END IF;

    IF EXISTS (SELECT * FROM VENTA V
        INNER JOIN USUARIO U ON U.IdUsuario = V.IdUsuario
        WHERE U.IDUSUARIO = p_IdUsuario) THEN
        pasoreglas := FALSE;
        p_Respuesta := FALSE;
        p_Mensaje := p_Mensaje || 'No se puede eliminar porque el usuario se encuentra relacionado a una VENTA\n';
    END IF;

    IF pasoreglas THEN
        DELETE FROM USUARIO WHERE IdUsuario = p_IdUsuario;
        p_Respuesta := TRUE;
    END IF;

    RETURN p_Respuesta, p_Mensaje;
END;
$$ LANGUAGE plpgsql;


/* ---------- PROCEDIMIENTOS PARA PRODUCTO -----------------*/

CREATE OR REPLACE FUNCTION sp_RegistrarProducto(
    p_Codigo VARCHAR(20),
    p_Nombre VARCHAR(30),
    p_Descripcion VARCHAR(30),
    p_IdCategoria INT,
    p_Estado BOOLEAN
)
RETURNS RECORD AS $$
DECLARE
    p_Resultado INT;
    p_Mensaje VARCHAR(500);
BEGIN
    p_Resultado := 0;
    p_Mensaje := '';

    IF NOT EXISTS (SELECT * FROM producto WHERE Codigo = p_Codigo) THEN
        INSERT INTO producto(Codigo, Nombre, Descripcion, IdCategoria, Estado)
        VALUES (p_Codigo, p_Nombre, p_Descripcion, p_IdCategoria, p_Estado);

        p_Resultado := currval(pg_get_serial_sequence('producto', 'idproducto'));
    ELSE
        p_Mensaje := 'Ya existe un producto con el mismo código';
    END IF;

    RETURN p_Resultado, p_Mensaje;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_ModificarProducto(
    p_IdProducto INT,
    p_Codigo VARCHAR(20),
    p_Nombre VARCHAR(30),
    p_Descripcion VARCHAR(30),
    p_IdCategoria INT,
    p_Estado BOOLEAN
)
RETURNS RECORD AS $$
DECLARE
    p_Resultado BOOLEAN;
    p_Mensaje VARCHAR(500);
BEGIN
    p_Resultado := TRUE;
    p_Mensaje := '';

    IF NOT EXISTS (SELECT * FROM PRODUCTO WHERE codigo = p_Codigo AND IdProducto != p_IdProducto) THEN
        UPDATE PRODUCTO SET
        codigo = p_Codigo,
        Nombre = p_Nombre,
        Descripcion = p_Descripcion,
        IdCategoria = p_IdCategoria,
        Estado = p_Estado
        WHERE IdProducto = p_IdProducto;
    ELSE
        p_Resultado := FALSE;
        p_Mensaje := 'Ya existe un producto con el mismo código';
    END IF;

    RETURN p_Resultado, p_Mensaje;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SP_EliminarProducto(
    p_IdProducto INT
)
RETURNS RECORD AS $$
DECLARE
    p_Respuesta BOOLEAN;
    p_Mensaje VARCHAR(500);
    pasoreglas BOOLEAN := TRUE;
BEGIN
    p_Respuesta := FALSE;
    p_Mensaje := '';

    IF EXISTS (SELECT * FROM DETALLE_COMPRA dc 
        INNER JOIN PRODUCTO p ON p.IdProducto = dc.IdProducto
        WHERE p.IdProducto = p_IdProducto) THEN
        pasoreglas := FALSE;
        p_Respuesta := FALSE;
        p_Mensaje := p_Mensaje || 'No se puede eliminar porque se encuentra relacionado a una COMPRA\n';
    END IF;

    IF EXISTS (SELECT * FROM DETALLE_VENTA dv
        INNER JOIN PRODUCTO p ON p.IdProducto = dv.IdProducto
        WHERE p.IdProducto = p_IdProducto) THEN
        pasoreglas := FALSE;
        p_Respuesta := FALSE;
        p_Mensaje := p_Mensaje || 'No se puede eliminar porque se encuentra relacionado a una VENTA\n';
    END IF;

    IF pasoreglas THEN
        DELETE FROM PRODUCTO WHERE IdProducto = p_IdProducto;
        p_Respuesta := TRUE;
    END IF;

    RETURN p_Respuesta, p_Mensaje;
END;
$$ LANGUAGE plpgsql;

/* ---------- PROCEDIMIENTOS PARA CLIENTE -----------------*/

CREATE OR REPLACE FUNCTION sp_RegistrarCliente(
    p_Documento VARCHAR(50),
    p_NombreCompleto VARCHAR(50),
    p_Correo VARCHAR(50),
    p_Telefono VARCHAR(50),
    p_Estado BOOLEAN
)
RETURNS RECORD AS $$
DECLARE
    p_Resultado INT;
    p_Mensaje VARCHAR(500);
BEGIN
    p_Resultado := 0;
    p_Mensaje := '';

    IF NOT EXISTS (SELECT * FROM CLIENTE WHERE Documento = p_Documento) THEN
        INSERT INTO CLIENTE(Documento, NombreCompleto, Correo, Telefono, Estado)
        VALUES (p_Documento, p_NombreCompleto, p_Correo, p_Telefono, p_Estado);

        p_Resultado := currval(pg_get_serial_sequence('cliente', 'idcliente'));
    ELSE
        p_Mensaje := 'El número de documento ya existe';
    END IF;

    RETURN p_Resultado, p_Mensaje;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_ModificarCliente(
    p_IdCliente INT,
    p_Documento VARCHAR(50),
    p_NombreCompleto VARCHAR(50),
    p_Correo VARCHAR(50),
    p_Telefono VARCHAR(50),
    p_Estado BOOLEAN
)
RETURNS RECORD AS $$
DECLARE
    p_Resultado BOOLEAN;
    p_Mensaje VARCHAR(500);
BEGIN
    p_Resultado := TRUE;
    p_Mensaje := '';

    IF NOT EXISTS (SELECT * FROM CLIENTE WHERE Documento = p_Documento AND IdCliente != p_IdCliente) THEN
        UPDATE CLIENTE SET
        Documento = p_Documento,
        NombreCompleto = p_NombreCompleto,
        Correo = p_Correo,
        Telefono = p_Telefono,
        Estado = p_Estado
        WHERE IdCliente = p_IdCliente;
    ELSE
        p_Resultado := FALSE;
        p_Mensaje := 'El número de documento ya existe';
    END IF;

    RETURN p_Resultado, p_Mensaje;
END;
$$ LANGUAGE plpgsql;

/* PROCESOS PARA REGISTRAR UNA VENTA */

/*Tipo de Tabla para detalle de la venta*/
CREATE TYPE EDetalle_Venta AS (
    IdProducto INT,
    PrecioVenta DECIMAL(18,2),
    Cantidad INT,
    SubTotal DECIMAL(18,2)
);

/* Registrar venta */
/*
CREATE OR REPLACE FUNCTION usp_RegistrarVenta(
    p_IdUsuario INT,
    p_TipoDocumento VARCHAR(500),
    p_NumeroDocumento VARCHAR(500),
    p_DocumentoCliente VARCHAR(500),
    p_NombreCliente VARCHAR(500),
    p_MontoPago DECIMAL(18,2),
    p_MontoCambio DECIMAL(18,2),
    p_MontoTotal DECIMAL(18,2),
    p_DetalleVenta EDetalle_Venta[]
)
RETURNS TABLE (
    Resultado BIT,
    Mensaje VARCHAR(500)
) AS $$
DECLARE
    p_Resultado BOOLEAN;
    p_Mensaje VARCHAR(500);
BEGIN
    p_Resultado := TRUE;
    p_Mensaje := '';

    BEGIN
        SAVEPOINT registro;

        DECLARE
            p_IdVenta INT;
        BEGIN
            INSERT INTO VENTA(IdUsuario, TipoDocumento, NumeroDocumento, DocumentoCliente, NombreCliente, MontoPago, MontoCambio, MontoTotal)
            VALUES (p_IdUsuario, p_TipoDocumento, p_NumeroDocumento, p_DocumentoCliente, p_NombreCliente, p_MontoPago, p_MontoCambio, p_MontoTotal)
            RETURNING IdVenta INTO p_IdVenta;

            -- Construir la consulta dinámica
            EXECUTE 'INSERT INTO DETALLE_VENTA(IdVenta, IdProducto, PrecioVenta, Cantidad, SubTotal) '
                || 'VALUES ($1, $2, $3, $4, $5)'
            USING p_IdVenta, (p_DetalleVenta[i]).IdProducto, (p_DetalleVenta[i]).PrecioVenta, 
                  (p_DetalleVenta[i]).Cantidad, (p_DetalleVenta[i]).SubTotal;

            COMMIT;
            p_Resultado := TRUE;
            p_Mensaje := 'Venta registrada exitosamente.';
        EXCEPTION
            WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT registro;
    p_Resultado := FALSE;
    p_Mensaje := 'Error: ' || SQLERRM;

        END;
    END;

    RETURN (p_Resultado, p_Mensaje);
END;
$$ LANGUAGE plpgsql;

*/


/* Reporte de compras */
CREATE OR REPLACE FUNCTION sp_ReporteCompras(
    p_FechaInicio VARCHAR(10),
    p_FechaFin VARCHAR(10),
    p_IdProveedor INT
)
RETURNS TABLE (
    FechaRegistro VARCHAR(10),
    TipoDocumento VARCHAR(500),
    NumeroDocumento VARCHAR(500),
    MontoTotal DECIMAL(18,2),
    UsuarioRegistro VARCHAR(500),
    DocumentoProveedor VARCHAR(50),
    RazonSocial VARCHAR(50),
    CodigoProducto VARCHAR(50),
    NombreProducto VARCHAR(50),
    Categoria VARCHAR(100),
    PrecioCompra DECIMAL(10,2),
    PrecioVenta DECIMAL(10,2),
    Cantidad INT,
    SubTotal DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(c.FechaRegistro, 'DD/MM/YYYY') AS FechaRegistro,
        c.TipoDocumento,
        c.NumeroDocumento,
        c.MontoTotal,
        u.NombreCompleto AS UsuarioRegistro,
        pr.Documento AS DocumentoProveedor,
        pr.RazonSocial,
        p.Codigo AS CodigoProducto,
        p.Nombre AS NombreProducto,
        ca.Descripcion AS Categoria,
        dc.PrecioCompra,
        dc.PrecioVenta,
        dc.Cantidad,
        dc.MontoTotal AS SubTotal
    FROM COMPRA c
    INNER JOIN USUARIO u ON u.IdUsuario = c.IdUsuario
    INNER JOIN PROVEEDOR pr ON pr.IdProveedor = c.IdProveedor
    INNER JOIN DETALLE_COMPRA dc ON dc.IdCompra = c.IdCompra
    INNER JOIN PRODUCTO p ON p.IdProducto = dc.IdProducto
    INNER JOIN CATEGORIA ca ON ca.IdCategoria = p.IdCategoria
    WHERE TO_DATE(c.FechaRegistro, 'DD/MM/YYYY') BETWEEN TO_DATE(p_FechaInicio, 'DD/MM/YYYY') AND TO_DATE(p_FechaFin, 'DD/MM/YYYY')
    AND pr.IdProveedor = CASE WHEN p_IdProveedor = 0 THEN pr.IdProveedor ELSE p_IdProveedor END;
END;
$$ LANGUAGE plpgsql;

/*Reporte de ventas*/

CREATE OR REPLACE FUNCTION sp_ReporteVentas(
    p_FechaInicio VARCHAR(10),
    p_FechaFin VARCHAR(10)
)
RETURNS TABLE (
    FechaRegistro VARCHAR(10),
    TipoDocumento VARCHAR(500),
    NumeroDocumento VARCHAR(500),
    MontoTotal DECIMAL(18,2),
    UsuarioRegistro VARCHAR(500),
    DocumentoCliente VARCHAR(500),
    NombreCliente VARCHAR(100),
    CodigoProducto VARCHAR(50),
    NombreProducto VARCHAR(50),
    Categoria VARCHAR(100),
    PrecioVenta DECIMAL(10,2),
    Cantidad INT,
    SubTotal DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(v.FechaRegistro, 'DD/MM/YYYY') AS FechaRegistro,
        v.TipoDocumento,
        v.NumeroDocumento,
        v.MontoTotal,
        u.NombreCompleto AS UsuarioRegistro,
        v.DocumentoCliente,
        v.NombreCliente,
        p.Codigo AS CodigoProducto,
        p.Nombre AS NombreProducto,
        ca.Descripcion AS Categoria,
        dv.PrecioVenta,
        dv.Cantidad,
        dv.SubTotal
    FROM VENTA v
    INNER JOIN USUARIO u ON u.IdUsuario = v.IdUsuario
    INNER JOIN DETALLE_VENTA dv ON dv.IdVenta = v.IdVenta
    INNER JOIN PRODUCTO p ON p.IdProducto = dv.IdProducto
    INNER JOIN CATEGORIA ca ON ca.IdCategoria = p.IdCategoria
    WHERE TO_DATE(v.FechaRegistro, 'DD/MM/YYYY') BETWEEN TO_DATE(p_FechaInicio, 'DD/MM/YYYY') AND TO_DATE(p_FechaFin, 'DD/MM/YYYY');
END;
$$ LANGUAGE plpgsql;



/****************** INSERTAMOS REGISTROS A LAS TABLAS ******************/
/*---------------------------------------------------------------------*/

/* Insertar Roles */
INSERT INTO rol (Descripcion)
VALUES ('ADMINISTRADOR');

INSERT INTO rol (Descripcion)
VALUES ('EMPLEADO');

/* Insertar Usuarios */
INSERT INTO USUARIO(Documento,NombreCompleto,Correo,Clave,IdRol)
VALUES ('101010','ADMINISTRADOR','@GMAIL.COM','123',7);

INSERT INTO USUARIO(Documento,NombreCompleto,Correo,Clave,IdRol)
VALUES ('20','EMPLEADO','@GMAIL.COM','456',8);


/* Insertar permisos */
INSERT INTO PERMISO(IdRol,NombreMenu)
VALUES
    (7,'menuusuarios'),
    (7,'menumantenedor'),
    (7,'menuventas'),
    (7,'menucompras'),
    (7,'menuclientes'),
    (7,'menuproveedores'),
    (7,'menureportes'),
    (7,'menuacercade');

INSERT INTO PERMISO(IdRol,NombreMenu)
VALUES
    (8,'menuventas'),
    (8,'menucompras'),
    (8,'menuclientes'),
    (8,'menuproveedores'),
    (8,'menuacercade');

/* Insertar negocio */
INSERT INTO NEGOCIO(IdNegocio,Nombre,RUC,Direccion,Logo)
VALUES (1,'Codigo Estudiante','20202020','av. codigo estudiante 123',null);


