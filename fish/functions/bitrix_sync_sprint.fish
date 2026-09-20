function bitrix_sync_sprint --description "Sincroniza uma Sprint do Bitrix (dry-run por padrão; use --apply para gravar)"
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
        python3 /home/lucaspicotti/Documentos/ObsidianVault/scripts/sync_bitrix.py --apply --sprint-id $rest
    else
        python3 /home/lucaspicotti/Documentos/ObsidianVault/scripts/sync_bitrix.py --dry-run --sprint-id $rest
    end
end
