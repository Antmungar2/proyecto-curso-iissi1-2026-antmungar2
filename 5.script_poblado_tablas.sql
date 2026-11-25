-- ============================================================================
-- PROYECTO BACKSTAGE - GESTIÓN DEL FESTIVAL AZAHAR SOUND
-- Script 5: Poblado inicial de tablas con datos de prueba (MariaDB)
-- Entregable 3 - IISSI-1
-- Orden de inserción respetando dependencias de claves ajenas (FK)
-- ============================================================================

SET NAMES utf8mb4;

-- ----------------------------------------------------------------------------
-- 1. TABLAS BASE (NIVEL 0)
-- ----------------------------------------------------------------------------

-- R.I.01: Usuarios (asistentes, profesionales con rol, profesional sin rol y solapado)
INSERT INTO Usuario (
    idUsuario, email, passwordHash, nombre, apellidos, documentoIdentidad,
    fechaNacimiento, telefono, fechaAlta, esAsistente, esProfesional, empresa, rolOperativo
) VALUES
('USR-DIR-01', 'direccion@azaharsound.es', '$2y$10$hashdir000000000000000001', 'Elena', 'Vázquez Morales', '28111222A', '1982-04-10', '+34600111001', '2025-01-10 09:00:00', FALSE, TRUE, 'Azahar Promotora S.L.', 'director_festival'),
('USR-PRG-01', 'programacion@azaharsound.es', '$2y$10$hashprg000000000000000002', 'Diego', 'Navarro Pérez', '28333444B', '1986-09-22', '+34600111002', '2025-01-12 10:00:00', FALSE, TRUE, 'Azahar Promotora S.L.', 'responsable_programacion'),
('USR-CTR-01', 'carlos.r@azaharsound.es', '$2y$10$hashctr000000000000000003', 'Carlos', 'Ruiz Navarro', '29456123K', '1988-09-08', '+34600111003', '2025-02-01 11:00:00', FALSE, TRUE, 'Seguridad Guadalquivir S.L.', 'control_recinto'),
('USR-ATC-01', 'taquilla@azaharsound.es', '$2y$10$hashatc000000000000000004', 'Sofía', 'Delgado Romero', '28555666C', '1993-06-15', '+34600111004', '2025-02-05 12:00:00', FALSE, TRUE, 'Azahar Promotora S.L.', 'atencion_cliente'),
('USR-PV-01',  'barras@azaharsound.es', '$2y$10$hashpv0000000000000000005', 'Álvaro', 'Jiménez Castro', '28777888D', '1994-11-30', '+34600111005', '2025-03-01 09:30:00', TRUE, TRUE, 'Hostelería Sur S.L.', 'personal_punto_venta'),
('USR-ART-01', 'tecnico.sonido@sonidosur.es', '$2y$10$hashart000000000000000006', 'Raúl', 'Méndez Torres', '28999000E', '1990-01-20', '+34600111006', '2026-04-01 08:00:00', FALSE, TRUE, 'Sonido Sur S.L.', NULL),
('USR-ASI-01', 'laura.m@mail.com', '$2y$10$hashasi000000000000000007', 'Laura', 'Mendoza Gil', '48123901A', '1999-03-14', '+34611223344', '2026-01-20 18:00:00', TRUE, FALSE, NULL, NULL),
('USR-ASI-02', 'javier.s@mail.com', '$2y$10$hashasi000000000000000008', 'Javier', 'Serrano Ortiz', '77890234M', '1995-11-02', '+34622334455', '2026-02-01 19:30:00', TRUE, FALSE, NULL, NULL),
('USR-ASI-03', 'marta.b@mail.com', '$2y$10$hashasi000000000000000009', 'Marta', 'Blanco Díaz', '53901842L', '2002-07-19', '+34633445566', '2026-02-15 16:45:00', TRUE, FALSE, NULL, NULL),
('USR-MEN-01', 'martin.r@mail.com', '$2y$10$hashmen000000000000000010', 'Martín', 'Ruiz Ortega', '54112233P', '2012-03-14', NULL, '2027-02-10 10:00:00', TRUE, FALSE, NULL, NULL);

-- R.I.02: Ediciones
INSERT INTO Edicion (idEdicion, nombre, anio, fechaInicio, fechaFin, aforoAutorizado) VALUES
(1, 'Azahar Sound 2025', 2025, '2025-05-23', '2025-05-25', 10000),
(2, 'Azahar Sound 2026', 2026, '2026-05-22', '2026-05-24', 13000),
(3, 'Azahar Sound 2027', 2027, '2027-05-21', '2027-05-23', 15000);

-- R.I.03: Zonas
INSERT INTO Zona (idZona, nombre, tipo, aforoMaximo, ubicacion) VALUES
(1, 'Recinto General Azahar', 'recinto_general', 15000, 'Parcela Principal junto al Guadalquivir'),
(2, 'Carpa Alameda', 'publica', 2500, 'Sector Norte del Recinto'),
(3, 'Patio VIP', 'VIP', 1200, 'Sector Este elevado'),
(4, 'Backstage Técnico', 'profesional', 300, 'Zona trasera de escenarios');

-- R.I.05: Artistas
INSERT INTO Artista (idArtista, nombreArtistico, generoMusical, paisOrigen) VALUES
(1, 'Quevedo', 'Urbano', 'España'),
(2, 'Vetusta Morla', 'Indie Rock', 'España'),
(3, 'Rozalén', 'Pop / Canción de autor', 'España'),
(4, 'Nathy Peluso', 'Pop / Urbano', 'Argentina'),
(5, 'Bizarrap', 'Electrónica / Urbano', 'Argentina');

-- ----------------------------------------------------------------------------
-- 2. TABLAS DE NIVEL 1
-- ----------------------------------------------------------------------------

-- R.I.04: Escenarios
INSERT INTO Escenario (idEscenario, nombre, zonaId, responsableId) VALUES
(1, 'Escenario Azahar', 1, 'USR-PRG-01'),
(2, 'Escenario Guadalquivir', 1, 'USR-PRG-01'),
(3, 'Escenario Carpa Alameda', 2, 'USR-PRG-01'),
(4, 'Escenario Patio', 3, 'USR-PRG-01');

-- R.I.07: Tipos de credencial
INSERT INTO TipoCredencial (
    idTipoCredencial, edicionId, nombre, destinatario, fechaValidez, perfilAcceso, precioActual, cupoMaximo
) VALUES
(1, 3, 'Abono General 2027', 'publico', NULL, 'general', 75.00, 10000),
(2, 3, 'Abono VIP 2027', 'publico', NULL, 'VIP', 140.00, 1200),
(3, 3, 'Entrada Viernes 2027', 'publico', '2027-05-21', 'general', 45.00, 3000),
(4, 3, 'Acreditación Staff Completo 2027', 'profesional', NULL, 'completo', 0.00, 300),
(5, 2, 'Abono General 2026', 'publico', NULL, 'general', 65.00, 10000);

-- R.I.09: Puntos de venta
INSERT INTO PuntoVenta (idPuntoVenta, edicionId, nombre, tipo, zonaId, responsableId) VALUES
(1, 3, 'Barra Azahar', 'barra', 1, 'USR-PV-01'),
(2, 3, 'Barra Patio VIP', 'barra', 3, 'USR-PV-01'),
(3, 3, 'Triana Burgers', 'food_truck', 1, 'USR-PV-01'),
(4, 3, 'Stand Oficial Azahar', 'tienda', 1, 'USR-PV-01');

-- R.I.13: Incidencias
INSERT INTO Incidencia (
    idIncidencia, edicionId, fechaHora, zonaId, tipo, gravedad, descripcion, registradorId
) VALUES
(1, 3, '2027-05-21 21:30:00', 1, 'sanitaria', 'leve', 'Atención por mareo leve junto a la entrada sur, sin necesidad de traslado.', 'USR-CTR-01'),
(2, 3, '2027-05-21 23:15:00', 2, 'seguridad', 'grave', 'Intento de acceso sin pulsera válida en puerta lateral de Carpa Alameda.', 'USR-CTR-01'),
(3, 3, '2027-05-22 20:45:00', 1, 'tecnica', 'leve', 'Fallo momentáneo en foco lateral del Escenario Guadalquivir resuelto en 10 minutos.', 'USR-PRG-01');

-- ----------------------------------------------------------------------------
-- 3. TABLAS DE NIVEL 2
-- ----------------------------------------------------------------------------

-- R.I.06: Actuaciones (respetando R.N.01: duración 30-180 min y horarios de jornada)
INSERT INTO Actuacion (
    idActuacion, escenarioId, edicionId, fechaHoraInicio, fechaHoraFin, esCabezaCartel, estado
) VALUES
(1, 1, 3, '2027-05-21 22:00:00', '2027-05-21 23:30:00', TRUE, 'programada'),
(2, 2, 3, '2027-05-21 20:00:00', '2027-05-21 21:30:00', FALSE, 'programada'),
(3, 3, 3, '2027-05-22 01:00:00', '2027-05-22 02:30:00', TRUE, 'programada'),
(4, 2, 3, '2027-05-22 22:00:00', '2027-05-22 23:30:00', TRUE, 'programada');

-- R.I.08: Credenciales (canjeadas, emitida, menor con adulto, staff y devolución pagada 2026)
INSERT INTO Credencial (
    codigo, tipoCredencialId, titularId, compradorId, fechaHoraEmision, precioPagado, estado,
    fechaHoraPrimerCanje, adultoResponsableId, urlAutorizacionMenor,
    nfcActual, estadoPulsera, fechaHoraAsignacionPulsera, fechaHoraBloqueoPulsera,
    fechaHoraSolicitudDevolucion, importeDevolucion, tramitadorDevolucionId, fechaHoraPagoDevolucion
) VALUES
('CRD-2027-0101', 1, 'USR-ASI-01', 'USR-ASI-01', '2027-02-10 10:00:00', 75.00, 'canjeada',
 '2027-05-21 17:00:00', NULL, NULL,
 'NFC-4410', 'activa', '2027-05-21 17:00:00', NULL,
 NULL, NULL, NULL, NULL),

('CRD-2027-0452', 2, 'USR-ASI-02', 'USR-ASI-02', '2027-02-12 12:30:00', 140.00, 'canjeada',
 '2027-05-21 17:30:00', NULL, NULL,
 'NFC-7821', 'activa', '2027-05-21 17:30:00', NULL,
 NULL, NULL, NULL, NULL),

('CRD-2027-0889', 3, 'USR-ASI-03', 'USR-ASI-03', '2027-03-01 15:00:00', 45.00, 'emitida',
 NULL, NULL, NULL,
 NULL, NULL, NULL, NULL,
 NULL, NULL, NULL, NULL),

('CRD-2027-0990', 1, 'USR-MEN-01', 'USR-ASI-01', '2027-02-10 10:05:00', 75.00, 'canjeada',
 '2027-05-21 17:05:00', 'USR-ASI-01', 'https://azaharsound.es/docs/autorizacion_martin_2027.pdf',
 'NFC-5520', 'activa', '2027-05-21 17:05:00', NULL,
 NULL, NULL, NULL, NULL),

('CRD-2027-9004', 4, 'USR-CTR-01', NULL, '2027-04-01 09:00:00', 0.00, 'canjeada',
 '2027-05-21 11:00:00', NULL, NULL,
 'NFC-9004', 'activa', '2027-05-21 11:00:00', NULL,
 NULL, NULL, NULL, NULL),

('CRD-2026-0001', 5, 'USR-ASI-01', 'USR-ASI-01', '2026-02-15 11:00:00', 65.00, 'canjeada',
 '2026-05-22 18:00:00', NULL, NULL,
 'NFC-2026-01', 'bloqueada', '2026-05-22 18:00:00', '2026-05-25 06:00:00',
 '2026-05-25 10:00:00', 12.50, 'USR-ATC-01', '2026-05-26 12:00:00');

-- R.I.10: Productos (incluye productos con alcohol y productos bajo stock mínimo para R.F.09)
INSERT INTO Producto (
    idProducto, puntoVentaId, nombre, categoria, precioActual, llevaAlcohol, stockDisponible, stockMinimo
) VALUES
(1, 1, 'Cerveza 33cl', 'bebida', 3.50, TRUE, 480, 100),
(2, 1, 'Agua 50cl', 'bebida', 2.00, FALSE, 40, 100),
(3, 2, 'Combinado Premium', 'bebida', 8.50, TRUE, 200, 50),
(4, 3, 'Hamburguesa Clásica', 'comida', 9.00, FALSE, 120, 30),
(5, 4, 'Camiseta Azahar 2027', 'merchandising', 22.00, FALSE, 15, 20);

-- ----------------------------------------------------------------------------
-- 4. TABLAS DE NIVEL 3
-- ----------------------------------------------------------------------------

-- Asociación A03: ActuacionArtista (incluye actuación con varios artistas)
INSERT INTO ActuacionArtista (actuacionId, artistaId) VALUES
(1, 1),
(2, 2),
(2, 3),
(3, 5),
(4, 4);

-- R.I.11: Movimientos de saldo (recargas y consumos coherentes con saldo >= 0)
INSERT INTO MovimientoSaldo (
    idMovimiento, credencialId, fechaHora, tipoMovimiento, importe,
    canalRecarga, productoId, cantidad, precioUnitario, vendedorId
) VALUES
('MOV-2027-001', 'CRD-2027-0101', '2027-05-20 18:00:00', 'recarga', 50.00, 'web', NULL, NULL, NULL, NULL),
('MOV-2027-002', 'CRD-2027-0452', '2027-05-21 17:45:00', 'recarga', 120.00, 'punto_recarga', NULL, NULL, NULL, NULL),
('MOV-2027-003', 'CRD-2027-0990', '2027-05-21 17:15:00', 'recarga', 25.00, 'web', NULL, NULL, NULL, NULL),
('MOV-2027-004', 'CRD-2027-0101', '2027-05-21 21:10:00', 'consumo', 7.00, NULL, 1, 2, 3.50, 'USR-PV-01'),
('MOV-2027-005', 'CRD-2027-0452', '2027-05-21 22:00:00', 'consumo', 17.00, NULL, 3, 2, 8.50, 'USR-PV-01'),
('MOV-2027-006', 'CRD-2027-0990', '2027-05-21 21:20:00', 'consumo', 2.00, NULL, 2, 1, 2.00, 'USR-PV-01'),
('MOV-2026-001', 'CRD-2026-0001', '2026-05-22 18:10:00', 'recarga', 12.50, 'web', NULL, NULL, NULL, NULL);

-- R.I.12: Accesos (permitidos, denegado por perfil y denegado por NFC desconocido)
INSERT INTO Acceso (
    idAcceso, credencialId, zonaId, fechaHora, tipoMovimiento, validadorId, resultado, motivoDenegacion
) VALUES
('ACC-2027-001', 'CRD-2027-0101', 1, '2027-05-21 19:15:00', 'entrada', 'USR-CTR-01', 'permitido', NULL),
('ACC-2027-002', 'CRD-2027-0452', 1, '2027-05-21 19:30:00', 'entrada', 'USR-CTR-01', 'permitido', NULL),
('ACC-2027-003', 'CRD-2027-0452', 3, '2027-05-21 20:10:00', 'entrada', 'USR-CTR-01', 'permitido', NULL),
('ACC-2027-004', 'CRD-2027-0101', 3, '2027-05-21 20:12:00', 'entrada', 'USR-CTR-01', 'denegado', 'Perfil de acceso general no autorizado en zona VIP'),
('ACC-2027-005', NULL,            1, '2027-05-21 20:20:00', 'entrada', 'USR-CTR-01', 'denegado', 'Código NFC desconocido no asociado a ninguna credencial');
