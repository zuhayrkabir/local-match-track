import { from_string, to_string } from './ditto.wasm.snippets/napi-dispatcher-wasm-2f83e9bddb5a9c18/inline0.js';
import { get_element } from './ditto.wasm.snippets/napi-dispatcher-wasm-2f83e9bddb5a9c18/inline1.js';
import { typeof_ } from './ditto.wasm.snippets/napi-dispatcher-wasm-2f83e9bddb5a9c18/inline2.js';
import * as __wbg_star0 from './ditto.wasm.snippets/napi-dispatcher-wasm-2f83e9bddb5a9c18/inline0.js';
import * as __wbg_star1 from './ditto.wasm.snippets/safer-ffi-a11ec19b6b02a0db/inline0.js';

let wasm;

const cachedTextDecoder = (typeof TextDecoder !== 'undefined' ? new TextDecoder('utf-8', { ignoreBOM: true, fatal: true }) : { decode: () => { throw Error('TextDecoder not available') } } );

if (typeof TextDecoder !== 'undefined') { cachedTextDecoder.decode(); };

let cachedUint8ArrayMemory0 = null;

function getUint8ArrayMemory0() {
    if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.byteLength === 0) {
        cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
    }
    return cachedUint8ArrayMemory0;
}

function getStringFromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return cachedTextDecoder.decode(getUint8ArrayMemory0().subarray(ptr, ptr + len));
}

function addToExternrefTable0(obj) {
    const idx = wasm.__externref_table_alloc();
    wasm.__wbindgen_export_2.set(idx, obj);
    return idx;
}

function handleError(f, args) {
    try {
        return f.apply(this, args);
    } catch (e) {
        const idx = addToExternrefTable0(e);
        wasm.__wbindgen_exn_store(idx);
    }
}

function getArrayU8FromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return getUint8ArrayMemory0().subarray(ptr / 1, ptr / 1 + len);
}

let WASM_VECTOR_LEN = 0;

const cachedTextEncoder = (typeof TextEncoder !== 'undefined' ? new TextEncoder('utf-8') : { encode: () => { throw Error('TextEncoder not available') } } );

const encodeString = (typeof cachedTextEncoder.encodeInto === 'function'
    ? function (arg, view) {
    return cachedTextEncoder.encodeInto(arg, view);
}
    : function (arg, view) {
    const buf = cachedTextEncoder.encode(arg);
    view.set(buf);
    return {
        read: arg.length,
        written: buf.length
    };
});

function passStringToWasm0(arg, malloc, realloc) {

    if (realloc === undefined) {
        const buf = cachedTextEncoder.encode(arg);
        const ptr = malloc(buf.length, 1) >>> 0;
        getUint8ArrayMemory0().subarray(ptr, ptr + buf.length).set(buf);
        WASM_VECTOR_LEN = buf.length;
        return ptr;
    }

    let len = arg.length;
    let ptr = malloc(len, 1) >>> 0;

    const mem = getUint8ArrayMemory0();

    let offset = 0;

    for (; offset < len; offset++) {
        const code = arg.charCodeAt(offset);
        if (code > 0x7F) break;
        mem[ptr + offset] = code;
    }

    if (offset !== len) {
        if (offset !== 0) {
            arg = arg.slice(offset);
        }
        ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
        const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
        const ret = encodeString(arg, view);

        offset += ret.written;
        ptr = realloc(ptr, len, offset, 1) >>> 0;
    }

    WASM_VECTOR_LEN = offset;
    return ptr;
}

let cachedDataViewMemory0 = null;

function getDataViewMemory0() {
    if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer.detached === true || (cachedDataViewMemory0.buffer.detached === undefined && cachedDataViewMemory0.buffer !== wasm.memory.buffer)) {
        cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
    }
    return cachedDataViewMemory0;
}

function isLikeNone(x) {
    return x === undefined || x === null;
}

const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(state => {
    wasm.__wbindgen_export_6.get(state.dtor)(state.a, state.b)
});

function makeMutClosure(arg0, arg1, dtor, f) {
    const state = { a: arg0, b: arg1, cnt: 1, dtor };
    const real = (...args) => {
        // First up with a closure we increment the internal reference
        // count. This ensures that the Rust closure environment won't
        // be deallocated while we're invoking it.
        state.cnt++;
        const a = state.a;
        state.a = 0;
        try {
            return f(a, state.b, ...args);
        } finally {
            if (--state.cnt === 0) {
                wasm.__wbindgen_export_6.get(state.dtor)(a, state.b);
                CLOSURE_DTORS.unregister(state);
            } else {
                state.a = a;
            }
        }
    };
    real.original = state;
    CLOSURE_DTORS.register(real, state, state);
    return real;
}

function debugString(val) {
    // primitive types
    const type = typeof val;
    if (type == 'number' || type == 'boolean' || val == null) {
        return  `${val}`;
    }
    if (type == 'string') {
        return `"${val}"`;
    }
    if (type == 'symbol') {
        const description = val.description;
        if (description == null) {
            return 'Symbol';
        } else {
            return `Symbol(${description})`;
        }
    }
    if (type == 'function') {
        const name = val.name;
        if (typeof name == 'string' && name.length > 0) {
            return `Function(${name})`;
        } else {
            return 'Function';
        }
    }
    // objects
    if (Array.isArray(val)) {
        const length = val.length;
        let debug = '[';
        if (length > 0) {
            debug += debugString(val[0]);
        }
        for(let i = 1; i < length; i++) {
            debug += ', ' + debugString(val[i]);
        }
        debug += ']';
        return debug;
    }
    // Test for built-in
    const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
    let className;
    if (builtInMatches && builtInMatches.length > 1) {
        className = builtInMatches[1];
    } else {
        // Failed to match the standard '[object ClassName]'
        return toString.call(val);
    }
    if (className == 'Object') {
        // we're a user defined class or Object
        // JSON.stringify avoids problems with cycles, and is generally much
        // easier than looping through ownProperties of `val`.
        try {
            return 'Object(' + JSON.stringify(val) + ')';
        } catch (_) {
            return 'Object';
        }
    }
    // errors
    if (val instanceof Error) {
        return `${val.name}: ${val.message}\n${val.stack}`;
    }
    // TODO we could test for more things here, like `Set`s and `Map`s.
    return className;
}

function takeFromExternrefTable0(idx) {
    const value = wasm.__wbindgen_export_2.get(idx);
    wasm.__externref_table_dealloc(idx);
    return value;
}
/**
 * @param {any} error
 * @returns {any}
 */
export function dittoffi_error_code(error) {
    const ret = wasm.dittoffi_error_code(error);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} error
 * @returns {any}
 */
export function dittoffi_error_free(error) {
    const ret = wasm.dittoffi_error_free(error);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} error
 * @returns {any}
 */
export function dittoffi_error_description(error) {
    const ret = wasm.dittoffi_error_description(error);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} error
 * @returns {any}
 */
export function dittoffi_error_internal_get_legacy_error_code(error) {
    const ret = wasm.dittoffi_error_internal_get_legacy_error_code(error);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {Uint8Array} timestamp
 * @param {number} nanos
 * @param {any} ts_name
 * @param {any} cbor
 * @param {any} txn
 * @returns {any}
 */
export function ditto_insert_timeseries_event(ditto, timestamp, nanos, ts_name, cbor, txn) {
    const ret = wasm.ditto_insert_timeseries_event(ditto, timestamp, nanos, ts_name, cbor, txn);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} log_hint
 * @returns {any}
 */
export function ditto_write_transaction(ditto, log_hint) {
    const ret = wasm.ditto_write_transaction(ditto, log_hint);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _ditto
 * @param {any} transaction
 * @returns {any}
 */
export function ditto_write_transaction_rollback(_ditto, transaction) {
    const ret = wasm.ditto_write_transaction_rollback(_ditto, transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_read_transaction(ditto) {
    const ret = wasm.ditto_read_transaction(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _ditto
 * @param {any} transaction
 * @returns {any}
 */
export function ditto_write_transaction_commit(_ditto, transaction) {
    const ret = wasm.ditto_write_transaction_commit(_ditto, transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} transaction
 * @returns {any}
 */
export function ditto_read_transaction_free(transaction) {
    const ret = wasm.ditto_read_transaction_free(transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} transaction
 * @returns {any}
 */
export function ditto_write_transaction_free(transaction) {
    const ret = wasm.ditto_write_transaction_free(transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} name
 * @returns {any}
 */
export function ditto_collection(ditto, name) {
    const ret = wasm.ditto_collection(ditto, name);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} doc_cbor
 * @param {string} write_strategy
 * @param {any} log_hint
 * @param {any} txn
 * @returns {any}
 */
export function ditto_collection_insert_value(ditto, coll_name, doc_cbor, write_strategy, log_hint, txn) {
    const ret = wasm.ditto_collection_insert_value(ditto, coll_name, doc_cbor, write_strategy, log_hint, txn);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {object} documents
 * @returns {any}
 */
export function ditto_documents_hash_mnemonic(documents) {
    const ret = wasm.ditto_documents_hash_mnemonic(documents);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} transaction
 * @param {any} id
 * @returns {any}
 */
export function dittoffi_try_collection_evict(ditto, coll_name, transaction, id) {
    const ret = wasm.dittoffi_try_collection_evict(ditto, coll_name, transaction, id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_get_collection_names(ditto) {
    const ret = wasm.ditto_get_collection_names(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _ditto
 * @param {any} coll_name
 * @param {any} id
 * @param {any} transaction
 * @returns {any}
 */
export function dittoffi_try_collection_get(_ditto, coll_name, id, transaction) {
    const ret = wasm.dittoffi_try_collection_get(_ditto, coll_name, id, transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} transaction
 * @param {any} ids
 * @returns {any}
 */
export function ditto_collection_evict_by_ids(ditto, coll_name, transaction, ids) {
    const ret = wasm.ditto_collection_evict_by_ids(ditto, coll_name, transaction, ids);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} doc_cbor
 * @param {string} write_strategy
 * @param {any} log_hint
 * @param {any} txn
 * @returns {any}
 */
export function dittoffi_try_collection_insert_value(ditto, coll_name, doc_cbor, write_strategy, log_hint, txn) {
    const ret = wasm.dittoffi_try_collection_insert_value(ditto, coll_name, doc_cbor, write_strategy, log_hint, txn);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _ditto
 * @param {any} coll_name
 * @param {any} transaction
 * @param {any} document
 * @returns {any}
 */
export function ditto_collection_update(_ditto, coll_name, transaction, document) {
    const ret = wasm.ditto_collection_update(_ditto, coll_name, transaction, document);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} txn
 * @param {any} query
 * @param {any} query_args_cbor
 * @param {object} js_order_by
 * @param {number} limit
 * @param {number} offset
 * @returns {any}
 */
export function ditto_collection_remove_query_str(ditto, coll_name, txn, query, query_args_cbor, js_order_by, limit, offset) {
    const ret = wasm.ditto_collection_remove_query_str(ditto, coll_name, txn, query, query_args_cbor, js_order_by, limit, offset);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _ditto
 * @param {any} coll_name
 * @param {any} id
 * @param {any} transaction
 * @returns {any}
 */
export function ditto_collection_get_with_write_transaction(_ditto, coll_name, id, transaction) {
    const ret = wasm.ditto_collection_get_with_write_transaction(_ditto, coll_name, id, transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} transaction
 * @param {any} ids
 * @returns {any}
 */
export function dittoffi_try_collection_evict_by_ids(ditto, coll_name, transaction, ids) {
    const ret = wasm.dittoffi_try_collection_evict_by_ids(ditto, coll_name, transaction, ids);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _ditto
 * @param {any} coll_name
 * @param {any} transaction
 * @param {any} id
 * @returns {any}
 */
export function ditto_collection_remove(_ditto, coll_name, transaction, id) {
    const ret = wasm.ditto_collection_remove(_ditto, coll_name, transaction, id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _ditto
 * @param {any} coll_name
 * @param {any} transaction
 * @param {any} id
 * @returns {any}
 */
export function dittoffi_try_collection_remove(_ditto, coll_name, transaction, id) {
    const ret = wasm.dittoffi_try_collection_remove(_ditto, coll_name, transaction, id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {object} documents
 * @returns {any}
 */
export function ditto_documents_hash(documents) {
    const ret = wasm.ditto_documents_hash(documents);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _ditto
 * @param {any} coll_name
 * @param {any} transaction
 * @param {object} documents
 * @returns {any}
 */
export function ditto_collection_update_multiple(_ditto, coll_name, transaction, documents) {
    const ret = wasm.ditto_collection_update_multiple(_ditto, coll_name, transaction, documents);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} transaction
 * @param {any} id
 * @returns {any}
 */
export function ditto_collection_evict(ditto, coll_name, transaction, id) {
    const ret = wasm.ditto_collection_evict(ditto, coll_name, transaction, id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} transaction
 * @param {any} ids
 * @returns {any}
 */
export function ditto_collection_remove_by_ids(ditto, coll_name, transaction, ids) {
    const ret = wasm.ditto_collection_remove_by_ids(ditto, coll_name, transaction, ids);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} txn
 * @param {any} query
 * @param {any} query_args_cbor
 * @param {object} js_order_by_params
 * @param {number} limit
 * @param {number} offset
 * @returns {any}
 */
export function ditto_collection_exec_query_str(ditto, coll_name, txn, query, query_args_cbor, js_order_by_params, limit, offset) {
    const ret = wasm.ditto_collection_exec_query_str(ditto, coll_name, txn, query, query_args_cbor, js_order_by_params, limit, offset);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} ids
 * @param {any} transaction
 * @returns {any}
 */
export function dittoffi_try_collection_find_by_ids(ditto, coll_name, ids, transaction) {
    const ret = wasm.dittoffi_try_collection_find_by_ids(ditto, coll_name, ids, transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _ditto
 * @param {any} coll_name
 * @param {any} id
 * @param {any} transaction
 * @returns {any}
 */
export function ditto_collection_get(_ditto, coll_name, id, transaction) {
    const ret = wasm.ditto_collection_get(_ditto, coll_name, id, transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} ids
 * @param {any} transaction
 * @returns {any}
 */
export function ditto_collection_find_by_ids(ditto, coll_name, ids, transaction) {
    const ret = wasm.ditto_collection_find_by_ids(ditto, coll_name, ids, transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} txn
 * @param {any} query
 * @param {any} query_args_cbor
 * @param {object} js_order_by
 * @param {number} limit
 * @param {number} offset
 * @returns {any}
 */
export function ditto_collection_evict_query_str(ditto, coll_name, txn, query, query_args_cbor, js_order_by, limit, offset) {
    const ret = wasm.ditto_collection_evict_query_str(ditto, coll_name, txn, query, query_args_cbor, js_order_by, limit, offset);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} name
 * @returns {any}
 */
export function dittoffi_try_collection(ditto, name) {
    const ret = wasm.dittoffi_try_collection(ditto, name);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} query
 * @param {any} query_args_cbor
 * @param {Function} callback
 * @returns {any}
 */
export function dittoffi_store_register_observer_throws(ditto, query, query_args_cbor, callback) {
    const ret = wasm.dittoffi_store_register_observer_throws(ditto, query, query_args_cbor, callback);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_store_observers(ditto) {
    const ret = wasm.dittoffi_store_observers(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_store_observer_id(observer) {
    const ret = wasm.dittoffi_store_observer_id(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _observer
 * @returns {any}
 */
export function dittoffi_store_observer_free(_observer) {
    const ret = wasm.dittoffi_store_observer_free(_observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_store_observer_cancel(observer) {
    const ret = wasm.dittoffi_store_observer_cancel(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_store_observer_is_cancelled(observer) {
    const ret = wasm.dittoffi_store_observer_is_cancelled(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_store_observer_query_string(observer) {
    const ret = wasm.dittoffi_store_observer_query_string(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {object} vec
 * @returns {any}
 */
export function dittoffi_store_observers_free_sparse(vec) {
    const ret = wasm.dittoffi_store_observers_free_sparse(vec);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_store_observer_query_arguments(observer) {
    const ret = wasm.dittoffi_store_observer_query_arguments(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_store_observer_query_arguments_cbor(observer) {
    const ret = wasm.dittoffi_store_observer_query_arguments_cbor(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_store_observer_query_arguments_json(observer) {
    const ret = wasm.dittoffi_store_observer_query_arguments_json(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_sync_subscriptions(ditto) {
    const ret = wasm.dittoffi_sync_subscriptions(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} sync_subscription
 * @returns {any}
 */
export function dittoffi_sync_subscription_id(sync_subscription) {
    const ret = wasm.dittoffi_sync_subscription_id(sync_subscription);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} __arg_0
 * @returns {any}
 */
export function dittoffi_sync_subscription_free(__arg_0) {
    const ret = wasm.dittoffi_sync_subscription_free(__arg_0);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} sync_subscription
 * @returns {any}
 */
export function dittoffi_sync_subscription_cancel(sync_subscription) {
    const ret = wasm.dittoffi_sync_subscription_cancel(sync_subscription);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} sync_subscription
 * @returns {any}
 */
export function dittoffi_sync_subscription_is_cancelled(sync_subscription) {
    const ret = wasm.dittoffi_sync_subscription_is_cancelled(sync_subscription);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} sync_subscription
 * @returns {any}
 */
export function dittoffi_sync_subscription_query_string(sync_subscription) {
    const ret = wasm.dittoffi_sync_subscription_query_string(sync_subscription);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {object} vec
 * @returns {any}
 */
export function dittoffi_sync_subscriptions_free_sparse(vec) {
    const ret = wasm.dittoffi_sync_subscriptions_free_sparse(vec);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} query
 * @param {any} query_args_cbor
 * @returns {any}
 */
export function dittoffi_sync_register_subscription_throws(ditto, query, query_args_cbor) {
    const ret = wasm.dittoffi_sync_register_subscription_throws(ditto, query, query_args_cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} sync_subscription
 * @returns {any}
 */
export function dittoffi_sync_subscription_query_arguments_cbor(sync_subscription) {
    const ret = wasm.dittoffi_sync_subscription_query_arguments_cbor(sync_subscription);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} sync_subscription
 * @returns {any}
 */
export function dittoffi_sync_subscription_query_arguments_json(sync_subscription) {
    const ret = wasm.dittoffi_sync_subscription_query_arguments_json(sync_subscription);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} statement
 * @param {any} args_cbor
 * @returns {any}
 */
export function dittoffi_try_exec_statement(ditto, statement, args_cbor) {
    const ret = wasm.dittoffi_try_exec_statement(ditto, statement, args_cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_presence_v3(ditto) {
    const ret = wasm.ditto_presence_v3(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} cb_arg
 * @returns {any}
 */
export function ditto_register_presence_v3_callback(ditto, cb_arg) {
    const ret = wasm.ditto_register_presence_v3_callback(ditto, cb_arg);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_clear_presence_callback(ditto) {
    const ret = wasm.ditto_clear_presence_callback(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_clear_presence_v3_callback(ditto) {
    const ret = wasm.ditto_clear_presence_v3_callback(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} result
 * @returns {any}
 */
export function dittoffi_query_result_free(result) {
    const ret = wasm.dittoffi_query_result_free(result);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} result
 * @param {number} idx
 * @returns {any}
 */
export function dittoffi_query_result_item_at(result, idx) {
    const ret = wasm.dittoffi_query_result_item_at(result, idx);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} query_result_item
 * @returns {any}
 */
export function dittoffi_query_result_item_new(query_result_item) {
    const ret = wasm.dittoffi_query_result_item_new(query_result_item);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} result
 * @returns {any}
 */
export function dittoffi_query_result_commit_id(result) {
    const ret = wasm.dittoffi_query_result_commit_id(result);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} item
 * @returns {any}
 */
export function dittoffi_query_result_item_cbor(item) {
    const ret = wasm.dittoffi_query_result_item_cbor(item);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} item
 * @returns {any}
 */
export function dittoffi_query_result_item_free(item) {
    const ret = wasm.dittoffi_query_result_item_free(item);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} item
 * @returns {any}
 */
export function dittoffi_query_result_item_json(item) {
    const ret = wasm.dittoffi_query_result_item_json(item);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} result
 * @returns {any}
 */
export function dittoffi_query_result_item_count(result) {
    const ret = wasm.dittoffi_query_result_item_count(result);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} result
 * @returns {any}
 */
export function dittoffi_query_result_has_commit_id(result) {
    const ret = wasm.dittoffi_query_result_has_commit_id(result);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} result
 * @param {number} idx
 * @returns {any}
 */
export function dittoffi_query_result_mutated_document_id_at(result, idx) {
    const ret = wasm.dittoffi_query_result_mutated_document_id_at(result, idx);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} result
 * @returns {any}
 */
export function dittoffi_query_result_mutated_document_id_count(result) {
    const ret = wasm.dittoffi_query_result_mutated_document_id_count(result);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_differ_new() {
    const ret = wasm.dittoffi_differ_new();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} differ
 * @param {object} items
 * @returns {any}
 */
export function dittoffi_differ_diff(differ, items) {
    const ret = wasm.dittoffi_differ_diff(differ, items);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} differ
 * @returns {any}
 */
export function dittoffi_differ_free(differ) {
    const ret = wasm.dittoffi_differ_free(differ);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} differ
 * @param {number} idx
 * @returns {any}
 */
export function dittoffi_differ_identity_key_path_at(differ, idx) {
    const ret = wasm.dittoffi_differ_identity_key_path_at(differ, idx);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} differ
 * @returns {any}
 */
export function dittoffi_differ_identity_key_path_count(differ) {
    const ret = wasm.dittoffi_differ_identity_key_path_count(differ);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} identity_key_paths
 * @returns {any}
 */
export function dittoffi_differ_new_with_identity_key_paths_throws(identity_key_paths) {
    const ret = wasm.dittoffi_differ_new_with_identity_key_paths_throws(identity_key_paths);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} token
 * @param {any} provider
 * @returns {any}
 */
export function ditto_auth_client_login_with_token_and_feedback(ditto, token, provider) {
    const ret = wasm.ditto_auth_client_login_with_token_and_feedback(ditto, token, provider);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {Function} js_expiring_cb
 * @returns {any}
 */
export function ditto_auth_client_make_login_provider(js_expiring_cb) {
    const ret = wasm.ditto_auth_client_make_login_provider(js_expiring_cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} js_ditto
 * @param {any} js_handler_or_null
 * @returns {any}
 */
export function dittoffi_presence_set_connection_request_handler(js_ditto, js_handler_or_null) {
    const ret = wasm.dittoffi_presence_set_connection_request_handler(js_ditto, js_handler_or_null);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} username
 * @param {any} password
 * @param {any} provider
 * @returns {any}
 */
export function ditto_auth_client_login_with_credentials(ditto, username, password, provider) {
    const ret = wasm.ditto_auth_client_login_with_credentials(ditto, username, password, provider);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} login_provider
 * @returns {any}
 */
export function ditto_auth_set_login_provider(ditto, login_provider) {
    const ret = wasm.ditto_auth_set_login_provider(ditto, login_provider);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_auth_client_logout(ditto) {
    const ret = wasm.ditto_auth_client_logout(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} token
 * @param {any} provider
 * @returns {any}
 */
export function ditto_auth_client_login_with_token(ditto, token, provider) {
    const ret = wasm.ditto_auth_client_login_with_token(ditto, token, provider);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_auth_client_user_id(ditto) {
    const ret = wasm.ditto_auth_client_user_id(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_auth_client_get_app_id(ditto) {
    const ret = wasm.ditto_auth_client_get_app_id(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_auth_client_get_site_id(ditto) {
    const ret = wasm.ditto_auth_client_get_site_id(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_auth_client_is_web_valid(ditto) {
    const ret = wasm.ditto_auth_client_is_web_valid(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} login_provider
 * @returns {any}
 */
export function ditto_auth_login_provider_free(login_provider) {
    const ret = wasm.ditto_auth_login_provider_free(login_provider);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} __arg_0
 * @returns {any}
 */
export function dittoffi_connection_request_free(__arg_0) {
    const ret = wasm.dittoffi_connection_request_free(__arg_0);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} manual_identity_str
 * @returns {any}
 */
export function ditto_identity_config_make_manual(manual_identity_str) {
    const ret = wasm.ditto_identity_config_make_manual(manual_identity_str);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} req
 * @param {number} _error_code
 * @returns {any}
 */
export function auth_server_auth_submit_with_error(req, _error_code) {
    const ret = wasm.auth_server_auth_submit_with_error(req, _error_code);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} req
 * @param {any} success_cbor
 * @returns {any}
 */
export function auth_server_auth_submit_with_success(req, success_cbor) {
    const ret = wasm.auth_server_auth_submit_with_success(req, success_cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _config_cbor_b64
 * @returns {any}
 */
export function ditto_identity_config_make_manual_v0(_config_cbor_b64) {
    const ret = wasm.ditto_identity_config_make_manual_v0(_config_cbor_b64);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} req
 * @param {number} _error_code
 * @returns {any}
 */
export function auth_server_refresh_submit_with_error(req, _error_code) {
    const ret = wasm.auth_server_refresh_submit_with_error(req, _error_code);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} app_id
 * @param {any} key_der_b64
 * @param {any} site_id
 * @returns {any}
 */
export function ditto_identity_config_make_shared_key(app_id, key_der_b64, site_id) {
    const ret = wasm.ditto_identity_config_make_shared_key(app_id, key_der_b64, site_id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} r
 * @param {string} authorized
 * @returns {any}
 */
export function dittoffi_connection_request_authorize(r, authorized) {
    const ret = wasm.dittoffi_connection_request_authorize(r, authorized);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} req
 * @param {any} success_cbor
 * @returns {any}
 */
export function auth_server_refresh_submit_with_success(req, success_cbor) {
    const ret = wasm.auth_server_refresh_submit_with_success(req, success_cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} r
 * @returns {any}
 */
export function dittoffi_connection_request_connection_type(r) {
    const ret = wasm.dittoffi_connection_request_connection_type(r);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} r
 * @returns {any}
 */
export function dittoffi_connection_request_peer_key_string(r) {
    const ret = wasm.dittoffi_connection_request_peer_key_string(r);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} app_id
 * @param {any} shared_token
 * @param {any} base_url
 * @returns {any}
 */
export function ditto_identity_config_make_online_playground(app_id, shared_token, base_url) {
    const ret = wasm.ditto_identity_config_make_online_playground(app_id, shared_token, base_url);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} app_id
 * @param {any} site_id
 * @returns {any}
 */
export function ditto_identity_config_make_offline_playground(app_id, site_id) {
    const ret = wasm.ditto_identity_config_make_offline_playground(app_id, site_id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} r
 * @returns {any}
 */
export function dittoffi_connection_request_peer_metadata_json(r) {
    const ret = wasm.dittoffi_connection_request_peer_metadata_json(r);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} app_id
 * @param {any} base_url
 * @returns {any}
 */
export function ditto_identity_config_make_online_with_authentication(app_id, base_url) {
    const ret = wasm.ditto_identity_config_make_online_with_authentication(app_id, base_url);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} r
 * @returns {any}
 */
export function dittoffi_connection_request_identity_service_metadata_json(r) {
    const ret = wasm.dittoffi_connection_request_identity_service_metadata_json(r);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function ditto_error_message() {
    const ret = wasm.ditto_error_message();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_is_encrypted(ditto) {
    const ret = wasm.ditto_is_encrypted(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} working_dir
 * @param {any} identity_config
 * @param {any} passphrase
 * @param {any} error_code
 * @returns {any}
 */
export function ditto_experimental_make_with_passphrase(working_dir, identity_config, passphrase, error_code) {
    const ret = wasm.ditto_experimental_make_with_passphrase(working_dir, identity_config, passphrase, error_code);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @returns {any}
 */
export function ditto_document_id(document) {
    const ret = wasm.ditto_document_id(document);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @returns {any}
 */
export function ditto_document_cbor(document) {
    const ret = wasm.ditto_document_cbor(document);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @returns {any}
 */
export function ditto_document_free(document) {
    const ret = wasm.ditto_document_free(document);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @param {any} pointer
 * @returns {any}
 */
export function ditto_document_remove(document, pointer) {
    const ret = wasm.ditto_document_remove(document, pointer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @param {any} cbor
 * @returns {any}
 */
export function ditto_document_update(document, cbor) {
    const ret = wasm.ditto_document_update(document, cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @param {any} pointer
 * @param {any} cbor
 * @returns {any}
 */
export function ditto_document_set_cbor(document, pointer, cbor) {
    const ret = wasm.ditto_document_set_cbor(document, pointer, cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @param {any} pointer
 * @param {number} amount
 * @returns {any}
 */
export function ditto_document_increment_counter(document, pointer, amount) {
    const ret = wasm.ditto_document_increment_counter(document, pointer, amount);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @param {any} pointer
 * @param {string} path_type
 * @returns {any}
 */
export function ditto_document_get_cbor_with_path_type(document, pointer, path_type) {
    const ret = wasm.ditto_document_get_cbor_with_path_type(document, pointer, path_type);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @param {any} pointer
 * @param {any} cbor
 * @param {number} _timestamp
 * @returns {any}
 */
export function ditto_document_set_cbor_with_timestamp(document, pointer, cbor, _timestamp) {
    const ret = wasm.ditto_document_set_cbor_with_timestamp(document, pointer, cbor, _timestamp);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document_cbor
 * @param {any} provided_cbor
 * @returns {any}
 */
export function dittoffi_check_doc_cbor_against_provided_cbor(document_cbor, provided_cbor) {
    const ret = wasm.dittoffi_check_doc_cbor_against_provided_cbor(document_cbor, provided_cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} document
 * @param {any} pointer
 * @param {string} path_type
 * @returns {any}
 */
export function dittoffi_try_document_get_cbor_with_path_type(document, pointer, path_type) {
    const ret = wasm.dittoffi_try_document_get_cbor_with_path_type(document, pointer, path_type);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_alloc_tracking_stop() {
    const ret = wasm.dittoffi_alloc_tracking_stop();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_alloc_tracking_start() {
    const ret = wasm.dittoffi_alloc_tracking_start();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} slice
 * @returns {any}
 */
export function dittoffi_bytes_double_box_byte_slice(slice) {
    const ret = wasm.dittoffi_bytes_double_box_byte_slice(slice);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} boxed
 * @returns {any}
 */
export function dittoffi_bytes_double_boxed_byte_slice_free(boxed) {
    const ret = wasm.dittoffi_bytes_double_boxed_byte_slice_free(boxed);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} _transaction
 * @returns {any}
 */
export function dittoffi_transaction_free(_transaction) {
    const ret = wasm.dittoffi_transaction_free(_transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} transaction
 * @returns {any}
 */
export function dittoffi_transaction_info(transaction) {
    const ret = wasm.dittoffi_transaction_info(transaction);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ffi_store
 * @returns {any}
 */
export function dittoffi_store_transactions(ffi_store) {
    const ret = wasm.dittoffi_store_transactions(ffi_store);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} transaction
 * @param {any} query
 * @param {any} query_args_cbor
 * @param {Function} continuation
 * @returns {any}
 */
export function dittoffi_transaction_execute_async_throws(transaction, query, query_args_cbor, continuation) {
    const ret = wasm.dittoffi_transaction_execute_async_throws(transaction, query, query_args_cbor, continuation);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} transaction
 * @param {string} action
 * @param {Function} continuation
 * @returns {any}
 */
export function dittoffi_transaction_complete_async_throws(transaction, action, continuation) {
    const ret = wasm.dittoffi_transaction_complete_async_throws(transaction, action, continuation);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} store
 * @param {any} options
 * @param {Function} continuation
 * @returns {any}
 */
export function dittoffi_store_begin_transaction_async_throws(store, options, continuation) {
    const ret = wasm.dittoffi_store_begin_transaction_async_throws(store, options, continuation);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_store_begin_transaction_options_make() {
    const ret = wasm.dittoffi_store_begin_transaction_options_make();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} cbor
 * @param {any} out_cbor
 * @returns {any}
 */
export function ditto_validate_document_id(cbor, out_cbor) {
    const ret = wasm.ditto_validate_document_id(cbor, out_cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} id
 * @param {string} string_primitive_format
 * @returns {any}
 */
export function ditto_document_id_query_compatible(id, string_primitive_format) {
    const ret = wasm.ditto_document_id_query_compatible(id, string_primitive_format);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} bytes
 * @param {string} padding_mode
 * @returns {any}
 */
export function dittoffi_base64_encode(bytes, padding_mode) {
    const ret = wasm.dittoffi_base64_encode(bytes, padding_mode);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} str
 * @param {string} padding_mode
 * @returns {any}
 */
export function dittoffi_try_base64_decode(str, padding_mode) {
    const ret = wasm.dittoffi_try_base64_decode(str, padding_mode);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} js_ditto
 * @param {Function} js_handler
 * @returns {any}
 */
export function dittoffi_ditto_set_authentication_status_handler(js_ditto, js_handler) {
    const ret = wasm.dittoffi_ditto_set_authentication_status_handler(js_ditto, js_handler);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_ditto_stop_sync(ditto) {
    const ret = wasm.dittoffi_ditto_stop_sync(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_ditto_is_sync_active(ditto) {
    const ret = wasm.dittoffi_ditto_is_sync_active(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_ditto_try_start_sync(ditto) {
    const ret = wasm.dittoffi_ditto_try_start_sync(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_transport_config_new() {
    const ret = wasm.dittoffi_transport_config_new();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function ditto_sdk_transports_error_new() {
    const ret = wasm.ditto_sdk_transports_error_new();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} it
 * @returns {any}
 */
export function ditto_sdk_transports_error_free(it) {
    const ret = wasm.ditto_sdk_transports_error_free(it);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_ditto_transport_config(ditto) {
    const ret = wasm.dittoffi_ditto_transport_config(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} it
 * @returns {any}
 */
export function ditto_sdk_transports_error_value(it) {
    const ret = wasm.ditto_sdk_transports_error_value(it);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} __arg_0
 * @returns {any}
 */
export function dittoffi_authentication_status_free(__arg_0) {
    const ret = wasm.dittoffi_authentication_status_free(__arg_0);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} auth_status
 * @returns {any}
 */
export function dittoffi_authentication_status_user_id(auth_status) {
    const ret = wasm.dittoffi_authentication_status_user_id(auth_status);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} transport_config_cbor
 * @param {boolean} should_validate
 * @returns {any}
 */
export function dittoffi_ditto_try_set_transport_config(ditto, transport_config_cbor, should_validate) {
    const ret = wasm.dittoffi_ditto_try_set_transport_config(ditto, transport_config_cbor, should_validate);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} auth_status
 * @returns {any}
 */
export function dittoffi_authentication_status_is_authenticated(auth_status) {
    const ret = wasm.dittoffi_authentication_status_is_authenticated(auth_status);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_free(ditto) {
    const ret = wasm.ditto_free(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} working_dir
 * @param {any} identity_config
 * @returns {any}
 */
export function ditto_make(working_dir, identity_config) {
    const ret = wasm.ditto_make(working_dir, identity_config);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_shutdown(ditto) {
    const ret = wasm.ditto_shutdown(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} js_ptr
 * @param {any} js_fun_or_null
 * @returns {any}
 */
export function ditto_register_transport_condition_changed_callback(js_ptr, js_fun_or_null) {
    const ret = wasm.ditto_register_transport_condition_changed_callback(js_ptr, js_fun_or_null);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_disable_sync_with_v3(ditto) {
    const ret = wasm.ditto_disable_sync_with_v3(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_run_garbage_collection(ditto) {
    const ret = wasm.ditto_run_garbage_collection(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function ditto_get_sdk_version() {
    const ret = wasm.ditto_get_sdk_version();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} device_name
 * @returns {any}
 */
export function ditto_set_device_name(ditto, device_name) {
    const ret = wasm.ditto_set_device_name(ditto, device_name);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_ditto_config(ditto) {
    const ret = wasm.dittoffi_ditto_config(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {string} platform
 * @param {string} language
 * @param {any} sdk_semver
 * @returns {any}
 */
export function ditto_init_sdk_version(platform, language, sdk_semver) {
    const ret = wasm.ditto_init_sdk_version(platform, language, sdk_semver);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_get_sdk_semver() {
    const ret = wasm.dittoffi_get_sdk_semver();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} config_cbor
 * @param {string} transport_config_mode
 * @param {any} default_root_directory
 * @returns {any}
 */
export function dittoffi_ditto_open_throws(config_cbor, transport_config_mode, default_root_directory) {
    const ret = wasm.dittoffi_ditto_open_throws(config_cbor, transport_config_mode, default_root_directory);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_ditto_is_activated(ditto) {
    const ret = wasm.dittoffi_ditto_is_activated(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_transports_diagnostics(ditto) {
    const ret = wasm.ditto_transports_diagnostics(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_DEFAULT_DATABASE_ID() {
    const ret = wasm.dittoffi_DEFAULT_DATABASE_ID();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_ditto_config_default() {
    const ret = wasm.dittoffi_ditto_config_default();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} working_dir
 * @param {any} identity_config
 * @param {any} experimental_passphrase
 * @param {string} transport_config_mode
 * @returns {any}
 */
export function dittoffi_ditto_try_new_blocking(working_dir, identity_config, experimental_passphrase, transport_config_mode) {
    const ret = wasm.dittoffi_ditto_try_new_blocking(working_dir, identity_config, experimental_passphrase, transport_config_mode);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} config_cbor
 * @param {string} transport_config_mode
 * @param {any} default_root_directory
 * @param {Function} continuation
 * @returns {any}
 */
export function dittoffi_ditto_open_async_throws(config_cbor, transport_config_mode, default_root_directory, continuation) {
    const ret = wasm.dittoffi_ditto_open_async_throws(config_cbor, transport_config_mode, default_root_directory, continuation);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_DITTO_DEVELOPMENT_PROVIDER() {
    const ret = wasm.dittoffi_DITTO_DEVELOPMENT_PROVIDER();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {boolean} enabled
 * @returns {any}
 */
export function dittoffi_ditto_set_cloud_sync_enabled(ditto, enabled) {
    const ret = wasm.dittoffi_ditto_set_cloud_sync_enabled(ditto, enabled);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} parameter_name
 * @returns {any}
 */
export function dittoffi_ditto_get_system_parameter_u64(ditto, parameter_name) {
    const ret = wasm.dittoffi_ditto_get_system_parameter_u64(ditto, parameter_name);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} parameter_name
 * @returns {any}
 */
export function dittoffi_ditto_get_system_parameter_bool(ditto, parameter_name) {
    const ret = wasm.dittoffi_ditto_get_system_parameter_bool(ditto, parameter_name);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} working_dir
 * @param {any} identity_config
 * @param {string} transport_config_mode
 * @returns {any}
 */
export function dittoffi_make_with_transport_config_mode(working_dir, identity_config, transport_config_mode) {
    const ret = wasm.dittoffi_make_with_transport_config_mode(working_dir, identity_config, transport_config_mode);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_ditto_absolute_persistence_directory(ditto) {
    const ret = wasm.dittoffi_ditto_absolute_persistence_directory(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} license
 * @returns {any}
 */
export function dittoffi_ditto_set_offline_only_license_token_throws(ditto, license) {
    const ret = wasm.dittoffi_ditto_set_offline_only_license_token_throws(ditto, license);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} indices
 * @returns {any}
 */
export function ditto_free_indices(indices) {
    const ret = wasm.ditto_free_indices(indices);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} id
 * @returns {any}
 */
export function ditto_live_query_signal_available_next(ditto, id) {
    const ret = wasm.ditto_live_query_signal_available_next(ditto, id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} query
 * @param {any} query_args_cbor
 * @param {object} js_order_by
 * @param {number} limit
 * @param {number} offset
 * @param {Function} cb
 * @returns {any}
 */
export function ditto_live_query_register_str_detached(ditto, coll_name, query, query_args_cbor, js_order_by, limit, offset, cb) {
    const ret = wasm.ditto_live_query_register_str_detached(ditto, coll_name, query, query_args_cbor, js_order_by, limit, offset, cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} legacy_id
 * @returns {any}
 */
export function ditto_live_query_start(ditto, legacy_id) {
    const ret = wasm.ditto_live_query_start(ditto, legacy_id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} query
 * @param {any} query_args_cbor
 * @param {Function} cb
 * @returns {any}
 */
export function dittoffi_try_experimental_register_change_observer_str_detached(ditto, query, query_args_cbor, cb) {
    const ret = wasm.dittoffi_try_experimental_register_change_observer_str_detached(ditto, query, query_args_cbor, cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} legacy_id
 * @returns {any}
 */
export function ditto_live_query_stop(ditto, legacy_id) {
    const ret = wasm.ditto_live_query_stop(ditto, legacy_id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {object} docs
 * @returns {any}
 */
export function ditto_sparse_vec_documents_free(docs) {
    const ret = wasm.ditto_sparse_vec_documents_free(docs);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} __arg_0
 * @returns {any}
 */
export function dittoffi_panic_free(__arg_0) {
    const ret = wasm.dittoffi_panic_free(__arg_0);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} js_panic_handler_or_null
 * @returns {any}
 */
export function dittoffi_ditto_set_panic_handler(js_panic_handler_or_null) {
    const ret = wasm.dittoffi_ditto_set_panic_handler(js_panic_handler_or_null);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} panic
 * @returns {any}
 */
export function dittoffi_panic_message(panic) {
    const ret = wasm.dittoffi_panic_message(panic);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_ditto_trigger_test_panic() {
    const ret = wasm.dittoffi_ditto_trigger_test_panic();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} panic
 * @returns {any}
 */
export function dittoffi_panic_stack_trace_string(panic) {
    const ret = wasm.dittoffi_panic_stack_trace_string(panic);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_ditto_trigger_test_panic_in_background() {
    const ret = wasm.dittoffi_ditto_trigger_test_panic_in_background();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_ditto_capture_stack_trace_string_internal() {
    const ret = wasm.dittoffi_ditto_capture_stack_trace_string_internal();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {boolean} value
 * @returns {any}
 */
export function dittoffi_ditto_use_helper_thread_for_panic_handler_internal(value) {
    const ret = wasm.dittoffi_ditto_use_helper_thread_for_panic_handler_internal(value);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} license
 * @param {any} out_err_msg
 * @returns {any}
 */
export function ditto_verify_license(ditto, license, out_err_msg) {
    const ret = wasm.ditto_verify_license(ditto, license, out_err_msg);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} license
 * @returns {any}
 */
export function dittoffi_try_verify_license(ditto, license) {
    const ret = wasm.dittoffi_try_verify_license(ditto, license);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function ditto_logger_init() {
    const ret = wasm.ditto_logger_init();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} arg
 * @returns {any}
 */
export function ditto_logger_set_custom_log_cb(arg) {
    const ret = wasm.ditto_logger_set_custom_log_cb(arg);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {boolean} enabled
 * @returns {any}
 */
export function ditto_logger_enabled(enabled) {
    const ret = wasm.ditto_logger_enabled(enabled);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function ditto_logger_enabled_get() {
    const ret = wasm.ditto_logger_enabled_get();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} log_file
 * @returns {any}
 */
export function ditto_logger_set_log_file(log_file) {
    const ret = wasm.ditto_logger_set_log_file(log_file);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {string} log_level
 * @returns {any}
 */
export function ditto_logger_minimum_log_level(log_level) {
    const ret = wasm.ditto_logger_minimum_log_level(log_level);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function ditto_logger_minimum_log_level_get() {
    const ret = wasm.ditto_logger_minimum_log_level_get();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {boolean} enabled
 * @returns {any}
 */
export function ditto_logger_emoji_headings_enabled(enabled) {
    const ret = wasm.ditto_logger_emoji_headings_enabled(enabled);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function ditto_logger_emoji_headings_enabled_get() {
    const ret = wasm.ditto_logger_emoji_headings_enabled_get();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} dest_path
 * @param {Function} continuation
 * @returns {any}
 */
export function dittoffi_logger_try_export_to_file_async(dest_path, continuation) {
    const ret = wasm.dittoffi_logger_try_export_to_file_async(dest_path, continuation);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {string} level
 * @param {any} msg
 * @returns {any}
 */
export function ditto_log(level, msg) {
    const ret = wasm.ditto_log(level, msg);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} query
 * @param {any} query_args_cbor
 * @param {object} js_order_by
 * @param {number} limit
 * @param {number} offset
 * @returns {number}
 */
export function ditto_remove_subscription(ditto, coll_name, query, query_args_cbor, js_order_by, limit, offset) {
    const ret = wasm.ditto_remove_subscription(ditto, coll_name, query, query_args_cbor, js_order_by, limit, offset);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} coll_name
 * @param {any} query
 * @param {any} query_args_cbor
 * @param {object} js_order_by
 * @param {number} limit
 * @param {number} offset
 * @returns {number}
 */
export function ditto_add_subscription(ditto, coll_name, query, query_args_cbor, js_order_by, limit, offset) {
    const ret = wasm.ditto_add_subscription(ditto, coll_name, query, query_args_cbor, js_order_by, limit, offset);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} query
 * @param {any} query_args_cbor
 * @returns {any}
 */
export function dittoffi_try_add_sync_subscription(ditto, query, query_args_cbor) {
    const ret = wasm.dittoffi_try_add_sync_subscription(ditto, query, query_args_cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} query
 * @param {any} query_args_cbor
 * @returns {any}
 */
export function dittoffi_try_remove_sync_subscription(ditto, query, query_args_cbor) {
    const ret = wasm.dittoffi_try_remove_sync_subscription(ditto, query, query_args_cbor);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} peer_info
 * @returns {any}
 */
export function dittoffi_presence_try_set_peer_metadata_json(ditto, peer_info) {
    const ret = wasm.dittoffi_presence_try_set_peer_metadata_json(ditto, peer_info);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {Function} callback
 * @returns {any}
 */
export function dittoffi_presence_register_observer_throws(ditto, callback) {
    const ret = wasm.dittoffi_presence_register_observer_throws(ditto, callback);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} peer_info
 * @returns {any}
 */
export function dittoffi_presence_set_peer_metadata_json_throws(ditto, peer_info) {
    const ret = wasm.dittoffi_presence_set_peer_metadata_json_throws(ditto, peer_info);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_presence_graph(ditto) {
    const ret = wasm.dittoffi_presence_graph(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_presence_observer_id(observer) {
    const ret = wasm.dittoffi_presence_observer_id(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_presence_observer_free(observer) {
    const ret = wasm.dittoffi_presence_observer_free(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_presence_observer_cancel(observer) {
    const ret = wasm.dittoffi_presence_observer_cancel(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function dittoffi_presence_peer_metadata_json(ditto) {
    const ret = wasm.dittoffi_presence_peer_metadata_json(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} observer
 * @returns {any}
 */
export function dittoffi_presence_observer_is_cancelled(observer) {
    const ret = wasm.dittoffi_presence_observer_is_cancelled(observer);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} handle
 * @returns {any}
 */
export function ditto_get_complete_attachment_data(ditto, handle) {
    const ret = wasm.ditto_get_complete_attachment_data(ditto, handle);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} bytes
 * @param {object} out_attachment
 * @returns {any}
 */
export function ditto_new_attachment_from_bytes(ditto, bytes, out_attachment) {
    const ret = wasm.ditto_new_attachment_from_bytes(ditto, bytes, out_attachment);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} id
 * @param {Function} on_complete_cb
 * @param {Function} on_progress_cb
 * @param {Function} on_deleted_cb
 * @returns {any}
 */
export function ditto_resolve_attachment(ditto, id, on_complete_cb, on_progress_cb, on_deleted_cb) {
    const ret = wasm.ditto_resolve_attachment(ditto, id, on_complete_cb, on_progress_cb, on_deleted_cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} id
 * @returns {any}
 */
export function ditto_get_attachment_status(ditto, id) {
    const ret = wasm.ditto_get_attachment_status(ditto, id);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} handle
 * @returns {any}
 */
export function ditto_free_attachment_handle(handle) {
    const ret = wasm.ditto_free_attachment_handle(handle);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} id
 * @param {any} cancel_token
 * @returns {any}
 */
export function ditto_cancel_resolve_attachment(ditto, id, cancel_token) {
    const ret = wasm.ditto_cancel_resolve_attachment(ditto, id, cancel_token);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} handle
 * @returns {any}
 */
export function ditto_get_complete_attachment_path(ditto, handle) {
    const ret = wasm.ditto_get_complete_attachment_path(ditto, handle);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {boolean} set_enabled
 * @returns {any}
 */
export function ditto_small_peer_info_set_enabled(ditto, set_enabled) {
    const ret = wasm.ditto_small_peer_info_set_enabled(ditto, set_enabled);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_small_peer_info_get_metadata(ditto) {
    const ret = wasm.ditto_small_peer_info_get_metadata(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {any} metadata
 * @returns {any}
 */
export function ditto_small_peer_info_set_metadata(ditto, metadata) {
    const ret = wasm.ditto_small_peer_info_set_metadata(ditto, metadata);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_small_peer_info_get_is_enabled(ditto) {
    const ret = wasm.ditto_small_peer_info_get_is_enabled(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @returns {any}
 */
export function ditto_small_peer_info_get_sync_scope(ditto) {
    const ret = wasm.ditto_small_peer_info_get_sync_scope(ditto);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ditto
 * @param {string} scope
 * @returns {any}
 */
export function ditto_small_peer_info_set_sync_scope(ditto, scope) {
    const ret = wasm.ditto_small_peer_info_set_sync_scope(ditto, scope);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} ty
 * @param {any} bytes
 * @returns {any}
 */
export function dittoffi_cbor_round_trip(ty, bytes) {
    const ret = wasm.dittoffi_cbor_round_trip(ty, bytes);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @returns {any}
 */
export function dittoffi_crypto_generate_secure_random_token() {
    const ret = wasm.dittoffi_crypto_generate_secure_random_token();
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} bytes
 * @returns {any}
 */
export function ditto_c_bytes_free(bytes) {
    const ret = wasm.ditto_c_bytes_free(bytes);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} s
 * @returns {any}
 */
export function ditto_c_string_free(s) {
    const ret = wasm.ditto_c_string_free(s);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} cbor
 * @param {any} path
 * @param {string} path_type
 * @returns {any}
 */
export function ditto_cbor_get_cbor_with_path_type(cbor, path, path_type) {
    const ret = wasm.ditto_cbor_get_cbor_with_path_type(cbor, path, path_type);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} arg
 * @returns {any}
 */
export function boxCBytesIntoBuffer(arg) {
    const ret = wasm.boxCBytesIntoBuffer(arg);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {object} arg
 * @returns {object}
 */
export function cStringVecToStringArray(arg) {
    const ret = wasm.cStringVecToStringArray(arg);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} fst
 * @param {Function} cb
 * @returns {any}
 */
export function withCBytes(fst, cb) {
    const ret = wasm.withCBytes(fst, cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {string} vec_ty
 * @param {string} ty
 * @param {Function} cb
 * @returns {any}
 */
export function withOutVecOfPtrs(vec_ty, ty, cb) {
    const ret = wasm.withOutVecOfPtrs(vec_ty, ty, cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {Function} cb
 * @returns {any}
 */
export function withOutU64(cb) {
    const ret = wasm.withOutU64(cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} arg
 * @returns {any}
 */
export function refCStringToString(arg) {
    const ret = wasm.refCStringToString(arg);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {Function} cb
 * @returns {any}
 */
export function withOutBoxCBytes(cb) {
    const ret = wasm.withOutBoxCBytes(cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} fst
 * @param {Function} cb
 * @returns {any}
 */
export function withCString(fst, cb) {
    const ret = wasm.withCString(fst, cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {Function} cb
 * @returns {any}
 */
export function withOutBoolean(cb) {
    const ret = wasm.withOutBoolean(cb);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} arg
 * @returns {any}
 */
export function refCBytesIntoBuffer(arg) {
    const ret = wasm.refCBytesIntoBuffer(arg);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

/**
 * @param {any} arg
 * @returns {any}
 */
export function boxCStringIntoString(arg) {
    const ret = wasm.boxCStringIntoString(arg);
    if (ret[2]) {
        throw takeFromExternrefTable0(ret[1]);
    }
    return takeFromExternrefTable0(ret[0]);
}

function __wbg_adapter_34(arg0, arg1, arg2) {
    wasm.closure9178_externref_shim(arg0, arg1, arg2);
}

function __wbg_adapter_37(arg0, arg1, arg2) {
    wasm.closure9249_externref_shim(arg0, arg1, arg2);
}

function __wbg_adapter_40(arg0, arg1) {
    wasm._dyn_core__ops__function__FnMut_____Output___R_as_wasm_bindgen__closure__WasmClosure___describe__invoke__h179800a3cfcdfb18(arg0, arg1);
}

function __wbg_adapter_43(arg0, arg1) {
    wasm._dyn_core__ops__function__FnMut_____Output___R_as_wasm_bindgen__closure__WasmClosure___describe__invoke__h4651bd91a2619ca0(arg0, arg1);
}

function __wbg_adapter_46(arg0, arg1) {
    wasm._dyn_core__ops__function__FnMut_____Output___R_as_wasm_bindgen__closure__WasmClosure___describe__invoke__h49c8fd8de7f0f31b(arg0, arg1);
}

function __wbg_adapter_49(arg0, arg1, arg2) {
    wasm.closure16976_externref_shim(arg0, arg1, arg2);
}

function __wbg_adapter_502(arg0, arg1, arg2, arg3) {
    wasm.closure17027_externref_shim(arg0, arg1, arg2, arg3);
}

const __wbindgen_enum_BinaryType = ["blob", "arraybuffer"];

const __wbindgen_enum_RequestCache = ["default", "no-store", "reload", "no-cache", "force-cache", "only-if-cached"];

const __wbindgen_enum_RequestCredentials = ["omit", "same-origin", "include"];

const __wbindgen_enum_RequestMode = ["same-origin", "no-cors", "cors", "navigate"];

async function __wbg_load(module, imports) {
    if (typeof Response === 'function' && module instanceof Response) {
        if (typeof WebAssembly.instantiateStreaming === 'function') {
            try {
                return await WebAssembly.instantiateStreaming(module, imports);

            } catch (e) {
                if (module.headers.get('Content-Type') != 'application/wasm') {
                    console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve Wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n", e);

                } else {
                    throw e;
                }
            }
        }

        const bytes = await module.arrayBuffer();
        return await WebAssembly.instantiate(bytes, imports);

    } else {
        const instance = await WebAssembly.instantiate(module, imports);

        if (instance instanceof WebAssembly.Instance) {
            return { instance, module };

        } else {
            return instance;
        }
    }
}

function __wbg_get_imports() {
    const imports = {};
    imports.wbg = {};
    imports.wbg.__wbg_abort_410ec47a64ac6117 = function(arg0, arg1) {
        arg0.abort(arg1);
    };
    imports.wbg.__wbg_abort_775ef1d17fc65868 = function(arg0) {
        arg0.abort();
    };
    imports.wbg.__wbg_append_299d5d48292c0495 = function() { return handleError(function (arg0, arg1, arg2, arg3, arg4) {
        arg0.append(getStringFromWasm0(arg1, arg2), getStringFromWasm0(arg3, arg4));
    }, arguments) };
    imports.wbg.__wbg_append_8c7dd8d641a5f01b = function() { return handleError(function (arg0, arg1, arg2, arg3, arg4) {
        arg0.append(getStringFromWasm0(arg1, arg2), getStringFromWasm0(arg3, arg4));
    }, arguments) };
    imports.wbg.__wbg_append_b2d1fc16de2a0e81 = function() { return handleError(function (arg0, arg1, arg2, arg3, arg4, arg5) {
        arg0.append(getStringFromWasm0(arg1, arg2), arg3, getStringFromWasm0(arg4, arg5));
    }, arguments) };
    imports.wbg.__wbg_append_b44785ebeb668479 = function() { return handleError(function (arg0, arg1, arg2, arg3) {
        arg0.append(getStringFromWasm0(arg1, arg2), arg3);
    }, arguments) };
    imports.wbg.__wbg_apply_36be6a55257c99bf = function() { return handleError(function (arg0, arg1, arg2) {
        const ret = arg0.apply(arg1, arg2);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_arrayBuffer_d1b44c4390db422f = function() { return handleError(function (arg0) {
        const ret = arg0.arrayBuffer();
        return ret;
    }, arguments) };
    imports.wbg.__wbg_buffer_609cc3eee51ed158 = function(arg0) {
        const ret = arg0.buffer;
        return ret;
    };
    imports.wbg.__wbg_call_672a4d21634d4a24 = function() { return handleError(function (arg0, arg1) {
        const ret = arg0.call(arg1);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_call_7cccdd69e0791ae2 = function() { return handleError(function (arg0, arg1, arg2) {
        const ret = arg0.call(arg1, arg2);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_clearInterval_d0ff292406f98cc3 = function(arg0) {
        const ret = clearInterval(arg0);
        return ret;
    };
    imports.wbg.__wbg_clearTimeout_42d9ccd50822fd3a = function(arg0) {
        const ret = clearTimeout(arg0);
        return ret;
    };
    imports.wbg.__wbg_clearTimeout_96804de0ab838f26 = function(arg0) {
        const ret = clearTimeout(arg0);
        return ret;
    };
    imports.wbg.__wbg_close_2893b7d056a0627d = function() { return handleError(function (arg0) {
        arg0.close();
    }, arguments) };
    imports.wbg.__wbg_code_cfd8f6868bdaed9b = function(arg0) {
        const ret = arg0.code;
        return ret;
    };
    imports.wbg.__wbg_code_f4ec1e6e2e1b0417 = function(arg0) {
        const ret = arg0.code;
        return ret;
    };
    imports.wbg.__wbg_crypto_574e78ad8b13b65f = function(arg0) {
        const ret = arg0.crypto;
        return ret;
    };
    imports.wbg.__wbg_data_432d9c3df2630942 = function(arg0) {
        const ret = arg0.data;
        return ret;
    };
    imports.wbg.__wbg_done_769e5ede4b31c67b = function(arg0) {
        const ret = arg0.done;
        return ret;
    };
    imports.wbg.__wbg_error_7534b8e9a36f1ab4 = function(arg0, arg1) {
        let deferred0_0;
        let deferred0_1;
        try {
            deferred0_0 = arg0;
            deferred0_1 = arg1;
            console.error(getStringFromWasm0(arg0, arg1));
        } finally {
            wasm.__wbindgen_free(deferred0_0, deferred0_1, 1);
        }
    };
    imports.wbg.__wbg_fetch_509096533071c657 = function(arg0, arg1) {
        const ret = arg0.fetch(arg1);
        return ret;
    };
    imports.wbg.__wbg_fetch_6bbc32f991730587 = function(arg0) {
        const ret = fetch(arg0);
        return ret;
    };
    imports.wbg.__wbg_fromstring_de5470cadd25e572 = function(arg0, arg1) {
        const ret = from_string(getStringFromWasm0(arg0, arg1));
        return ret;
    };
    imports.wbg.__wbg_getRandomValues_1c61fac11405ffdc = function() { return handleError(function (arg0, arg1) {
        globalThis.crypto.getRandomValues(getArrayU8FromWasm0(arg0, arg1));
    }, arguments) };
    imports.wbg.__wbg_getRandomValues_9b655bdd369112f2 = function() { return handleError(function (arg0, arg1) {
        globalThis.crypto.getRandomValues(getArrayU8FromWasm0(arg0, arg1));
    }, arguments) };
    imports.wbg.__wbg_getRandomValues_a8ddca022803a145 = function() { return handleError(function (arg0, arg1) {
        globalThis.crypto.getRandomValues(getArrayU8FromWasm0(arg0, arg1));
    }, arguments) };
    imports.wbg.__wbg_getRandomValues_b8f5dbd5f3995a9e = function() { return handleError(function (arg0, arg1) {
        arg0.getRandomValues(arg1);
    }, arguments) };
    imports.wbg.__wbg_getTime_46267b1c24877e30 = function(arg0) {
        const ret = arg0.getTime();
        return ret;
    };
    imports.wbg.__wbg_getTimezoneOffset_6b5752021c499c47 = function(arg0) {
        const ret = arg0.getTimezoneOffset();
        return ret;
    };
    imports.wbg.__wbg_get_67b2ba62fc30de12 = function() { return handleError(function (arg0, arg1) {
        const ret = Reflect.get(arg0, arg1);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_getelement_3d1fb7c84026d09c = function(arg0, arg1) {
        const ret = get_element(arg0, arg1 >>> 0);
        return ret;
    };
    imports.wbg.__wbg_has_a5ea9117f258a0ec = function() { return handleError(function (arg0, arg1) {
        const ret = Reflect.has(arg0, arg1);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_headers_9cb51cfd2ac780a4 = function(arg0) {
        const ret = arg0.headers;
        return ret;
    };
    imports.wbg.__wbg_instanceof_ArrayBuffer_e14585432e3737fc = function(arg0) {
        let result;
        try {
            result = arg0 instanceof ArrayBuffer;
        } catch (_) {
            result = false;
        }
        const ret = result;
        return ret;
    };
    imports.wbg.__wbg_instanceof_Blob_ca721ef3bdab15d1 = function(arg0) {
        let result;
        try {
            result = arg0 instanceof Blob;
        } catch (_) {
            result = false;
        }
        const ret = result;
        return ret;
    };
    imports.wbg.__wbg_instanceof_Function_07c665125a9d8cfc = function(arg0) {
        let result;
        try {
            result = arg0 instanceof Function;
        } catch (_) {
            result = false;
        }
        const ret = result;
        return ret;
    };
    imports.wbg.__wbg_instanceof_Object_7f2dcef8f78644a4 = function(arg0) {
        let result;
        try {
            result = arg0 instanceof Object;
        } catch (_) {
            result = false;
        }
        const ret = result;
        return ret;
    };
    imports.wbg.__wbg_instanceof_Performance_0ac1286c87171f57 = function(arg0) {
        let result;
        try {
            result = arg0 instanceof Performance;
        } catch (_) {
            result = false;
        }
        const ret = result;
        return ret;
    };
    imports.wbg.__wbg_instanceof_Response_f2cc20d9f7dfd644 = function(arg0) {
        let result;
        try {
            result = arg0 instanceof Response;
        } catch (_) {
            result = false;
        }
        const ret = result;
        return ret;
    };
    imports.wbg.__wbg_instanceof_Uint8Array_17156bcf118086a9 = function(arg0) {
        let result;
        try {
            result = arg0 instanceof Uint8Array;
        } catch (_) {
            result = false;
        }
        const ret = result;
        return ret;
    };
    imports.wbg.__wbg_iterator_9a24c88df860dc65 = function() {
        const ret = Symbol.iterator;
        return ret;
    };
    imports.wbg.__wbg_length_a446193dc22c12f8 = function(arg0) {
        const ret = arg0.length;
        return ret;
    };
    imports.wbg.__wbg_log_4dcc98b185543bcb = function(arg0, arg1) {
        let deferred0_0;
        let deferred0_1;
        try {
            deferred0_0 = arg0;
            deferred0_1 = arg1;
            console.log(getStringFromWasm0(arg0, arg1));
        } finally {
            wasm.__wbindgen_free(deferred0_0, deferred0_1, 1);
        }
    };
    imports.wbg.__wbg_message_5c5d919204d42400 = function(arg0, arg1) {
        const ret = arg1.message;
        const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbg_msCrypto_a61aeb35a24c1329 = function(arg0) {
        const ret = arg0.msCrypto;
        return ret;
    };
    imports.wbg.__wbg_new0_f788a2397c7ca929 = function() {
        const ret = new Date();
        return ret;
    };
    imports.wbg.__wbg_new_018dcc2d6c8c2f6a = function() { return handleError(function () {
        const ret = new Headers();
        return ret;
    }, arguments) };
    imports.wbg.__wbg_new_23a2665fac83c611 = function(arg0, arg1) {
        try {
            var state0 = {a: arg0, b: arg1};
            var cb0 = (arg0, arg1) => {
                const a = state0.a;
                state0.a = 0;
                try {
                    return __wbg_adapter_502(a, state0.b, arg0, arg1);
                } finally {
                    state0.a = a;
                }
            };
            const ret = new Promise(cb0);
            return ret;
        } finally {
            state0.a = state0.b = 0;
        }
    };
    imports.wbg.__wbg_new_31a97dac4f10fab7 = function(arg0) {
        const ret = new Date(arg0);
        return ret;
    };
    imports.wbg.__wbg_new_405e22f390576ce2 = function() {
        const ret = new Object();
        return ret;
    };
    imports.wbg.__wbg_new_78feb108b6472713 = function() {
        const ret = new Array();
        return ret;
    };
    imports.wbg.__wbg_new_8a6f238a6ece86ea = function() {
        const ret = new Error();
        return ret;
    };
    imports.wbg.__wbg_new_92c54fc74574ef55 = function() { return handleError(function (arg0, arg1) {
        const ret = new WebSocket(getStringFromWasm0(arg0, arg1));
        return ret;
    }, arguments) };
    imports.wbg.__wbg_new_9fd39a253424609a = function() { return handleError(function () {
        const ret = new FormData();
        return ret;
    }, arguments) };
    imports.wbg.__wbg_new_a12002a7f91c75be = function(arg0) {
        const ret = new Uint8Array(arg0);
        return ret;
    };
    imports.wbg.__wbg_new_c68d7209be747379 = function(arg0, arg1) {
        const ret = new Error(getStringFromWasm0(arg0, arg1));
        return ret;
    };
    imports.wbg.__wbg_new_cdd9942127fcb1fd = function(arg0, arg1) {
        const ret = new Error(getStringFromWasm0(arg0, arg1));
        return ret;
    };
    imports.wbg.__wbg_new_e25e5aab09ff45db = function() { return handleError(function () {
        const ret = new AbortController();
        return ret;
    }, arguments) };
    imports.wbg.__wbg_newnoargs_105ed471475aaf50 = function(arg0, arg1) {
        const ret = new Function(getStringFromWasm0(arg0, arg1));
        return ret;
    };
    imports.wbg.__wbg_newwithbyteoffsetandlength_d97e637ebe145a9a = function(arg0, arg1, arg2) {
        const ret = new Uint8Array(arg0, arg1 >>> 0, arg2 >>> 0);
        return ret;
    };
    imports.wbg.__wbg_newwithlength_a381634e90c276d4 = function(arg0) {
        const ret = new Uint8Array(arg0 >>> 0);
        return ret;
    };
    imports.wbg.__wbg_newwithstrandinit_06c535e0a867c635 = function() { return handleError(function (arg0, arg1, arg2) {
        const ret = new Request(getStringFromWasm0(arg0, arg1), arg2);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_newwithstrsequence_6e9d6479e1cf978d = function() { return handleError(function (arg0, arg1, arg2) {
        const ret = new WebSocket(getStringFromWasm0(arg0, arg1), arg2);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_newwithu8arraysequenceandoptions_068570c487f69127 = function() { return handleError(function (arg0, arg1) {
        const ret = new Blob(arg0, arg1);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_newwithyearmonthdayhrminsec_72c204d952ef4426 = function(arg0, arg1, arg2, arg3, arg4, arg5) {
        const ret = new Date(arg0 >>> 0, arg1, arg2, arg3, arg4, arg5);
        return ret;
    };
    imports.wbg.__wbg_next_25feadfc0913fea9 = function(arg0) {
        const ret = arg0.next;
        return ret;
    };
    imports.wbg.__wbg_next_6574e1a8a62d1055 = function() { return handleError(function (arg0) {
        const ret = arg0.next();
        return ret;
    }, arguments) };
    imports.wbg.__wbg_node_905d3e251edff8a2 = function(arg0) {
        const ret = arg0.node;
        return ret;
    };
    imports.wbg.__wbg_now_0dc4920a47cf7280 = function(arg0) {
        const ret = arg0.now();
        return ret;
    };
    imports.wbg.__wbg_now_2c95c9de01293173 = function(arg0) {
        const ret = arg0.now();
        return ret;
    };
    imports.wbg.__wbg_now_807e54c39636c349 = function() {
        const ret = Date.now();
        return ret;
    };
    imports.wbg.__wbg_now_d18023d54d4e5500 = function(arg0) {
        const ret = arg0.now();
        return ret;
    };
    imports.wbg.__wbg_performance_6adc3b899e448a23 = function(arg0) {
        const ret = arg0.performance;
        return ret;
    };
    imports.wbg.__wbg_performance_7a3ffd0b17f663ad = function(arg0) {
        const ret = arg0.performance;
        return ret;
    };
    imports.wbg.__wbg_process_dc0fbacc7c1c06f7 = function(arg0) {
        const ret = arg0.process;
        return ret;
    };
    imports.wbg.__wbg_push_737cfc8c1432c2c6 = function(arg0, arg1) {
        const ret = arg0.push(arg1);
        return ret;
    };
    imports.wbg.__wbg_queueMicrotask_97d92b4fcc8a61c5 = function(arg0) {
        queueMicrotask(arg0);
    };
    imports.wbg.__wbg_queueMicrotask_d3219def82552485 = function(arg0) {
        const ret = arg0.queueMicrotask;
        return ret;
    };
    imports.wbg.__wbg_randomFillSync_ac0988aba3254290 = function() { return handleError(function (arg0, arg1) {
        arg0.randomFillSync(arg1);
    }, arguments) };
    imports.wbg.__wbg_readyState_7ef6e63c349899ed = function(arg0) {
        const ret = arg0.readyState;
        return ret;
    };
    imports.wbg.__wbg_reason_49f1cede8bcf23dd = function(arg0, arg1) {
        const ret = arg1.reason;
        const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbg_require_60cc747a6bc5215a = function() { return handleError(function () {
        const ret = module.require;
        return ret;
    }, arguments) };
    imports.wbg.__wbg_resolve_4851785c9c5f573d = function(arg0) {
        const ret = Promise.resolve(arg0);
        return ret;
    };
    imports.wbg.__wbg_send_0293179ba074ffb4 = function() { return handleError(function (arg0, arg1, arg2) {
        arg0.send(getStringFromWasm0(arg1, arg2));
    }, arguments) };
    imports.wbg.__wbg_send_fc0c204e8a1757f4 = function() { return handleError(function (arg0, arg1, arg2) {
        arg0.send(getArrayU8FromWasm0(arg1, arg2));
    }, arguments) };
    imports.wbg.__wbg_setInterval_bede69d6c8f41bb4 = function() { return handleError(function (arg0, arg1) {
        const ret = setInterval(arg0, arg1);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_setTimeout_4ec014681668a581 = function(arg0, arg1) {
        const ret = setTimeout(arg0, arg1);
        return ret;
    };
    imports.wbg.__wbg_setTimeout_63008613644b07af = function() { return handleError(function (arg0, arg1, arg2) {
        const ret = arg0.setTimeout(arg1, arg2);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_setTimeout_eefe7f4c234b0c6b = function() { return handleError(function (arg0, arg1) {
        const ret = setTimeout(arg0, arg1);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_set_65595bdd868b3009 = function(arg0, arg1, arg2) {
        arg0.set(arg1, arg2 >>> 0);
    };
    imports.wbg.__wbg_set_bb8cecf6a62b9f46 = function() { return handleError(function (arg0, arg1, arg2) {
        const ret = Reflect.set(arg0, arg1, arg2);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_setbinaryType_92fa1ffd873b327c = function(arg0, arg1) {
        arg0.binaryType = __wbindgen_enum_BinaryType[arg1];
    };
    imports.wbg.__wbg_setbody_5923b78a95eedf29 = function(arg0, arg1) {
        arg0.body = arg1;
    };
    imports.wbg.__wbg_setcache_12f17c3a980650e4 = function(arg0, arg1) {
        arg0.cache = __wbindgen_enum_RequestCache[arg1];
    };
    imports.wbg.__wbg_setcredentials_c3a22f1cd105a2c6 = function(arg0, arg1) {
        arg0.credentials = __wbindgen_enum_RequestCredentials[arg1];
    };
    imports.wbg.__wbg_setheaders_834c0bdb6a8949ad = function(arg0, arg1) {
        arg0.headers = arg1;
    };
    imports.wbg.__wbg_setmethod_3c5280fe5d890842 = function(arg0, arg1, arg2) {
        arg0.method = getStringFromWasm0(arg1, arg2);
    };
    imports.wbg.__wbg_setmode_5dc300b865044b65 = function(arg0, arg1) {
        arg0.mode = __wbindgen_enum_RequestMode[arg1];
    };
    imports.wbg.__wbg_setonclose_14fc475a49d488fc = function(arg0, arg1) {
        arg0.onclose = arg1;
    };
    imports.wbg.__wbg_setonerror_8639efe354b947cd = function(arg0, arg1) {
        arg0.onerror = arg1;
    };
    imports.wbg.__wbg_setonmessage_6eccab530a8fb4c7 = function(arg0, arg1) {
        arg0.onmessage = arg1;
    };
    imports.wbg.__wbg_setonopen_2da654e1f39745d5 = function(arg0, arg1) {
        arg0.onopen = arg1;
    };
    imports.wbg.__wbg_setsignal_75b21ef3a81de905 = function(arg0, arg1) {
        arg0.signal = arg1;
    };
    imports.wbg.__wbg_settype_39ed370d3edd403c = function(arg0, arg1, arg2) {
        arg0.type = getStringFromWasm0(arg1, arg2);
    };
    imports.wbg.__wbg_signal_aaf9ad74119f20a4 = function(arg0) {
        const ret = arg0.signal;
        return ret;
    };
    imports.wbg.__wbg_stack_0ed75d68575b0f3c = function(arg0, arg1) {
        const ret = arg1.stack;
        const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbg_stack_5184e86c2ee98052 = function(arg0, arg1) {
        const ret = arg1.stack;
        const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbg_static_accessor_GLOBAL_88a902d13a557d07 = function() {
        const ret = typeof global === 'undefined' ? null : global;
        return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
    };
    imports.wbg.__wbg_static_accessor_GLOBAL_THIS_56578be7e9f832b0 = function() {
        const ret = typeof globalThis === 'undefined' ? null : globalThis;
        return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
    };
    imports.wbg.__wbg_static_accessor_SELF_37c5d418e4bf5819 = function() {
        const ret = typeof self === 'undefined' ? null : self;
        return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
    };
    imports.wbg.__wbg_static_accessor_WINDOW_5de37043a91a9c40 = function() {
        const ret = typeof window === 'undefined' ? null : window;
        return isLikeNone(ret) ? 0 : addToExternrefTable0(ret);
    };
    imports.wbg.__wbg_status_f6360336ca686bf0 = function(arg0) {
        const ret = arg0.status;
        return ret;
    };
    imports.wbg.__wbg_stringify_f7ed6987935b4a24 = function() { return handleError(function (arg0) {
        const ret = JSON.stringify(arg0);
        return ret;
    }, arguments) };
    imports.wbg.__wbg_subarray_aa9065fa9dc5df96 = function(arg0, arg1, arg2) {
        const ret = arg0.subarray(arg1 >>> 0, arg2 >>> 0);
        return ret;
    };
    imports.wbg.__wbg_then_44b73946d2fb3e7d = function(arg0, arg1) {
        const ret = arg0.then(arg1);
        return ret;
    };
    imports.wbg.__wbg_then_48b406749878a531 = function(arg0, arg1, arg2) {
        const ret = arg0.then(arg1, arg2);
        return ret;
    };
    imports.wbg.__wbg_tostring_da980fc4fe2711a0 = function(arg0, arg1) {
        const ret = to_string(arg1);
        const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbg_typeof_2e6e8f97a58dc821 = function(arg0, arg1) {
        const ret = typeof_(arg1);
        const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbg_url_ae10c34ca209681d = function(arg0, arg1) {
        const ret = arg1.url;
        const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbg_url_ce9ab75bf9627ae4 = function(arg0, arg1) {
        const ret = arg1.url;
        const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbg_valueOf_7392193dd78c6b97 = function(arg0) {
        const ret = arg0.valueOf();
        return ret;
    };
    imports.wbg.__wbg_valueOf_fdbb54fcdfe33477 = function(arg0) {
        const ret = arg0.valueOf();
        return ret;
    };
    imports.wbg.__wbg_value_cd1ffa7b1ab794f1 = function(arg0) {
        const ret = arg0.value;
        return ret;
    };
    imports.wbg.__wbg_versions_c01dfd4722a88165 = function(arg0) {
        const ret = arg0.versions;
        return ret;
    };
    imports.wbg.__wbg_wasClean_605b4fd66d44354a = function(arg0) {
        const ret = arg0.wasClean;
        return ret;
    };
    imports.wbg.__wbindgen_cb_drop = function(arg0) {
        const obj = arg0.original;
        if (obj.cnt-- == 1) {
            obj.a = 0;
            return true;
        }
        const ret = false;
        return ret;
    };
    imports.wbg.__wbindgen_closure_wrapper23357 = function(arg0, arg1, arg2) {
        const ret = makeMutClosure(arg0, arg1, 9179, __wbg_adapter_34);
        return ret;
    };
    imports.wbg.__wbindgen_closure_wrapper23471 = function(arg0, arg1, arg2) {
        const ret = makeMutClosure(arg0, arg1, 9250, __wbg_adapter_37);
        return ret;
    };
    imports.wbg.__wbindgen_closure_wrapper31358 = function(arg0, arg1, arg2) {
        const ret = makeMutClosure(arg0, arg1, 12219, __wbg_adapter_40);
        return ret;
    };
    imports.wbg.__wbindgen_closure_wrapper36796 = function(arg0, arg1, arg2) {
        const ret = makeMutClosure(arg0, arg1, 13876, __wbg_adapter_43);
        return ret;
    };
    imports.wbg.__wbindgen_closure_wrapper43281 = function(arg0, arg1, arg2) {
        const ret = makeMutClosure(arg0, arg1, 16428, __wbg_adapter_46);
        return ret;
    };
    imports.wbg.__wbindgen_closure_wrapper45439 = function(arg0, arg1, arg2) {
        const ret = makeMutClosure(arg0, arg1, 16977, __wbg_adapter_49);
        return ret;
    };
    imports.wbg.__wbindgen_debug_string = function(arg0, arg1) {
        const ret = debugString(arg1);
        const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        const len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbindgen_error_new = function(arg0, arg1) {
        const ret = new Error(getStringFromWasm0(arg0, arg1));
        return ret;
    };
    imports.wbg.__wbindgen_init_externref_table = function() {
        const table = wasm.__wbindgen_export_2;
        const offset = table.grow(4);
        table.set(0, undefined);
        table.set(offset + 0, undefined);
        table.set(offset + 1, null);
        table.set(offset + 2, true);
        table.set(offset + 3, false);
        ;
    };
    imports.wbg.__wbindgen_is_function = function(arg0) {
        const ret = typeof(arg0) === 'function';
        return ret;
    };
    imports.wbg.__wbindgen_is_null = function(arg0) {
        const ret = arg0 === null;
        return ret;
    };
    imports.wbg.__wbindgen_is_object = function(arg0) {
        const val = arg0;
        const ret = typeof(val) === 'object' && val !== null;
        return ret;
    };
    imports.wbg.__wbindgen_is_string = function(arg0) {
        const ret = typeof(arg0) === 'string';
        return ret;
    };
    imports.wbg.__wbindgen_is_undefined = function(arg0) {
        const ret = arg0 === undefined;
        return ret;
    };
    imports.wbg.__wbindgen_memory = function() {
        const ret = wasm.memory;
        return ret;
    };
    imports.wbg.__wbindgen_number_new = function(arg0) {
        const ret = arg0;
        return ret;
    };
    imports.wbg.__wbindgen_string_get = function(arg0, arg1) {
        const obj = arg1;
        const ret = typeof(obj) === 'string' ? obj : undefined;
        var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_malloc, wasm.__wbindgen_realloc);
        var len1 = WASM_VECTOR_LEN;
        getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
        getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
    };
    imports.wbg.__wbindgen_string_new = function(arg0, arg1) {
        const ret = getStringFromWasm0(arg0, arg1);
        return ret;
    };
    imports.wbg.__wbindgen_throw = function(arg0, arg1) {
        throw new Error(getStringFromWasm0(arg0, arg1));
    };
    imports['./snippets/napi-dispatcher-wasm-2f83e9bddb5a9c18/inline0.js'] = __wbg_star0;
    imports['./snippets/safer-ffi-a11ec19b6b02a0db/inline0.js'] = __wbg_star1;

    return imports;
}

function __wbg_init_memory(imports, memory) {

}

function __wbg_finalize_init(instance, module) {
    wasm = instance.exports;
    init.__wbindgen_wasm_module = module;
    cachedDataViewMemory0 = null;
    cachedUint8ArrayMemory0 = null;


    wasm.__wbindgen_start();
    return wasm;
}

function initSync(module) {
    if (wasm !== undefined) return wasm;


    if (typeof module !== 'undefined') {
        if (Object.getPrototypeOf(module) === Object.prototype) {
            ({module} = module)
        } else {
            console.warn('using deprecated parameters for `initSync()`; pass a single object instead')
        }
    }

    const imports = __wbg_get_imports();

    __wbg_init_memory(imports);

    if (!(module instanceof WebAssembly.Module)) {
        module = new WebAssembly.Module(module);
    }

    const instance = new WebAssembly.Instance(module, imports);

    return __wbg_finalize_init(instance, module);
}

async function init(module_or_path) {
    if (wasm !== undefined) return wasm;


    if (typeof module_or_path !== 'undefined') {
        if (Object.getPrototypeOf(module_or_path) === Object.prototype) {
            ({module_or_path} = module_or_path)
        } else {
            console.warn('using deprecated parameters for the initialization function; pass a single object instead')
        }
    }

    if (typeof module_or_path === 'undefined') {
        throw new Error("Can't load ditto.wasm, expected module to be provided at initialization time but got nothing.");
    }
    const imports = __wbg_get_imports();

    if (typeof module_or_path === 'string' || (typeof Request === 'function' && module_or_path instanceof Request) || (typeof URL === 'function' && module_or_path instanceof URL)) {
        module_or_path = fetch(module_or_path);
    }

    __wbg_init_memory(imports);

    const { instance, module } = await __wbg_load(await module_or_path, imports);

    return __wbg_finalize_init(instance, module);
}

export { initSync };
export { init };
