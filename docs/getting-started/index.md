# Getting Started

New to Topolograph? Start here.

<div class="grid cards" markdown>

-   :material-help-circle-outline:{ .lg .middle } __What is Topolograph?__

    ---

    Understand what Topolograph does, the problem it solves, and how the pieces
    of the suite fit together.

    [:octicons-arrow-right-24: Read the overview](what-is-topolograph.md)

-   :material-docker:{ .lg .middle } __Quick Start with Docker__

    ---

    Run a local, self-hosted instance in a few minutes with Docker Compose.

    [:octicons-arrow-right-24: Install with Docker](quickstart-docker.md)

-   :material-flag-checkered:{ .lg .middle } __Your First Topology__

    ---

    Upload a Link-State Database from one router and build your first shortest
    path.

    [:octicons-arrow-right-24: Build your first graph](first-topology.md)

</div>

## The 60-second version

1. **Run Topolograph** locally with [Docker](quickstart-docker.md).
2. **Get your topology in** — [paste an LSDB text file](../ingestion/text-file.md),
   or stream it live via a [GRE](../ingestion/gre.md) or
   [BGP-LS](../ingestion/bgp-ls.md) Watcher session.
3. **Analyze it** — [build paths, simulate failures, find weak spots](../analysis/index.md).
4. **Monitor it** — turn on a [Watcher](../monitoring/index.md) to capture every
   change and alert on it.
