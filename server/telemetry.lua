if Config.support_the_creator_telemetry then
    CreateThread(function()
        local version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
        local server_name = GetConvar('sv_hostname', 'unknown')

        PerformHttpRequest(
            'https://telemetry-human-labs-raid.kajahasir.workers.dev',
            function(_status_code, _response, _headers)
                -- Ignore failures etc.
            end,
            'POST',
            json.encode({
                version = version,
                language = Config.language,
                server_name = server_name
            }),
            { ['Content-Type'] = 'application/json' }
        )
    end)
end
