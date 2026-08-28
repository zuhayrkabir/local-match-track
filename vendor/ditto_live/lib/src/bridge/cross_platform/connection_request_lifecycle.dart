import "package:meta/meta.dart";

import "../../presence/presence.dart";
import "types.dart";

/// Drives the lifecycle of a single `dittoffi_connection_request_t *` handler
/// invocation.
///
/// The FFI contract (see `docs/ffi/src/transports/connections.md`) requires
/// every handler invocation to release the request handle with [free] exactly
/// once. Calling [authorize] is optional — omitting it before [free] is an
/// implicit reject — but we always call it explicitly so the remote peer does
/// not have to wait for the core's ~10s timeout when a customer handler
/// rejects or throws.
///
/// [free] is always called, even if [authorize] throws.
@internal
Future<void> runConnectionRequestHandler({
  required CPPointer<CPConnectionRequest> request,
  required Future<ConnectionRequestAuthorization> Function(
    CPPointer<CPConnectionRequest>,
  ) handler,
  required void Function(
    CPPointer<CPConnectionRequest>,
    ConnectionRequestAuthorization,
  ) authorize,
  required void Function(CPPointer<CPConnectionRequest>) free,
  required void Function(Object error, StackTrace stackTrace) onError,
}) async {
  ConnectionRequestAuthorization? authorization;
  try {
    authorization = await handler(request);
  } catch (e, st) {
    onError(e, st);
  } finally {
    try {
      authorize(
        request,
        authorization ?? ConnectionRequestAuthorization.deny,
      );
    } catch (e, st) {
      onError(e, st);
    } finally {
      free(request);
    }
  }
}
