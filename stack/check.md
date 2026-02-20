EUC DNS Request – Test Environment (SCTASK1667311)
Purpose: Reply to Global Service Desk / EUC team with the exact information they need to create the DNS entry for the Test environment, so that the Test frontend is accessible via VPN (same as was done for Dev under INC163081).
Information to Provide to EUC (copy into SCTASK1667311)
The following has been filled in from the Azure Portal (Static Web App azeuw1tswasakura, private endpoint azeuw1tswasakura_privateendpoint, Private DNS zone Recordsets). You can paste this into the ticket as-is.
1. Full URL that needs to be configured
Hostname (FQDN):
lemon-wave-07fa68003.2.azurestaticapps.net


Full URL:
https://lemon-wave-07fa68003.2.azurestaticapps.net/


(Test environment uses .2. in the URL; Dev uses .3..)
2. Private endpoint IP address (Test environment)
Private endpoint IP:
10.19.54.136


(From Private DNS zone Recordsets: A record lemon-wave-07fa68003 → 10.19.54.136.)
3. DNS zone where the entry should be created
DNS zone:
privatelink.2.azurestaticapps.net


Record to create:
Type: A record
Name/host: lemon-wave-07fa68003 (the first part of the FQDN before .2.azurestaticapps.net)
Value: 10.19.54.136
Effect: So that lemon-wave-07fa68003.2.azurestaticapps.net resolves to the private endpoint IP for users on VPN / internal network (same as was done for Dev).
(Test uses zone privatelink.2.azurestaticapps.net; Dev uses privatelink.3.azurestaticapps.net.)
4. Reference to previous DNS configuration (Dev)
For Dev, the same setup was completed under INC163081 with help from Paurav Gandhi. The configuration was:
Item	Dev (reference)
Full URL	https://orange-sand-03a59b103.3.azurestaticapps.net/
Private endpoint IP	10.19.54.134
DNS zone	privatelink.3.azurestaticapps.net
A record	Host orange-sand-03a59b103 → IP 10.19.54.134
We need the same type of entry for the Test environment: an A record so that VPN users resolve lemon-wave-07fa68003.2.azurestaticapps.net to the Test private endpoint IP 10.19.54.136 (zone privatelink.2.azurestaticapps.net or equivalent corporate DNS).


VPN: No change is required on the VPN side; the same VPN URL/configuration used for Dev will work for Test once this DNS entry is in place.
Verified from Azure Portal (Test)
Static Web App: azeuw1tswasakura (RG: AZ-VDC000006-EUW1-RG-BI-TEST-CENTRAL, Source: uat (Custom)).
Private endpoint: azeuw1tswasakura_privateendpoint; DNS configuration shows zone privatelink.2.azurestaticapps.net.
Private DNS zone Recordsets: Zone privatelink.2.azurestaticapps.net already has A record lemon-wave-07fa68003 -> 10.19.54.136. EUC need to ensure the same resolution (this FQDN -> 10.19.54.136) is available for corporate DNS / VPN clients so that users on VPN can reach the Test app.
Summary Table
Item	Dev (done – reference)	Test (to configure)
Full URL	https://orange-sand-03a59b103.3.azurestaticapps.net/	https://lemon-wave-07fa68003.2.azurestaticapps.net/
Private endpoint IP	10.19.54.134	10.19.54.136
DNS zone	privatelink.3.azurestaticapps.net	privatelink.2.azurestaticapps.net
A record name	orange-sand-03a59b103	lemon-wave-07fa68003
Separate Ticket?
No separate ticket needed for this step. The Cloud team completed the private endpoint for Test (RITM1633330). The DNS entry is a follow-up that EUC handles (as they did for Dev). SCTASK1667311 is the correct request for the DNS part; you only need to provide the four pieces of information above in that ticket.

