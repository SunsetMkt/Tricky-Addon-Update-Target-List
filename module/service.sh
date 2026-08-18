MODPATH=${0%/*}
PATH=$PATH:/data/adb/ap/bin:/data/adb/ksu/bin:/data/adb/magisk
HIDE_DIR="/data/adb/modules/.TA_utl"
TS="/data/adb/modules/tricky_store"
OMK="/data/adb/modules/oh_my_keymint"
TEES="/data/adb/modules/teesim"
TSPA="/data/adb/modules/tsupport-advance"

if [ -d "$TS" ] && [ ! -e "$TS/disable" ]; then
    RUNTIME="$TS"
elif [ -d "$OMK" ] && [ ! -e "$OMK/disable" ]; then
    RUNTIME="$OMK"
elif [ -d "$TEES" ] && [ ! -e "$TEES/disable" ]; then
    RUNTIME="$TEES"
fi

. "$MODPATH/common/manager.sh"

# Handle sensitive prop in background
sh "$MODPATH/prop.sh" &

# Disable TSupport-A auto update target to prevent overwrite
if [ -d "$TSPA" ]; then
    touch "/storage/emulated/0/stop-tspa-auto-target"
elif [ ! -d "$TSPA" ] && [ -f "/storage/emulated/0/stop-tspa-auto-target" ]; then
    rm -f "/storage/emulated/0/stop-tspa-auto-target"
fi

# Magisk manager show module even without module.prop
# Move to a hidden folder to hide from Magisk manager
hide_module() {
    # Don't hide module in TEESimulator
    [ "$RUNTIME" = "$TEES" ] && return

    if [ "$MODPATH" != "$HIDE_DIR" ]; then
        rm -rf "$HIDE_DIR"
        mkdir -p "$HIDE_DIR"
        busybox chcon --reference="$MODPATH" "$HIDE_DIR"
        cp -af "$MODPATH/." "$HIDE_DIR/"
    fi
    MODPATH="$HIDE_DIR"
}

# Magisk operation
if [ "$MANAGER" = "MAGISK" ]; then
    # Hide module from Magisk manager
    hide_module
    [ -f "$MODPATH/action.sh.old" ] && mv -f "$MODPATH/action.sh.old" "$MODPATH/action.sh"
else
    [ -f "$MODPATH/action.sh" ] && mv -f "$MODPATH/action.sh" "$MODPATH/action.sh.old"
    [ -d "$HIDE_DIR" ] && rm -rf "$HIDE_DIR"
fi

# Symlink tricky store
if [ -f "$MODPATH/action.sh" ] && [ ! -e "$RUNTIME/action.sh" ]; then
    ln -s "$MODPATH/action.sh" "$RUNTIME/action.sh"
fi
if [ ! -e "$RUNTIME/webroot" ]; then
    ln -s "$MODPATH/webui" "$RUNTIME/webroot"
elif [ ! -e "$MODPATH/webroot" ]; then
    ln -s "$MODPATH/webui" "$MODPATH/webroot"
fi

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

sh "$MODPATH/common/get_extra.sh" --xposed >/dev/null 2>&1

# Clean up
if [ ! "$RUNTIME" = "$TEES" ]; then
    # Hide module from APatch, KernelSU, KSUWebUIStandalone, MMRL
    rm -f "$MODPATH/module.prop"

    # Remove old TA_utl folder for Magisk
    [ ! -f "$MODPATH/action.sh" ] || rm -rf "/data/adb/modules/TA_utl";
fi
