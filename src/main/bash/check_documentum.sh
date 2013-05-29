#!/bin/bash

#Declarations
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

# environment
JAVA_HOME=/usr/java/latest

PROG=`/bin/basename $0`
GREP=/bin/grep
ECHO=/bin/echo

# function for boolean results
bool_result() {
if [ $RESULT == 0 ] ; then
	$ECHO "OK!"
	exit $OK
elif [ ${RESULT} >= 1 ] ; then
	$ECHO "WARNING!"
	exit $WARNING
fi
}

# function for checking Indexagent results
index_agent_result() {
res=`${GREP} -i 'running' ${RESULT}`
count=`${WC} ${res}`
}	

# print usage function
print_usage() {
    echo "Usage: $PROG -u <username> -p <password> -d <docbase_name> -w <sec> -c <sec> -[SiWwFC] -q <fulltext index user>"
}

if [ $# -lt 4 ]; then
    print_usage
    exit $UNKNOWN
fi

# make sure script is running as documentum owner user
if [ `whoami` = root ]; then
   echo "UNKNOWN: Please make sure script is running as documentum owner user"
    exit $UNKNOWN
fi

while test $# -gt 0; do
case "$1" in
        --help)
            print_help
            exit $OK
            ;;
        -h)
            print_help
            exit $OK
            ;;
        -u)
            USERNAME=$2;
            shift 2;
            ;;
        -p)
            PASSWORD=$2;
            shift 2;
            ;;
        -d)
            DOCBASE=$2;
            shift 2;
            ;;
        -w)
            WARN=$2;
            shift 2;
            ;;
        -c)
            CRIT=$2;
            shift 2;
            ;;
	-q)
	    COMMAND="-q ${2}";
	    shift 2;
	    ;;
	-S)
	    COMMAND="-S";
	    shift 1;
	    ;;
	-W)
	    COMMAND="-W";
	    shift 1;
	    ;;
	-w)
	    COMMAND="-w";
	    shift 1;
	    ;;
	-i)
	    COMMAND="-i";
	    shift 2;
	    ;;
	-F)
	    COMMAND="-F";
	    shift 1;
	    ;;
	-C)
	    COMMAND="-C";
	    shift 1;
	    ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit $UNKNOWN
            ;;
esac
done

# command list
JAVA_MEM="-Xms128m -Xmx128m -XX:MaxPermSize=64m"
CLASSPATH="classes/main:.:./libs/*"
CLASS="ru.jilime.documentum.Monitor"
CMD="${JAVA_HOME}/bin/java ${JAVA_MEM} -cp "${CLASSPATH}" ${CLASS} -u ${USERNAME} -p ${PASSWORD} -d ${DOCBASE} ${COMMAND}"

# all check results
RESULT="`${CMD}`"

# check is there boolean function?
if [ ${COMMAND} == "-C" ] || [ ${COMMAND} == "-F" ] && [ $? == 0 ] ; then
	bool_result
fi

# check is there result from IndexAgent
if [ ${COMMAND} == "-i" ] && [ $? == 0 ] ; then
	index_agent_result
fi

if [ $? == 0 ] ; then
    if [ $RESULT -lt $WARN ] ; then
       $ECHO "OK!"
       exit $OK
    elif [ $RESULT -ge $WARN] ; then
	    if [ $RESULT -lt $CRIT]; then
		    $ECHO "WARNING!"
		    exit $WARNING
	    fi
	$ECHO "CRITICAL"
	exit $CRITICAL
    fi
fi

$ECHO "ERROR while retrieving information from Documentum!"
$ECHO $!
exit $CRITICAL
