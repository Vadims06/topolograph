# IS-IS Watcher

**IS-IS Watcher** es la contraparte de [OSPF Watcher](ospf-watcher.md) para
IS-IS. Escucha de forma pasiva el plano de control de IS-IS — mediante una
[adyacencia GRE](../ingestion/gre.md) o [BGP-LS](../ingestion/bgp-ls.md) — y
registra o exporta cada cambio hacia **ELK**, **Zabbix**, **WebHooks**, y el
panel de monitoreo de **Topolograph**. Al igual que OSPF Watcher, se
distribuye como contenedores.

[:simple-github: vadims06/isiswatcher](https://github.com/Vadims06/isiswatcher){ .md-button }

![Arquitectura de IS-IS Watcher + Topolograph](../assets/isiswatcher_architecture.png)

## Eventos detectados

- Adyacencia de vecino IS-IS **arriba/abajo**
- **Cambios de costo** de enlace IS-IS
- Redes IS-IS que **aparecen/desaparecen**
- **Atributos de TE** de IS-IS: grupo administrativo, ancho de banda máximo
  del enlace, ancho de banda máximo reservable, ancho de banda no reservado,
  métrica de TE por defecto, y shared risk link group (SRLG)
- **Flags de nodo** de IS-IS: transiciones de **overload (OL)** y
  **attached (ATT)** (además de ABR/ASBR derivados mediante BGP-LS)

Todo se agrupa por **nivel de IS-IS (L1/L2)** en la línea de tiempo:

![Panel de Topolograph con eventos L1/L2 de IS-IS](../assets/dashboard_l1_l2_events.png)

!!! example "Cómo se ven los niveles"
    Una captura típica podría mostrar: un cambio de métrica en un enlace que
    aparece como **registros duplicados tanto para L1 como para L2**; un
    router que cae **solo para L2** después de aplicar
    `isis circuit-type level-1`; un cambio de métrica posterior visto
    **solo en L1**; y una nueva red stub que aparece **en L2**.

## Conectarlo

La configuración de la conexión está en
[Cómo Obtener la Topología](../ingestion/index.md):

- [**Modo GRE**](../ingestion/gre.md) — FRR forma una adyacencia IS-IS
  mediante un túnel GRE; un **filtro IS-IS XDP** mantiene al Watcher en
  modo de solo escucha descartando cualquier LSP que anuncie más que la
  propia red del Watcher.
- [**Modo BGP-LS**](../ingestion/bgp-ls.md) — el router exporta la topología
  IS-IS mediante BGP-LS; GoBGP + el reenviador alimentan al Watcher.

![Instancias FRR individuales por área mediante GRE](../assets/gre_frr_instances.png)

!!! warning "Un túnel GRE por área"
    IS-IS, al igual que OSPF, inunda por área/nivel. En modo GRE necesita
    **al menos un túnel GRE hacia cada área** que quiera monitorear — esto
    es una propiedad de la inundación de estado de enlace, no una
    limitación de la herramienta. BGP-LS evita esto al transportar todo el
    dominio en una única sesión.

!!! note "Compatibilidad"
    Los cambios de red IS-IS aparecen en el grafo a partir de
    [topolograph v2.38](https://github.com/Vadims06/topolograph/releases/tag/v2.38)
    o posterior.

## Soporte de TLV y métricas

IS-IS Watcher analiza tanto las métricas de estilo antiguo (narrow) como las
de estilo nuevo (wide) y admite alcanzabilidad IPv6. Los TLV que entiende —
y la matriz de compatibilidad por proveedor — se resumen en la página
[Proveedores compatibles](../reference/supported-vendors.md#is-is-tlv-support).

TLV clave: IS Reachability (2), Extended IS Reachability (22), IPv4
Internal/Extended Reachability (128/135), e IPv6 Reachability (236).

!!! info "Compilación personalizada de FRR"
    Ejecutar IS-IS sobre GRE requiere una compilación de FRR capaz de
    hacerlo; el repositorio de IS-IS Watcher provee la compilación
    necesaria. Consulte el [repositorio](https://github.com/Vadims06/isiswatcher)
    para más detalles.

## Laboratorio rápido (containerlab)

El repositorio incluye una topología de containerlab para probar el
monitoreo de IS-IS de extremo a extremo — consulte el directorio
`containerlab/` y la tabla de
[tamaños de implementación](index.md#deployment-sizes) para saber cómo
agregar Topolograph y ELK.

!!! tip "¿Sin dispositivo? Modo de prueba"
    Al igual que con OSPF Watcher, `TEST_MODE` reproduce eventos de
    demostración de IS-IS desde un archivo estático, para que pueda probar
    todo el flujo sin hardware.

## Formato del registro de eventos

IS-IS Watcher emite los mismos registros de eventos separados por comas que
OSPF Watcher (con el **nivel** de IS-IS incluido junto a ellos) — así que
las integraciones de [ELK](elk-kibana.md), [Zabbix](zabbix.md) y
[Webhook](webhooks.md) funcionan de forma idéntica. Consulte el
[formato de registro de OSPF Watcher](ospf-watcher.md#event-log-format)
para un desglose campo por campo.

---

**Relacionado:** [OSPF Watcher](ospf-watcher.md) ·
[Traffic Engineering](../analysis/traffic-engineering.md) ·
[ELK / Kibana](elk-kibana.md)
