function pg_dump --description 'Run pg_dump inside the Docker databases-container'
    if test -t 0
        docker exec -it databases-container pg_dump $argv
    else
        docker exec -i databases-container pg_dump $argv
    end
end
