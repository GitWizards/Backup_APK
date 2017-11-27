#!/bin/bash

# Funzione di backup
function check_apk {
	clear && reset
    echo Avvio Check APK
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
    ./$1/adb shell pm list packages > check_app.txt
    sed -e 's/package://' check_app.txt > check_app1.txt
    mv check_app1.txt check_app.txt

    a="$(< ripristina_apk.info wc -l)"
    for ((i=1; i<="${a}"; i++))
    do
        mystring="$(sed -n $i'p' ./ripristina_apk.info)"
        IFS='-' read -a myarray <<< "$mystring"
        IFS='/' read -a myarray1 <<< "${myarray[2]}"

        b="$(cat ./check_app.txt | grep ${myarray1[3]})"

        if [[ $b != *[!\ ]* ]]; then
            echo Ripristino ${myarray1[3]}
            ./$1/adb install ${mystring}
            echo 
        fi

    done
    echo Ripristino completato
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
        check_apk 'linux'
        display_menu 'linux'
    # TODO Potrebbe entrare qui in caso di sistema non riconosciuto, mettere if
    else
        # 32-bit
        check_apk 'linux32'
        display_menu 'linux32'
    fi

    elif [[ "$OSTYPE" == "darwin"* ]]
    then
        # Mac OSX
        check_apk 'macos'
        display_menu 'macos'
    else
        echo Sistema non riconosciuto...
fi