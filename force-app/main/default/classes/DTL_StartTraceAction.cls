/**
 * Flow Invocable Action: DTL_StartTrace
 */
public with sharing class DTL_StartTraceAction {

    public class Request {
        @InvocableVariable(required=true)
        public String traceType; // FLOW or APEX

        @InvocableVariable
        public String transactionName;

        @InvocableVariable
        public String flowApiName;

        @InvocableVariable
        public String replayClass; // only for APEX traces

        @InvocableVariable
        public String inputsJson;

        @InvocableVariable
        public String contextJson;
    }

    public class Response {
        @InvocableVariable
        public String traceId;
    }

    @InvocableMethod(label='DTL Start Trace' description='Creates a DTL trace and returns the traceId.')
    public static List<Response> invoke(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request r : requests) {
            DTL_TraceService.StartRequest sr = new DTL_TraceService.StartRequest();
            sr.traceType = r.traceType;
            sr.transactionName = r.transactionName;
            sr.flowApiName = r.flowApiName;
            sr.replayClass = r.replayClass;
            sr.inputsJson = r.inputsJson;
            sr.contextJson = r.contextJson;

            Id id = DTL_TraceService.startTrace(sr);
            Response resp = new Response();
            resp.traceId = String.valueOf(id);
            out.add(resp);
        }
        return out;
    }
}
