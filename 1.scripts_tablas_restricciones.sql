-- ============================================================================
-- PROYECTO BACKSTAGE - GESTIÓN DEL FESTIVAL AZAHAR SOUND
-- Script 1: Creación de tablas y restricciones declarativas (MariaDB)
-- Entregable 3 - IISSI-1
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- 1. BORRADO DE TABLAS (ORDEN INVERSO DE DEPENDENCIAS)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS Acceso;
DROP TABLE IF EXISTS MovimientoSaldo;
DROP TABLE IF EXISTS ActuacionArtista;
DROP TABLE IF EXISTS Producto;
DROP TABLE IF EXISTS Credencial;
DROP TABLE IF EXISTS Actuacion;
DROP TABLE IF EXISTS Incidencia;
DROP TABLE IF EXISTS PuntoVenta;
DROP TABLE IF EXISTS TipoCredencial;
DROP TABLE IF EXISTS Escenario;
DROP TABLE IF EXISTS Artista;
DROP TABLE IF EXISTS Zona;
DROP TABLE IF EXISTS Edicion;
DROP TABLE IF EXISTS Usuario;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------------------------------------------------------
-- 2. CREACIÓN DE TABLAS BASE (NIVEL 0: SIN CLAVES AJENAS)
-- ----------------------------------------------------------------------------

-- R.I.01: Usuarios (implementa jerarquía total y solapada Asistente/Profesional)
CREATE TABLE Usuario (
    idUsuario          VARCHAR(30)  NOT NULL,
    email              VARCHAR(150) NOT NULL,
    passwordHash       VARCHAR(255) NOT NULL,
    nombre             VARCHAR(100) NOT NULL,
    apellidos          VARCHAR(150) NOT NULL,
    documentoIdentidad VARCHAR(20)  NOT NULL,
    fechaNacimiento    DATE         NOT NULL,
    telefono           VARCHAR(20)  NULL,
    fechaAlta          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    esAsistente        BOOLEAN      NOT NULL DEFAULT FALSE,
    esProfesional      BOOLEAN      NOT NULL DEFAULT FALSE,
    empresa            VARCHAR(150) NULL,
    rolOperativo       VARCHAR(40)  NULL,
    CONSTRAINT pk_usuario PRIMARY KEY (idUsuario),
    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT uq_usuario_documento UNIQUE (documentoIdentidad),
    CONSTRAINT chk_usuario_email_formato CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT chk_usuario_tipo_obligatorio CHECK (esAsistente = TRUE OR esProfesional = TRUE),
    CONSTRAINT chk_usuario_rol_valido CHECK (
        rolOperativo IS NULL OR rolOperativo IN (
            'director_festival',
            'responsable_programacion',
            'control_recinto',
            'atencion_cliente',
            'personal_punto_venta'
        )
    ),
    CONSTRAINT chk_usuario_coherencia_profesional CHECK (
        (esProfesional = TRUE AND empresa IS NOT NULL AND TRIM(empresa) <> '')
        OR
        (esProfesional = FALSE AND empresa IS NULL AND rolOperativo IS NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.02: Ediciones del festival
CREATE TABLE Edicion (
    idEdicion       INT          NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(100) NOT NULL,
    anio            SMALLINT     NOT NULL,
    fechaInicio     DATE         NOT NULL,
    fechaFin        DATE         NOT NULL,
    aforoAutorizado INT          NOT NULL,
    CONSTRAINT pk_edicion PRIMARY KEY (idEdicion),
    CONSTRAINT uq_edicion_anio UNIQUE (anio),
    CONSTRAINT chk_edicion_fechas CHECK (
        fechaInicio <= fechaFin
        AND YEAR(fechaInicio) = anio
        AND YEAR(fechaFin) = anio
    ),
    CONSTRAINT chk_edicion_aforo CHECK (aforoAutorizado > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.03: Zonas del recinto
CREATE TABLE Zona (
    idZona      INT          NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(100) NOT NULL,
    tipo        VARCHAR(30)  NOT NULL,
    aforoMaximo INT          NOT NULL,
    ubicacion   VARCHAR(200) NOT NULL,
    CONSTRAINT pk_zona PRIMARY KEY (idZona),
    CONSTRAINT uq_zona_nombre UNIQUE (nombre),
    CONSTRAINT chk_zona_tipo CHECK (
        tipo IN ('recinto_general', 'publica', 'VIP', 'profesional')
    ),
    CONSTRAINT chk_zona_aforo CHECK (aforoMaximo > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.05: Artistas
CREATE TABLE Artista (
    idArtista       INT          NOT NULL AUTO_INCREMENT,
    nombreArtistico VARCHAR(120) NOT NULL,
    generoMusical   VARCHAR(80)  NOT NULL,
    paisOrigen      VARCHAR(80)  NOT NULL,
    CONSTRAINT pk_artista PRIMARY KEY (idArtista),
    CONSTRAINT uq_artista_nombre UNIQUE (nombreArtistico)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 3. CREACIÓN DE TABLAS DE NIVEL 1 (DEPENDEN DE NIVEL 0)
-- ----------------------------------------------------------------------------

-- R.I.04: Escenarios
CREATE TABLE Escenario (
    idEscenario   INT          NOT NULL AUTO_INCREMENT,
    nombre        VARCHAR(100) NOT NULL,
    zonaId        INT          NOT NULL,
    responsableId VARCHAR(30)  NULL,
    CONSTRAINT pk_escenario PRIMARY KEY (idEscenario),
    CONSTRAINT uq_escenario_nombre UNIQUE (nombre),
    CONSTRAINT fk_escenario_zona FOREIGN KEY (zonaId)
        REFERENCES Zona (idZona),
    CONSTRAINT fk_escenario_responsable FOREIGN KEY (responsableId)
        REFERENCES Usuario (idUsuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.07: Tipos de credencial (entradas y acreditaciones por edición)
CREATE TABLE TipoCredencial (
    idTipoCredencial INT          NOT NULL AUTO_INCREMENT,
    edicionId        INT          NOT NULL,
    nombre           VARCHAR(100) NOT NULL,
    destinatario     VARCHAR(20)  NOT NULL,
    fechaValidez     DATE         NULL,
    perfilAcceso     VARCHAR(20)  NOT NULL,
    precioActual     DECIMAL(8,2) NOT NULL,
    cupoMaximo       INT          NOT NULL,
    CONSTRAINT pk_tipo_credencial PRIMARY KEY (idTipoCredencial),
    CONSTRAINT uq_tipo_credencial_edicion_nombre UNIQUE (edicionId, nombre),
    CONSTRAINT fk_tipo_credencial_edicion FOREIGN KEY (edicionId)
        REFERENCES Edicion (idEdicion),
    CONSTRAINT chk_tipo_credencial_destinatario CHECK (
        destinatario IN ('publico', 'profesional')
    ),
    CONSTRAINT chk_tipo_credencial_perfil CHECK (
        perfilAcceso IN ('general', 'VIP', 'operativo', 'completo')
    ),
    CONSTRAINT chk_tipo_credencial_perfil_publico CHECK (
        destinatario = 'profesional' OR perfilAcceso IN ('general', 'VIP')
    ),
    CONSTRAINT chk_tipo_credencial_precio CHECK (
        (destinatario = 'publico' AND precioActual > 0.00)
        OR
        (destinatario = 'profesional' AND precioActual = 0.00)
    ),
    CONSTRAINT chk_tipo_credencial_cupo CHECK (cupoMaximo > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.09: Puntos de venta (barras, food trucks y tienda)
CREATE TABLE PuntoVenta (
    idPuntoVenta  INT          NOT NULL AUTO_INCREMENT,
    edicionId     INT          NOT NULL,
    nombre        VARCHAR(100) NOT NULL,
    tipo          VARCHAR(20)  NOT NULL,
    zonaId        INT          NOT NULL,
    responsableId VARCHAR(30)  NOT NULL,
    CONSTRAINT pk_punto_venta PRIMARY KEY (idPuntoVenta),
    CONSTRAINT uq_punto_venta_edicion_nombre UNIQUE (edicionId, nombre),
    CONSTRAINT fk_punto_venta_edicion FOREIGN KEY (edicionId)
        REFERENCES Edicion (idEdicion),
    CONSTRAINT fk_punto_venta_zona FOREIGN KEY (zonaId)
        REFERENCES Zona (idZona),
    CONSTRAINT fk_punto_venta_responsable FOREIGN KEY (responsableId)
        REFERENCES Usuario (idUsuario),
    CONSTRAINT chk_punto_venta_tipo CHECK (
        tipo IN ('barra', 'food_truck', 'tienda')
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.13: Incidencias
CREATE TABLE Incidencia (
    idIncidencia  INT         NOT NULL AUTO_INCREMENT,
    edicionId     INT         NOT NULL,
    fechaHora     DATETIME    NOT NULL,
    zonaId        INT         NOT NULL,
    tipo          VARCHAR(20) NOT NULL,
    gravedad      VARCHAR(20) NOT NULL,
    descripcion   TEXT        NOT NULL,
    registradorId VARCHAR(30) NOT NULL,
    CONSTRAINT pk_incidencia PRIMARY KEY (idIncidencia),
    CONSTRAINT fk_incidencia_edicion FOREIGN KEY (edicionId)
        REFERENCES Edicion (idEdicion),
    CONSTRAINT fk_incidencia_zona FOREIGN KEY (zonaId)
        REFERENCES Zona (idZona),
    CONSTRAINT fk_incidencia_registrador FOREIGN KEY (registradorId)
        REFERENCES Usuario (idUsuario),
    CONSTRAINT chk_incidencia_tipo CHECK (
        tipo IN ('sanitaria', 'seguridad', 'tecnica')
    ),
    CONSTRAINT chk_incidencia_gravedad CHECK (
        gravedad IN ('leve', 'grave', 'muy_grave')
    ),
    CONSTRAINT chk_incidencia_descripcion CHECK (TRIM(descripcion) <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 4. CREACIÓN DE TABLAS DE NIVEL 2 (DEPENDEN DE NIVELES 0 Y 1)
-- ----------------------------------------------------------------------------

-- R.I.06: Actuaciones
CREATE TABLE Actuacion (
    idActuacion     INT         NOT NULL AUTO_INCREMENT,
    escenarioId     INT         NOT NULL,
    edicionId       INT         NOT NULL,
    fechaHoraInicio DATETIME    NOT NULL,
    fechaHoraFin    DATETIME    NOT NULL,
    esCabezaCartel  BOOLEAN     NOT NULL DEFAULT FALSE,
    estado          VARCHAR(20) NOT NULL DEFAULT 'programada',
    CONSTRAINT pk_actuacion PRIMARY KEY (idActuacion),
    CONSTRAINT fk_actuacion_escenario FOREIGN KEY (escenarioId)
        REFERENCES Escenario (idEscenario),
    CONSTRAINT fk_actuacion_edicion FOREIGN KEY (edicionId)
        REFERENCES Edicion (idEdicion),
    CONSTRAINT chk_actuacion_duracion CHECK (
        fechaHoraFin >= DATE_ADD(fechaHoraInicio, INTERVAL 30 MINUTE)
        AND fechaHoraFin <= DATE_ADD(fechaHoraInicio, INTERVAL 180 MINUTE)
    ),
    CONSTRAINT chk_actuacion_franja_horaria CHECK (
        TIME(fechaHoraInicio) >= '12:00:00' OR TIME(fechaHoraInicio) < '06:00:00'
    ),
    CONSTRAINT chk_actuacion_estado CHECK (
        estado IN ('programada', 'realizada', 'cancelada')
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.08: Credenciales (entradas nominativas y acreditaciones)
CREATE TABLE Credencial (
    codigo                       VARCHAR(30)  NOT NULL,
    tipoCredencialId             INT          NOT NULL,
    titularId                    VARCHAR(30)  NOT NULL,
    compradorId                  VARCHAR(30)  NULL,
    fechaHoraEmision             DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    precioPagado                 DECIMAL(8,2) NOT NULL,
    estado                       VARCHAR(20)  NOT NULL DEFAULT 'emitida',
    fechaHoraPrimerCanje         DATETIME     NULL,
    adultoResponsableId          VARCHAR(30)  NULL,
    urlAutorizacionMenor         VARCHAR(255) NULL,
    nfcActual                    VARCHAR(50)  NULL,
    estadoPulsera                VARCHAR(20)  NULL,
    fechaHoraAsignacionPulsera   DATETIME     NULL,
    fechaHoraBloqueoPulsera      DATETIME     NULL,
    fechaHoraSolicitudDevolucion DATETIME     NULL,
    importeDevolucion            DECIMAL(8,2) NULL,
    tramitadorDevolucionId       VARCHAR(30)  NULL,
    fechaHoraPagoDevolucion      DATETIME     NULL,
    CONSTRAINT pk_credencial PRIMARY KEY (codigo),
    CONSTRAINT uq_credencial_nfc UNIQUE (nfcActual),
    CONSTRAINT fk_credencial_tipo FOREIGN KEY (tipoCredencialId)
        REFERENCES TipoCredencial (idTipoCredencial),
    CONSTRAINT fk_credencial_titular FOREIGN KEY (titularId)
        REFERENCES Usuario (idUsuario),
    CONSTRAINT fk_credencial_comprador FOREIGN KEY (compradorId)
        REFERENCES Usuario (idUsuario),
    CONSTRAINT fk_credencial_adulto FOREIGN KEY (adultoResponsableId)
        REFERENCES Usuario (idUsuario),
    CONSTRAINT fk_credencial_tramitador FOREIGN KEY (tramitadorDevolucionId)
        REFERENCES Usuario (idUsuario),
    CONSTRAINT chk_credencial_precio CHECK (precioPagado >= 0.00),
    CONSTRAINT chk_credencial_estado CHECK (
        estado IN ('emitida', 'canjeada', 'anulada')
    ),
    CONSTRAINT chk_credencial_estado_pulsera CHECK (
        estadoPulsera IS NULL OR estadoPulsera IN ('activa', 'bloqueada')
    ),
    CONSTRAINT chk_credencial_adulto_distinto CHECK (
        adultoResponsableId IS NULL OR adultoResponsableId <> titularId
    ),
    CONSTRAINT chk_credencial_coherencia_canje CHECK (
        (estado = 'emitida' AND fechaHoraPrimerCanje IS NULL AND nfcActual IS NULL)
        OR
        (estado = 'canjeada' AND fechaHoraPrimerCanje IS NOT NULL AND nfcActual IS NOT NULL)
        OR
        (estado = 'anulada' AND (nfcActual IS NULL OR estadoPulsera = 'bloqueada'))
    ),
    CONSTRAINT chk_credencial_coherencia_pulsera CHECK (
        (
            nfcActual IS NULL
            AND estadoPulsera IS NULL
            AND fechaHoraAsignacionPulsera IS NULL
            AND fechaHoraBloqueoPulsera IS NULL
        )
        OR
        (
            nfcActual IS NOT NULL
            AND estadoPulsera IS NOT NULL
            AND fechaHoraAsignacionPulsera IS NOT NULL
            AND (
                (estadoPulsera = 'activa' AND fechaHoraBloqueoPulsera IS NULL)
                OR
                (estadoPulsera = 'bloqueada' AND fechaHoraBloqueoPulsera IS NOT NULL AND fechaHoraBloqueoPulsera >= fechaHoraAsignacionPulsera)
            )
        )
    ),
    CONSTRAINT chk_credencial_coherencia_devolucion CHECK (
        (
            fechaHoraSolicitudDevolucion IS NULL
            AND importeDevolucion IS NULL
            AND tramitadorDevolucionId IS NULL
            AND fechaHoraPagoDevolucion IS NULL
        )
        OR
        (
            fechaHoraSolicitudDevolucion IS NOT NULL
            AND importeDevolucion IS NOT NULL
            AND importeDevolucion > 0.00
            AND tramitadorDevolucionId IS NOT NULL
            AND (fechaHoraPagoDevolucion IS NULL OR fechaHoraPagoDevolucion >= fechaHoraSolicitudDevolucion)
        )
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.10: Productos ofrecidos en cada punto de venta
CREATE TABLE Producto (
    idProducto      INT          NOT NULL AUTO_INCREMENT,
    puntoVentaId    INT          NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    categoria       VARCHAR(20)  NOT NULL,
    precioActual    DECIMAL(8,2) NOT NULL,
    llevaAlcohol    BOOLEAN      NOT NULL DEFAULT FALSE,
    stockDisponible INT          NOT NULL,
    stockMinimo     INT          NOT NULL,
    CONSTRAINT pk_producto PRIMARY KEY (idProducto),
    CONSTRAINT uq_producto_pv_nombre UNIQUE (puntoVentaId, nombre),
    CONSTRAINT fk_producto_pv FOREIGN KEY (puntoVentaId)
        REFERENCES PuntoVenta (idPuntoVenta),
    CONSTRAINT chk_producto_categoria CHECK (
        categoria IN ('bebida', 'comida', 'merchandising')
    ),
    CONSTRAINT chk_producto_precio CHECK (precioActual > 0.00),
    CONSTRAINT chk_producto_stock CHECK (stockDisponible >= 0 AND stockMinimo >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 5. CREACIÓN DE TABLAS DE NIVEL 3 (DEPENDEN DE NIVELES 0, 1 Y 2)
-- ----------------------------------------------------------------------------

-- R.I.06 / Asociación A03: Participación de artistas en actuaciones (M:N)
CREATE TABLE ActuacionArtista (
    actuacionId INT NOT NULL,
    artistaId   INT NOT NULL,
    CONSTRAINT pk_actuacion_artista PRIMARY KEY (actuacionId, artistaId),
    CONSTRAINT fk_act_art_actuacion FOREIGN KEY (actuacionId)
        REFERENCES Actuacion (idActuacion) ON DELETE CASCADE,
    CONSTRAINT fk_act_art_artista FOREIGN KEY (artistaId)
        REFERENCES Artista (idArtista)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.11: Movimientos de saldo (recargas y consumos cashless)
CREATE TABLE MovimientoSaldo (
    idMovimiento   VARCHAR(40)  NOT NULL,
    credencialId   VARCHAR(30)  NOT NULL,
    fechaHora      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipoMovimiento VARCHAR(20)  NOT NULL,
    importe        DECIMAL(8,2) NOT NULL,
    canalRecarga   VARCHAR(20)  NULL,
    productoId     INT          NULL,
    cantidad       INT          NULL,
    precioUnitario DECIMAL(8,2) NULL,
    vendedorId     VARCHAR(30)  NULL,
    CONSTRAINT pk_movimiento_saldo PRIMARY KEY (idMovimiento),
    CONSTRAINT fk_movimiento_credencial FOREIGN KEY (credencialId)
        REFERENCES Credencial (codigo),
    CONSTRAINT fk_movimiento_producto FOREIGN KEY (productoId)
        REFERENCES Producto (idProducto),
    CONSTRAINT fk_movimiento_vendedor FOREIGN KEY (vendedorId)
        REFERENCES Usuario (idUsuario),
    CONSTRAINT chk_movimiento_tipo CHECK (
        tipoMovimiento IN ('recarga', 'consumo')
    ),
    CONSTRAINT chk_movimiento_canal CHECK (
        canalRecarga IS NULL OR canalRecarga IN ('web', 'punto_recarga')
    ),
    CONSTRAINT chk_movimiento_coherencia CHECK (
        (
            tipoMovimiento = 'recarga'
            AND canalRecarga IS NOT NULL
            AND importe BETWEEN 5.00 AND 200.00
            AND productoId IS NULL
            AND cantidad IS NULL
            AND precioUnitario IS NULL
            AND vendedorId IS NULL
        )
        OR
        (
            tipoMovimiento = 'consumo'
            AND canalRecarga IS NULL
            AND productoId IS NOT NULL
            AND cantidad IS NOT NULL
            AND cantidad > 0
            AND precioUnitario IS NOT NULL
            AND precioUnitario > 0.00
            AND vendedorId IS NOT NULL
            AND ROUND(importe, 2) = ROUND(cantidad * precioUnitario, 2)
        )
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- R.I.12: Registros de lectura en controles de acceso
CREATE TABLE Acceso (
    idAcceso         VARCHAR(40)  NOT NULL,
    credencialId     VARCHAR(30)  NULL,
    zonaId           INT          NOT NULL,
    fechaHora        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipoMovimiento   VARCHAR(20)  NOT NULL,
    validadorId      VARCHAR(30)  NOT NULL,
    resultado        VARCHAR(20)  NOT NULL,
    motivoDenegacion VARCHAR(255) NULL,
    CONSTRAINT pk_acceso PRIMARY KEY (idAcceso),
    CONSTRAINT fk_acceso_credencial FOREIGN KEY (credencialId)
        REFERENCES Credencial (codigo),
    CONSTRAINT fk_acceso_zona FOREIGN KEY (zonaId)
        REFERENCES Zona (idZona),
    CONSTRAINT fk_acceso_validador FOREIGN KEY (validadorId)
        REFERENCES Usuario (idUsuario),
    CONSTRAINT chk_acceso_tipo CHECK (
        tipoMovimiento IN ('entrada', 'salida')
    ),
    CONSTRAINT chk_acceso_resultado CHECK (
        resultado IN ('permitido', 'denegado')
    ),
    CONSTRAINT chk_acceso_motivo CHECK (
        (resultado = 'permitido' AND motivoDenegacion IS NULL)
        OR
        (resultado = 'denegado' AND motivoDenegacion IS NOT NULL AND TRIM(motivoDenegacion) <> '')
    ),
    CONSTRAINT chk_acceso_desconocida CHECK (
        credencialId IS NOT NULL OR resultado = 'denegado'
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;