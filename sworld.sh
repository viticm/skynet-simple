###
 # SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 # $Id sworld.sh
 # @link https://github.com/viticm/skynet-simple for the canonical source repository
 # @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 # @license
 # @user viticm( viticm.ti@gmail.com )
 # @date 2020/07/15 19:31
 # @uses Start the world server shell.
###
#!/bin/sh

HOST="https://cyd2184.oicp.vip/download/game/skynet-simple/"

. ./start.sh -t world -h $HOST $@
