function psql --description 'Run psql inside the Docker databases-container'
    if test -t 0
        docker exec -it databases-container psql $argv
    else
        docker exec -i databases-container psql $argv
    end
end
