#!/bin/bash


# Funzione di backup
function backup_apk {
	clear && reset
    echo Avvio Backup APK
    echo --------------------
    echo "          ______           _     ___                      "
    echo "         |  ____|         | |   / _ \                     "
    echo "         | |__  __ _  ___ | |_ | | | | _ __               "
    echo "         |  __|/ _  |/ __|| __|| | | || '_ \              "
    echo "         | |  | (_| |\__ \| |_ | |_| || | | |             "
    echo "         |_|   \__,_||___/ \__| \___/ |_| |_|             "
    echo "                                                          "
    echo "                __  _                                     "
    echo "               / _|| |                                    "
    echo "   ___   ___  | |_ | |_ __      __ __ _  _ __  ___        "
    echo "  / __| / _ \ |  _|| __|\ \ /\ / // _  ||  __|/ _ "'\'"   "
    echo "  "'\'"__ \| |_| || |  | |_  \ V  V /| (_| || |  |  __/   "
    echo "  |___/ \___/ |_|   \__|  \_/\_/  \____||_|   \___|       "
    echo "                                                          "
    sleep 2
    clear

    # Kill-server (Android <= 6.0)
    ./$1/adb kill-server 1>/dev/null

    # Riavvia adb
    ./$1/adb start-server 1>/dev/null

    # Clean
    rm -f ./$1/.output 2>/dev/null

    #Versione Android
    version=$(./$1/adb shell getprop ro.build.version.sdk)
}


# Menu principale
function display_menu {
    if [ $version >> 21 ]
    then
        clear ; rm 21
    else
        echo "Versione Android non supportata"
    fi

    PS3='Quale operazione vuoi fare?: '
    options=("Backup APK" "Ripristino APK" "Esci")

    select opt in "${options[@]}"
    do
        case $opt in
        "Backup APK")
            clear

            # Elimino il file di ripristino
            rm -f ripristina_apk.info 2>/dev/null

            # Importa le applicazioni dal dispositivo a .output
            ./$1/adb shell pm list packages >> ./$1/.output

            # Rimuove prefisso 'package'
            sed -e 's/package://' ./$1/.output > ./$1/.output2
            mv ./$1/.output2 ./$1/.output

            # Indica numero linee file output
            totaline=$(wc -l ./$1/.output)
            totalinec="${totaline// .\/$1\/.output}"

            # Crea cartella backup
            mkdir backup_apk_`date "+%d-%m-%Y"`/$p 2>/dev/null

            for (( i=1; i<=$totalinec; i++))
            do
                print=$(sed -n $i'p' ./$1/.output)

                #Individua la posizione esatta dell'APK
                print1=$(./$1/adb shell pm path $print)

                IFS='/'
                array=( $print1 )
                if [ "${array[1]}" == "data" ]
                then
                    IFS=''

                    replace=$(sed 's/package://g' <<< $print1)
                    replace1=$(sed 's/package:\/data\/app\///g' <<< $print1)

                    echo "Backup ${replace//\/base.apk} in..."

                    ./$1/adb pull $replace ./"backup_apk_`date "+%d-%m-%Y"`/$p"/$replace
                    echo
                    ls=$(ls `pwd`"/backup_apk_`date "+%d-%m-%Y"`$p$replace") 
                    echo $ls >> ripristina_apk.info
                fi  
            done

            echo "Backup Completato"
            ;;

        "Ripristino APK")
            clear
            totaline=$(wc -l ./ripristina_apk.info)
            totalinec="${totaline// .\/\ripristina_apk.info}"

            for (( i=1; i<=$totalinec; i++))
            do
                print=$(sed -n $i'p' ./ripristina_apk.info)

                ./$1/adb install $print
            done

            echo "Ripristino Completato"
            ;;

        "Esci")
            break
            ;;

        *)
            echo Funzione non esistente
            ;;
    esac
done
}


## Main
# Controllo sistema
if [[ "$OSTYPE" == "linux-gnu" ]]
then
    # Linux
    MACHINE_TYPE=`uname -m`

    if [ ${MACHINE_TYPE} == 'x86_64' ]
    then
        # 64-bit
        backup_apk 'linux'
        display_menu 'linux'
    # TODO Potrebbe entrare qui in caso di sistema non riconosciuto, mettere if
    else
        # 32-bit
        backup_apk 'linux32'
        display_menu 'linux32'
    fi

    elif [[ "$OSTYPE" == "darwin16" ]]
    then
        # Mac OSX
        backup_apk 'macos'
        display_menu 'macos'
    else
        echo Sistema non riconosciuto...
fi
