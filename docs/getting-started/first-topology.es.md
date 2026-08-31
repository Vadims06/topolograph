# Su Primera Topología

Este recorrido lo lleva desde una instancia de Topolograph recién iniciada
hasta su primer grafo analizado usando la entrada más simple: un **archivo
de texto** copiado de un router.

!!! info "Necesitará"
    - Una instancia de Topolograph en ejecución ([instalar con Docker](quickstart-docker.md)).
    - Acceso a **un** router en el área OSPF o IS-IS que quiera mapear.

## 1. Obtenga la LSDB de un dispositivo

Como toda el área comparte una misma base de datos, solo necesita
recolectarla de un único router. Elija el comando para su plataforma — la
matriz completa está en la página de
[Proveedores compatibles](../reference/supported-vendors.md). Por ejemplo:

=== "Cisco (OSPF)"

    ```
    show ip ospf database router
    show ip ospf database network
    show ip ospf database external
    ```

=== "Juniper (OSPF)"

    ```
    show ospf database router extensive | no-more
    show ospf database network extensive | no-more
    show ospf database external extensive | no-more
    ```

=== "FRRouting (OSPF)"

    ```
    show ip ospf database router
    show ip ospf database network
    show ip ospf database external
    ```

=== "Cisco (IS-IS)"

    ```
    show isis database detail
    ```

Guarde la salida en un archivo de texto plano. Puede pegar las secciones
LSA 1 / 2 / 5 en un único archivo.

!!! tip "Enlaces más completos (opcional)"
    Para OSPF en FRRouting, agregue la salida de
    `show ip ospf database opaque-area` al mismo archivo para incorporar
    datos de ancho de banda, métrica de TE y grupo administrativo. Esto es
    opcional — el grafo se sigue construyendo solo con LSA 1/2/5. Consulte
    [Traffic Engineering](../analysis/traffic-engineering.md).

## 2. Súbala

1. Abra Topolograph en `http://localhost:8080/`.
2. Elija subir una topología y pegue (o suba) su archivo de texto.
3. Seleccione el **proveedor** y el **protocolo** que coinciden con su
   captura.
4. Envíe — Topolograph analiza la LSDB y renderiza el grafo.

![Subir una LSDB y obtener un grafo](../assets/text_file_and_short_paths.gif)

El resultado es una **instantánea**: una imagen congelada del estado de la
red en el momento en que capturó la base de datos. Todo análisis que
ejecute ocurre sobre esta instantánea, así que nada de lo que haga aquí
puede afectar a la red en vivo.

## 3. Construya una ruta más corta

Con el grafo en pantalla, elija un nodo de origen y otro de destino y
construya la ruta más corta entre ellos. Topolograph resalta la ruta y
muestra su costo total.

![Construir un árbol de ruta más corta](../assets/build-spt.gif)

Desde aquí puede de inmediato:

- Revelar la **ruta de respaldo** que la red usaría si la primaria fallara.
- **Apagar un enlace o nodo** y observar cómo se redirige el tráfico.
- Abrir el **Mapa de calor de red** para encontrar sus enlaces más cargados y
  menos protegidos.

Todo esto se cubre en [Análisis y visualización](../analysis/index.md).

## 4. Hacia dónde ir después

<div class="grid cards" markdown>

-   :material-transit-connection-variant:{ .lg .middle } __Transmítala en vivo__

    ---

    ¿Cansado de copiar y pegar? Haga que un Watcher alimente la topología
    automáticamente mediante GRE o BGP-LS.

    [:octicons-arrow-right-24: Cómo obtener la topología](../ingestion/index.md)

-   :material-vector-polyline:{ .lg .middle } __Profundice en el análisis__

    ---

    Rutas de respaldo, ECMP, simulación de fallos, planificación de costos y
    el mapa de calor.

    [:octicons-arrow-right-24: Análisis y visualización](../analysis/index.md)

-   :material-radar:{ .lg .middle } __Monitoree de forma continua__

    ---

    Capture cada cambio de adyacencia y costo y envíelo a ELK, Zabbix o Slack.

    [:octicons-arrow-right-24: Monitoreo en tiempo real](../monitoring/index.md)

-   :material-console:{ .lg .middle } __Automatícelo__

    ---

    Recolecte y suba LSDB con la CLI `topo` y el SDK de Python.

    [:octicons-arrow-right-24: Python SDK](../automation/python-sdk.md)

</div>
