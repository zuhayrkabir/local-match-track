
    export function to_string(value) {
        return value.toString();
    }
    export function is_number(value) {
        return typeof value === 'number';
    }
    export function try_downsize(value) {
        switch (typeof value) {
            case 'bigint':
                if (-Number.MAX_SAFE_INTEGER <= value
                    && value <= Number.MAX_SAFE_INTEGER)
                {
                    return Number(value);
                }
            case 'number':
                return value;
            default:
                throw new Error(`number or bigint expected, got \`${value}\``);
        }
    }
    export function from_string(repr) {
        return BigInt(repr);
    }
