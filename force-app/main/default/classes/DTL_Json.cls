/**
 * Thin wrappers around JSON parsing/serialization with guardrails.
 */
public class DTL_Json {
    public static Map<String, Object> parseObject(String json) {
        if (String.isBlank(json)) return new Map<String, Object>();
        Object o = JSON.deserializeUntyped(json);
        if (o instanceof Map<String, Object>) {
            return (Map<String, Object>) o;
        }
        throw new DTL_Exceptions.ValidationException('Expected JSON object/map.');
    }

    public static List<Object> parseArray(String json) {
        if (String.isBlank(json)) return new List<Object>();
        Object o = JSON.deserializeUntyped(json);
        if (o instanceof List<Object>) {
            return (List<Object>) o;
        }
        throw new DTL_Exceptions.ValidationException('Expected JSON array/list.');
    }

    public static String stringify(Object o) {
        return JSON.serialize(o);
    }

    public static String pretty(Object o) {
        return JSON.serializePretty(o);
    }
}
