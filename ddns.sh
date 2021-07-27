#!/bin/bash

# debug=1

URL="https://dyn.dns.he.net/nic/update"
historyFile=".iphistory_he"

fontRed='\033[31m'
fontGreen='\033[32m'
fontBlue='\033[36m'
fontNormal='\033[0m'

function echoRed() {
    echo -e "${fontRed}${*}${fontNormal}"
}
function echoBlue() {
    echo -e "${fontBlue}${*}${fontNormal}"
}
function echoGreen() {
    echo -e "${fontGreen}${*}${fontNormal}"
}

function debug() {
    if [ "$debug" == "1" ]; then
        echo "$*" 
    fi
}

function UpdateHost() { # 更新宿主机的地址 输入 recordName device hostname password
    local recordName="$1"
    local device="$2"
    local hostname="$3"
    local password="$4"
    echoBlue "更新${recordName}" 1>&2
    local ipv4History ipv6History
    ipv4History=$(echo "$history" | grep "^${recordName} " | cut -d " " -f 2)
    ipv6History=$(echo "$history" | grep "^${recordName} " | cut -d " " -f 3)
    if [ -n "$device" ]; then
        device="dev $device"
    fi
    local ipv4Address ipv6Address
    ipv4Address=$(ip -4 addr list scope global $device | sed -n "s/.*inet \([0-9.]\+\).*/\1/p" | head -n 1) #宿主机ipv4
    ipv6Address=$(ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1) #宿主机ipv6
    # 更新ipv4
    if [[ -n "$ipv4Address" && "$ipv4History" != "$ipv4Address" ]]; then
        echoBlue "ipv4变更" 1>&2
        debug "记录: ${ipv4History}" 1>&2
        debug "实际: ${ipv4Address}" 1>&2
        local info
        info=$(curl "${URL}" -d "hostname=${hostname}" -d "password=${password}" -d "myip=${ipv4Address}")
        debug "$info" 1>&2
        info=$(echo ${info} | cut -d ' ' -f 1)
        if [[ "$info" == "good" || "$info" == "nochg" ]]; then
            echoGreen "更新成功" 1>&2
            ipv4History=${ipv4Address}
        else
            echoRed "更新失败：${info}" 1>&2
        fi
    else
        echoBlue "ipv4未变更" 1>&2
    fi

    # 更新ipv6
    if [[ -n "$ipv6Address" && "$ipv6History" != "$ipv6Address" ]]; then
        echoBlue "ipv6变更" 1>&2
        debug "记录: ${ipv6History}" 1>&2
        debug "实际: ${ipv6Address}" 1>&2
        info=$(curl "${URL}" -d "hostname=${hostname}" -d "password=${password}" -d "myip=${ipv6Address}")
        debug "$info" 1>&2
        info=$(echo ${info} | cut -d ' ' -f 1)
        if [[ "$info" == "good" || "$info" == "nochg" ]]; then
            echoGreen "更新成功" 1>&2
            ipv6History=${ipv6Address}
        else
            echoRed "更新失败：${info}" 1>&2
        fi
    else
        echoBlue "ipv6未变更" 1>&2
    fi
    echo "${recordName} ${ipv4History} ${ipv6History}"
}

function UpdateHostIPv4() { # 更新宿主机的地址 ipv4 Only 输入 recordName device hostname password
    local recordName="$1"
    local device="$2"
    local hostname="$3"
    local password="$4"
    echoBlue "更新${recordName}" 1>&2
    local ipv4History ipv6History
    ipv4History=$(echo "$history" | grep "^${recordName} " | cut -d " " -f 2)

    if [ -n "$device" ]; then
        device="dev $device"
    fi
    local ipv4Address ipv6Address
    ipv4Address=$(ip -4 addr list scope global $device | sed -n "s/.*inet \([0-9.]\+\).*/\1/p" | head -n 1) #宿主机ipv4

    # 更新ipv4
    if [[ -n "$ipv4Address" && "$ipv4History" != "$ipv4Address" ]]; then
        echoBlue "ipv4变更" 1>&2
        debug "记录: ${ipv4History}" 1>&2
        debug "实际: ${ipv4Address}" 1>&2
        local info
        info=$(curl "${URL}" -d "hostname=${hostname}" -d "password=${password}" -d "myip=${ipv4Address}")
        debug "$info" 1>&2
        info=$(echo ${info} | cut -d ' ' -f 1)
        if [[ "$info" == "good" || "$info" == "nochg" ]]; then
            echoGreen "更新成功" 1>&2
            ipv4History=${ipv4Address}
        else
            echoRed "更新失败：${info}" 1>&2
        fi
    else
        echoBlue "ipv4未变更" 1>&2
    fi

    echo "${recordName} ${ipv4History} ${ipv6History}"
}

function UpdateHostIPv6() { # 更新宿主机的地址 ipv6 Only 输入 recordName device hostname password
    local recordName="$1"
    local device="$2"
    local hostname="$3"
    local password="$4"
    echoBlue "更新${recordName}" 1>&2
    local ipv4History ipv6History

    ipv6History=$(echo "$history" | grep "^${recordName} " | cut -d " " -f 3)
    if [ -n "$device" ]; then
        device="dev $device"
    fi
    local ipv4Address ipv6Address

    ipv6Address=$(ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1) #宿主机ipv6
    # 更新ipv6
    if [[ -n "$ipv6Address" && "$ipv6History" != "$ipv6Address" ]]; then
        echoBlue "ipv6变更" 1>&2
        debug "记录: ${ipv6History}" 1>&2
        debug "实际: ${ipv6Address}" 1>&2
        info=$(curl "${URL}" -d "hostname=${hostname}" -d "password=${password}" -d "myip=${ipv6Address}")
        debug "$info" 1>&2
        info=$(echo ${info} | cut -d ' ' -f 1)
        if [[ "$info" == "good" || "$info" == "nochg" ]]; then
            echoGreen "更新成功" 1>&2
            ipv6History=${ipv6Address}
        else
            echoRed "更新失败：${info}" 1>&2
        fi
    else
        echoBlue "ipv6未变更" 1>&2
    fi
    echo "${recordName} ${ipv4History} ${ipv6History}"
}

function UpdateContainer() { # 更新容器的地址 输入 recordName containerName device hostname password
    local recordName="$1"
    local containerName="$2"
    local device="$3"
    local hostname="$4"
    local password="$5"
    echoBlue "更新${recordName}" 1>&2
    local ipv4History ipv6History
    ipv4History=$(echo "$history" | grep "^${recordName} " | cut -d " " -f 2)
    ipv6History=$(echo "$history" | grep "^${recordName} " | cut -d " " -f 3)
    if [ -n "$device" ]; then
        device="dev $device"
    fi
    local ipv4Address ipv6Address
    ipv4Address=$(lxc exec local:${containerName} -- ip -4 addr list scope global $device | sed -n "s/.*inet \([0-9.]\+\).*/\1/p" | head -n 1) #容器ipv4
    ipv6Address=$(lxc exec local:${containerName} -- ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1) #容器ipv6
    # 更新ipv4
    if [[ -n "$ipv4Address" && "$ipv4History" != "$ipv4Address" ]]; then
        echoBlue "ipv4变更" 1>&2
        debug "记录: ${ipv4History}" 1>&2
        debug "实际: ${ipv4Address}" 1>&2
        local info
        info=$(curl "${URL}" -d "hostname=${hostname}" -d "password=${password}" -d "myip=${ipv4Address}")
        debug "$info" 1>&2
        info=$(echo ${info} | cut -d ' ' -f 1)
        if [[ "$info" == "good" || "$info" == "nochg" ]]; then
            echoGreen "更新成功" 1>&2
            ipv4History=${ipv4Address}
        else
            echoRed "更新失败：${info}" 1>&2
        fi
    else
        echoBlue "ipv4未变更" 1>&2
    fi

    # 更新ipv6
    if [[ -n "$ipv6Address" && "$ipv6History" != "$ipv6Address" ]]; then
        echoBlue "ipv6变更" 1>&2
        debug "记录: ${ipv6History}" 1>&2
        debug "实际: ${ipv6Address}" 1>&2
        info=$(curl "${URL}" -d "hostname=${hostname}" -d "password=${password}" -d "myip=${ipv6Address}")
        debug "$info" 1>&2
        info=$(echo ${info} | cut -d ' ' -f 1)
        if [[ "$info" == "good" || "$info" == "nochg" ]]; then
            echoGreen "更新成功" 1>&2
            ipv6History=${ipv6Address}
        else
            echoRed "更新失败：${info}" 1>&2
        fi
    else
        echoBlue "ipv6未变更" 1>&2
    fi
    echo "${recordName} ${ipv4History} ${ipv6History}"
}

function UpdateContainerIPv4() { # 更新容器的地址 ipv4 Only 输入 recordName containerName device hostname password
    local recordName="$1"
    local containerName="$2"
    local device="$3"
    local hostname="$4"
    local password="$5"
    echoBlue "更新${recordName}" 1>&2
    local ipv4History ipv6History
    ipv4History=$(echo "$history" | grep "^${recordName} " | cut -d " " -f 2)

    if [ -n "$device" ]; then
        device="dev $device"
    fi
    local ipv4Address ipv6Address
    ipv4Address=$(lxc exec local:${containerName} -- ip -4 addr list scope global $device | sed -n "s/.*inet \([0-9.]\+\).*/\1/p" | head -n 1) #容器ipv4

    # 更新ipv4
    if [[ -n "$ipv4Address" && "$ipv4History" != "$ipv4Address" ]]; then
        echoBlue "ipv4变更" 1>&2
        debug "记录: ${ipv4History}" 1>&2
        debug "实际: ${ipv4Address}" 1>&2
        local info
        info=$(curl "${URL}" -d "hostname=${hostname}" -d "password=${password}" -d "myip=${ipv4Address}")
        debug "$info" 1>&2
        info=$(echo ${info} | cut -d ' ' -f 1)
        if [[ "$info" == "good" || "$info" == "nochg" ]]; then
            echoGreen "更新成功" 1>&2
            ipv4History=${ipv4Address}
        else
            echoRed "更新失败：${info}" 1>&2
        fi
    else
        echoBlue "ipv4未变更" 1>&2
    fi

    echo "${recordName} ${ipv4History} ${ipv6History}"
}

function UpdateContainerIPv6() { # 更新容器的地址 ipv6 Only 输入 recordName containerName device hostname password
    local recordName="$1"
    local containerName="$2"
    local device="$3"
    local hostname="$4"
    local password="$5"
    echoBlue "更新${recordName}" 1>&2
    local ipv4History ipv6History

    ipv6History=$(echo "$history" | grep "^${recordName} " | cut -d " " -f 3)
    if [ -n "$device" ]; then
        device="dev $device"
    fi
    local ipv4Address ipv6Address

    ipv6Address=$(lxc exec local:${containerName} -- ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1) #容器ipv6

    # 更新ipv6
    if [[ -n "$ipv6Address" && "$ipv6History" != "$ipv6Address" ]]; then
        echoBlue "ipv6变更" 1>&2
        debug "记录: ${ipv6History}" 1>&2
        debug "实际: ${ipv6Address}" 1>&2
        info=$(curl "${URL}" -d "hostname=${hostname}" -d "password=${password}" -d "myip=${ipv6Address}")
        debug "$info" 1>&2
        info=$(echo ${info} | cut -d ' ' -f 1)
        if [[ "$info" == "good" || "$info" == "nochg" ]]; then
            echoGreen "更新成功" 1>&2
            ipv6History=${ipv6Address}
        else
            echoRed "更新失败：${info}" 1>&2
        fi
    else
        echoBlue "ipv6未变更" 1>&2
    fi
    echo "${recordName} ${ipv4History} ${ipv6History}"
}

if [ -r "$historyFile" ]; then
    history=$(cat "$historyFile")
fi
debug "History:" 1>&2
debug "${history}" 1>&2

{
    UpdateHost HOST eth1 example.com 'key'
    UpdateHostIPv4 HOSTv4 eth0 example.org 'key'
    UpdateHostIPv6 HOSTv6 eth0 example.org 'key'
    UpdateContainer Container ubuntu eth0 example.example.com 'key'
} > "$historyFile"

debug "Update:" 1>&2
debug "$(cat "$historyFile")" 1>&2
