# OSPF Watcher

**OSPF Watcher** es una herramienta de monitoreo para cambios de topología
OSPF. Escucha de forma pasiva el plano de control de OSPF — mediante una
[adyacencia GRE](../ingestion/gre.md) o [BGP-LS](../ingestion/bgp-ls.md) — y
registra cada cambio y/o lo exporta (mediante Logstash o Fluent Bit) hacia
**ELK**, **Zabbix**, **WebHooks**, y el panel de monitoreo de
**Topolograph**. Todo se distribuye como contenedores, así que arranca
rápido.

[:simple-github: vadims06/ospfwatcher](https://github.com/Vadims06/ospfwatcher){ .md-button }

![Arquitectura de OSPF Watcher + Topolograph con reglas XDP](../assets/ospfwatcher_architecture.png)

## Eventos detectados

- Adyacencia de vecino OSPF **arriba/abajo**
- **Cambios de costo** de enlace OSPF
- Redes OSPF que **aparecen/desaparecen**
- **Atributos de TE** de OSPF (mediante opaque LSA o BGP-LS): grupo
  administrativo, ancho de banda máximo del enlace, ancho de banda máximo
  reservable, ancho de banda no reservado, métrica de TE por defecto, y
  shared risk link group (SRLG)
- **Cambios de rol de nodo** en OSPF: un router que se convierte (o deja de
  ser) en **ABR** (Area Border Router), **ASBR** (AS Boundary Router), o que
  entra/sale de **max-metric** (RFC 3137, stub router — todos los enlaces
  de tránsito se anuncian con la métrica máxima para desviar el tráfico de
  tránsito; el equivalente en OSPF del overload bit de IS-IS)

![Monitoreo OSPF — evento de nueva subred](../assets/ospf_monitoring_new_subnet.png)

![Monitoreo OSPF — cambio de métrica, costo anterior y nuevo](../assets/ospf_monitoring_change_metric.png)

![Monitoreo OSPF — eventos de enlace arriba/abajo en la línea de tiempo](../assets/ospf_monitoring_down_link.png)

## Conectarlo

La conexión en sí se configura en
[Cómo Obtener la Topología](../ingestion/index.md):

- [**Modo GRE**](../ingestion/gre.md) — FRR forma una adyacencia OSPF
  mediante un túnel GRE. Un **filtro OSPF XDP** garantiza que el Watcher se
  mantenga en modo de solo escucha.
- [**Modo BGP-LS**](../ingestion/bgp-ls.md) — el router exporta la topología
  OSPF mediante BGP-LS; GoBGP + el reenviador alimentan al Watcher. Requiere
  la imagen **`vadims06/ospf-watcher:v3.1.0`** o posterior.

!!! note "Compatibilidad"
    Los cambios de red OSPF aparecen en el grafo de Topolograph a partir de
    [topolograph v2.27](https://github.com/Vadims06/topolograph/releases/tag/v2.27)
    o posterior.

## Laboratorio rápido (containerlab) { #quick-lab-containerlab }

Un laboratorio ya preparado en `containerlab/frr01` le permite observar
cambios de OSPF sin hardware real:

```bash
./containerlab/frr01/prepare.sh
sudo clab deploy --topo ./containerlab/frr01/frr01.clab.yml
```

![Registros del laboratorio containerlab de OSPF Watcher](../assets/ospfwatcher_containerlab.png)

En esta configuración mínima, el Watcher imprime los cambios de topología en
un archivo de texto. Agregue Topolograph y/o ELK para visualizarlos y
buscarlos — consulte la tabla de
[tamaños de implementación](index.md#deployment-sizes).

!!! tip "¿Sin dispositivo? Modo de prueba"
    Establezca `TEST_MODE=True` para reproducir una LSDB de demostración y
    eventos de ejemplo (pérdida de adyacencia, cambio de métrica) de extremo
    a extremo a través del flujo.

## Formato del registro de eventos { #event-log-format }

Los eventos del Watcher son líneas simples separadas por comas. Un evento de
host (adyacencia):

```text
2023-01-01T00:00:00Z,demo-watcher,host,10.10.10.4,down,10.10.10.5,01Jan2023_00h00m00s_7_hosts,0,1234,192.168.145.5
```

> `10.10.10.5` detectó que el host `10.10.10.4`, en la interfaz con
> `192.168.145.5`, en el área `0` / AS `1234`, quedó **abajo** en la marca
> de tiempo indicada.

Un evento de cambio de métrica:

```text
2023-01-01T00:00:00Z,demo-watcher,network,192.168.13.0/24,changed,old_cost:10,new_cost:12,10.10.10.1,01Jan2023_00h00m00s_7_hosts,0.0.0.0,1234,internal,0
```

> `10.10.10.1` detectó que la métrica de la red stub interna
> `192.168.13.0/24` cambió de `10` a `12`.

Un evento de cambio de flag de nodo:

```text
2023-01-01T00:00:00Z,demo-watcher,node,10.1.1.3,changed,attr:abr,old:0,new:1,10.1.1.3,01Jan2023_00h00m00s_7_hosts,0,1234
```

> `10.1.1.3` se anunció a sí mismo como **ABR** (`abr` `0` → `1`). Se emite
> un evento por cada flag cambiado (`abr`, `asbr`, `maxmetric` para OSPF;
> `overload`, `attached` para IS-IS). Entrar en max-metric también emite un
> evento `metric` por enlace, ya que el costo de cada enlace de tránsito
> salta a su máximo.

Estos registros son los que Logstash/Fluent Bit reenvían a
[ELK](elk-kibana.md), [Zabbix](zabbix.md) y [Webhooks](webhooks.md).

## Modo de solo escucha (XDP) { #listen-only-mode-xdp }

En modo GRE, el Watcher ejecuta una instancia real de FRR — así que es
crítico que **nunca** pueda inyectar prefijos en su dominio OSPF. Un
**filtro XDP** inspecciona cada mensaje OSPF que FRR intenta enviar y
descarta cualquier cosa que anuncie más que la propia red del túnel GRE del
Watcher.

![Wireshark antes/después del filtro XDP](../assets/xdp_lsa5_drop.png)

Por ejemplo, si `8.8.8.8/32` se redistribuyera accidentalmente en el
Watcher, la LSA 5 es descartada por XDP y nunca llega a la red. La misma
protección se aplica a los mensajes Database Description y a las redes stub
adicionales en LSA 1.

Comandos útiles:

```bash
# Watch XDP drop logs
sudo cat /sys/kernel/debug/tracing/trace_pipe

# Confirm the XDP program is attached to the Watcher's interface
ip l show dev it-vhost1025      # look for "prog/xdp id ..."

# Enable / disable the filter
sudo docker run -it --rm -v ./:/home/watcher/watcher/ --cap-add=NET_ADMIN \
  -u root --network host vadims06/ospf-watcher:latest \
  python3 ./client.py --action enable_xdp --watcher_num <num>
```

## Solución de problemas

**Modo GRE** — confirme la adyacencia:

```text
show ip ospf neighbor
```

Su dispositivo debería aparecer como vecino. Si no aparece, ejecute el
script de diagnóstico del Watcher (consulte la sección de solución de
problemas del repositorio).

**Modo BGP-LS** — el Watcher publica en Topolograph solo después de que la
sesión BGP está activa. Verifíquelo:

```bash
docker logs watcher<num>-bgpls-ospf-bgplswatcher
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp neighbor
docker exec -it watcher<num>-bgpls-ospf-bgplswatcher gobgp global rib -a ls
```

Consulte [Sesión BGP-LS](../ingestion/bgp-ls.md#3-verify-the-bgp-ls-session)
para el flujo de verificación completo.

---

**Relacionado:** [IS-IS Watcher](isis-watcher.md) ·
[ELK / Kibana](elk-kibana.md) · [Zabbix](zabbix.md) · [Webhooks](webhooks.md)
