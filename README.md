# Lenguaje SQL — ConsultaDatos DML

**Escenario Técnico: CineGest 2.0**

Base de datos relacional para una cadena de cines:

- `CINES` (id_cine, nombre, ciudad)
- `PELICULAS` (id_pelicula, titulo, director, genero)
- `PROYECCIONES` (id_proyeccion, id_cine, id_pelicula, fecha, hora, recaudacion)
  > *Nota: id_cine e id_pelicula son claves ajenas*

---

## EJERCICIO 1: Consultas Básicas y Composiciones

### 1. Título y género de películas de 'Ciencia Ficción', ordenadas alfabéticamente

```sql
SELECT titulo, genero
FROM PELICULAS
WHERE genero = 'Ciencia Ficción'
ORDER BY titulo ASC;
```

### 2. Nombre del cine y título de la película para todas las proyecciones (JOIN interno)

```sql
SELECT C.nombre, P.titulo
FROM PROYECCIONES PR
INNER JOIN CINES C ON PR.id_cine = C.id_cine
INNER JOIN PELICULAS P ON PR.id_pelicula = P.id_pelicula;
```

### 3. Nombre de todos los cines e id_pelicula de sus proyecciones, incluyendo los nulos (JOIN externo)

Queremos saber qué cines **no** han proyectado películas hoy. Se usa `LEFT JOIN` para incluir cines sin proyecciones registradas:

```sql
SELECT C.nombre, PR.id_pelicula
FROM CINES C
LEFT JOIN PROYECCIONES PR ON C.id_cine = PR.id_cine;
```

> Con `LEFT JOIN` se muestran **todos** los cines, y aquellos sin proyecciones aparecerán con `NULL` en `id_pelicula`.

---

## EJERCICIO 2: Consultas de Resumen y Agrupación

### 1. Recaudación total acumulada por cada cine

```sql
SELECT C.nombre, SUM(PR.recaudacion) AS total_recaudacion
FROM PROYECCIONES PR
INNER JOIN CINES C ON PR.id_cine = C.id_cine
GROUP BY C.nombre;
```

### 2. Solo los cines con recaudación total superior a 5.000 €

```sql
SELECT C.nombre, SUM(PR.recaudacion) AS total_recaudacion
FROM PROYECCIONES PR
INNER JOIN CINES C ON PR.id_cine = C.id_cine
GROUP BY C.nombre
HAVING SUM(PR.recaudacion) > 5000;
```

> **¿Por qué `HAVING` y no `WHERE`?**
>
> `WHERE` filtra filas **antes** de agrupar, por lo que no puede operar sobre valores agregados como `SUM()`. `HAVING` filtra **después** de que `GROUP BY` ha calculado los grupos y sus agregados, lo que permite filtrar por el resultado de funciones como `SUM`, `COUNT`, `AVG`, etc.

---

## EJERCICIO 3: Subconsultas y Herramientas

### 1. Títulos de películas con recaudación superior a la media en una sesión individual

```sql
SELECT DISTINCT P.titulo
FROM PELICULAS P
INNER JOIN PROYECCIONES PR ON P.id_pelicula = PR.id_pelicula
WHERE PR.recaudacion > (
    SELECT AVG(recaudacion)
    FROM PROYECCIONES
);
```

### 2. Comando DML para mostrar resultados en MySQL Workbench vs Consola CLI

El comando de manipulación de datos que se ejecuta en **ambas herramientas** para mostrar resultados es `SELECT`. La diferencia entre herramientas es únicamente de interfaz:

| Herramienta | Cómo se muestran los resultados |
|---|---|
| **MySQL Workbench** | Los resultados aparecen en una tabla gráfica en el panel inferior, con columnas y filas fácilmente legibles. |
| **Consola CLI** | Los resultados se muestran en texto plano con formato de tabla ASCII directamente en la terminal. |

En ambos casos el comando SQL es idéntico; la diferencia es solo visual. Workbench facilita la lectura y exportación; la CLI es más rápida para entornos sin interfaz gráfica.

---

## EJERCICIO 4: Optimización de Consultas

### 1. Índice para acelerar búsquedas por `fecha` en PROYECCIONES

Si la tabla `PROYECCIONES` tuviera millones de registros y las búsquedas por `fecha` fueran lentas, se crearía el siguiente índice:

```sql
CREATE INDEX idx_proyecciones_fecha ON PROYECCIONES(fecha);
```

> **¿Por qué un índice evita leer la tabla completa?**
>
> Sin índice, el motor de base de datos realiza un **Full Table Scan**: recorre fila a fila toda la tabla hasta encontrar las coincidencias. Con un índice sobre `fecha`, el motor construye una estructura ordenada (árbol B) que permite localizar directamente las filas con la fecha buscada, sin recorrer el resto. Esto reduce drásticamente el tiempo de respuesta y el uso de I/O en disco.

### 2. Consulta eficiente vs. ineficiente para obtener títulos de películas proyectadas en 2023

**Versión 1 — Ineficiente** (malas prácticas de selección y filtrado):

```sql
SELECT *
FROM PROYECCIONES PR, PELICULAS P
WHERE PR.id_pelicula = P.id_pelicula
AND YEAR(PR.fecha) = 2023;
```

Problemas:
- `SELECT *` recupera todas las columnas de ambas tablas, generando tráfico de red innecesario.
- `YEAR(PR.fecha)` aplica una función sobre la columna, lo que **impide usar el índice** sobre `fecha` (el motor no puede aplicar el índice con funciones envolventes).
- Sintaxis de JOIN implícito (coma), menos legible y propensa a errores.

**Versión 2 — Optimizada**:

```sql
SELECT P.titulo
FROM PROYECCIONES PR
INNER JOIN PELICULAS P ON PR.id_pelicula = P.id_pelicula
WHERE PR.fecha BETWEEN '2023-01-01' AND '2023-12-31';
```

Mejoras:
- `SELECT P.titulo` recupera solo la columna necesaria → **menos tráfico de red y menos memoria**.
- `BETWEEN` opera directamente sobre el valor de `fecha` sin funciones → **el motor puede usar el índice** sobre `fecha`.
- `INNER JOIN` explícito → más legible y estándar.

> **Importancia de la optimización:**
>
> | Aspecto | Versión ineficiente | Versión optimizada |
> |---|---|---|
> | **Tráfico de red** | Alto (todas las columnas) | Bajo (solo `titulo`) |
> | **Uso de memoria** | Alto (filas completas) | Bajo (columna única) |
> | **Aprovechamiento de índices** | No (función `YEAR()` lo bloquea) | Sí (`BETWEEN` lo permite) |
>
> En tablas grandes, la diferencia puede ser de segundos frente a milisegundos.
