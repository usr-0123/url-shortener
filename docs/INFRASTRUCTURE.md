# Infrastructure Deep Dive

This document explains each Terraform module, the Azure resources it creates,
and the reasoning behind specific design choices.

---

## Module: `hub_vnet`

**Resources created:** `azurerm_virtual_network`, 3× `azurerm_subnet`,
`azurerm_virtual_network_peering` (one per spoke)

The hub VNet is the network backbone. It hosts no workloads — only shared
infrastructure services. Three subnets are mandatory:

- `AzureFirewallSubnet` — Azure requires this exact name. Must be /26 or larger.
- `GatewaySubnet` — Azure requires this exact name for VPN/ExpressRoute gateways.
- `snet-shared-*` — Internal Load Balancer frontend, management tooling.

The hub peers to each spoke with `allow_gateway_transit = true`, which lets spokes
use the hub's VPN Gateway to reach on-premises. Without this flag, each spoke would
need its own gateway — three times the cost and complexity.

---

## Module: `spoke_vnet`

**Resources created:** `azurerm_virtual_network`, `azurerm_subnet`,
`azurerm_network_security_group`, `azurerm_route_table`, `azurerm_virtual_network_peering`

This module is instantiated three times with different variables — once per tier.
The key resources are:

**NSG rules** are tier-specific via `var.nsg_rules`. The web spoke allows port 443
inbound from `AzureLoadBalancer`; the data spoke has a catch-all deny rule at
priority 4000 that blocks everything except SQL from the app spoke.

**Route table** creates a single UDR: `0.0.0.0/0 → AzureFirewall private IP`.
This is what forces *all egress* through the firewall — without this, VMs and
containers in the spoke could reach the internet directly, bypassing policy.
`disable_bgp_route_propagation = true` prevents the VPN Gateway from injecting
routes that could override the firewall route.

**Subnet delegation** for `Microsoft.App/environments` is required for Azure
Container Apps VNet injection. Without it, Container Apps cannot deploy into
the subnet.

---

## Module: `firewall`

**Resources created:** `azurerm_public_ip`, `azurerm_firewall_policy`,
`azurerm_firewall`, `azurerm_firewall_policy_rule_collection_group`

The firewall runs in the hub and inspects all traffic that the UDRs force through it.

**Policy vs. Classic rules:** This module uses Firewall Policy (the newer approach)
rather than classic firewall rules. Policy supports rule inheritance across environments
and is required for Premium SKU features like TLS inspection and IDPS.

**Application rules** match on FQDN — the firewall does DNS resolution to get the
IPs behind `*.azure.com`, `*.azurecr.io`, etc., and allows only those. Everything
else is implicitly denied. This means a compromised container cannot exfiltrate data
to an attacker-controlled domain even if it has network access.

**Network rules** are evaluated before application rules and match on IP + port.
The spoke-to-spoke rules (web→app on 3001, app→data on 1433) are here because they
are IP-based, not FQDN-based.

**Why not Network Security Groups alone?** NSGs operate at the subnet level and can
only allow/deny based on IP and port. They cannot inspect HTTP traffic, match FQDNs,
or centralise policy. The firewall + NSG combination is defence in depth: NSG is the
first layer (coarse-grained), firewall is the second (fine-grained).

---

## Module: `dns`

**Resources created:** `azurerm_private_dns_zone`,
`azurerm_private_dns_zone_virtual_network_link` (one per VNet),
`azurerm_traffic_manager_profile`, `azurerm_traffic_manager_azure_endpoint` (1–2)

**Private DNS zone** (`internal.snipurl.local`) is linked to all four VNets. Auto-
registration is enabled on the web and app spokes, so Container Apps instances get
DNS records automatically when they start. The data spoke has auto-registration off
because Azure SQL uses its own private endpoint DNS (`*.database.windows.net`
resolved via a separate private DNS zone — not covered in this module).

**Traffic Manager** uses Priority routing with a 30-second TTL. In production,
lower TTL = faster failover but higher DNS query cost. 30s is a reasonable demo
value — it means a region failure is resolved by DNS within ~30–60 seconds.

The `/api/health` health probe endpoint must return HTTP 200 for the endpoint to be
considered healthy. If it returns anything else for 2 consecutive 30-second intervals
(60 seconds total), Traffic Manager marks the endpoint degraded and routes to the
secondary. You can demo this by temporarily returning 503 from the health endpoint.

---

## How modules wire together

```
azurerm_resource_group
       │
       ├── hub_vnet
       │     └── firewall_subnet_id ──► firewall.firewall_subnet_id
       │     └── vnet_id ──────────────► spoke_*.hub_vnet_id
       │
       ├── firewall
       │     └── firewall_private_ip ──► spoke_*.firewall_private_ip
       │
       ├── spoke_web
       ├── spoke_app          all three └── vnet_id ──► hub_vnet.spoke_vnet_ids
       ├── spoke_data
       │
       └── dns
             └── vnet_links = { hub, web, app, data VNet IDs }
```

The only ordering constraint Terraform cannot infer automatically is hub_vnet's
`spoke_vnet_ids` input — it depends on spoke outputs which in turn depend on hub
outputs (for `hub_vnet_id`). Terraform handles this correctly through its dependency
graph as long as you do not use `-target`.
