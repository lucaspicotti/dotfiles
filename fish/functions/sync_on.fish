function sync_on
    if not pgrep -x syncthing >/dev/null
        syncthing serve >/dev/null 2>&1 &
        disown
        sleep 1
    end

    sync_status
end
