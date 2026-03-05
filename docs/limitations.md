# Limitations / Design constraints

This repo focuses on **replayability** and **portability**.

## Inputs/Outputs must be JSON-safe

The capture format is JSON. For best results, keep inputs and outputs to:

- String, Boolean, Integer, Decimal
- Date, DateTime (ISO-8601 strings)
- Id (18-char strings)
- Lists of primitives / Ids
- Maps with string keys

Avoid passing full sObjects or Apex types that cannot round-trip through JSON.

## Flow replay expectations

For FLOW traces, the engine replays by:

1. Creating a Flow interview by API name (`FlowApiName__c`)
2. Supplying captured input variables (from `InputsJson__c`)
3. Running the interview
4. Reading output variables **by the keys in `ExpectedOutputsJson__c`**

So, to compare outputs correctly, ensure your Flow output variable API names match the keys you store in expected outputs.

## Side effects

The replay engine does not automatically isolate or rollback DML. If your transaction mutates data, replaying may mutate data again.

Recommended patterns:

- Design “replay mode” inputs (e.g., `DryRun = true`)
- Keep transactions pure where possible
- Record Ids created during capture and guard against duplicate creation in replay
