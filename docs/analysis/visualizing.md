# Visualizing & Analyzing

This is the heart of Topolograph: an interactive OSPF/IS-IS graph you can probe
with the same algorithms the routers use. Everything below runs against your
uploaded **snapshot**, so experiments never affect the production network.

## Shortest paths

Pick a source and a destination node and Topolograph builds the **shortest path
tree** between them, highlighting the path(s) and showing the total IGP cost.

![Shortest path tree between two nodes](../static/SPT.png)

When multiple equal-cost paths exist, **ECMP** is shown explicitly so you can see
where traffic load-balances.

![Topology with ECMP paths](../static/topology_with_ecmp.png)

## Backup paths

Topolograph doesn't just show the primary path — it computes the **backup path**
the network would actually use if the primary failed, including **secondary**
backups. This answers the question every change-window raises: *"if this link
goes, where does the traffic go?"*

![Backup shortest path tree](../static/backup_SPT.png)

When you reason about capacity during a failure, all links are counted, whether
or not they belong to an ECMP set.

## Simulating failures { #simulating-failures }

Test "what if" scenarios without changing anything on the live network.

### Shut a link

First make sure you are in failure-reaction mode: switch from the general view to
the **Network reaction to failure** tab. On that tab a left-click on a link
changes behaviour — each click simulates an adjacency going down / the link being
removed from the graph. Topolograph recomputes paths instantly and shows how
traffic re-routes around it.

![Network reaction to removing a link](../static/network_reaction_rem_edge1.png)

You can see the result together with statistics on the recalculated paths:

![Network reaction to a removed edge, with stats](../static/network_reaction_rem_edge_with_stat.png)

### Shut a node

Simulate an entire router failing and watch traffic flow around the failed node.
Right-click a node and choose **Shutdown this node**.

![Network reaction to shutting a node](../static/network_reaction_shut_node.png)

![Result after shutting a node](../static/network_reaction_result_on_shut_node.png)

## Planning link costs

Change an IGP metric on the fly and immediately see the effect on path
selection — ideal for planning network work, draining traffic off a link, or
checking a metric before applying it on the real network.

Make sure you are still on the **Network reaction to failure** tab. Right-click a
link: a form listing the links appears. Set a new metric value next to the link
you need — the re-routing result shows on the graph immediately.

![Network reaction to an OSPF cost change](../static/network_reaction_ospf_cost_change.png)

## Network Heatmap { #network-heatmap }

The **Network Heatmap** (under Analytics) reveals structural properties of the
topology at a glance — which links and nodes carry the most paths, where your
single points of failure are, and which networks have **no backup path**.

![Network heatmap with networks](../static/network_heatmap_with_networks.png)

Nodes marked red carry the most networks with no backup path.

Choose **None backuped** networks to see networks with a single termination
point: they attach to only one device, so if that device fails they become
unreachable.

![Heatmap highlighting non-backed-up networks](../static/network_heatmap_with_not_backuped_networks.png)

## Detecting asymmetric paths

Routing that takes one path forward and a different path back can complicate
firewalls, QoS and troubleshooting. Topolograph's **Analytics → Asymmetric
paths** report finds these pairs for you.

![Analytics menu — asymmetric paths](../static/analytics_menu_asym_paths.png)

![A real asymmetric path example](../static/asymmetric_path_real_example.png)

## Where to go next

<div class="grid cards" markdown>

-   :material-compare:{ .lg .middle } __Compare two snapshots__

    ---

    See what changed between snapshots.

    [:octicons-arrow-right-24: Comparing states](comparing-states.md)

-   :material-tune-variant:{ .lg .middle } __Add TE data__

    ---

    Bandwidth, TE metric, admin groups.

    [:octicons-arrow-right-24: Traffic Engineering](traffic-engineering.md)

-   :material-radar:{ .lg .middle } __Watch it live__

    ---

    Capture every change as it happens.

    [:octicons-arrow-right-24: Real-time monitoring](../monitoring/index.md)

</div>
