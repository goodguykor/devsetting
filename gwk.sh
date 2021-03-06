#!/bin/bash
#
#    NAVER gateway utility
#
#   ================================================================
#    Original Copyright information
#
#    @author : (origin) yunsang.choi(oddpoet@gmail.com)
#    @author : (forked) jinkwon(master@bdyne.net)
#    @author : (forked) dongwon(dkim010@gmail.com)
#    @src : (origin) https://gist.github.com/gists/3115022
#    @src : (forked) https://github.com/Jinkwon/naver-gw-kit/
#   -------
#    v1.3.6 (dkim010@gmail.com)
#       - add feature : highlight specific hosts
#       - add feature : change to custom user
#    v1.3.5 (dkim010@gmail.com)
#       - add feature : ssh with authorized key 
#    v1.3.4
#       - minor change (display text) 
#    v1.3.3 
#       - allow '-' character in hostname
#    v1.3.2
#       - add feature : manage host description.
#    v1.3.1
#       - rearrange key 
#    v1.3.0
#       - support interactive kinit
#    v1.2.2
#       - display message when rlogin 
#    v1.2.1
#       - fix tab auto-completion
#    v1.2.0
#       - support bash key map
#       - improve tab auto-completion
#       - thanx to @worwornf for feedback
#   ================================================================
#
#    Copyright (C) 2017 Gwangmin Lee
#    
#    Author: Gwangmin Lee <gwangmin0123@gmail.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

 
#========================================
# Constants for configuration
#========================================
HOST_LIST_FILE=~/.known_hosts
HOST_DISPLAY_COUNT=25
USER_LIST_FOR_RLOGIN1=(irteam irteamsu )
USER_LIST_FOR_RLOGIN2=(data )
USER_LIST_ITER=1
USER_LIST_FOR_RLOGIN=(${USER_LIST_FOR_RLOGIN1[@]})
PROTOCOL_LIST=(rlogin ssh )
 
VERSION="1.3.6"
#========================================
# kinit
#========================================
# run direct
function kerberos_expired {
    IFS=' ' read -ra TOKENS <<< "`klist | tail -1`"
    KER_EXPIRED="${TOKENS[2]} ${TOKENS[3]}"
    CURRENT=`date +"%m/%d/%y %H:%M:%S"`
    if [[ $CURRENT > $KER_EXPIRED ]]; then
        kinit -f
        kerberos_expired
    fi
}

#kinit -f
kerberos_expired

#========================================
# Read key input
#   see : http://www.linuxquestions.org/questions/programming-9/bash-case-with-arrow-keys-and-del-backspace-etc-523441/
#========================================
SpecialKeyCodes="
0027 0091 0051 0126 0;delete
0027 0091 0065 0;up
0027 0091 0066 0;down
0027 0091 0067 0;right
0027 0091 0068 0;left
0027 0091 0090 0;shift-tab
"
 
ControlCharacters=(
    [0x00]="enter"          # "Null character"
    [0x09]="tab"
    [0x7F]="backspace"
    [0x08]="ctrl-h"
    [0x15]="ctrl-u"
    [0x01]="ctrl-a" 
    [0x05]="ctrl-e"
    [0x02]="ctrl-b"
    [0x06]="ctrl-f"
    [0x0b]="ctrl-k"
    [0x04]="ctrl-d"
    [0x17]="ctrl-w"
    [0x0e]="ctrl-n"
    [0x12]="ctrl-r"
)

function read1 {
    IFS='' read  -sn1 "${@}" scancode
}
function read2 {
    # Captues Ctrl-C 
    local -i ECode=0
    stty -echo raw
    scancode=$(dd bs=1 count=1 2>/dev/null || true )
    stty echo -raw
}
function read_key {
    local scancode 
    local scancode_f
    local d
    if read1 ${1:-}; then
        d=$(printf '%04d' "'${scancode}")
        case "${scancode}" in
            [^[:cntrl:]])
                echo "${scancode}"
                ;;
            $'\e')
                local -i icnt=1
                local oscancode Match=
                scancode_f="${d}"
                while read1 -t1 && [ ${icnt} -lt 9 ]; do
                    let icnt+=1
                    scancode_f="${scancode_f} $(printf '%04d' "'${scancode}")"
                    if  [ ${icnt} -eq 2 ] ; then
                        case "${scancode}" in
                            [[O]) continue;;
                            [^[:cntrl:]]) Match="alt-${scancode}"; break ;;
                        esac
                    fi
                    Match="$(echo "${SpecialKeyCodes}" | grep "^${scancode_f} 0;")"
                    if [ -n "${Match:-}" ]; then
                        Match="${Match#*;}"
                        Match="${Match%;*}"
                        break
                    fi
                    oscancode="${scancode}"
                done
                if [ -z "${Match}" ]; then
                    case "${scancode_f}" in
                        '0027') Match="escape" ;;
                        '0027 0079') Match="alt-O" ;;
                        '0027 0091') Match="alt-[" ;;
                    esac
                fi
                if [ -n "${Match}" ]; then
                    echo "${Match}"
                else
                    # print any unrecognised codes
                    echo "${scancode_f} 0;"
                fi
                ;;
            *)
                d=$(printf '%d' "'${scancode}")
                if [ -n "${ControlCharacters[${d}]:-}" ]; then
                    echo "${ControlCharacters[${d}]}"
                else
                    # print any unrecognised control characters
                    printf 'Unknown %02x\n' "'${scancode}"
                fi
                ;;
        esac
    fi
}
 
 
#========================================
# Control screen
#========================================
black="\x1b[30m"
red="\x1b[31m"
green="\x1b[32m"
yellow="\x1b[33m"
blue="\x1b[34m"
magenta="\x1b[35m"
cyan="\x1b[36m"
white="\x1b[37m"
reset="\x1b[39m"
 
bg_black="\x1b[40m"
bg_red="\x1b[41m"
bg_green="\x1b[42m"
bg_yellow="\x1b[43m"
bg_blue="\x1b[44m"
bg_magenta="\x1b[45m"
bg_cyan="\x1b[46m"
bg_white="\x1b[47m"
bg_reset="\x1b[49m"
 
bold="\x1b[1m"
bold_off="\x1b[22m"
underline="\x1b[4m"
underline_off="\x1b[24m"
 
save_cursor() {
    tput sc
}
restore_cursor() {
    tput rc
}
move_cursor() {
    tput cup $1 $2
}
 
#========================================
# Control user list
#========================================
# var: user list
user_list=(${USER_LIST_FOR_RLOGIN[@]})
# var: selected user
user=${user_list[0]}
# func: change user
next_user() {
    local index=0
    local cnt=${#user_list[@]}
    while true;do
        if [ "$user" == "${user_list[index]}" ]; then
            user=${user_list[(index+1) % cnt]}
            return
        fi
        let "index=index+1 % cnt"
    done
}
change_user_group() {
    if [ $USER_LIST_ITER -eq 1 ]; then
        user_list=(${USER_LIST_FOR_RLOGIN2[@]})
        USER_LIST_ITER=2
    else
        user_list=(${USER_LIST_FOR_RLOGIN1[@]})
        USER_LIST_ITER=1
    fi
    user=${user_list[0]}
}
#========================================
# Control protocol list
#========================================
# var: protocol list
protocol_list=(${PROTOCOL_LIST[@]})
# var: selected protocol
protocol=${protocol_list[0]}
# func: change protocol
next_protocol() {
    local index=0
    local cnt=${#protocol_list[@]}
    while true;do
        if [ "$protocol" == "${protocol_list[index]}" ]; then
            protocol=${protocol_list[(index+1) % cnt]}
            return
        fi
        let "index=index+1 % cnt"
    done
}
 
#========================================
# Control host list
#========================================
host_list=()
host_descs=()
hostname_filter=
filtered_host_list=
selected_host= 
cursor_offset=0
init_host_list() {
    if [ ! -f $HOST_LIST_FILE ];then
        touch $HOST_LIST_FILE
    fi
    while read line;do
        local len=${#host_list[@]}
        echo $line != "$*"
        if [ -n "$line" ] && [[ $line != '#'* ]];then
            host_list[$len]=`echo "$line" | sed -r 's/[ \t].+//'`
        fi
    done < $HOST_LIST_FILE
    host_list=($(printf "%s\n" ${host_list[@]} | sort -u ))
    filter_host_list
}
 
modify_host_description() {
    if [ ! -z "$selected_host" ];then
#       sed -i~ -r "s/^${selected_host}[ \t]?.*/$selected_host/"  $HOST_LIST_FILE
        set_host_description "$selected_host"
    else 
        message="select a host to modify."
    fi
}
 
set_host_description() {
    local host=$1
    local old_desc="$(host_description $host)"
    
    clear
    print_signature
        echo -e "Enter description for ${yellow}$host${reset}: "
    if [ ! -z "$old_desc" ];then
        echo -e "(current description : ${magenta}$old_desc${reset})${white}"
    fi
        read -e desc
    echo -e "${reset}"
    if [ -z "$desc" ];then desc="$old_desc"; fi
    if [ -z "$desc" ];then desc=""; fi
 
    if [ -z "`cat $HOST_LIST_FILE | grep -E "^$host"`" ];then
        echo "$host     $desc" >> $HOST_LIST_FILE
    else
        sed -i~ -r "s/^${host}[ \t]?.*/$host   $desc/"  $HOST_LIST_FILE
    fi
}
 
add_host_to_list() {
    local host=$1
    if [ -z "`cat $HOST_LIST_FILE | grep -E "^$host"`" ];then
        host_list=("${host_list[@]}" "$host")
        host_list=($(printf "%s\n" ${host_list[*]} | sort -u ))
        set_host_description "$host"
    fi
}
 
filter_host_list() {
    filtered_host_list=($( 
        for i in ${host_list[@]};do 
            echo $i
        done | grep "$hostname_filter"
    ))
    if [ -z `echo $selected_host | grep "$hostname_filter"` ];then
        selected_host=
    fi
}
 
host_index_of() {
    local host=$1
    local index=0
    while [ $index -lt ${#filtered_host_list[@]} ];do
        if [ "${filtered_host_list[index]}" == "$host" ];then
            echo $index
            return
        fi
        let "index++"
    done
    echo ""
}
 
select_next_host() {
    local cycle=${1:-false}
    local index
    local cnt=${#filtered_host_list[@]}
    if [ $cnt == 0 ];then
        selected_host=
        return
    elif [ -z "$selected_host" ];then
        selected_host="${filtered_host_list[0]}"
    else
        index=$(host_index_of $selected_host)
        let "index++"
        if [ $index -lt "${#filtered_host_list[@]}" ];then
            selected_host="${filtered_host_list[index]}"
        elif [ $cycle == true ];then
            selected_host="${filtered_host_list[0]}" 
        fi
    fi
}
 
select_prev_host() {
    local cycle=${1:-false}
    local index
    local cnt=${#filtered_host_list[@]}
    if [ $cnt == 0 ];then
        selected_host=
        return
    elif [ -z "$selected_host" ];then
        local cnt=${#filtered_host_list[@]}
        selected_host="${filtered_host_list[cnt-1]}"
    else
        index=$(host_index_of $selected_host)
        let "index--"
        if [ $index -ge 0 ];then
            selected_host="${filtered_host_list[index]}"
        elif [ $cycle == true ];then
            selected_host="${filtered_host_list[cnt-1]}" 
        fi
    fi
}
 
complete_hostname() {
    local common_matched
    local matched
    
    while true;do
        for hostname in "${filtered_host_list[@]}" ;do
            matched="`echo $hostname | grep -o "${hostname_filter}." | head -n 1`"
            common_matched="${common_matched:-$matched}"
            if [ "$matched" != "$common_matched" ];then
                return
            fi
        done
        common_matched="${matched}"
        if [ -z "$common_matched" ]; then 
            break 
        fi
        if [ "$hostname_filter" == "$common_matched" ];then
            break
        fi
        hostname_filter="$common_matched"
        common_matched=
        filter_host_list
    done
        if [ ${#filtered_host_list[@]} -eq 1 ];then
                hostname_filter="${filtered_host_list[0]}"
                filter_host_list
        fi
}
 
append_hostname_filter() {
    local ch=$1
    local len=${#hostname_filter}
    local prefix=${hostname_filter:0:($len+$cursor_offset)}
    local postfix=${hostname_filter:($cursor_offset)}
    if [ $cursor_offset -eq 0 ];then
        postfix=""
    fi
    hostname_filter=$prefix$ch$postfix
    filter_host_list
}
 
delete_prev_ch_hostname_filter() {
    local len=${#hostname_filter}
    local prefix=${hostname_filter:0:($len+$cursor_offset)}
    local postfix=${hostname_filter:($cursor_offset)}
    if [ $cursor_offset -eq 0 ];then
        postfix=""
    fi
    local prefix_len=${#prefix}
    if [ $len -gt 0 -a $prefix_len -gt 0 ];then
        prefix=${prefix:0:($prefix_len-1)}
        hostname_filter=${prefix}${postfix}
        filter_host_list
    fi
}
 
delete_next_ch_hostname_filter() {
    local len=${#hostname_filter}
    local prefix=${hostname_filter:0:($len+$cursor_offset)}
    local postfix=${hostname_filter:($cursor_offset)}
    if [ $cursor_offset -eq 0 ];then
        postfix=""
        return
    fi
    if [ $len -gt 0 ];then
        hostname_filter=${prefix}${postfix:1}
        cursor_move_right
        filter_host_list
    fi
}
 
delete_prev_all_hostname_filter() {
    local len=${#hostname_filter}
    local prefix=${hostname_filter:0:($len+$cursor_offset)}
    local postfix=${hostname_filter:($cursor_offset)}
    if [ $cursor_offset -eq 0 ];then
        postfix=""
    fi
    local prefix_len=${#prefix}
    if [ $len -gt 0 -a $prefix_len -gt 0 ];then
        hostname_filter=${postfix}
        filter_host_list
    fi
}
 
delete_next_all_hostname_filter() {
    local len=${#hostname_filter}
    local prefix=${hostname_filter:0:($len+$cursor_offset)}
    local postfix=${hostname_filter:($cursor_offset)}
    if [ $cursor_offset -eq 0 ];then
        postfix=""
        return
    fi
    if [ $len -gt 0 ];then
        hostname_filter=${prefix}
        cursor_move_end
        filter_host_list
    fi
}
 
 
clear_hostname_filter() {
    hostname_filter=
    cursor_offset=0
    filter_host_list
}
 
cursor_move_left() {
    let "cursor_offset--"
    local len=${#hostname_filter}
    if (( len < (0-$cursor_offset) ));then
        let "cursor_offset=0-len"
    fi
}
 
cursor_move_right() {
    let "cursor_offset++"
    if [ $cursor_offset -gt 0 ];then
        cursor_offset=0
    fi
}
 
cursor_move_begin() {
    local len="${#hostname_filter}"
    let "cursor_offset=0-len"
}
 
cursor_move_end() {
    cursor_offset=0
}
 
 
#========================================
# Print host list
#========================================
begin_index=0
adjust_begin_index() {
    local selected=$(host_index_of $selected_host)
    local last_index
    let last_index=begin_index+HOST_DISPLAY_COUNT-1
    if [ -z $selected ];then
        selected=0
    fi
    if [ $selected -lt $begin_index ];then
        begin_index=$selected
    fi
    if [ $selected -gt $last_index ];then
        let begin_index=selected-HOST_DISPLAY_COUNT+1
    fi
}
 
host_description() {
    local hostname=$1
    echo "`cat $HOST_LIST_FILE | grep \"$hostname\" | sed -r -e 's/^[^ \t]+[ \t]*//' -e 's/[ \t]+$//'`" 
}
 
print_host_list() {
    adjust_begin_index
    echo "Known hosts (${#filtered_host_list[@]}/${#host_list[@]})"
    local last_index
    let last_index=begin_index+HOST_DISPLAY_COUNT-1
    for (( i= $begin_index; i <= $last_index; i++ ));do
        if [ $i -ge ${#filtered_host_list[@]} ];then
            break
        fi
        local host="${filtered_host_list[i]}"
        local printmsg=" - $host"
        if [ -n "$hostname_filter" ];then
            local matched=`echo $host | grep -o "$hostname_filter" | head -n 1`
            printmsg=${printmsg/$matched/${underline}$matched${underline_off}} 
        fi
        if [ "$selected_host" == "$host" ];then
            printmsg=${printmsg/ -/>>}
            printmsg=${bg_yellow}${black}$printmsg${reset}${bg_reset}
        else
            case $host in 
                *ciot* ) printmsg=${red}$printmsg${reset};;
                *.ncl ) printmsg=${cyan}$printmsg${reset};;
                *.lab ) printmsg=${green}$printmsg${reset};;
                * ) printmsg=${white}$printmsg${reset};;
            esac
        fi
            echo -en "$printmsg"
        local blank=30
        local hostlen=${#host}
        let "blank=blank-hostlen"
        for (( k=0; k<$blank; k++));do echo -n " " ;done
        local description=$(host_description $host)
        echo -e "$description"
    done
}
#========================================
# Logo And Help
#========================================
print_logo(){
    echo -en "${cyan}"
    echo -en "${reset}"
    echo -e "==============================================================================="
    
}
 
print_help() {
    echo -en " [/]: change user to rlogin        "
    echo -en " [']: change protocol ssh/rlogin   "
    echo -en " [ctrl-n]: clear hostname          "
    echo -e  " [ctrl-c]: quit"
    echo -e  " [=]: modify description for the selected host"
    echo -e  " - hostname will be autosaved if it is valid.($HOST_LIST_FILE)"
}
 
print_command() {
    local command
    command="${command}${magenta}`whoami`@gw-kit> ${reset}"
    if [ $protocol == "ssh" ]; then
        command="${command}${white}ssh ${bold}$user@${yellow}$hostname_filter${reset}${bold_off}"
    else
        command="${command}${white}rlogin -l ${bold}$user ${yellow}$hostname_filter${reset}${bold_off}"
    fi
    
    echo "-------------------------------------------------------------------------------"  
    if [ -n "$message" ];then
        echo -e "${red}${bold}[!] $message${bold_off}${reset}"
        message=
    else
        echo 
    fi
    echo -en $command
    save_cursor
    echo
    echo "-------------------------------------------------------------------------------"  
}
set_cursor() {
    for (( i=0; i > $cursor_offset; i-- ));do
        tput cub1
    done
}

p_hostname_filter=-1
p_begine_index=-1
p_selected_host=-1
p_cursor_offset=0
reset_p() {
    p_hostname_filter=-1
    p_begine_index=-1
    p_selected_host=-1
    p_cursor_offset=0
}

print_screen__() {
    if [[ $p_hostname_filter != $hostname_filter || \
        $p_begin_index != $begin_index || \
        $p_selected_host != $selected_host || \
        $p_cursor_offset != $cursor_offset ]]; then

        p_hostname_filter=$hostname_filter
        p_begin_index=$begin_index
        p_selected_host=$selected_host
        p_cursor_offset=$cursor_offset

        clear
        print_logo
        print_help
        print_command
        print_host_list
        restore_cursor
        set_cursor
    fi
}
 
print_screen() {
    clear
    print_logo
    print_help
    print_command
    print_host_list
    restore_cursor
    set_cursor
}
 
print_signature(){
    echo -e "${cyan}Gateway-kit${reset} ${blue}ver$VERSION${reset}"
}
 
#========================================
# execute rlogin
#========================================
do_execute() {
    reset_p
    if [ -n "$selected_host" ];then
        hostname_filter=$selected_host
        selected_host=
        filter_host_list
        return
    fi
    if [ -z "$hostname_filter" ];then
        message="you should select a host to rlogin!"
        return
    fi
    clear
    local tmpfile="$(basename $0).$$.tmp"
    print_signature
    echo -e "Try to ${protocol} to ${yellow}$hostname_filter${reset} as ${magenta}$user${reset} ..."
    echo 
    if [ $protocol == "ssh" ]; then
        `ssh $user@$hostname_filter 2> $tmpfile > /dev/tty`
    else
        `rlogin -l $user $hostname_filter 2> $tmpfile > /dev/tty`
    fi
    if [ $? == 0 ];then 
        clear
        add_host_to_list $hostname_filter
    else
        message=$( cat $tmpfile | head -n 1)
    fi
    filter_host_list
    clear
}
 
good_bye(){
    tput cud1
    tput cud1
    tput ed
    echo -e "${reset}${red}Happy Hacking!${reset}"
    echo 
    stty echo 
    rm ~/gwk.sh.*.tmp &> /dev/null
    exit 0;
}
 
#==============================================================================
# Initialize
#==============================================================================
init_host_list
trap good_bye INT # trap ctrl+c
 
#==============================================================================
# Main Loop
#==============================================================================
while true;do
    print_screen
    k=$(read_key)
    case $k in
        # bash key bind
        ctrl-a ) cursor_move_begin;;
        ctrl-e ) cursor_move_end;;
        ctrl-b ) cursor_move_left;;
        ctrl-f ) cursor_move_right;;
        ctrl-d ) delete_next_ch_hostname_filter;;
        ctrl-h ) delete_prev_ch_hostname_filter;;
        ctrl-k ) delete_next_all_hostname_filter;;
        ctrl-u ) delete_prev_all_hostname_filter;;
        ctrl-w ) delete_prev_all_hostname_filter;;
        # common
        backspace ) delete_prev_ch_hostname_filter;;
        up ) select_prev_host;;
        down ) select_next_host;;
        left ) cursor_move_left;;
        right ) cursor_move_right;;
        tab ) complete_hostname;;
        / ) next_user;;
        \? ) change_user_group;;
        : ) next_protocol;;
        delete ) delete_next_ch_hostname_filter;;
        # special
        ctrl-n ) clear_hostname_filter;;
        = ) modify_host_description;;
        # inputhost name filter
        [-a-zA-Z0-9_\.] ) append_hostname_filter $k;;
        enter ) do_execute;;
    esac
done
