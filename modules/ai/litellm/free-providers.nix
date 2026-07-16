{
  aihubmix = {
    env = "AIHUBMIX_API_KEY";
    api = "https://aihubmix.com";
    prefix = "openai";
  };
  cohere = {
    env = "COHERE_API_KEY";
    api = "https://api.cohere.com/v2/";
    prefix = "cohere";
  };
  nvidia = {
    env = "NVIDIA_API_KEY";
    prefix = "openai";
  };
  openrouter = {
    env = "OPENROUTER_API_KEY";
    prefix = "openrouter";
  };
  kenari = {
    env = "KENARI_API_KEY";
    prefix = "openai";
    models = [
      "deepseek-v4-flash:free"
      "hy3:free"
      "kimi-k2-7-code:free"
      "mimo-v2-5"
    ];
  };
  zai = {
    env = "ZHIPU_API_KEY";
    prefix = "openai";
  };
}
