-- ============================================================
--  DML y Control TCL - Actividad 1
--  Alumno : Alejandro Gomez
--  Curso  : 1º DAW
--  Motor  : Oracle 21c XE (XEPDB1)
-- ============================================================

-- ============================================================
-- PREPARACION DEL ENTORNO
-- ============================================================
CREATE TABLE productos_u4  AS SELECT * FROM OE.PRODUCT_INFORMATION;
CREATE TABLE inventario_u4 AS SELECT * FROM OE.INVENTORIES;
CREATE TABLE precios_altos AS
    SELECT product_id, product_name, list_price
    FROM   OE.PRODUCT_INFORMATION WHERE 1 = 0;
CREATE TABLE log_pedidos (
    id_log NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    accion VARCHAR2(100), fecha DATE
);

-- ============================================================
-- PASO 2 - INSERCION (INSERT)
-- ============================================================

-- 2.1 Simple
INSERT INTO productos_u4 (product_id, product_name, list_price)
VALUES (7000, 'Cable HDMI 2.1', 25);

-- 2.2 Columnas especificas
INSERT INTO productos_u4 (product_id, product_name, category_id)
VALUES (7001, 'Hub USB-C', 10);

-- 2.3 Uso de Nulos
INSERT INTO productos_u4 (product_id, product_name, product_description,
    category_id, weight_class, warranty_period, supplier_id,
    product_status, list_price, min_price, catalog_url)
VALUES (7002, 'Teclado Mecanico', 'Teclado retro iluminado',
    10, 2, NULL, NULL, 'available', 89.99, 60.00, NULL);

-- 2.4 Sintaxis de Fecha con SYSDATE
INSERT INTO log_pedidos (accion, fecha)
VALUES ('Insercion de prueba actividad DML', SYSDATE);

-- 2.5 Copia de fila
INSERT INTO productos_u4
    SELECT 7003, product_name, product_description,
           category_id, weight_class, warranty_period,
           supplier_id, product_status, list_price,
           min_price, catalog_url
    FROM   productos_u4
    WHERE  product_id = 1797;

-- 2.6 Insercion Masiva
INSERT INTO productos_u4
    SELECT *
    FROM   productos_u4
    WHERE  list_price > 5000
      AND  product_id NOT IN (SELECT product_id FROM productos_u4);

-- 2.7 Subconsulta con Filtro
INSERT INTO productos_u4
    SELECT *
    FROM   productos_u4 op
    WHERE  op.category_id = 11
      AND  op.product_id NOT IN (SELECT product_id FROM productos_u4);

-- 2.9 Calculo en Insercion
INSERT INTO productos_u4 (product_id, product_name, category_id, list_price)
VALUES (
    7005, 'Producto Calculado Cat10', 10,
    (SELECT AVG(list_price) * 2
     FROM OE.PRODUCT_INFORMATION
     WHERE category_id = 10)
);

-- 2.10 Multitabla
INSERT INTO precios_altos (product_id, product_name, list_price)
    SELECT product_id, product_name, list_price
    FROM   OE.PRODUCT_INFORMATION
    WHERE  list_price > 1000;

COMMIT;

-- ============================================================
-- PASO 3 - MODIFICACION (UPDATE)
-- ============================================================

-- 3.1 Directo
UPDATE productos_u4 SET product_status = 'obsolete' WHERE product_id = 1797;

-- 3.2 Multiple
UPDATE productos_u4 SET min_price = 50, list_price = 80 WHERE product_id = 7000;

-- 3.3 Filtro Simple
UPDATE productos_u4 SET list_price = list_price + 10 WHERE category_id = 12;

-- 3.4 Uso de LIKE
UPDATE productos_u4 SET product_status = 'discontinued' WHERE product_name LIKE 'Software%';

-- 3.5 Basado en NULL
UPDATE productos_u4 SET min_price = 5 WHERE min_price IS NULL;

-- 3.6 Calculo Porcentual
UPDATE productos_u4 SET list_price = list_price * 0.80 WHERE weight_class = 5;

-- 3.7 Subconsulta Simple
UPDATE productos_u4
SET    list_price = list_price + 100
WHERE  category_id = 11;

-- 3.8 Update Correlacionado
UPDATE productos_u4 p
SET    p.min_price = (
    SELECT MIN(i.quantity_on_hand)
    FROM   inventario_u4 i
    WHERE  i.product_id = p.product_id
)
WHERE  EXISTS (
    SELECT 1
    FROM   inventario_u4 i
    WHERE  i.product_id = p.product_id
);

-- 3.9 Condicion de Existencia
UPDATE productos_u4
SET    product_status = 'available'
WHERE  product_id IN (SELECT product_id FROM inventario_u4 WHERE quantity_on_hand >= 1);

-- 3.10 Logica Compleja
UPDATE productos_u4
SET    list_price = list_price * 0.95
WHERE  list_price > (SELECT AVG(list_price) FROM productos_u4);

COMMIT;

-- ============================================================
-- PASO 4 - BORRADO (DELETE)
-- ============================================================

-- 4.1 ID Especifico
DELETE FROM productos_u4 WHERE product_id = 7000;

-- 4.2 Filtro de Texto
DELETE FROM productos_u4 WHERE product_description LIKE '%Test%';

-- 4.3 Rango Numerico
DELETE FROM productos_u4 WHERE list_price BETWEEN 0 AND 1;

-- 4.4 Estado y Categoria
DELETE FROM productos_u4 WHERE category_id = 10 AND product_status = 'under development';

-- 4.5 Sin Inventario
DELETE FROM productos_u4
WHERE  product_id NOT IN (SELECT DISTINCT product_id FROM inventario_u4);

-- 4.6 Subconsulta de Agregacion
DELETE FROM productos_u4 WHERE min_price = (SELECT MIN(min_price) FROM productos_u4);

-- 4.7 Relacional
DELETE FROM productos_u4
WHERE  product_id NOT IN (SELECT DISTINCT product_id FROM OE.ORDER_ITEMS);

-- 4.8 Basado en Almacen
DELETE FROM inventario_u4
WHERE  warehouse_id IN (
    SELECT w.warehouse_id FROM OE.WAREHOUSES w
    JOIN HR.LOCATIONS l ON w.location_id = l.location_id
    JOIN HR.COUNTRIES c ON l.country_id  = c.country_id
    WHERE c.country_name = 'Japan'
);

-- 4.9 Doble Condicion Subquery
DELETE FROM productos_u4
WHERE  category_id IN (
    SELECT category_id FROM productos_u4
    GROUP BY category_id HAVING COUNT(*) < 5
);

-- 4.10 Limpieza Total
DELETE FROM productos_u4 WHERE product_id BETWEEN 7000 AND 8000;
COMMIT;

-- ============================================================
-- PASO 5 - TRANSACCIONES Y CONCURRENCIA
-- ============================================================

-- Preparacion
CREATE TABLE cuenta_bancaria (
    id NUMBER PRIMARY KEY, titular VARCHAR2(50), saldo NUMBER(10,2)
);
INSERT INTO cuenta_bancaria VALUES (1, 'Usuario A', 1000);
INSERT INTO cuenta_bancaria VALUES (2, 'Usuario B', 2000);
COMMIT;

-- Escenario 1: Atomicidad
BEGIN
    UPDATE cuenta_bancaria SET saldo = saldo - 500 WHERE id = 1;
    DECLARE v_filas NUMBER; BEGIN
        UPDATE cuenta_bancaria SET saldo = saldo + 500 WHERE id = 99;
        v_filas := SQL%ROWCOUNT;
        IF v_filas = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Cuenta destino no encontrada.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || ' - Revertido.');
        RETURN;
    END;
    COMMIT;
END;
/
SELECT * FROM cuenta_bancaria;

-- Escenario 2: SAVEPOINTs
UPDATE cuenta_bancaria SET saldo = saldo * 1.10;
SAVEPOINT sp_subida;

INSERT INTO cuenta_bancaria VALUES (3, 'Usuario C', 500);
SAVEPOINT sp_nuevo_usuario;

DELETE FROM cuenta_bancaria;

ROLLBACK TO SAVEPOINT sp_nuevo_usuario;
SELECT * FROM cuenta_bancaria;
COMMIT;

-- Escenario 3: Bloqueos
UPDATE cuenta_bancaria SET saldo = 0 WHERE id = 1;
COMMIT;

-- Escenario 4: Commit Fantasma
DELETE FROM cuenta_bancaria WHERE id = 2;
CREATE TABLE log_errores (msg VARCHAR2(100));
ROLLBACK;
SELECT * FROM cuenta_bancaria;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
