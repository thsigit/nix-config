{ providers, ... }:
{
  services.litellm.settings.model_list = [
    {
      model_name = "gemini-2.5-flash-lite";
      litellm_params = {
        model = "gemini/gemini-2.5-flash-lite";
        api_base = providers.gemini.apiBase;
        api_key = "os.environ/${providers.gemini.env}";
      };
    }

    {
      model_name = "gpt-oss-20b";
      litellm_params = {
        model = "fireworks/gpt-oss-20b";
        api_base = providers.fireworks.apiBase;
        api_key = "os.environ/${providers.fireworks.env}";
      };
    }

    {
      model_name = "elephant-alpha";
      litellm_params = {
        model = "openrouter/elephant-alpha";
        api_base = providers.openrouter.apiBase;
        api_key = "os.environ/${providers.openrouter.env}";
      };
    }
  ];
}