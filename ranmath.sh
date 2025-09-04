#!/usr/bin/env sh
dependencies="cat grep wc expr"
for c in $(printf "$dependencies"); do command -v || { printf "missing command: %s" "$c\n"; exit 1; }; done

appname="Random Math: Zufällige Aufgaben zur Übung"
# für Übung und Test
#   Bestanden: 1. Keine Fehler (eine Wiederholung je Aufgabe möglich)
#              2. Unter 3 Sekunden je Aufgabe
#              3. Mindestens (max-min+1)^2 zufällige Aufgaben gelöst

# Konfiguration
g=1      # Grenze für Wiederholungen
cdot="·" # 00b7 – das Malzeichen
delay=5
maxlist=20

COL_NC='\e[0m' # No Color
COL_BLACK='\e[0;30m'
COL_GRAY='\e[1;30m'
COL_RED='\e[0;31m'
COL_LIGHT_RED='\e[1;31m'
COL_GREEN='\e[0;32m'
COL_LIGHT_GREEN='\e[1;32m'
COL_BROWN='\e[0;33m'
COL_YELLOW='\e[1;33m'
COL_BLUE='\e[0;34m'
COL_LIGHT_BLUE='\e[1;34m'
COL_PURPLE='\e[0;35m'
COL_LIGHT_PURPLE='\e[1;35m'
COL_CYAN='\e[0;36m'
COL_LIGHT_CYAN='\e[1;36m'
COL_LIGHT_GRAY='\e[0;37m'
COL_WHITE='\e[1;37m'


# RANDOM ist eine Umgebungsvariable
generate_random() {
    test $# -eq 2 && { min=$1; max=$2; }
    local range=$((max - min + 1))
    printf "%s\n" $(( RANDOM % range + min ))
}

is_valid_name() {
  case "$1" in
    [A-Z][a-zA-Z]*) return 0 ;;
    *) return 1 ;;
  esac
}

sort_list() {
  test $# -ge 1 && { maxlist=$1; shift; }

  tmpfile=$(mktemp)

  for file in list/*.list; do
    name=$(cat "$file" | grep "Name" | cut -d":" -f2)
    time=$(cat "$file" | grep "Startzeit" | cut -d":" -f2)
    runt=$(cat "$file" | grep "Wertzeit" | cut -d":" -f2)
    task=$(cat "$file" | grep "Aufgaben" | cut -d":" -f2)
    pnts=$(cat "$file" | grep "Punkte" | cut -d":" -f2)

    printf "%s|%s|%s|%s|%s\n" "$runt" "$name" "$time" "$task" "$pnts"
  done | while IFS='|' read -r runt name time tasks points; do
    rate=$(printf "scale=2; ${points} / ${tasks} * 100\n" | bc)
    run=$(( $runt - $time ))
    pertask=$(printf "scale=2; ${run} / ${tasks}\n" | bc )
    if ! time=$(date -d "@$time" +"%y%m%d_%H:%M" 2>/dev/null); then
      time="INVALID"
    fi

    printf "%s|%s|%s|%s|%s\n" "$rate" "$pertask" "$tasks" "$name" "$time"
  done  >> "$tmpfile"

  printf "## Bestenliste\n\n"
  printf "| %3s | %-12s | %-12s | %7s | %6s | %7s |\n" "  #" "$(printf "%5s")Name" "$(printf "%7s")Wann" "Richtig" "Zeit" "Aufgaben"
  printf "| %s | %s | %s | %s | %s | %s |\n" "--:" ":$(printf "%10s"|tr " " "-"):" ":$(printf "%10s"|tr " " "-"):" "$(printf "%6s"|tr " " "-"):" "$(printf "%5s"|tr " " "-"):" "$(printf "%7s"|tr " " "-"):"
  cnt=0
  sort -t'|' -k1,1nr -k2,2n -k3,3n "$tmpfile" | while IFS='|' read -r points pertask tasks name time; do
    cnt=$(( $cnt + 1 ))
    test "$cnt" -gt "$maxlist" && break
    nlength_half=$(printf "( 12 - "$(printf "${name}" | wc -c)" ) / 2 + 1\n" | bc)
    points=$( printf "$points"|cut -d"." -f1 )
    printf "| %3s | %-12s | %12s | %7s | %6s | %8s |\n" "${cnt}" "$(printf "%${nlength_half}s")${name}" "${time}" "${points} %" "${pertask}" "${tasks}"
  done

  #~ printf "${tmpfile}"
  rm "${tmpfile}"

}

help="Usage: $0 <min=2> <max=9>\n\nmin  Minimum\n     Vorgabewert 2\nmax  Maximum\n     Vorgabewert 9\n\n"
test "$1" = "list" && { sort_list; exit 0; }
test "$#" -lt 2 && { printf "${help}"; min=2; max=9; } || { min=$1; shift; max=$1; shift; }
if ! [[ "$min" =~ ^-?[0-9]+$ && "$max" =~ ^-?[0-9]+$ ]]; then
  printf "Fehler: min und max müssen Ganze Zahlen sein.\n\n${help}"
  exit 1
fi

test "$#" -ne 0 && { delay=$1; shift; }

test "$min" -gt "$max" && { printf "Fehler: min muss kleiner oder gleich max sein.\;"; exit 1; }

clear
printf "\n# $appname\n\n"
sort_list
printf "\n## Neues Spiel\n\n"

while :
do
  printf "Name: "
  read varname
  is_valid_name $varname && break || printf "Einen ordentlichen Namen bitte!\n"
done

aufgabenop="*" # "+-*/"
oplen=$(printf "$aufgabenop"|wc -c)

#todo: Fix für mehr als ein Operation
maxaufgaben=$(( ( $min - $max + 1 ) * ( $min - $max + 1 ) ))
printf "Aufgaben: ${maxaufgaben} im Bereich [ $min ; $max ]"
aufgaben=0
punkte=0

wartezeit=${delay}
clear;
printf "$appname\n\n"
printf "Start in $wartezeit Sekunden …\n\n"
startzeit="$(($(date +%s) + $wartezeit))"

tmpsigfile=$(mktemp)
while [ "$startzeit" -ge `date +%s` ]; do
  time="$(( $startzeit - `date +%s` ))"
  printf '%s\r' "$(date -u -d "@$time" +%S)"
done

clear
startzeit="$(date +%s)"
while :
do
  test $aufgaben -gt 0 && {
    if [ "$aufgaben" -ge "$maxaufgaben" ] ; then
      gewonnen=1
    fi
    if [ "$aufgaben" -ge 100 ] && [ "${jeAufgabe}" -lt 3 ] && [ "$punkte" -eq "$aufgaben" ]; then
      gewonnen=1
    fi
    test "$gewonnen" && { printf "%30sWertung: Gewonnen!\n"; break; }
    test "$verloren" && printf "%30sWertung: ${COL_LIGHT_CYAN}Weiter üben${COL_NC}!\n"
    jetzt="$(date +%s)"
    sekunden=$(( ${jetzt} - ${startzeit} ))
    jeAufgabeD=$( printf "scale=2;${sekunden} / ${aufgaben}\n" | bc | tr "." "," )
    jeAufgabe=$( printf "${sekunden} / ${aufgaben}\n" | bc )
    test "${jeAufgabe}" -lt 3 && zeitFarbe="${COL_GREEN}" || zeitFarbe="${COL_RED}"
    test "${punkte}" -ge "${aufgaben}" && punktFarbe="${COL_GREEN}" || { punktFarbe="${COL_RED}"; verloren=1; }
    printf "%30sPunkte : ${punktFarbe}${punkte} von ${aufgaben}$COL_NC\n"
    CIR_S="⚫"
    CIR_V="🟣"
    CIR_B="🟤"
    CIR_O="🟠"
    CIR_Y="🟡"
    CIR_W="⚪"
    CIR_G="🟢"
    CIR_F="⚽"
    # todo
    # printf "%${spaces}s"|tr " " ""
    printf "%30sZeit   : ${zeitFarbe}${jeAufgabeD} Sekunden je Aufgabe = ${sekunden} Sekunden / ${aufgaben} von ${maxaufgaben}${COL_NC}\n\n"

    fnts=$(date -d "@${startzeit}" +'%Y%m%dT%H%M%S')
    fn="list/${fnts}_${varname}.list"
    printf "Name: $varname\nStartzeit: ${startzeit}\nWertzeit: ${jetzt}\nPunkte: ${punkte}\nAufgaben: ${aufgaben}\n" > ${fn}
  }

  cnt=0
  while : # vermeide doppelte Aufgaben
  do
    rando=$(generate_random 1 $oplen)
    rando=$(expr substr "${aufgabenop}" "${rando}" "1")
    rand1=$(generate_random)
    rand2=$(generate_random)
    sig="${startzeit}${rand1}${rand2}${rando}"

    grep -q "$sig" "${tmpsigfile}" && cnt=$(( $cnt + 1 )) || break
    if [ "${cnt}" -ge "${maxaufgaben}" ] ; then
      verloren=1; break
    fi
  done

  w=0 # Wiederholungen zählen
  while :
  do
    case "$rando" in
      "+") opD="+"; opResult=$(( $rand1 + $rand2 ));;
      "-") opD="–"; opResult=$(( $rand1 - $rand2 ));;
      "*") opD="${cdot}"; opResult=$(( $rand1 * $rand2 ));;
      "/") opD=":"; opResult=$(( $rand1 / $rand2 ));;
    esac
    printf "Aufgabe: ${rand1} ${opD} ${rand2} = "
    read number

    w=$(( $w + 1))

    if [[ "${number}" =~ ^-?[0-9]+$ ]]; then
      spaces=$(( 5 - $(printf "$number"|wc -c) )) # Anzahl bestimmen
      if [[ "$opResult" -eq "$number" ]]; then
        case "$rando" in
          "+") ;;
          "-") ;;
          "*")
            printf "         "
            test "$rand1" -eq "$rand2" && printf "${rand1}² = "
            printf "$rand2 $opD $rand1 = $number"
            printf "%${spaces}s"
            printf "| ✅ Korrekt!\n\n"
            punkte=$(( $punkte + 1 ))
            printf "$sig\n" >> "${tmpsigfile}"
            break
            ;;
          "/") ;;
        esac
      else
        case "$rando" in
          "+") ;;
          "-") ;;
          "*")
            printf "%9s"
            printf "❌ Falsch!\n"
            if [[ "$w" -gt "$g" ]]; then # Versuche begrenzen
              printf "         $rand1 $opD $rand2 = $rand2 $opD $rand1 = "$(( $rand2 * $rand1 ))"\n\n"
              break
            fi
            ;;
          "/") ;;
        esac
      fi
    else
      printf "Eingabefehler. Gib eine ganze Zahl ein.\n"
    fi
  done
  aufgaben=$(( $aufgaben + 1 ))
done

rm "$tmpsigfile"
