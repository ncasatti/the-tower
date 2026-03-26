function oc
    docker compose run --rm openclaw-cli $argv
end

function ocg
    docker compose exec -it openclaw-gateway node dist/index.js $argv
end
