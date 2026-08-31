# Visualización y Análisis

Este es el corazón de Topolograph: un grafo interactivo OSPF/IS-IS que puede
examinar con los mismos algoritmos que usan los routers. Todo lo que sigue se
ejecuta sobre su **instantánea** cargada, así que los experimentos nunca
afectan a la red en producción.

## Rutas más cortas

Elija un nodo de origen y uno de destino y Topolograph construye el **árbol
de ruta más corta** entre ellos, resaltando la(s) ruta(s) y mostrando el
costo total del IGP.

![Árbol de ruta más corta entre dos nodos](../static/SPT.png)

Cuando existen varias rutas de igual costo, **ECMP** se muestra
explícitamente para que pueda ver dónde se balancea la carga del tráfico.

![Topología con rutas ECMP](../static/topology_with_ecmp.png)

## Rutas de respaldo

Topolograph no solo muestra la ruta primaria — calcula la **ruta de
respaldo** que la red usaría realmente si la primaria fallara, incluidos los
respaldos **secundarios**. Esto responde la pregunta que surge en toda
ventana de cambios: *"si este enlace cae, ¿a dónde va el tráfico?"*

![Árbol de ruta más corta de respaldo](../static/backup_SPT.png)

También distingue las rutas de respaldo que se apoyan en ECMP de las que no,
lo cual importa al razonar sobre la capacidad durante un fallo.

## Simulación de fallos { #simulating-failures }

Pruebe escenarios hipotéticos sin tocar nada en producción.

### Apagar un enlace

Elimine un enlace y Topolograph recalcula las rutas al instante, mostrando
cómo se redirige el tráfico a su alrededor.

![Reacción de la red al eliminar un enlace](../static/network_reaction_rem_edge1.png)

Puede ver el resultado junto con las estadísticas afectadas:

![Reacción de la red a un enlace eliminado, con estadísticas](../static/network_reaction_rem_edge_with_stat.png)

### Apagar un nodo

Simule la caída de un router completo y observe cómo fluye el tráfico
alrededor del nodo fallido. Haga clic derecho en un nodo y elija
**Shutdown this node**.

![Reacción de la red al apagar un nodo](../static/network_reaction_shut_node.png)

![Resultado después de apagar un nodo](../static/network_reaction_result_on_shut_node.png)

## Planificación de costos de enlace

Cambie una métrica de IGP al instante y vea de inmediato el efecto en la
selección de rutas — ideal para planificar un mantenimiento, desviar tráfico
de un enlace o validar un diseño de costos antes de aplicarlo.

Asegúrese de seguir en la pestaña **Reacción de la red a fallos**. Haga clic
derecho en un enlace: aparece un formulario con la lista de enlaces. Defina
un nuevo valor de métrica junto al enlace que necesite; el resultado del
recálculo de rutas se muestra en el grafo de inmediato.

![Reacción de la red a un cambio de costo OSPF](../static/network_reaction_ospf_cost_change.png)

## Mapa de Calor de Red { #network-heatmap }

El **Mapa de Calor de Red** (en Analytics) revela de un vistazo las
propiedades estructurales de la topología — qué enlaces y nodos transportan
más rutas, dónde están sus puntos únicos de fallo y qué redes **no tienen
ruta de respaldo**.

![Mapa de calor de red con redes](../static/network_heatmap_with_networks.png)

Los nodos marcados en rojo concentran la mayor cantidad de redes sin ruta de
respaldo.

Filtre por las redes que **no tienen respaldo** para encontrar exactamente
dónde un único fallo causaría una pérdida de alcanzabilidad:

![Mapa de calor resaltando redes sin respaldo](../static/network_heatmap_with_not_backuped_networks.png)

## Detección de rutas asimétricas

El enrutamiento que toma una ruta de ida y otra distinta de vuelta puede
complicar los firewalls, el QoS y la resolución de problemas. El informe
**Analytics → Asymmetric paths** de Topolograph encuentra estos pares por
usted.

![Menú de Analytics — rutas asimétricas](../static/analytics_menu_asym_paths.png)

![Un ejemplo real de ruta asimétrica](../static/asymmetric_path_real_example.png)

## Hacia dónde ir después

<div class="grid cards" markdown>

-   :material-compare:{ .lg .middle } __Compare dos instantáneas__

    ---

    Vea qué cambió entre capturas.

    [:octicons-arrow-right-24: Comparación de estados](comparing-states.md)

-   :material-tune-variant:{ .lg .middle } __Agregue datos de TE__

    ---

    Ancho de banda, métrica de TE, grupos administrativos.

    [:octicons-arrow-right-24: Traffic Engineering](traffic-engineering.md)

-   :material-radar:{ .lg .middle } __Obsérvelo en vivo__

    ---

    Capture cada cambio a medida que ocurre.

    [:octicons-arrow-right-24: Monitoreo en tiempo real](../monitoring/index.md)

</div>
