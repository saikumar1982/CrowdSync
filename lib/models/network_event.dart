enum NetworkEventType {
  connected,
  disconnected,
  connectionRejected,
  message,
  filePayload,
  fileTransferUpdate,
  error,
}

class NetworkEvent {
  const NetworkEvent({
    required this.type,
    this.endpointId,
    this.endpointName,
    this.message,
    this.payloadId,
    this.fileUri,
    this.filePath,
    this.transferStatus,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.error,
  });

  final NetworkEventType type;
  final String? endpointId;
  final String? endpointName;
  final Map<String, dynamic>? message;
  final int? payloadId;
  final String? fileUri;
  final String? filePath;
  final String? transferStatus;
  final int bytesTransferred;
  final int totalBytes;
  final Object? error;
}
