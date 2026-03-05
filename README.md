# Org Digital Twin + Transaction Replay Lab

Deterministic, reproducible **transaction replay** for Salesforce — capture a transaction’s semantic trace (inputs, key context, decisions, outputs) and replay it later to validate behavior after changes.

> Public credit: **Jyotishko Roy** — https://orcid.org/0009-0000-2837-4731

## What you get

- **Trace SDK (Apex)** — start a trace, emit checkpoints, end a trace with expected outputs.
- **Replay Engine (Apex)** — re-runs a trace deterministically (Flow transactions or replayable Apex transactions).
- **Diffing** — compares expected vs replay outputs; stores a machine-readable diff JSON and renders it in the UI.
- **Replay Runner (LWC)** — a clean UI for listing traces, replaying, and inspecting diffs/checkpoints.

## Supported “transaction types”

| Type | Capture | Replay | Typical use |
|---|---|---|---|
| **FLOW** | Use invocable actions inside any Flow | Engine runs the Flow with captured inputs and reads output variables | Regression checks after flow edits |
| **APEX** | Call SDK from your Apex (or Flow invocable) | Engine invokes a class implementing `DTL_ReplayableTransaction` | Deterministic unit-style transactions |

## Quick start

### Option A — Deploy to any org (Sandbox/Dev/Prod)

1. Install Salesforce CLI + authenticate to your org.
2. Deploy source:
   ```bash
   sfdx force:source:deploy -p force-app -u <your-org-alias>
   ```
3. Assign permissions:
   ```bash
   sfdx force:user:permset:assign -n DTL_Admin -u <your-org-alias>
   ```

4. Seed a sample trace (anonymous Apex):
   ```bash
   sfdx force:apex:execute -f scripts/apex/create_sample_trace.apex -u <your-org-alias>
   ```

5. In Salesforce, open the app **DTL Lab** → tab **Replay Lab**.

### Option B — Scratch org

```bash
sfdx force:org:create -f config/project-scratch-def.json -a dtl_lab -s
sfdx force:source:push
sfdx force:user:permset:assign -n DTL_Admin
sfdx force:apex:execute -f scripts/apex/create_sample_trace.apex
sfdx force:org:open -p lightning/n/DTL_Replay_Lab
```

## Flow instrumentation (capture traces in your own Flows)

Use these invocable actions in a Flow:

1. **DTL_StartTrace** → returns `traceId`
2. **DTL_EmitCheckpoint** → pass `traceId`, a label, and a JSON payload
3. **DTL_EndTrace** → pass `traceId` and a JSON map of expected outputs (keys must match Flow variable API names)

Then replay in the UI. The replay engine uses keys in `ExpectedOutputsJson__c` to read output variables from the Flow interview.

> Note: inputs/outputs are JSON. For deterministic replay, prefer primitives, Ids, and simple lists/maps. See `docs/limitations.md`.

## Architecture

- `DTL_Trace__c` stores transaction metadata and expected/replayed outputs.
- `DTL_Checkpoint__c` stores ordered semantic checkpoints for a trace.
- `DTL_TraceService` is the SDK backend.
- `DTL_ReplayEngine` re-runs transactions and computes diffs.
- `dtlReplayRunner` (LWC) is the UI surface.

More detail: `docs/architecture.md`.

## Security model

- CRUD/FLS enforced via `DTL_Security` and `Security.stripInaccessible`.
- UI is intended for admins / QA users via permission set `DTL_Admin`.
- See `SECURITY.md` for reporting.

## Roadmap ideas (good first issues)

- Replay “dry-run” mode with isolated DML using mocks
- Per-checkpoint diffing
- Trace export/import for cross-org replay
- Deterministic seeding for external callouts (Named Credentials stubs)

## License

Apache-2.0. See `LICENSE`, `NOTICE`.
