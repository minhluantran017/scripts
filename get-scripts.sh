RED=$'\e[1;31m'
BLU=$'\e[1;32m'
YEL=$'\e[1;33m'
MAG=$'\e[1;35m'
WHI=$'\e[0m'
TEMPDIR=${TEMPDIR:=$(mktemp)}
function info() { echo ${BLU}INFO: $1${WHI}; }
function warn() { echo ${YEL}WARN: $1${WHI}; }
function err() { echo ${RED}ERR: $1${WHI}; }

function welcome() {
    echo "  _______________________________________________________"
    echo " / ${RED}Hello my friend, welcome to my scripts!${WHI}               \\"
    echo "/ ${BLU}These small script may make your Dev/DevOps life easier.${WHI}\\"
    echo "\\ ${MAG}Please note that they're just simple as it should be.${WHI}   /"
    echo " \\ ${YEL}I don't want them to be complex ever! Enjoy it!${WHI}       /"
    echo "  -------------------------------------------------------"
    echo "${MAG}        \   ^__^"
    echo "${MAG}         \  (oo)\_______"
    echo "${MAG}            (__)\       )\/\\"
    echo "${MAG}                ||----w |"
    echo "${MAG}                ||     ||${WHI}"
}

function check_requirement() {
    info "Checking requirements first..."
    if [[ -z $(which git) ]]; then err "Please install git on your system first!" && exit 1; fi
    if [[ -z $(which python3) ]]; then warn "Should install Python 3 on your system!"; fi
    info "All things seem fine. Go!"
}

function checkout_code() {
    info "Checking out my code from GitHub..."
    git checkout --quiet https://github.com/minhluantran017/scripts.git $TEMPDIR
}

function create_binaries() {
    info "Creating executable scripts..."
    cd $TEMPDIR
    ls | egrep '*.sh|*.py' | grep -v "get-scripts.sh" | sort | while read filename
    do
        shortcut=`echo $filename | sed  's/.sh\|.py$//g'`
        if [[ -e /usr/local/bin/$shortcut ]]; then warn "File existed: $shortcut. Overwritting..."; fi
        sudo rm -f /usr/local/bin/$shortcut
        sudo cp $TEMPDIR/$filename /usr/local/bin/$shortcut
        sudo chmod +x /usr/local/bin/$shortcut
        echo "    $filename --> /usr/local/bin/$shortcut"
    done
}

function clean_stuffs() {
    rm -rf $TEMPDIR
}

welcome
check_requirement
checkout_code
create_binaries
clean_stuffs
