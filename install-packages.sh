#!/bin/bash

apt-get install -y tar wget gzip rubygems jq
apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline6 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

export DEBIAN_FRONTEND=noninteractive

declare -a DEPENDENCIES=(tar wget gzip gem jq)

LOGFILE=/dev/null
OUTPUT=/usr/local/bin

URLS_BOSH=https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-3.0.1-linux-amd64
URLS_CF='https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github'
REPO_CREDHUB=cloudfoundry-incubator/credhub-cli
REPO_GOVC=vmware/govmomi
REPO_OM=pivotal-cf/om
REPO_PIVNET_CLI=pivotal-cf/pivnet-cli
REPO_BBR=cloudfoundry-incubator/bosh-backup-and-restore
REPO_BBL=cloudfoundry/bosh-bootloader

###
## Helpers
###

log() {
    echo $@ >> $LOGFILE
}

function_exists() {
    declare -f -F $1 > /dev/null
    return $?
}

validate() {
    if [ "$USER" != "root" ]; then
        echo "Please run as root or with sudo" 1>&2
        exit 2
    fi

    missing=
    for dep in "${DEPENDENCIES[@]}"; do
        hash "$dep" || missing="$missing "
    done

    if [ ! -z "$missing" ]; then
        echo "Missing required dependencies: $missing" 1>&2
        exit 2
    else
        log "All dependency requirements met"
    fi
}

get_latest_release() {
    DOWNLOAD_URL=$(curl --silent "https://api.github.com/repos/$1/releases/latest" | \
      jq -r \
      --arg flavor $2 '.assets[] | select(.name | contains($flavor)) | .browser_download_url')
    echo $DOWNLOAD_URL
}


###
## Installations
###

install_bosh() {
    log 'Installing bosh'

    wget -qO "$OUTPUT"/bosh "$URLS_BOSH"
    chmod +x "$OUTPUT"/bosh
}

install_cf() {
    log 'Installing cf'

    wget -qO "$OUTPUT"/cf.tgz "$URLS_CF"
    gzip -dc "$OUTPUT"/cf.tgz > "$OUTPUT"/cf
    chmod +x "$OUTPUT"/cf
    
    rm "$OUTPUT"/cf.tgz
}

install_credhub() {
    log 'Installing credhub'

    get_latest_release "$REPO_CREDHUB" "linux"

    wget -qO "$OUTPUT"/credhub "$DOWNLOAD_URL"
    chmod +x "$OUTPUT"/credhub
}

install_govc() {
    log 'Installing govc'

    TEMP_FILE=`mktemp`

    get_latest_release "$REPO_GOVC" "linux_amd64"

    wget -qO "$TEMP_FILE" "$DOWNLOAD_URL"
    gzip -dc "$TEMP_FILE" > "$OUTPUT"/govc
    chmod +x "$OUTPUT"/govc

    rm "$TEMP_FILE"
}

install_pivnet_cli() {
    log 'Installing pivnet cli'

    get_latest_release "$REPO_PIVNET_CLI" "linux"

    wget -qO "$OUTPUT"/pivnet "$DOWNLOAD_URL"
    chmod +x "$OUTPUT"/pivnet

}

install_om() {
    log 'Installing om'

    get_latest_release "$REPO_OM" "linux"

    wget -qO "$OUTPUT"/om "$DOWNLOAD_URL"
    chmod +x "$OUTPUT"/om
}

install_bbr() {
    log 'Installing bbr'

    TMP_DIR=$PWD/bbr-release
    mkdir -p $TMP_DIR


    get_latest_release "$REPO_BBR" "bbr"

    wget -qO "$OUTPUT"/bbr.tar "$DOWNLOAD_URL"
    tar -xvf "$OUTPUT"/bbr.tar -C $TMP_DIR

    mv $TMP_DIR/releases/bbr "$OUTPUT"/bbr

    rm -rf $TMP_DIR "$OUTPUT"/bbr.tar
}

install_bbl() {
    log 'Installing bbl'

    get_latest_release "$REPO_BBL" "linux"

    wget -qO "$OUTPUT"/bbl "$DOWNLOAD_URL"
    chmod +x "$OUTPUT"/bbl
}

install_uaac() {
    log 'Installing uaac cli'
    gem install cf-uaac >> $LOGFILE
}

install_git() {
    log 'Installing git'
    apt-get install git
}


###
# Main
##

while getopts 'vo:' param; do
    case $param in
        o ) log "Setting output to $OPTARG"
            OUTPUT="$OPTARG"
            ;;
        v ) LOGFILE=/dev/stdout
            ;;
        ? ) echo "Unkown option $OPTARG" 1>&2
            exit 3
            ;;
    esac
done

shift $(($OPTIND - 1))

#validate

if [ ! -d "$OUTPUT" ]; then
  mkdir -p $OUTPUT
fi

if [ ! -z "$1" ]; then
    function_exists install_$1 && eval install_$1 || echo "Unknown installation $1" 1>&2 && exit 4
else
    install_bosh
    install_cf
    install_credhub
    install_govc
    install_om
    install_uaac
    install_pivnet_cli
    install_git
    install_bbr
    install_bbl
fi

# install.sh