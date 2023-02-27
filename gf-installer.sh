#!/bin/bash

#####################
######настройки######
minioroot='root'
miniovol='/data/minio'
sleeptime=5
#####################


WORKDIR="`pwd`"
LOGFILE="${WORKDIR}/gf-installer.log"

function status {
    if [ "$1" == "OK" ]; then
        echo -e "\033[0;32m$1\033[0m"
    else
        echo -e "\033[0;31m$1\nЛог сохранён в ${LOGFILE}\033[0m"
        exit 1
    fi
}

function spinner {
    while :; do for s in / - \\ \|; do printf "\b$s"; sleep .1; done; done
}

function prepareOs {
    echo "`date` prepareOs():"
    dnf -y install curl vim tcpdump mc && return 0 || return 1
} &>>${LOGFILE}

function installPG {
    echo "`date` installPG():"
    DISTRO_MAJOR=$(grep '^VERSION_ID' /etc/os-release | awk -F'"' '{print $2}' | awk -F '.' '{print $1}')
    dnf -y module disable postgresql &&\
    dnf install -y "https://download.postgresql.org/pub/repos/yum/reporpms/EL-${DISTRO_MAJOR}-x86_64/pgdg-redhat-repo-latest.noarch.rpm" &&\
    dnf clean all &&\
    dnf -y install postgresql15-server &&\
    /usr/pgsql-15/bin/postgresql-15-setup initdb &&\
    systemctl enable --now postgresql-15 && sleep ${sleeptime}
    echo "`date` installPG() статус:"
    su - -c "psql -c 'SELECT version();'" postgres | grep 15 && return 0 || return 1
} &>>${LOGFILE}

function installK3s {
    echo "`date` installK3s():"
    curl -sfL https://get.k3s.io | sh - && sleep ${sleeptime}
    echo "`date` installK3s() статус:"
    kubectl get nodes | grep -i ready && return 0 || return 1
} &>>${LOGFILE}

function installS3 {
    echo "`date` installS3():"
    miniopass=$( < /dev/urandom tr -dc '@#%^&*;:<>.?_A-Za-z0-9' | head -c${1:-24} )

    echo -e "${minioroot}\n${miniopass}" > "${WORKDIR}/s3pass.txt" && chmod 600 "${WORKDIR}/s3pass.txt"
    dnf -y install https://dl.min.io/server/minio/release/linux-amd64/minio-20230131022419.0.0.x86_64.rpm \
    https://dl.min.io/client/mc/release/linux-amd64/mcli-20230128202938.0.0.x86_64.rpm &&\
    useradd -M -r -U minio-user &&\
    mkdir -p ${miniovol} && chown -R minio-user:minio-user ${miniovol} &&\
    { echo "MINIO_VOLUMES='${miniovol}'" > /etc/default/minio;\
    echo "MINIO_OPTS='--console-address :9001'" >> /etc/default/minio;\
    echo "MINIO_ROOT_USER=${minioroot}" >> /etc/default/minio;\
    echo "MINIO_ROOT_PASSWORD=${miniopass}" >> /etc/default/minio ; } &&\
    systemctl enable --now minio && sleep ${sleeptime} &&\
    mcli alias set gradefactor http://localhost:9000 "${minioroot}" "${miniopass}"
    echo "`date` installS3() статус:"
    [[ `mcli admin info gradefactor | grep -oP '\d+ drives? online' | grep -oP '^\d+'` -gt 0 ]] && return 0 || return 1
} &>>${LOGFILE}

#####################################################################################################################################################

echo -e '-----------------------------------------'
echo -e 'Подготовка инфраструктуры для GradeFactor\n-----------------------------------------'
[[ "`whoami`" == 'root' ]] || status 'Необходимо быть root'
ping -c3 ya.ru &>/dev/null || status 'Недоступен интернет'

while :
do
echo -ne "[ 1 ] k3s\n[ 2 ] PostgreSQL 15\n[ 3 ] S3 storage\n[ q ] Выход из установки\nВыберите продукт для установки: "
read CHOICE
    case $CHOICE in
    1)
        echo -n 'Подготовка OS...  '
	spinner &
	spinpid=$!
        prepareOs
	exitcode=$?
	kill -9 ${spinpid}
	echo -en "\033[1K\rПодготовка OS... "
	[[ ${exitcode} -eq 0 ]] && status 'OK' || status 'ОШИБКА'

        echo -n 'Установка k3s...  '
	spinner &
	spinpid=$!
        installK3s
	exitcode=$?
	kill -9 ${spinpid}
	echo -en "\033[1K\rУстановка k3s... "
	[[ ${exitcode} -eq 0 ]] && status 'OK' || status 'ОШИБКА'
        exit 0
        ;;

    2)
        echo -n 'Подготовка OS...  '
	spinner &
	spinpid=$!
        prepareOs
	exitcode=$?
	kill -9 ${spinpid}
	echo -en "\033[1K\rПодготовка OS... "
	[[ ${exitcode} -eq 0 ]] && status 'OK' || status 'ОШИБКА'

        echo -n 'Установка PostgreSQL 15...  '
	spinner &
	spinpid=$!
        installPG
	exitcode=$?
	kill -9 ${spinpid}
	echo -en "\033[1K\rУстановка PostgreSQL 15... "
	[[ ${exitcode} -eq 0 ]] && status 'OK' || status 'ОШИБКА'
        exit 0
        ;;

    3)
        echo -n 'Подготовка OS...  '
	spinner &
	spinpid=$!
        prepareOs
	exitcode=$?
	kill -9 ${spinpid}
	echo -en "\033[1K\rПодготовка OS... "
	[[ ${exitcode} -eq 0 ]] && status 'OK' || status 'ОШИБКА'

        echo -n 'Установка S3 storage...  '
	spinner &
	spinpid=$!
        installS3
	exitcode=$?
	kill -9 ${spinpid}
	echo -en "\033[1K\rУстановка S3 storage... "
	[[ ${exitcode} -eq 0 ]] && status 'OK' || status 'ОШИБКА'
        echo "Пароль сохранён в ${WORKDIR}/s3pass.txt"
        exit 0
        ;;

    Q|q)
        exit 0
        ;;

    *)
        echo -e '\nВыберите один из указанных пунктов'
        ;;
    esac
done
