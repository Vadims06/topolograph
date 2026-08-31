# Comparaison des états du réseau

Chaque topologie que vous importez est un **instantané** — le réseau figé
au moment de la capture. Topolograph conserve vos instantanés dans le
temps, ce qui signifie que vous pouvez en mettre deux côte à côte et voir
*exactement* ce qui a changé.

## Le flux de travail classique

1. **Instantané avant.** Importez la LSDB actuelle (ou laissez un
   [Watcher](../monitoring/index.md) alimenter automatiquement les
   instantanés en continu).
2. **Effectuez votre changement.** Par exemple, redistribuez des routes de
   BGP vers OSPF avec une route-map et une prefix-list, ajustez une
   métrique de lien, ou ajoutez une nouvelle adjacence.
3. **Instantané après.** Importez la nouvelle LSDB.
4. **Comparez.** Topolograph met en évidence les différences entre les deux
   états.

Comme chaque import est horodaté, vous pouvez comparer deux moments
quelconques — pas seulement des moments consécutifs.

## Ce que montre une comparaison

- Les **liens** qui sont apparus ou ont disparu entre les deux états.
- Les **changements de coût** sur les liens existants.
- Les **réseaux/préfixes** ajoutés ou retirés.
- Les **nœuds** qui ont rejoint ou quitté la topologie.

Cela transforme la question « mon changement a-t-il fait ce que
j'attendais ? » en une réponse visuelle et vérifiable — au lieu de comparer
à l'œil la sortie brute des commandes `show`.

## Se marie bien avec la surveillance

Les instantanés manuels avant/après sont parfaits pour les changements
planifiés. Pour les changements *non planifiés*, un
[Watcher](../monitoring/index.md) enregistre en continu chaque transition,
si bien que vous pouvez remonter dans une chronologie d'états et voir ce
qui a changé et quand — et déclencher des alertes via
[ELK](../monitoring/elk-kibana.md), [Zabbix](../monitoring/zabbix.md) ou
[Slack](../monitoring/webhooks.md).

---

**Suivant :** [Construire des topologies arbitraires avec YAML →](yaml-topologies.md)
