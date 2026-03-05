# Architecture

## Data model

### `DTL_Trace__c`
A single captured transaction, containing:

- transaction type (`FLOW` or `APEX`)
- capture metadata (timestamps, initiator, source org)
- captured **inputs** (JSON)
- expected outputs (JSON)
- replay outputs (JSON)
- diff output (JSON)

### `DTL_Checkpoint__c`
Ordered checkpoints for semantic tracing.

## Control plane

### Trace SDK (Apex)
- `DTL_TraceService.startTrace(...)`
- `DTL_TraceService.emitCheckpoint(...)`
- `DTL_TraceService.endTrace(...)`

Flow users call these via invocable wrappers:
- `DTL_StartTraceAction`
- `DTL_EmitCheckpointAction`
- `DTL_EndTraceAction`

### Replay engine (Apex)
- `DTL_ReplayEngine.replay(traceId)`:
  1. loads trace
  2. dispatches by type (`FLOW` or `APEX`)
  3. executes
  4. computes `DTL_DiffUtil.diff(expected, actual)`
  5. persists replay results

### UI (LWC)
`dtlReplayRunner` uses `DTL_ReplayController` (AuraEnabled) to:
- list traces
- fetch detail (including checkpoints)
- replay and refresh

## Determinism notes

- For Flow: deterministic if the Flow logic is deterministic for the same inputs.
- Avoid time/random-dependent branching unless you inject those values as inputs.
- External callouts should be stubbed/mocked if you want deterministic output.
