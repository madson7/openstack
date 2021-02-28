#!/usr/bin/env bash
set -o errexit -o nounset
# This script is the first to run and the only one to run as root.

# XXX The name activate_autostart.sh is hard-coded in ks.cfg and preseed.cfg.

readonly RCAUTOSTART=stackauto

# Remove any sysvinit files that called us (written by {ks,preseed}.cfg)
rm -f /etc/init.d/stack /etc/rc2.d/S40stack

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)
source "$TOP_DIR/config/paths"
# source_deploy doesn't work here
source "$CONFIG_DIR/deploy.stack"
source "$LIB_DIR/functions.guest.sh"

indicate_current_auto

# This guest script doesn't write to $HOME; the log file's extension is .auto
exec_logfile "$LOG_DIR" "auto"

# Clean up rc.local (used for activating autostart in systemd systems)
if grep activate_autostart.sh /etc/rc.local; then
    # systemd
    echo "Restoring /etc/rc.local."
    sed -i 's/# exit 0/exit 0/' /etc/rc.local
    # Leave our deactivated code so it can be found and checked
    sed -i '/activate_autostart.sh/ s/^/#/' /etc/rc.local
    STACK_AUTO=/root/$RCAUTOSTART
else
    # sysvinit
    STACK_AUTO=/etc/init.d/$RCAUTOSTART
fi

# Some guest additions leave a broken symlink /sbin/mount.vboxsf
as_root_fix_mount_vboxsf_link

if ! id -u "$VM_SHELL_USER" >/dev/null 2>&1; then
    echo "User $VM_SHELL_USER does not exist -> adding it."
    useradd stack -G vboxsf
    echo "$VM_SHELL_USER:$VM_SHELL_USER" | chpasswd
elif ! id -Gn "$VM_SHELL_USER" >/dev/null 2>&1 | grep -q vboxsf; then
    echo "User $VM_SHELL_USER is not in group vboxsf -> adding it."
    usermod -a -G vboxsf "$VM_SHELL_USER"
fi

echo "Adding sudo privileges for user VM_SHELL_USER."
as_root_inject_sudoer

if [ ! -f "$STACK_SCRIPTS_DIR/template-$RCAUTOSTART" ]; then
    echo "Template not found: $STACK_SCRIPTS_DIR/template-$RCAUTOSTART"
    exit 1
fi

# LOG_DIR and SHARE_DIR are based on the temporary mount point /media/sf_*
# which won't be there after reboot; use new paths for stackauto

NLOG_DIR="/$SHARE_NAME/$(basename "$LOG_DIR")"

echo "Creating $STACK_AUTO."
sed -e "
    s,%SHARE_NAME%,$SHARE_NAME,g;
    s,%VM_SHELL_USER%,$VM_SHELL_USER,g;
    s,%NLOG_DIR%,$NLOG_DIR,g;
    s,%RCAUTOSTART%,$RCAUTOSTART,g;
    " "$STACK_SCRIPTS_DIR/template-$RCAUTOSTART" > "$STACK_AUTO"

chmod 755 "$STACK_AUTO"

echo "Making devstack's OS detection work with nounset."
init_os_ident

if [ "$STACK_AUTO" = "/root/$RCAUTOSTART" ]; then
    echo "Creating systemd service $RCAUTOSTART.service."
    cat << SERVICE > /etc/systemd/system/$RCAUTOSTART.service
[Unit]
Description=OpenStack autostart
Requires=vboxadd-service.service

[Service]
Type=simple
ExecStart=$STACK_AUTO
TimeoutSec=0
# Consider service running even after all our processes have exited
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl enable "$RCAUTOSTART.service"
    systemctl start "$RCAUTOSTART.service"
else
    ln -sv "../init.d/$RCAUTOSTART" "/etc/rc2.d/S99$RCAUTOSTART"
fi
