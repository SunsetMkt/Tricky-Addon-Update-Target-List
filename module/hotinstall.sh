#!/bin/sh

MODPATH=${0%/*}
TS="/data/adb/modules/tricky_store"
OMK="/data/adb/modules/oh_my_keymint"
TEES="/data/adb/modules/teesim"

if [ -d "$TS" ] && [ ! -e "$TS/disable" ]; then
    RUNTIME="$TS"
elif [ -d "$OMK" ] && [ ! -e "$OMK/disable" ]; then
    RUNTIME="$OMK"
elif [ -d "$TEES" ] && [ ! -e "$TEES/disable" ]; then
    RUNTIME="$TEES"
fi

sh "$MODPATH/post-fs-data.sh" > /dev/null 2>&1
sh "$MODPATH/service.sh" > /dev/null 2>&1

# Hide module from APatch, KernelSU, KSUWebUIStandalone, MMRL
if [ "$RUNTIME" != "$TEES" ]; then  # Don't hide module in TEESimulator
    nohup sh -c "
    count=0
    while kill -0 $PPID 2>/dev/null; do
        [ \$count -ge 5 ] && break
        sleep 1
        count=\$((count + 1))
    done
    rm -f '$MODPATH/module.prop'
    " >/dev/null 2>&1 &
fi
