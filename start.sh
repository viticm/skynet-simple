###
 # SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 # $Id start.sh
 # @link https://github.com/viticm/skynet-simple for the canonical source repository
 # @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 # @license
 # @user viticm( viticm.ti@gmail.com )
 # @date 2020/07/15 16:08
 # @uses Start skynet simple shell script.
###
#!/bin/sh

function die(){
  echo $1;exit -1;
}

export ROOT=$(cd `dirname $0`; pwd)
export OP_TYPE=0
while getopts "dki:h:t:p:" arg
do
  case $arg in
    i) export SVR_ID=$OPTARG;;
    d) export OP_TYPE=1;;
    k) export OP_TYPE=2;;
    h) export SETTING_HOST=$OPTARG;;
    t) export SVR_TYPE=$OPTARG;;
    p) export CFGPATH=$OPTARG;;
  esac
done

[ -z "$SVR_ID" ] && die "expected SVR_ID"
[ -z "$SETTING_HOST" ] && die "expected SETTING_HOST"
[ -z "$SVR_TYPE" ] && die "expected SVR_TYPE"

SVR_NAME="$SVR_TYPE"_"$SVR_ID"

export SETTING_HOST=$SETTING_HOST:-"https://cyd2184.oicp.vip/download/game/"

RUN_PATH=$ROOT"/bin"
export LOGPATH=$RUN_PATH"/log"
export PIDFILE=$RUN_PATH"/"$SVR_NAME".pid"
export DPORT_FILE=$RUN_PATH"/"$SVR_NAME".dport"

if [ $OP_TYPE -eq 2 ]; then
  #kill `cat $PIDFILE`
  echo "begin stop" | nc 127.0.0.1 `cat $DPORT_FILE` -v -il
  if [ 0 -eq $? ]; then
    while true; do
      if [ -f $PIDFILE ]; then
        ps -fe | grep `cat $PIDFILE` | grep -v grep
        [ 0 -ne $? ] && exit 0 || exit 1
      else
        exit 1
      fi
    done
  else
    if [ -f $PIDFILE ]; then
      kill -9 `cat $PIDFILE`
    fi
  fi
  exit 0
fi

# check run.
if [ -f $PIDFILE ]; then
  if kill -0 `cat $PIDFILE` 2 > /dev/null; then
    die "server: "$SVR_NAME" is running"
  fi
fi

#export SETTING_HOST="192.168.1.30:8081"
export SVR_TYPE=$SVR_TYPE
export DAEMON=""
export LOGGER=""
export JE_MALLOC_CONF="background_thread:true,
dirty_decay_ms:0,muzzy_decay_ms:0,narenas:8"

echo $tp$SVR_ID
day=`date "+%Y%m%d"`
echo "tail "$LOGPATH"/log/"$tp$SVR_ID""-$day"-msg.log"
[ $OP_TYPE -eq 1 ] && export LOGGER=$LOGPATH"/log/"$SVR_NAME
[ $OP_TYPE -eq 1 ] && export DAEMON=$PIDFILE

flagfile=$ROOT"/bin/"$SVR_NAME".bootflag"
echo ""> $flagfile
$ROOT/skynet/skynet $ROOT/bin/config.$SVR_TYPE

function start_status(){
  # Start max time.
  _maxtime=30
  _step=1
  i=0
  while true; do
    [ $i -ge $_maxtime ] && echo "DEBUGPORT FILE not exist!!!" && return 1
    [ ! -f $DEBUGPORT ] && sleep ${_step} && i=`expr $i + ${_step}` && continue
    status=`cat $flagfile`
    if [[ "${status}" =~ "success" ]];then
      echo "boot "$tp$SVR_ID" ...ok"
      return 0
    else
      echo "waiting for boot:"$SVR_NAME
      sleep $_step
      i=`expr $i + ${_step}`
    fi
    [ $i -ge $_maxtime ] && echo "boot timeout!!!" && return 1
  done
}
[2 -eq $OP_TYPE] && sleep 2 && start_status
