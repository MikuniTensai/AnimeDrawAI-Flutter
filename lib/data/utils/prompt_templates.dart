class PromptTemplates {
  static const List<String> commonDetailed = [
    "masterpiece",
    "best quality",
    "ultra-detailed",
    "8k",
    "cinematic lighting",
    "dynamic angle",
    "detailed background",
  ];

  static const List<String> commonNegatives = [
    "low quality",
    "worst quality",
    "normal quality",
    "blurry",
    "jpeg artifacts",
    "error",
    "bad anatomy",
    "extra fingers",
    "missing fingers",
    "bad hands",
  ];

  static List<String> getSuggestionsForWorkflow(String workflowId) {
    if (workflowId.contains("anime")) {
      return [
        "anime style",
        "vibrant colors",
        "smooth lines",
        ...commonDetailed,
      ];
    } else if (workflowId.contains("realistic")) {
      return [
        "photorealistic",
        "raw photo",
        "dslr",
        "soft lighting",
        ...commonDetailed,
      ];
    }
    return commonDetailed;
  }
}
