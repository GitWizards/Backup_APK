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
    echo "   ___   ___  | |_ | |_ __      __ ____  ____  ___        "
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

    # Versione Android
    version=$(./$1/adb shell getprop ro.build.version.sdk)
    version="${version/$'\r'/}"
        
    # Check Android found
    check=$(./$1/adb devices)

    # Check device is phone or watch
    watch=$(./$1/adb shell getprop | grep "characteristics")
}


# Menu principale
function display_menu {
    if ! [[ ${check//List of devices attached} == *"device"* ]]
    then
    clear ; echo "Dispositivo non trovato o offline!"
    exit;
    fi

    if [ "$version" -ge 22 ]
    then
        clear
    else
        clear
        echo "Versione Android ($version) non supportata"
        echo "Versione Android ($version) non supportata" > log.txt
        exit
    fi

    PS3='Quale operazione vuoi fare?: '
    options=("Backup APK" "Ripristino APK" "Esci")

    select opt in "${options[@]}"
    do
        case $opt in
        "Backup APK")
            clear
            SECONDS=0
            if [[ ${watch} == *"watch"* ]]
            then
            ./$1/adb shell settings put global airplane_mode_on 1
            fi

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
                # Seleziona il Package Name (eg. com.android) dell'applicazione
                package=$(sed -n $i'p' ./$1/.output)
                package=$(echo $package|tr -d '\r')

                # Individua la posizione esatta dell'applicazione
                address=$(./$1/adb shell pm path $package)
                address="${address/package:/}"
                
                # Indica la cartella di appartenenza dell'applicazione
                array=$(echo $address| cut -d'/' -f 2)

                if [ "$array" == "data" ]
                then
                    if [ "$version" -ge 22 ]
                    then
                        address=$(echo $address|tr -d '\r')

                        echo "Backup $package in..."
                        ./$1/adb pull $address ./"backup_apk_`date "+%d-%m-%Y"`/$p"/$address
                        echo
                        ls=$(ls "./backup_apk_`date "+%d-%m-%Y"`$p$address") 
                        echo $ls >> ripristina_apk.info
                    fi
                fi
            done
            
            
            #Disable airplane mode_on
            ./$1/adb shell settings put global airplane_mode_on 0
            
            duration=$SECONDS
            echo ""
            echo "Backup Completato in $(($duration / 60)) minuti e $(($duration % 60)) secondi."
            ;;

        "Ripristino APK")
            clear
            SECONDS=0
            totaline=$(wc -l ./ripristina_apk.info)
            totalinec="${totaline// .\/\ripristina_apk.info}"

            for (( i=1; i<=$totalinec; i++))
            do
                print=$(sed -n $i'p' ./ripristina_apk.info)

                ./$1/adb install $print
            done

            duration=$SECONDS
            echo ""
            echo "Ripristino Completato in $(($duration / 60)) minuti e $(($duration % 60)) secondi."
            ;;

        "Esci")
            exit 0
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

    elif [[ "$OSTYPE" == "darwin"* ]]
    then
        # Mac OSX
        backup_apk 'macos'
        display_menu 'macos'
    else
        echo Sistema non riconosciuto...
fi