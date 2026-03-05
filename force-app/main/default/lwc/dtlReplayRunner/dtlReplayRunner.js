import { LightningElement, track } from 'lwc';
import listTraces from '@salesforce/apex/DTL_ReplayController.listTraces';
import getTraceDetail from '@salesforce/apex/DTL_ReplayController.getTraceDetail';
import replayTrace from '@salesforce/apex/DTL_ReplayController.replayTrace';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const MAX_TRACES = 100;

function fmt(dt) {
  if (!dt) return '';
  try {
    return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(dt));
  } catch (e) {
    return String(dt);
  }
}

function prettyJson(text) {
  if (!text) return '{}';
  try {
    return JSON.stringify(JSON.parse(text), null, 2);
  } catch (e) {
    return text;
  }
}

export default class DtlReplayRunner extends LightningElement {
  @track traces;
  @track selected;
  @track error;
  @track filterText = '';
  @track isReplaying = false;

  connectedCallback() {
    this.refresh();
  }

  get filteredTraces() {
    if (!this.traces) return [];
    const q = (this.filterText || '').trim().toLowerCase();
    if (!q) return this.traces;
    return this.traces.filter(t => {
      const hay = [t.transactionName, t.status, t.traceType].join(' ').toLowerCase();
      return hay.includes(q);
    });
  }

  get replayDisabled() {
    return !this.selected || this.isReplaying;
  }

  get hasDiffs() {
    if (!this.selected || !this.selected.replayDiffJson) return false;
    try {
      const d = JSON.parse(this.selected.replayDiffJson);
      return Array.isArray(d) && d.length > 0;
    } catch (e) {
      return false;
    }
  }

  get diffRows() {
    if (!this.hasDiffs) return [];
    let d = [];
    try {
      d = JSON.parse(this.selected.replayDiffJson);
    } catch (e) {
      return [];
    }
    return d.map((x, idx) => ({
      key: `${idx}-${x.path}`,
      path: x.path,
      type: x.type,
      expected: x.expected !== undefined ? JSON.stringify(x.expected) : '',
      actual: x.actual !== undefined ? JSON.stringify(x.actual) : '',
      hasExpected: x.expected !== undefined,
      hasActual: x.actual !== undefined
    }));
  }

  async refresh() {
    this.error = undefined;
    try {
      const rows = await listTraces({ limitSize: MAX_TRACES });
      this.traces = (rows || []).map(r => ({
        ...r,
        capturedAtHuman: fmt(r.capturedAt),
        replayRanAtHuman: fmt(r.replayRanAt),
        _statusClass: this.statusClass(r.status),
        _rowClass: 'dtl-row-btn'
      }));
    } catch (e) {
      this.error = this.normalizeError(e);
      this.traces = undefined;
    }
  }

  handleRefresh() {
    this.refresh();
  }

  handleFilter(evt) {
    this.filterText = evt.target.value;
  }

  async selectTrace(evt) {
    const id = evt.currentTarget.dataset.id;
    if (!id) return;

    // Highlight selection
    this.traces = (this.traces || []).map(t => ({
      ...t,
      _rowClass: t.id === id ? 'dtl-row-btn dtl-row-btn--selected' : 'dtl-row-btn'
    }));

    this.error = undefined;
    try {
      const d = await getTraceDetail({ traceId: id });
      const checkpoints = (d.checkpoints || []).map(c => ({
        ...c,
        createdDateHuman: fmt(c.createdDate),
        payloadJsonPretty: prettyJson(c.payloadJson)
      }));

      this.selected = {
        ...d,
        capturedAtHuman: fmt(d.capturedAt),
        replayRanAtHuman: fmt(d.replayRanAt),
        inputsJsonPretty: prettyJson(d.inputsJson),
        contextJsonPretty: prettyJson(d.contextJson),
        expectedOutputsJsonPretty: prettyJson(d.expectedOutputsJson),
        replayOutputsJsonPretty: prettyJson(d.replayOutputsJson),
        _statusClass: this.statusClass(d.status),
        checkpoints
      };
    } catch (e) {
      this.error = this.normalizeError(e);
      this.selected = undefined;
    }
  }

  async handleReplay() {
    if (!this.selected?.id) return;
    this.isReplaying = true;
    this.error = undefined;
    try {
      const rr = await replayTrace({ traceId: this.selected.id });
      const title = rr.success ? 'Replay succeeded' : 'Replay completed with diffs';
      const variant = rr.success ? 'success' : 'warning';
      this.dispatchEvent(new ShowToastEvent({ title, message: rr.statusMessage || '', variant }));
      await this.selectTrace({ currentTarget: { dataset: { id: this.selected.id } } });
      await this.refresh();
    } catch (e) {
      this.error = this.normalizeError(e);
      this.dispatchEvent(new ShowToastEvent({ title: 'Replay failed', message: this.error, variant: 'error' }));
    } finally {
      this.isReplaying = false;
    }
  }

  statusClass(status) {
    const s = (status || '').toUpperCase();
    if (s === 'REPLAYED') return 'dtl-badge dtl-badge--ok';
    if (s === 'FAILED') return 'dtl-badge dtl-badge--bad';
    return 'dtl-badge';
  }

  normalizeError(e) {
    if (!e) return 'Unknown error';
    if (typeof e === 'string') return e;
    const body = e.body;
    if (body) {
      if (Array.isArray(body)) return body.map(x => x.message).join('; ');
      if (typeof body.message === 'string') return body.message;
    }
    if (typeof e.message === 'string') return e.message;
    try { return JSON.stringify(e); } catch (_e) { return 'Unknown error'; }
  }
}
