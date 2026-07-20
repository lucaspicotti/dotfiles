function pg_restore --description 'Run pg_restore inside the Docker databases-container'
    if test -t 0
        docker exec -it databases-container pg_restore $argv
    else
        docker exec -i databases-container pg_restore $argv
    end
end
