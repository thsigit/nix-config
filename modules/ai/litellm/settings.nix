{ ... }:

{
  services.litellm.settings = {
    general_settings = {
      database_url = "postgresql:///litellm?host=/run/postgresql";

      # We'll revisit this once we verify the preferred way to inject
      # the master key. If LiteLLM doesn't expand os.environ here,
      # we'll use a different approach.
      master_key = "os.environ/LITELLM_MASTER_KEY";
    };

    litellm_settings = {
      json_logs = true;
      drop_params = true;
    };
  };
}