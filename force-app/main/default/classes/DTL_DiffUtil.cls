/**
 * Produces a compact diff array for expected vs actual.
 *
 * Output format: List<Map<String,Object>> where each entry is:
 *  - path: JSON pointer-ish path, e.g. "/score"
 *  - type: "missing" | "extra" | "mismatch"
 *  - expected: expected value (when applicable)
 *  - actual: actual value (when applicable)
 */
public class DTL_DiffUtil {

    public static List<Map<String, Object>> diff(Object expected, Object actual) {
        List<Map<String, Object>> out = new List<Map<String, Object>>();
        walk(out, '', expected, actual);
        return out;
    }

    private static void walk(List<Map<String, Object>> out, String path, Object exp, Object act) {
        if (exp == null && act == null) return;
        if (exp == null && act != null) {
            out.add(entry(path, 'extra', null, act));
            return;
        }
        if (exp != null && act == null) {
            out.add(entry(path, 'missing', exp, null));
            return;
        }

        // Same primitive?
        if (isPrimitive(exp) && isPrimitive(act)) {
            if (!String.valueOf(exp).equals(String.valueOf(act))) {
                out.add(entry(path, 'mismatch', exp, act));
            }
            return;
        }

        // Maps
        if (exp instanceof Map<String, Object> && act instanceof Map<String, Object>) {
            Map<String, Object> e = (Map<String, Object>) exp;
            Map<String, Object> a = (Map<String, Object>) act;

            Set<String> keys = new Set<String>();
            keys.addAll(e.keySet());
            keys.addAll(a.keySet());

            for (String k : keys) {
                String p = path + '/' + escape(k);
                Boolean hasE = e.containsKey(k);
                Boolean hasA = a.containsKey(k);

                if (hasE && !hasA) {
                    out.add(entry(p, 'missing', e.get(k), null));
                } else if (!hasE && hasA) {
                    out.add(entry(p, 'extra', null, a.get(k)));
                } else {
                    walk(out, p, e.get(k), a.get(k));
                }
            }
            return;
        }

        // Lists
        if (exp instanceof List<Object> && act instanceof List<Object>) {
            List<Object> eL = (List<Object>) exp;
            List<Object> aL = (List<Object>) act;
            Integer max = Math.max(eL.size(), aL.size());
            for (Integer i = 0; i < max; i++) {
                String p = path + '/' + String.valueOf(i);
                if (i >= eL.size()) {
                    out.add(entry(p, 'extra', null, aL[i]));
                } else if (i >= aL.size()) {
                    out.add(entry(p, 'missing', eL[i], null));
                } else {
                    walk(out, p, eL[i], aL[i]);
                }
            }
            return;
        }

        // Type mismatch fallback
        if (!String.valueOf(exp).equals(String.valueOf(act))) {
            out.add(entry(path, 'mismatch', exp, act));
        }
    }

    private static Boolean isPrimitive(Object o) {
        return o instanceof String ||
               o instanceof Boolean ||
               o instanceof Integer ||
               o instanceof Long ||
               o instanceof Decimal ||
               o instanceof Double ||
               o instanceof Date ||
               o instanceof Datetime;
    }

    private static Map<String, Object> entry(String path, String type, Object expected, Object actual) {
        Map<String, Object> m = new Map<String, Object>();
        m.put('path', String.isBlank(path) ? '/' : path);
        m.put('type', type);
        if (type != 'extra') m.put('expected', expected);
        if (type != 'missing') m.put('actual', actual);
        return m;
    }

    private static String escape(String s) {
        if (s == null) return '';
        return s.replace('~','~0').replace('/','~1');
    }
}
