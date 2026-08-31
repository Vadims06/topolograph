# Sesión GRE

En **modo GRE**, un Watcher forma una adyacencia OSPF/IS-IS real con uno de
sus routers mediante un **túnel GRE**, y luego reenvía de forma pasiva cada
cambio de estado de enlace hacia Topolograph. A diferencia de un archivo de
texto, este es un flujo *en vivo* — el grafo y la línea de tiempo de eventos
se actualizan a medida que la red cambia.

El modo GRE funciona con prácticamente cualquier router que pueda construir
un túnel GRE y ejecutar OSPF/IS-IS sobre él, lo que lo convierte en la
opción de ingesta en vivo más ampliamente compatible.

![Arquitectura del Watcher con adyacencia GRE y filtro XDP](../assets/ospfwatcher_architecture.png)

## Cómo funciona

- El Watcher ejecuta una instancia de **FRR** dentro de un espacio de nombres
  de red aislado.
- Ese FRR forma una adyacencia OSPF (o IS-IS) con su router **mediante un
  túnel GRE**.
- Una vez adyacente, el router inunda su LSDB hacia el Watcher como con
  cualquier otro vecino — y el Watcher convierte cada cambio en un evento
  para Topolograph, ELK, Zabbix o Slack.

!!! warning "El Watcher es pasivo — y está protegido"
    El Watcher es un participante de **solo escucha**. Un **filtro OSPF XDP**
    inspecciona todo lo que la instancia de FRR intenta anunciar y descarta
    cualquier DB description o LSUpdate que anuncie más que la propia red del
    túnel GRE del Watcher. Esto garantiza que el Watcher nunca pueda inyectar
    prefijos inesperados en su dominio OSPF. Consulte
    [Modo de solo escucha](../monitoring/ospf-watcher.md#listen-only-mode-xdp).

Cada Watcher mantiene todas las rutas y actualizaciones dentro de su
**propio espacio de nombres**, así que nunca afecta el enrutamiento del host
ni a otros Watchers.

## 1. Configure el túnel en el router

Construya un túnel GRE desde el dispositivo hasta el host que ejecuta el
Watcher. Un ejemplo con Cisco:

```text
interface Tunnel0
 ip address <gre-tunnel-ip>
 tunnel mode gre
 tunnel source <router-ip>
 tunnel destination <host-ip>
 ip ospf network type point-to-point
```

Luego incluya la red del túnel GRE en la configuración de OSPF/IS-IS del
router para que pueda formarse una adyacencia a través de ella.

## 2. Configure el Watcher

Del lado del Watcher, la red del túnel GRE se establece en la configuración
de FRR (`quagga/config/ospfd.conf` para OSPF). Implementar el espacio de
nombres de laboratorio del Watcher, por ejemplo mediante containerlab,
crea:

- un espacio de nombres de red aislado para el Watcher y su FRR,
- un par de interfaces tap que conecta el Watcher con el host Linux,
- el **túnel GRE** dentro del espacio de nombres del Watcher,
- NAT para el tráfico GRE,
- los procesos de FRR + Watcher,
- el **filtro OSPF XDP** vinculado a la interfaz tap del Watcher.

Los pasos exactos están en los repositorios del Watcher:
[OSPF Watcher](https://github.com/Vadims06/ospfwatcher) ·
[IS-IS Watcher](https://github.com/Vadims06/isiswatcher).

!!! tip "¿No tiene un router a mano? Use el modo de prueba"
    Establezca `TEST_MODE=True` para alimentar un Watcher desde un archivo
    LSDB de demostración estático y reproducir cambios de ejemplo (pérdida de
    adyacencia, cambio de métrica) — perfecto para probar el flujo completo
    sin ningún dispositivo. También hay un
    [laboratorio containerlab](../monitoring/ospf-watcher.md#quick-lab-containerlab)
    listo para usar.

## 3. Verifique la adyacencia

Confirme que el FRR del Watcher ve a su router como vecino:

Abra una consola en el FRR del Watcher y ejecute `vtysh`:

```text
docker exec -it <watcher-container> vtysh
```

```text
show ip ospf neighbor      # OSPF
show isis neighbor         # IS-IS
```

Su dispositivo de red debería aparecer en la salida. Si no aparece, el
Watcher incluye un script de diagnóstico — consulte la sección de solución
de problemas en las páginas de
[OSPF Watcher](../monitoring/ospf-watcher.md) /
[IS-IS Watcher](../monitoring/isis-watcher.md).

## GRE vs BGP-LS

El modo GRE necesita un túnel y una adyacencia de IGP por punto de conexión.
Si sus routers pueden exportar la topología mediante **BGP-LS**, ese modo
evita los túneles por completo y escala con más facilidad entre áreas/niveles.

[:octicons-arrow-right-24: Comparar con BGP-LS](bgp-ls.md)

---

**Siguiente:** vea qué hace el Watcher con el flujo →
[OSPF Watcher](../monitoring/ospf-watcher.md) ·
[IS-IS Watcher](../monitoring/isis-watcher.md)
