absinthe_loaded? = RequestCache.Application.dependency_found?(:absinthe) and
                    RequestCache.Application.dependency_found?(:absinthe_plug)
if absinthe_loaded? do
  defmodule RequestCache.Middleware do
    alias RequestCache.Util

    @behaviour Absinthe.Middleware

    @impl Absinthe.Middleware
    def call(%Absinthe.Resolution{} = resolution, opts) when is_list(opts) do
      opts = ensure_valid_ttl(opts)
      enable_cache_for_resolution(resolution, opts)
    end

    @impl Absinthe.Middleware
    def call(%Absinthe.Resolution{} = resolution, ttl) when is_integer(ttl) do
      enable_cache_for_resolution(resolution, ttl: ttl)
    end

    defp enable_cache_for_resolution(resolution, opts) do
      if resolution.context[RequestCache.Config.conn_private_key()][:enabled?] do
        if RequestCache.Config.verbose?() do
          Util.verbose_log("[RequestCache.Middleware] Enabling cache for resolution")
        end

        %{resolution |
          context: Map.update!(
            resolution.context,
            RequestCache.Config.conn_private_key(),
            &Keyword.put(&1, :request, opts)
          )
        }
      else
        Util.log_cache_disabled_message()

        resolution
      end
    end

    defp ensure_valid_ttl(opts) do
      ttl = opts[:ttl] || RequestCache.Config.default_ttl()
      Keyword.put(opts, :ttl, ttl)
    end
  end
end
