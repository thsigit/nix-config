[
  {
    model_name = "gemini/gemini-2.5-flash-lite";
    litellm_params = {
      model = "gemini/gemini-2.5-flash-lite";
      api_base = "https://generativelanguage.googleapis.com/v1beta";
      api_key = "os.environ/GEMINI_API_KEY";
    };
  }
  {
    model_name = "ollama/llama3.2";
    litellm_params = {
      model = "ollama/llama3.2";
      api_base = "http://127.0.0.1:11434";
    };
  }
]
