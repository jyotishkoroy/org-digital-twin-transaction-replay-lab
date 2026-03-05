/**
 * Replays a Flow interview and reads output variables by name.
 */
public class DTL_FlowRunner {

    public class FlowRunResult {
        public Map<String, Object> outputs = new Map<String, Object>();
        public String statusMessage;
    }

    public static FlowRunResult run(String flowApiName, Map<String, Object> inputs, Set<String> outputKeys) {
        if (String.isBlank(flowApiName)) {
            throw new DTL_Exceptions.ReplayException('Flow API name is required for FLOW traces.');
        }

        FlowRunResult res = new FlowRunResult();
        Map<String, Object> inVars = (inputs == null) ? new Map<String, Object>() : inputs;

        try {
            Flow.Interview interview = Flow.Interview.createInterview(flowApiName, inVars);
            interview.start();

            if (outputKeys != null) {
                for (String k : outputKeys) {
                    try {
                        Object v = interview.getVariableValue(k);
                        res.outputs.put(k, v);
                    } catch (Exception e) {
                        // If the variable doesn't exist or isn't accessible in this interview.
                        res.outputs.put(k, null);
                    }
                }
            }
            res.statusMessage = 'Flow interview completed.';
            return res;
        } catch (Exception e) {
            throw new DTL_Exceptions.ReplayException('Flow replay failed: ' + e.getMessage());
        }
    }
}
