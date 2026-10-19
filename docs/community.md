# Community & Support

Topolograph is built in the open. Use the channels below if you need help, found
a bug, or want to contribute.

<div class="grid cards" markdown>

-   :fontawesome-brands-telegram:{ .lg .middle } __Telegram group__

    ---

    Ask questions and chat with other users.

    [:octicons-arrow-right-24: t.me/topolograph](https://t.me/topolograph)

-   :fontawesome-brands-github:{ .lg .middle } __GitHub__

    ---

    Issues, source, and releases for every component.

    [:octicons-arrow-right-24: github.com/Vadims06](https://github.com/Vadims06)

-   :material-web:{ .lg .middle } __Hosted instance__

    ---

    Try Topolograph without self-hosting.

    [:octicons-arrow-right-24: topolograph.com](https://topolograph.com)

</div>

## Project repositories

| Project | Repository |
| --- | --- |
| Topolograph | <https://github.com/Vadims06/topolograph> |
| Docker deployment | <https://github.com/Vadims06/topolograph-docker> |
| OSPF Watcher | <https://github.com/Vadims06/ospfwatcher> |
| IS-IS Watcher | <https://github.com/Vadims06/isiswatcher> |
| Python SDK | <https://github.com/Vadims06/topolograph-sdk> |
| MCP Server | <https://github.com/Vadims06/topolograph-mcp-server> |
| AI Agent | <https://github.com/Vadims06/ospf-isis-ai-agent> |

## Reporting issues

Found a parsing problem with a particular vendor's LSDB? Sharing a sample
database on the relevant repo is the fastest way to get support added — several
IS-IS cases on the [Supported Vendors](reference/supported-vendors.md) page are
waiting on exactly that.

## Videos

* OSPF Watcher. Real-time monitoring with instant notification: <https://youtu.be/2IHbxmDVMA0>
* IS-IS Watcher. Track the whole IS-IS domain from a single router: <https://youtu.be/7ZQFSe1szk8>
* OSPF/IS-IS AI Agent: MCP for network protocols: <https://youtu.be/92YBRXqZWUo>
* BGP-LS in action: monitoring IS-IS networks via IS-IS Watcher and Topolograph: <https://youtu.be/gL0iqXgPJlE>

## Contributing

### Adding a new feature to the core of Topolograph

Email admin at topolograph.com to get access to the repository.

### Adding a new vendor

Create five separate TextFSM files for the different LSA types of one vendor. See the [wiki](https://github.com/Vadims06/topolograph/wiki/How-to-add-new-vendor-support).

### Adding a new vendor to the SDK collector

The [Topolograph SDK](https://github.com/Vadims06/topolograph-sdk) uses a Nornir driver to collect LSDB data from network devices. To support a new vendor, add its commands to the command registry in `topolograph/collector/commands.py`:

```python
COMMAND_REGISTRY = {
    "ospf": {
        "your_vendor": [
            "show ip ospf database router",      # LSA1 command
            "show ip ospf database network",     # LSA2 command
            "show ip ospf database external"     # LSA5 command (optional)
        ]
    },
    "isis": {
        "your_vendor": [
            "show isis database detail"          # IS-IS LSDB command
        ]
    }
}
```

Then submit a pull request to the [topolograph-sdk repository](https://github.com/Vadims06/topolograph-sdk). The SDK uses these commands when collecting LSDB data from devices with the specified vendor in the inventory file.

## Known issues

If you upload an LSDB and press Delete right away, the topology is deleted and added again. Press the Upload LSDB tab again, and then deleting the topology works.

## Where to start

New here? Begin with [What is Topolograph?](getting-started/what-is-topolograph.md)
and the [Quick Start](getting-started/quickstart-docker.md).
