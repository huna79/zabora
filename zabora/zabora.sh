#!/usr/bin/env bash
PATH=/usr/local/bin:${PATH}

#################################################################################

#################################################################################
#
#  Variable Definition
# ---------------------
#
APP_NAME=$(basename $0)
APP_DIR=$(dirname $0)
APP_VER="1.5.3.7"
APP_WEB="https://github.com/huna79/zabora"
#
#################################################################################

#################################################################################
#
#  Load Oracle Environment
# -------------------------
#
[ -x ${APP_DIR}/${APP_NAME%.*}.conf ] || . ${APP_DIR}/${APP_NAME%.*}.conf
#
#################################################################################

#################################################################################
#
#  Function Definition
# ---------------------
#
usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -h            Displays this help message."
    echo "  -a            Query arguments."
    echo "  -s ARG(str)   Query to Oracle."
    echo "  -o ARG(str)   Set SID to make the query."
    echo "  -j            Jsonify output."
    echo "  -v            Show the script version."
    echo ""
    exit 1
}

version() {
    echo "${APP_NAME%.*} ${APP_VER}"
    exit 1
}

load_oracle() {
    if [[ -f ${APP_DIR}/zabora.oraenv ]]; then
       . ${APP_DIR}/zabora.oraenv
    else
       ORAENV_ASK=NO
       . /usr/local/bin/oraenv > /dev/null
    fi
}

databases() {
    ps -eo command | grep -v sed | sed -n 's/ora_pmon_\(.*\)/\1/p'
}

zabbix_not_support() {
    echo "ZBX_NOTSUPPORTED"
    exit 1
}
#
#################################################################################

#################################################################################
while getopts "s::a:o:hvj:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	s)
	    SQL="${APP_DIR}/sql/${OPTARG}"
	    ;;
	o)
	    ORACLE_SID=${OPTARG}
	    DISCOVER=0
	    ;;
	j)
	    JSON=1
	    JSON_ATTR=${OPTARG}
	    ;;
	a)
	    SQL_ARGS=${OPTARG}
	    ;;
	v)
	    version
	    ;;
	\?)
	    exit 1
	    ;;
    esac
done

if [[ ${SQL} =~ db_list$ ]]; then
    values=($(databases))

    if [ -z "${values}" ]; then
        zabbix_not_support
    fi

    if [[ ${JSON} -eq 1 ]]; then
        echo '{'
        echo '   "data":['

        for ((i=0; i<${#values[*]}; i++)); do
            output='{ "'{#${JSON_ATTR}}'":"'${values[${i}]}'" }'

            if ((${i} != ${#values[*]}-1)); then
                output+=,
            fi

            echo "      ${output}"
        done

        echo '   ]'
        echo '}'
    else
        for value in ${values[*]}; do
            echo ${value}
        done
    fi
elif [[ -f "${SQL%.sql}.sql" ]]; then
    if [[ ${DISCOVER:-1} -eq 1 ]]; then
        databases=$(databases)

        if [ -z "${databases}" ]; then
            zabbix_not_support
        fi
    else
        databases=${ORACLE_SID}
    fi

    i=0
    for database in ${databases}; do
        ORACLE_SID=${database}
        load_oracle
        rval=$(sqlplus -S -L ${ORACLE_USER}/${ORACLE_PASS} @${SQL} "${SQL_ARGS}")

        if [ ${?} -ne 0 ]; then
            zabbix_not_support
        fi

        if [ -n "${rval}" ]; then
            dbnames[${i}]=${database}
            dbvalues[${i}]=${rval}
            ((i++))
        fi
    done

    if [[ ${JSON} -eq 1 ]]; then
        echo '{'
        echo '   "data":['

        for ((i=0; i<${#dbnames[*]}; i++)); do
            values=(${dbvalues[${i}]})

            for ((j=0; j<${#values[*]}; j++)); do
                echo '      { "'{#ORACLE_SID}'":"'${dbnames[${i}]}'",'
                output='"'{#${JSON_ATTR}}'":"'${values[${j}]}'" }'

                if ((${i} != ${#dbnames[*]}-1 || ${j} != ${#values[*]}-1)); then
                    output+=,
                fi

                echo "        ${output}"
            done
        done

        echo '   ]'
        echo '}'
    else
        for dbvalue in "${dbvalues[@]}"; do
            echo $dbvalue
        done
    fi
else
    zabbix_not_support
fi
