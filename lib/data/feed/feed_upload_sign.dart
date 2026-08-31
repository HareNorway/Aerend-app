class FeedUploadSignParams {
  final String cloudName;
  final String apiKey;
  final int timestamp;
  final String signature;
  final String publicId;
  final String folder;
  final String resourceType;
  final String? eager;
  final int maxFileSize;

  const FeedUploadSignParams({
    required this.cloudName,
    required this.apiKey,
    required this.timestamp,
    required this.signature,
    required this.publicId,
    required this.folder,
    required this.resourceType,
    this.eager,
    required this.maxFileSize,
  });

  factory FeedUploadSignParams.fromJson(Map<String, dynamic> json) {
    return FeedUploadSignParams(
      cloudName: json['cloud_name'] as String,
      apiKey: json['api_key'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      signature: json['signature'] as String,
      publicId: json['public_id'] as String,
      folder: json['folder'] as String,
      resourceType: json['resource_type'] as String,
      eager: json['eager'] as String?,
      maxFileSize: (json['max_file_size'] as num).toInt(),
    );
  }
}
