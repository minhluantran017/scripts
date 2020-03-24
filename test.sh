

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
  -V | --version )
    echo "This is version"
    exit
    ;;
  -s | --string )
    shift; echo $1
    ;;
  -f | --flag )
    flag=1; echo "flag=$flag"
    ;;
esac; shift; done
if [[ "$1" == '--' ]]; then shift; fi