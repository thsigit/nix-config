{ ... }:

{
  services.litellm.settings = {
    general_settings = {
      database_url = "postgresql:///litellm?host=/run/postgresql";
      master_key = "os.environ/LITELLM_MASTER_KEY";
    };

    litellm_settings = {
      json_logs = true;
      drop_params = true;
    };
  };
}