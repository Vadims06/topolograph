# Session GRE

En **mode GRE**, un Watcher établit une véritable adjacence OSPF/IS-IS avec
l'un de vos routeurs via un **tunnel GRE**, puis transmet passivement chaque
changement d'état de liens vers Topolograph. Contrairement à un fichier
texte, il s'agit d'un flux *en direct* — le graphe et la chronologie des
événements se mettent à jour à mesure que le réseau change.

Le mode GRE fonctionne avec pratiquement n'importe quel routeur capable de
construire un tunnel GRE et d'exécuter OSPF/IS-IS par-dessus, ce qui en fait
l'option d'import en direct la plus largement compatible.

![Architecture du Watcher avec adjacence GRE et filtre XDP](../assets/ospfwatcher_architecture.png)

## Fonctionnement

- Le Watcher exécute une instance **FRR** dans un espace de noms réseau
  isolé.
- Ce FRR établit une adjacence OSPF (ou IS-IS) avec votre routeur **via un
  tunnel GRE**.
- Une fois l'adjacence établie, le routeur inonde sa LSDB vers le Watcher
  comme n'importe quel autre voisin — et le Watcher transforme chaque
  changement en événement pour Topolograph, ELK, Zabbix ou Slack.

!!! warning "Le Watcher est passif — et protégé"
    Le Watcher est un participant en **écoute seule**. Un **filtre XDP
    OSPF** inspecte tout ce que l'instance FRR tente d'annoncer et rejette
    toute description de base de données ou tout LSUpdate qui annonce plus
    que le réseau du tunnel GRE du Watcher lui-même. Cela garantit que le
    Watcher ne peut jamais injecter de préfixes inattendus dans votre
    domaine OSPF. Voir
    [Mode écoute seule](../monitoring/ospf-watcher.md#listen-only-mode-xdp).

Chaque Watcher conserve toutes les routes et mises à jour dans son **propre
espace de noms**, si bien qu'il n'affecte jamais le routage de l'hôte ni les
autres Watchers.

## 1. Configurer le tunnel sur le routeur

Construisez un tunnel GRE entre l'équipement et l'hôte exécutant le Watcher.
Exemple Cisco :

```text
interface Tunnel0
 ip address <gre-tunnel-ip>
 tunnel mode gre
 tunnel source <router-ip>
 tunnel destination <host-ip>
 ip ospf network type point-to-point
```

Incluez ensuite le réseau du tunnel GRE dans la configuration OSPF/IS-IS du
routeur pour qu'une adjacence puisse s'établir à travers lui.

## 2. Configurer le Watcher

Côté Watcher, le réseau du tunnel GRE est défini dans la configuration FRR
(`quagga/config/ospfd.conf` pour OSPF). Le déploiement de l'espace de noms
du laboratoire Watcher, par exemple via containerlab, crée :

- un espace de noms réseau isolé pour le Watcher et son FRR,
- une paire d'interfaces tap reliant le Watcher à l'hôte Linux,
- le **tunnel GRE** à l'intérieur de l'espace de noms du Watcher,
- le NAT pour le trafic GRE,
- les processus FRR + Watcher,
- le **filtre XDP OSPF** lié à l'interface tap du Watcher.

Les étapes précises se trouvent dans les dépôts des Watchers :
[OSPF Watcher](https://github.com/Vadims06/ospfwatcher) ·
[IS-IS Watcher](https://github.com/Vadims06/isiswatcher).

!!! tip "Pas de routeur sous la main ? Utilisez le mode test"
    Définissez `TEST_MODE=True` pour alimenter un Watcher à partir d'un
    fichier LSDB de démonstration statique et rejouer des changements
    d'exemple (perte d'adjacence, changement de métrique) — parfait pour
    essayer le pipeline de bout en bout sans aucun équipement. Il existe
    aussi un [laboratoire containerlab](../monitoring/ospf-watcher.md#quick-lab-containerlab)
    prêt à l'emploi.

## 3. Vérifier l'adjacence

Confirmez que le FRR du Watcher voit votre routeur comme voisin :

Ouvrez une console sur le FRR du Watcher et lancez `vtysh` :

```text
docker exec -it <watcher-container> vtysh
```

```text
show ip ospf neighbor      # OSPF
show isis neighbor         # IS-IS
```

Votre équipement réseau doit apparaître dans la sortie. Si ce n'est pas le
cas, le Watcher fournit un script de diagnostic — voir la section dépannage
des pages [OSPF Watcher](../monitoring/ospf-watcher.md) /
[IS-IS Watcher](../monitoring/isis-watcher.md).

## GRE vs BGP-LS

Le mode GRE nécessite un tunnel et une adjacence IGP par point de
rattachement. Si vos routeurs peuvent exporter la topologie via **BGP-LS**,
ce mode évite entièrement les tunnels et s'étend plus facilement à travers
les zones/niveaux.

[:octicons-arrow-right-24: Comparer avec BGP-LS](bgp-ls.md)

---

**Suivant :** voir ce que le Watcher fait du flux →
[OSPF Watcher](../monitoring/ospf-watcher.md) ·
[IS-IS Watcher](../monitoring/isis-watcher.md)
