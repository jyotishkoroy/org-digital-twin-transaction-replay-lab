/**
 * Implement this to make an Apex transaction replayable.
 *
 * Contract:
 * - execute(inputs) must be deterministic for the same inputs (or accept a "mode" flag).
 * - return value is a Map<String,Object> of outputs (JSON-serializable).
 */
public interface DTL_ReplayableTransaction {
    Map<String, Object> execute(Map<String, Object> inputs);
}
