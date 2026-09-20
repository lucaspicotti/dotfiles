function bitrix_sync_backlog --description "Sincroniza o Backlog do Bitrix (dry-run por padrão; use --apply para gravar)"
    set -l apply 0
    set -l rest
    for a in $argv
        if test "$a" = --apply
            set apply 1
        else
            set rest $rest $a
        end
    end

    if test $apply -eq 1
        python3 /home/lucaspicotti/Documentos/ObsidianVault/scripts/sync_bitrix.py --apply --backlog $rest
    else
        python3 /home/lucaspicotti/Documentos/ObsidianVault/scripts/sync_bitrix.py --dry-run --backlog $rest
    end
end
