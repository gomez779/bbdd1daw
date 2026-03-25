# DML y Control TCL – Actividad 1
**Alumno:** Alejandro Gomez | **Curso:** 1º DAW | **Motor:** Oracle 21c XE (XEPDB1)

---

## Preparación del Entorno

Se crean tablas espejo para trabajar sin modificar los datos maestros del esquema OE:

```sql
CREATE TABLE productos_u4  AS SELECT * FROM OE.PRODUCT_INFORMATION;
CREATE TABLE inventario_u4 AS SELECT * FROM OE.INVENTORIES;
CREATE TABLE precios_altos AS
    SELECT product_id, product_name, list_price
    FROM   OE.PRODUCT_INFORMATION WHERE 1 = 0;
CREATE TABLE log_pedidos (
    id_log NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    accion VARCHAR2(100), fecha DATE
);
```

> [ INSERTAR CAPTURA AQUI - Preparacion - Tablas espejo creadas (DESCRIBE productos_u4) ]

---

## Paso 2 – Bloque de Inserción (INSERT)

### 2.1 Simple
Insertar un producto con ID 7000, nombre 'Cable HDMI 2.1' y precio 25.
```sql
INSERT INTO productos_u4 (product_id, product_name, list_price)
VALUES (7000, 'Cable HDMI 2.1', 25);
```
> [ INSERTAR CAPTURA AQUI - 2.1 INSERT simple - producto 7000 ]

---

### 2.2 Columnas específicas
Insertar el producto 7001 'Hub USB-C' solo con ID, nombre y category_id = 10.
```sql
INSERT INTO productos_u4 (product_id, product_name, category_id)
VALUES (7001, 'Hub USB-C', 10);
```
> [ INSERTAR CAPTURA AQUI - 2.2 INSERT columnas especificas - producto 7001 ]

---

### 2.3 Uso de Nulos
Insertar el producto 7002 dejando warranty_period como NULL de forma explícita.
```sql
INSERT INTO productos_u4 (product_id, product_name, product_description,
    category_id, weight_class, warranty_period, supplier_id,
    product_status, list_price, min_price, catalog_url)
VALUES (7002, 'Teclado Mecanico', 'Teclado retro iluminado',
    10, 2, NULL, NULL, 'available', 89.99, 60.00, NULL);
```
> [ INSERTAR CAPTURA AQUI - 2.3 INSERT con NULL - producto 7002 ]

---

### 2.4 Sintaxis de Fecha con SYSDATE
Insertar un registro en la tabla de log usando SYSDATE para la fecha actual.
```sql
INSERT INTO log_pedidos (accion, fecha)
VALUES ('Insercion de prueba actividad DML', SYSDATE);
```
> [ INSERTAR CAPTURA AQUI - 2.4 INSERT con SYSDATE - log_pedidos ]

---

### 2.5 Copia de fila
Insertar un nuevo producto con datos idénticos al producto 1797 pero con ID 7003.
```sql
INSERT INTO productos_u4
    SELECT 7003, product_name, product_description,
           category_id, weight_class, warranty_period,
           supplier_id, product_status, list_price,
           min_price, catalog_url
    FROM   productos_u4
    WHERE  product_id = 1797;
```
> [ INSERTAR CAPTURA AQUI - 2.5 INSERT copia de fila - producto 7003 desde 1797 ]

---

### 2.6 Inserción Masiva
Insertar todos los productos de la tabla original con list_price > 5000 que no existan ya.
```sql
INSERT INTO productos_u4
    SELECT *
    FROM   OE.PRODUCT_INFORMATION
    WHERE  list_price > 5000
      AND  product_id NOT IN (SELECT product_id FROM productos_u4);
```
> [ INSERTAR CAPTURA AQUI - 2.6 INSERT masivo - productos con list_price > 5000 ]

---

### 2.7 Subconsulta con Filtro
Insertar productos de la categoría 11 que no existan en productos_u4.
```sql
INSERT INTO productos_u4
    SELECT *
    FROM   OE.PRODUCT_INFORMATION op
    WHERE  op.category_id = 11
      AND  op.product_id NOT IN (SELECT product_id FROM productos_u4);
```
> [ INSERTAR CAPTURA AQUI - 2.7 INSERT subconsulta - categoria 11 nuevos ]

---

### 2.8 Carga Parcial
Insertar solo product_id y product_name de productos con stock en el almacén 1.
```sql
INSERT INTO productos_u4 (product_id, product_name)
    SELECT DISTINCT pi.product_id, pi.product_name
    FROM   OE.PRODUCT_INFORMATION pi
    JOIN   OE.INVENTORIES i ON pi.product_id = i.product_id
    WHERE  i.warehouse_id = 1
      AND  pi.product_id NOT IN (SELECT product_id FROM productos_u4);
```
> [ INSERTAR CAPTURA AQUI - 2.8 INSERT carga parcial - stock almacen 1 ]

---

### 2.9 Cálculo en Inserción
Insertar el producto 7005 con list_price = doble de la media de la categoría 10.
```sql
INSERT INTO productos_u4 (product_id, product_name, category_id, list_price)
VALUES (
    7005, 'Producto Calculado Cat10', 10,
    (SELECT AVG(list_price) * 2
     FROM OE.PRODUCT_INFORMATION
     WHERE category_id = 10)
);
```
> [ INSERTAR CAPTURA AQUI - 2.9 INSERT calculo - producto 7005 con precio calculado ]

---

### 2.10 Multitabla
Insertar en precios_altos todos los productos con list_price > 1000.
```sql
INSERT INTO precios_altos (product_id, product_name, list_price)
    SELECT product_id, product_name, list_price
    FROM   OE.PRODUCT_INFORMATION
    WHERE  list_price > 1000;

COMMIT;
```
> [ INSERTAR CAPTURA AQUI - 2.10 INSERT multitabla - precios_altos > 1000 ]

---

## Paso 3 – Bloque de Modificación (UPDATE)

### 3.1 Directo
```sql
UPDATE productos_u4 SET product_status = 'obsolete' WHERE product_id = 1797;
```
> [ INSERTAR CAPTURA AQUI - 3.1 UPDATE directo - producto 1797 a obsolete ]

### 3.2 Múltiple
```sql
UPDATE productos_u4 SET min_price = 50, list_price = 80 WHERE product_id = 7000;
```
> [ INSERTAR CAPTURA AQUI - 3.2 UPDATE multiple - producto 7000 precios ]

### 3.3 Filtro Simple
```sql
UPDATE productos_u4 SET list_price = list_price + 10 WHERE category_id = 12;
```
> [ INSERTAR CAPTURA AQUI - 3.3 UPDATE filtro simple - incremento categoria 12 ]

### 3.4 Uso de LIKE
```sql
UPDATE productos_u4 SET product_status = 'discontinued' WHERE product_name LIKE 'Software%';
```
> [ INSERTAR CAPTURA AQUI - 3.4 UPDATE LIKE - discontinued Software% ]

### 3.5 Basado en NULL
```sql
UPDATE productos_u4 SET min_price = 5 WHERE min_price IS NULL;
```
> [ INSERTAR CAPTURA AQUI - 3.5 UPDATE NULL - min_price nulo a 5 ]

### 3.6 Cálculo Porcentual
```sql
UPDATE productos_u4 SET list_price = list_price * 0.80 WHERE weight_class = 5;
```
> [ INSERTAR CAPTURA AQUI - 3.6 UPDATE porcentual - rebaja 20% weight_class 5 ]

### 3.7 Subconsulta Simple
```sql
UPDATE productos_u4
SET    list_price = list_price + 100
WHERE  category_id = (
    SELECT category_id FROM OE.CATEGORIES_TAB WHERE category_name = 'Software/Other'
);
```
> [ INSERTAR CAPTURA AQUI - 3.7 UPDATE subconsulta - +100 Software/Other ]

### 3.8 Update Correlacionado
```sql
UPDATE productos_u4 p
SET    p.min_price = (
    SELECT MIN(oi.unit_price) FROM OE.ORDER_ITEMS oi WHERE oi.product_id = p.product_id
)
WHERE  EXISTS (SELECT 1 FROM OE.ORDER_ITEMS oi WHERE oi.product_id = p.product_id);
```
> [ INSERTAR CAPTURA AQUI - 3.8 UPDATE correlacionado - min_price desde order_items ]

### 3.9 Condición de Existencia
```sql
UPDATE productos_u4
SET    product_status = 'available'
WHERE  product_id IN (SELECT product_id FROM inventario_u4 WHERE quantity_on_hand >= 1);
```
> [ INSERTAR CAPTURA AQUI - 3.9 UPDATE existencia - available con stock ]

### 3.10 Lógica Compleja
```sql
UPDATE productos_u4
SET    list_price = list_price * 0.95
WHERE  list_price > (SELECT AVG(list_price) FROM productos_u4);

COMMIT;
```
> [ INSERTAR CAPTURA AQUI - 3.10 UPDATE logica compleja - -5% sobre media global ]

---

## Paso 4 – Bloque de Borrado (DELETE)

### 4.1 ID Específico
```sql
DELETE FROM productos_u4 WHERE product_id = 7000;
```
> [ INSERTAR CAPTURA AQUI - 4.1 DELETE ID - producto 7000 borrado ]

### 4.2 Filtro de Texto
```sql
DELETE FROM productos_u4 WHERE product_description LIKE '%Test%';
```
> [ INSERTAR CAPTURA AQUI - 4.2 DELETE texto - descripcion contiene Test ]

### 4.3 Rango Numérico
```sql
DELETE FROM productos_u4 WHERE list_price BETWEEN 0 AND 1;
```
> [ INSERTAR CAPTURA AQUI - 4.3 DELETE rango - list_price entre 0 y 1 ]

### 4.4 Estado y Categoría
```sql
DELETE FROM productos_u4 WHERE category_id = 10 AND product_status = 'under development';
```
> [ INSERTAR CAPTURA AQUI - 4.4 DELETE estado y categoria - cat10 under development ]

### 4.5 Sin Inventario
```sql
DELETE FROM productos_u4
WHERE  product_id NOT IN (SELECT DISTINCT product_id FROM inventario_u4);
```
> [ INSERTAR CAPTURA AQUI - 4.5 DELETE sin inventario - productos huerfanos ]

### 4.6 Subconsulta de Agregación
```sql
DELETE FROM productos_u4 WHERE min_price = (SELECT MIN(min_price) FROM productos_u4);
```
> [ INSERTAR CAPTURA AQUI - 4.6 DELETE subconsulta agregacion - min_price mas bajo ]

### 4.7 Relacional
```sql
DELETE FROM productos_u4
WHERE  product_id NOT IN (SELECT DISTINCT product_id FROM OE.ORDER_ITEMS);
```
> [ INSERTAR CAPTURA AQUI - 4.7 DELETE relacional - nunca vendidos ]

### 4.8 Basado en Almacén
```sql
DELETE FROM inventario_u4
WHERE  warehouse_id IN (
    SELECT w.warehouse_id FROM OE.WAREHOUSES w
    JOIN HR.LOCATIONS l ON w.location_id = l.location_id
    JOIN HR.COUNTRIES c ON l.country_id  = c.country_id
    WHERE c.country_name = 'Japan'
);
```
> [ INSERTAR CAPTURA AQUI - 4.8 DELETE almacen Japan - inventario_u4 ]

### 4.9 Doble Condición Subquery
```sql
DELETE FROM productos_u4
WHERE  category_id IN (
    SELECT category_id FROM productos_u4
    GROUP BY category_id HAVING COUNT(*) < 5
);
```
> [ INSERTAR CAPTURA AQUI - 4.9 DELETE doble subquery - categorias con menos de 5 ]

### 4.10 Limpieza Total
```sql
DELETE FROM productos_u4 WHERE product_id BETWEEN 7000 AND 8000;
COMMIT;
```
> [ INSERTAR CAPTURA AQUI - 4.10 DELETE limpieza total - IDs 7000-8000 ]

---

## Paso 5 – Transacciones y Concurrencia

### Preparación
```sql
CREATE TABLE cuenta_bancaria (
    id NUMBER PRIMARY KEY, titular VARCHAR2(50), saldo NUMBER(10,2)
);
INSERT INTO cuenta_bancaria VALUES (1, 'Usuario A', 1000);
INSERT INTO cuenta_bancaria VALUES (2, 'Usuario B', 2000);
COMMIT;
```
> [ INSERTAR CAPTURA AQUI - Preparacion cuenta_bancaria creada ]

---

### Escenario 1: Atomicidad (All-or-Nothing)
Se simula una transferencia a una cuenta inexistente (ID 99). El bloque PL/SQL detecta que el UPDATE no afectó ninguna fila y ejecuta ROLLBACK, garantizando que la cuenta 1 no pierda los 500€.

```sql
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
```
> [ INSERTAR CAPTURA AQUI - Escenario 1 - ROLLBACK atomicidad: cuenta 1 conserva 1000 euros ]

**Explicación:** Si solo se ejecutara el primer UPDATE sin revertirlo, la cuenta 1 perdería 500€ sin que nadie los recibiera. El ROLLBACK es imprescindible: o se completan las dos operaciones o no se completa ninguna.

---

### Escenario 2: Puntos de Guardado y Deshacer Parcial
```sql
UPDATE cuenta_bancaria SET saldo = saldo * 1.10;
SAVEPOINT sp_subida;

INSERT INTO cuenta_bancaria VALUES (3, 'Usuario C', 500);
SAVEPOINT sp_nuevo_usuario;

DELETE FROM cuenta_bancaria;

ROLLBACK TO SAVEPOINT sp_nuevo_usuario;
SELECT * FROM cuenta_bancaria;
COMMIT;
```
> [ INSERTAR CAPTURA AQUI - Escenario 2 - SAVEPOINT: 3 usuarios con saldos subidos ]

---

### Escenario 3: Bloqueos y Tiempo de Espera
```sql
-- TERMINAL 1: modifica sin commit (bloquea la fila)
UPDATE cuenta_bancaria SET saldo = 0 WHERE id = 1;

-- TERMINAL 2: queda bloqueada esperando a T1
-- UPDATE cuenta_bancaria SET saldo = 5000 WHERE id = 1;

-- TERMINAL 1: libera el bloqueo
COMMIT;
```
> [ INSERTAR CAPTURA AQUI - Escenario 3 - T1: UPDATE sin COMMIT ]
> [ INSERTAR CAPTURA AQUI - Escenario 3 - T2: sesion bloqueada esperando ]
> [ INSERTAR CAPTURA AQUI - Escenario 3 - Tras COMMIT en T1: T2 se desbloquea ]

---

### Escenario 4: El "Commit Fantasma" (DDL implícito)
```sql
DELETE FROM cuenta_bancaria WHERE id = 2;          -- DML sin commit
CREATE TABLE log_errores (msg VARCHAR2(100));       -- DDL hace COMMIT implicito
ROLLBACK;                                           -- Ya no recupera al Usuario 2
SELECT * FROM cuenta_bancaria;
```
> [ INSERTAR CAPTURA AQUI - Escenario 4 - Commit fantasma: Usuario 2 NO aparece ]

**Comportamiento de Oracle:** Antes de ejecutar cualquier sentencia DDL, Oracle confirma automáticamente todas las transacciones DML abiertas en esa sesión. Por eso el ROLLBACK posterior no tiene efecto: el DELETE ya fue confirmado de forma implícita por el `CREATE TABLE`. Mezclar DML y DDL en la misma sesión sin conocer este comportamiento puede provocar pérdidas de datos irrecuperables.

---

## Conclusión
Esta actividad ha permitido practicar las tres operaciones DML en Oracle con complejidad creciente: desde inserciones simples hasta subconsultas correlacionadas y operaciones masivas. El bloque TCL ha demostrado la importancia del control de transacciones: atomicidad, SAVEPOINTs, bloqueos concurrentes y el peligroso commit fantasma que Oracle ejecuta implícitamente ante cualquier sentencia DDL.
