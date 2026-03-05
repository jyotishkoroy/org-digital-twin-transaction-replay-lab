# Setup / Install

This repo is an **SFDX** project. You can deploy it to **any Salesforce org** (Developer Edition, Sandbox, Production).

## Prerequisites

- Salesforce CLI (`sfdx`)
- A Salesforce org authenticated via CLI (`sfdx force:auth:web:login -a <alias>`)

## Deploy

```bash
sfdx force:source:deploy -p force-app -u <org-alias>
sfdx force:user:permset:assign -n DTL_Admin -u <org-alias>
```

## Create your first trace (sample)

```bash
sfdx force:apex:execute -f scripts/apex/create_sample_trace.apex -u <org-alias>
```

## Open the UI

From Salesforce App Launcher, open **DTL Lab** and go to **Replay Lab** tab.

You can also open directly:

- Setup → Tabs → “DTL Replay Lab”
- Or: `lightning/n/DTL_Replay_Lab`

## Uninstall

Delete custom objects:

- `DTL_Trace__c`
- `DTL_Checkpoint__c`

and remove the permission set:

- `DTL_Admin`

(If you prefer a clean uninstall path, deploy via an unlocked package; see `docs/packaging.md`.)
