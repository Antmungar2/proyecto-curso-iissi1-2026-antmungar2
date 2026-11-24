-- ============================================================================
-- PROYECTO BACKSTAGE - GESTIÓN DEL FESTIVAL AZAHAR SOUND
-- Script 2: Funciones y procedimientos almacenados (MariaDB)
-- Entregable 3 - IISSI-1
-- ============================================================================

SET NAMES utf8mb4;

-- Limpieza previa para permitir reejecución limpia
DROP FUNCTION IF EXISTS fn_saldo_actual;
DROP FUNCTION IF EXISTS fn_saldo_disponible;
DROP FUNCTION IF EXISTS fn_ocupacion_zona;
DROP FUNCTION IF EXISTS fn_edad_usuario_en_fecha;
DROP FUNCTION IF EXISTS fn_plazas_disponibles_tipo;

DROP PROCEDURE IF EXISTS sp_recargar_credencial;
DROP PROCEDURE IF EXISTS sp_canjear_credencial;
DROP PROCEDURE IF EXISTS sp_reponer_pulsera;
DROP PROCEDURE IF EXISTS sp_registrar_consumo;
DROP PROCEDURE IF EXISTS sp_productos_a_reponer;

DELIMITER //

-- ============================================================================
-- 1. FUNCIONES (Mínimo 5)
-- ============================================================================

-- Función 1 (R.I.08, R.F.07, R.N.06, R.N.09):
-- Calcula el saldo actual de una credencial (recargas - consumos - devolución pagada).
CREATE FUNCTION fn_saldo_actual(p_codigo VARCHAR(30))
RETURNS DECIMAL(8,2)
READS SQL DATA
BEGIN
    DECLARE v_recargas DECIMAL(8,2) DEFAULT 0.00;
    DECLARE v_consumos DECIMAL(8,2) DEFAULT 0.00;
    DECLARE v_devuelto DECIMAL(8,2) DEFAULT 0.00;

    SELECT COALESCE(SUM(importe), 0.00) INTO v_recargas
    FROM MovimientoSaldo
    WHERE credencialId = p_codigo AND tipoMovimiento = 'recarga';

    SELECT COALESCE(SUM(importe), 0.00) INTO v_consumos
    FROM MovimientoSaldo
    WHERE credencialId = p_codigo AND tipoMovimiento = 'consumo';

    SELECT COALESCE(importeDevolucion, 0.00) INTO v_devuelto
    FROM Credencial
    WHERE codigo = p_codigo AND fechaHoraPagoDevolucion IS NOT NULL;

    RETURN v_recargas - v_consumos - v_devuelto;
END//

-- Función 2 (R.I.08, R.F.07, R.N.06, R.N.09):
-- Calcula el saldo disponible para consumir (0.00 si existe una devolución solicitada pendiente).
CREATE FUNCTION fn_saldo_disponible(p_codigo VARCHAR(30))
RETURNS DECIMAL(8,2)
READS SQL DATA
BEGIN
    DECLARE v_solicitud DATETIME;
    DECLARE v_pago DATETIME;

    SELECT fechaHoraSolicitudDevolucion, fechaHoraPagoDevolucion
    INTO v_solicitud, v_pago
    FROM Credencial
    WHERE codigo = p_codigo;

    IF v_solicitud IS NOT NULL AND v_pago IS NULL THEN
        RETURN 0.00;
    END IF;

    RETURN fn_saldo_actual(p_codigo);
END//

-- Función 3 (R.F.11, R.N.10):
-- Calcula la ocupación actual en tiempo real de una zona (entradas permitidas - salidas permitidas).
CREATE FUNCTION fn_ocupacion_zona(p_idZona INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_ocupacion INT DEFAULT 0;

    SELECT COALESCE(SUM(CASE WHEN tipoMovimiento = 'entrada' THEN 1 ELSE -1 END), 0)
    INTO v_ocupacion
    FROM Acceso
    WHERE zonaId = p_idZona AND resultado = 'permitido';

    RETURN v_ocupacion;
END//

-- Función 4 (R.N.05, R.N.07, R.F.06):
-- Calcula la edad cumplida en años de un usuario en una fecha concreta.
CREATE FUNCTION fn_edad_usuario_en_fecha(p_idUsuario VARCHAR(30), p_fecha DATE)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_fechaNac DATE;

    SELECT fechaNacimiento INTO v_fechaNac
    FROM Usuario
    WHERE idUsuario = p_idUsuario;

    IF v_fechaNac IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN TIMESTAMPDIFF(YEAR, v_fechaNac, p_fecha);
END//

-- Función 5 (R.N.02, R.F.04):
-- Calcula las plazas libres restantes de un tipo de credencial según su cupo máximo.
CREATE FUNCTION fn_plazas_disponibles_tipo(p_idTipoCredencial INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_cupo INT DEFAULT 0;
    DECLARE v_emitidas INT DEFAULT 0;

    SELECT cupoMaximo INTO v_cupo
    FROM TipoCredencial
    WHERE idTipoCredencial = p_idTipoCredencial;

    SELECT COUNT(*) INTO v_emitidas
    FROM Credencial
    WHERE tipoCredencialId = p_idTipoCredencial AND estado <> 'anulada';

    RETURN v_cupo - v_emitidas;
END//

-- ============================================================================
-- 2. PROCEDIMIENTOS ALMACENADOS (Mínimo 5)
-- ============================================================================

-- Procedimiento 1 (R.N.06, R.I.11):
-- Registra una recarga de saldo validando estado de la credencial y límites (5 € - 200 €).
CREATE PROCEDURE sp_recargar_credencial(
    IN p_idMovimiento VARCHAR(40),
    IN p_codigo       VARCHAR(30),
    IN p_importe      DECIMAL(8,2),
    IN p_canal        VARCHAR(20)
)
BEGIN
    DECLARE v_estado VARCHAR(20);
    DECLARE v_devolucion DATETIME;

    SELECT estado, fechaHoraSolicitudDevolucion
    INTO v_estado, v_devolucion
    FROM Credencial
    WHERE codigo = p_codigo;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La credencial no existe.';
    ELSEIF v_estado = 'anulada' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se puede recargar una credencial anulada.';
    ELSEIF v_devolucion IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se permiten recargas tras solicitar la devolución.';
    ELSEIF p_importe < 5.00 OR p_importe > 200.00 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error (R.N.06): El importe de recarga debe estar entre 5.00 y 200.00 euros.';
    END IF;

    INSERT INTO MovimientoSaldo (
        idMovimiento, credencialId, fechaHora, tipoMovimiento, importe, canalRecarga
    ) VALUES (
        p_idMovimiento, p_codigo, NOW(), 'recarga', p_importe, p_canal
    );
END//

-- Procedimiento 2 (R.N.11, R.I.08):
-- Realiza el primer canje de una credencial emitida asignándole su pulsera NFC activa.
CREATE PROCEDURE sp_canjear_credencial(
    IN p_codigo VARCHAR(30),
    IN p_nfc    VARCHAR(50)
)
BEGIN
    DECLARE v_estado VARCHAR(20);

    SELECT estado INTO v_estado
    FROM Credencial
    WHERE codigo = p_codigo;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La credencial no existe.';
    ELSEIF v_estado <> 'emitida' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error (R.N.11): Solo se pueden canjear credenciales en estado emitida.';
    END IF;

    UPDATE Credencial
    SET estado = 'canjeada',
        fechaHoraPrimerCanje = NOW(),
        nfcActual = p_nfc,
        estadoPulsera = 'activa',
        fechaHoraAsignacionPulsera = NOW(),
        fechaHoraBloqueoPulsera = NULL
    WHERE codigo = p_codigo;
END//

-- Procedimiento 3 (R.N.11):
-- Repone la pulsera NFC de una credencial ya canjeada por pérdida o rotura conservando saldo y accesos.
CREATE PROCEDURE sp_reponer_pulsera(
    IN p_codigo   VARCHAR(30),
    IN p_nuevoNfc VARCHAR(50)
)
BEGIN
    DECLARE v_estado VARCHAR(20);

    SELECT estado INTO v_estado
    FROM Credencial
    WHERE codigo = p_codigo;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La credencial no existe.';
    ELSEIF v_estado <> 'canjeada' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error (R.N.11): Solo se puede reponer la pulsera de una credencial canjeada.';
    END IF;

    UPDATE Credencial
    SET nfcActual = p_nuevoNfc,
        estadoPulsera = 'activa',
        fechaHoraAsignacionPulsera = NOW(),
        fechaHoraBloqueoPulsera = NULL
    WHERE codigo = p_codigo;
END//

-- Procedimiento 4 (R.N.06, R.N.07, R.N.08):
-- Registra un consumo cashless validando pulsera activa, mayoría de edad para alcohol, stock y saldo.
CREATE PROCEDURE sp_registrar_consumo(
    IN p_idMovimiento VARCHAR(40),
    IN p_codigo       VARCHAR(30),
    IN p_idProducto   INT,
    IN p_cantidad     INT,
    IN p_vendedorId   VARCHAR(30)
)
BEGIN
    DECLARE v_titularId VARCHAR(30);
    DECLARE v_estado VARCHAR(20);
    DECLARE v_estadoPulsera VARCHAR(20);
    DECLARE v_precio DECIMAL(8,2);
    DECLARE v_alcohol BOOLEAN;
    DECLARE v_stock INT;
    DECLARE v_importe DECIMAL(8,2);

    IF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error (R.N.08): La cantidad debe ser un entero positivo.';
    END IF;

    SELECT titularId, estado, estadoPulsera
    INTO v_titularId, v_estado, v_estadoPulsera
    FROM Credencial
    WHERE codigo = p_codigo;

    IF v_titularId IS NULL OR v_estado <> 'canjeada' OR v_estadoPulsera <> 'activa' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error (R.N.06): La credencial debe estar canjeada y con pulsera activa.';
    END IF;

    SELECT precioActual, llevaAlcohol, stockDisponible
    INTO v_precio, v_alcohol, v_stock
    FROM Producto
    WHERE idProducto = p_idProducto;

    IF v_precio IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El producto indicado no existe.';
    ELSEIF v_alcohol = TRUE AND fn_edad_usuario_en_fecha(v_titularId, CURDATE()) < 18 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error (R.N.07): Prohibida la venta de alcohol a menores de 18 años.';
    ELSEIF v_stock < p_cantidad THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error (R.N.08): Stock insuficiente para realizar el consumo.';
    END IF;

    SET v_importe = ROUND(p_cantidad * v_precio, 2);

    IF fn_saldo_disponible(p_codigo) < v_importe THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error (R.N.06): Saldo disponible insuficiente.';
    END IF;

    START TRANSACTION;
        INSERT INTO MovimientoSaldo (
            idMovimiento, credencialId, fechaHora, tipoMovimiento, importe,
            productoId, cantidad, precioUnitario, vendedorId
        ) VALUES (
            p_idMovimiento, p_codigo, NOW(), 'consumo', v_importe,
            p_idProducto, p_cantidad, v_precio, p_vendedorId
        );

        UPDATE Producto
        SET stockDisponible = stockDisponible - p_cantidad
        WHERE idProducto = p_idProducto;
    COMMIT;
END//

-- Procedimiento 5 (R.F.09):
-- Lista los productos de un punto de venta cuyo stock disponible está por debajo del stock mínimo.
CREATE PROCEDURE sp_productos_a_reponer(IN p_idPuntoVenta INT)
BEGIN
    SELECT
        idProducto,
        nombre,
        categoria,
        stockDisponible,
        stockMinimo,
        (stockMinimo - stockDisponible) AS unidadesFaltantes
    FROM Producto
    WHERE puntoVentaId = p_idPuntoVenta
      AND stockDisponible < stockMinimo
    ORDER BY unidadesFaltantes DESC;
END//

DELIMITER ;

-- ============================================================================
-- 3. PRUEBAS PARA LA DEFENSA (Ejecutar tras Script 1 y Script 5)
-- ============================================================================
-- Pruebas de funciones:
SELECT fn_saldo_actual('CRD-2027-0101') AS saldo_actual_laura;
SELECT fn_saldo_disponible('CRD-2027-0101') AS saldo_disponible_laura;
SELECT fn_ocupacion_zona(1) AS ocupacion_recinto_general;
SELECT fn_edad_usuario_en_fecha('USR-MEN-01', '2027-05-21') AS edad_martin_en_festival;
SELECT fn_plazas_disponibles_tipo(1) AS plazas_libres_abono_general;

-- Pruebas de procedimientos:
CALL sp_productos_a_reponer(1);
-- CALL sp_recargar_credencial('MOV-TEST-001', 'CRD-2027-0101', 20.00, 'web');
-- CALL sp_canjear_credencial('CRD-2027-0889', 'NFC-3302');
-- CALL sp_reponer_pulsera('CRD-2027-0101', 'NFC-4410-NEW');
-- CALL sp_registrar_consumo('MOV-TEST-002', 'CRD-2027-0101', 2, 1, 'USR-PV-01');
