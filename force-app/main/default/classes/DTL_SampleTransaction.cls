/**
 * Sample deterministic transaction (no external side effects).
 *
 * Used to seed a trace and demonstrate replay + diff.
 */
public with sharing class DTL_SampleTransaction implements DTL_ReplayableTransaction {

    public class CaptureRequest {
        public Integer a;
        public Integer b;
        public Integer threshold;
    }

    public static void capture(CaptureRequest req) {
        if (req == null) throw new DTL_Exceptions.ValidationException('CaptureRequest is required.');
        if (req.threshold == null) req.threshold = 0;

        Map<String, Object> inputs = new Map<String, Object>{
            'a' => req.a,
            'b' => req.b,
            'threshold' => req.threshold
        };

        DTL_TraceService.StartRequest sr = new DTL_TraceService.StartRequest();
        sr.traceType = 'APEX';
        sr.transactionName = 'Sample Deterministic Transaction';
        sr.replayClass = 'DTL_SampleTransaction';
        sr.inputsJson = DTL_Json.stringify(inputs);
        sr.contextJson = DTL_Json.stringify(new Map<String, Object>{
            'note' => 'This sample transaction is deterministic and side-effect free.',
            'createdBy' => 'Jyotishko Roy',
            'orcid' => 'https://orcid.org/0009-0000-2837-4731'
        });

        Id traceId = DTL_TraceService.startTrace(sr);

        // Emit checkpoints (semantic trace)
        DTL_TraceService.emitCheckpoint(traceId, 1, 'Normalize Inputs', DTL_Json.stringify(new Map<String,Object>{
            'a' => req.a,
            'b' => req.b,
            'threshold' => req.threshold
        }));

        Integer score = safeInt(req.a) + safeInt(req.b);
        DTL_TraceService.emitCheckpoint(traceId, 2, 'Compute Score', DTL_Json.stringify(new Map<String,Object>{
            'score' => score
        }));

        Boolean decision = (score >= safeInt(req.threshold));
        DTL_TraceService.emitCheckpoint(traceId, 3, 'Decision', DTL_Json.stringify(new Map<String,Object>{
            'decision' => decision,
            'rule' => 'score >= threshold'
        }));

        Map<String, Object> expectedOutputs = new Map<String, Object>{
            'score' => score,
            'decision' => decision
        };
        DTL_TraceService.endTrace(traceId, DTL_Json.stringify(expectedOutputs));
    }

    public Map<String, Object> execute(Map<String, Object> inputs) {
        Integer a = safeInt(inputs.get('a'));
        Integer b = safeInt(inputs.get('b'));
        Integer threshold = safeInt(inputs.get('threshold'));
        Integer score = a + b;
        Boolean decision = (score >= threshold);

        return new Map<String, Object>{
            'score' => score,
            'decision' => decision
        };
    }

    private static Integer safeInt(Object o) {
        if (o == null) return 0;
        if (o instanceof Integer) return (Integer) o;
        if (o instanceof Long) return Integer.valueOf(String.valueOf(o));
        if (o instanceof Decimal) return ((Decimal)o).intValue();
        return Integer.valueOf(String.valueOf(o));
    }
}
