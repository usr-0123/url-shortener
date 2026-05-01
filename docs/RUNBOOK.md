# Runbook

Common operations and how to perform them.

---

## Simulate a Traffic Manager failover

1. Open the Azure portal → Traffic Manager profiles → `tm-snipurl-dev`
2. Note the current DNS resolution: `nslookup snipurl-dev.trafficmanager.net`
3. In your app, temporarily make `/api/health` return HTTP 503
4. Wait 60–90 seconds (2 failed probe intervals × 30s + TTL)
5. Run `nslookup` again — you should see the IP change to the secondary endpoint
6. Revert the health endpoint and watch Traffic Manager recover

**For demos:** Do this live. It takes ~90 seconds and is the most impressive
networking concept to show in an interview — it makes geo-failover tangible.

---

## Rotate the SQL admin password

```bash
# 1. Generate a new password
NEW_PASS=$(openssl rand -base64 24)

# 2. Update in Terraform (prompts you to enter it, won't echo)
cd infrastructure/environments/dev
terraform apply -var="sql_admin_password=$NEW_PASS"

# 3. Update the app's environment variable in Container Apps
az containerapp secret set \
  --name ca-snipurl-dev \
  --resource-group rg-snipurl-dev \
  --secrets "db-password=$NEW_PASS"

az containerapp update \
  --name ca-snipurl-dev \
  --resource-group rg-snipurl-dev \
  --set-env-vars "DATABASE_PASSWORD=secretref:db-password"
```

---

## Update Firewall application rules

Edit `infrastructure/modules/firewall/main.tf` — add a new FQDN to the
`destination_fqdns` list in the `allow-azure-services` rule. Then:

```bash
cd infrastructure/environments/dev
terraform plan   # Verify only the rule collection group changes
terraform apply
```

Changes to firewall rules are in-place updates — no downtime.

---

## Check firewall logs

```bash
# Recent denied traffic (last 100 entries)
az monitor log-analytics query \
  --workspace "log-snipurl-dev" \
  --analytics-query "AzureDiagnostics
    | where Category == 'AzureFirewallNetworkRule'
    | where msg_s contains 'Deny'
    | project TimeGenerated, msg_s
    | order by TimeGenerated desc
    | take 100"
```

This is useful in interviews to show you understand observability — the firewall
logs every allowed and denied connection with source IP, destination IP, and port.

---

## Tear down dev environment (save costs)

```bash
./scripts/destroy-dev.sh
# This runs terraform destroy on the dev environment.
# The script prompts for confirmation before proceeding.
# Takes ~15 minutes. VPN Gateway deprovisioning is the slow step.
```

**Estimated savings:** ~$290/month while the environment is down.

---

## Add a new spoke

1. Add a new `module "spoke_X"` block in `infrastructure/environments/dev/main.tf`
   with a new CIDR (e.g. `10.4.0.0/24`)
2. Add the new spoke's `vnet_id` to `hub_vnet.spoke_vnet_ids`
3. Add the new VNet ID to `dns.vnet_links`
4. Add a firewall network rule if the spoke needs to communicate with another spoke
5. `terraform plan && terraform apply`

No changes needed to existing modules.
