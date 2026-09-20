function portcheck --description 'Verifica se algo está escutando/conectado numa porta TCP; útil para confirmar shutdown de processos em dev'
    if test (count $argv) -ne 1
        echo "uso: portcheck <porta>"
        return 1
    end

    set -l port $argv[1]
    if lsof -i :$port
        return 0
    else
        echo "porta $port livre - nenhum processo escutando/conectado"
        return 1
    end
end
