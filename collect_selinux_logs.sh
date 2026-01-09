#!/bin/bash
# Script to collect SELinux logs and denials

echo "=== SELinux Log Collection Script ==="
echo ""

# Check SELinux status
echo "1. SELinux Status:"
getenforce 2>/dev/null || echo "  getenforce not available"
echo ""

# Collect recent AVC denials from audit log
echo "2. Recent AVC Denials from audit.log:"
if [ -f /var/log/audit/audit.log ]; then
    echo "  Using ausearch:"
    ausearch -m avc -ts recent 2>/dev/null | tail -50 || echo "  ausearch failed or no recent denials"
    echo ""
    echo "  Using grep on audit.log (last 50 lines with avc):"
    grep -i "avc" /var/log/audit/audit.log 2>/dev/null | tail -50 || echo "  No AVC denials found"
else
    echo "  /var/log/audit/audit.log not found"
fi
echo ""

# Collect from journalctl (systemd systems)
echo "3. Recent SELinux denials from journalctl:"
journalctl -p err --since "1 hour ago" 2>/dev/null | grep -i "avc\|selinux\|denied" | tail -50 || echo "  journalctl not available or no denials"
echo ""

# Collect from messages log
echo "4. Recent SELinux messages from /var/log/messages:"
if [ -f /var/log/messages ]; then
    grep -i "avc\|selinux\|denied" /var/log/messages 2>/dev/null | tail -50 || echo "  No SELinux messages found"
else
    echo "  /var/log/messages not found"
fi
echo ""

# Use sealert if available
echo "5. Using sealert to analyze denials:"
if command -v sealert >/dev/null 2>&1; then
    sealert -a /var/log/audit/audit.log 2>/dev/null | tail -100 || echo "  sealert analysis failed"
else
    echo "  sealert not available"
fi
echo ""

# Generate AVC denial report
echo "6. AVC Denial Summary Report:"
if command -v aureport >/dev/null 2>&1; then
    echo "  Recent AVC denials by type:"
    aureport -a --summary 2>/dev/null | head -20 || echo "  aureport failed"
else
    echo "  aureport not available"
fi
echo ""

# Check for SELinux errors in boot log
echo "7. Checking boot.log for SELinux errors:"
if [ -f boot.log ]; then
    grep -i "avc\|selinux\|denied\|permission denied" boot.log | tail -50 || echo "  No SELinux errors in boot.log"
else
    echo "  boot.log not found in current directory"
fi
echo ""

echo "=== Collection Complete ==="
echo ""
echo "To collect logs in real-time, run:"
echo "  tail -f /var/log/audit/audit.log | grep avc"
echo ""
echo "To set SELinux to permissive mode (to see all denials):"
echo "  sudo setenforce 0"
echo ""
echo "To view all recent AVC denials:"
echo "  ausearch -m avc -ts recent"
echo ""
