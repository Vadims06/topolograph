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

-   :material-rocket-launch-outline:{ .lg .middle } __Use the demo topology__

    ---

    A 13-router demo topology loads automatically on first start and is
    available to everyone - build paths right away without uploading anything.

    [:octicons-arrow-right-24: Analysis & visualization](../analysis/index.md)

-   :material-flag-checkered:{ .lg .middle } __Your First Topology__

    ---

    Upload the LSDB output from one router and build your first path.

    [:octicons-arrow-right-24: Build your first graph](first-topology.md)

</div>

## Where to start

1. **Run Topolograph** locally with [Docker](quickstart-docker.md).
2. **Open the "Upload topology" tab** and start working with the pre-loaded
   demo graph.
3. **Analyze the demo graph** - [build paths, simulate failures, find weak
   spots](../analysis/index.md).

## Next steps

1. **Upload your own topology** - [paste an LSDB text file](../ingestion/text-file.md),
   or stream it live via a [GRE](../ingestion/gre.md) or
   [BGP-LS](../ingestion/bgp-ls.md) Watcher session.
2. **Turn on monitoring** - run a [Watcher](../monitoring/index.md) to capture
   every change and alert on it.
