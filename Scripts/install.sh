#!/usr/bin/env bash
#|---/ /+--------------------------+---/ /|#
#|--/ /-| Main installation script |--/ /-|#
#|-/ /---+--------------------------+/ /--|#

cat << "EOF"

-------------------------------------------------
        .
       / \         _       _  _      ___  ___ 
      /^  \      _| |_    | || |_  _|   \| __|
     /  _  \    |_   _|   | __ | || | |) | _| 
    /  | | ~\     |_|     |_||_|\_, |___/|___|
   /.-'   '-.\                  |__/          

-------------------------------------------------

EOF

#--------------------------------#
# import variables and functions #
#--------------------------------#
scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

#--------------------#
# pre-install script #
#--------------------#
cat << "EOF"
                _         _       _ _
 ___ ___ ___   |_|___ ___| |_ ___| | |
| . |  _| -_|  | |   |_ -|  _| .'| | |
|  _|_| |___|  |_|_|_|___|_| |__,|_|_|
|_|

EOF

"${scrDir}/install_pre.sh"

#------------#
# installing #
#------------#
cat << "EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

#----------------------#
# prepare package list #
#----------------------#
shift $((OPTIND - 1))
cust_pkg=$1
cp "${scrDir}/custom_hypr.lst" "${scrDir}/install_pkg.lst"

if [ -f "${cust_pkg}" ] && [ ! -z "${cust_pkg}" ]; then
    cat "${cust_pkg}" >> "${scrDir}/install_pkg.lst"
fi

#--------------------------------#
# add nvidia drivers to the list #
#--------------------------------#
if nvidia_detect; then
    cat /usr/lib/modules/*/pkgbase | while read krnl; do
    echo "${krnl}-headers" >> "${scrDir}/install_pkg.lst"
done
nvidia_detect --drivers >> "${scrDir}/install_pkg.lst"
fi

nvidia_detect --verbose

#--------------------------------#
# install packages from the list #
#--------------------------------#
"${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
rm "${scrDir}/install_pkg.lst"

#---------------------#
# post-install script #
#---------------------#
cat << "EOF"

             _      _         _       _ _
 ___ ___ ___| |_   |_|___ ___| |_ ___| | |
| . | . |_ -|  _|  | |   |_ -|  _| .'| | |
|  _|___|___|_|    |_|_|_|___|_| |__,|_|_|
|_|

EOF

"${scrDir}/install_pst.sh"

#------------------------#
# enable system services #
#------------------------#
cat << "EOF"

                 _
 ___ ___ ___ _ _|_|___ ___ ___
|_ -| -_|  _| | | |  _| -_|_ -|
|___|___|_|  \_/|_|___|___|___|

EOF

while read servChk; do

    if [[ $(systemctl list-units --all -t service --full --no-legend "${servChk}.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "${servChk}.service" ]]; then
        echo -e "\033[0;33m[SKIP]\033[0m ${servChk} service is active..."
    else
        echo -e "\033[0;32m[systemctl]\033[0m starting ${servChk} system service..."
        sudo systemctl enable "${servChk}.service"
        sudo systemctl start "${servChk}.service"
    fi

done < "${scrDir}/system_ctl.lst"
