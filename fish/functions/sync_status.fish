function sync_status
    if not pgrep -x syncthing >/dev/null
        echo "Syncthing nao esta rodando."
        return 1
    end

    echo "Syncthing status:"
    syncthing cli show system
end
