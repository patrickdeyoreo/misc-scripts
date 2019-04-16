#! /usr/bin/env bash

## A Game of Scrabble
##
## Scrabble uses 102 tiles totaling 187 points in the following distribution:
##
## 0  points : _ x2
## 1  points : E x12, A x9, I x9, O x8, N x6, R x6, T x6, L x4, S x4, U x4
## 2  points : D x4, G x3
## 3  points : B x2, C x2, M x2, P x2
## 4  points : F x2, H x2, V x2, W x2, Y x2
## 5  points : K x1
## 8  points : J x1, X x1
## 10 points: Q x1, Z x1


## Enable debugging output
if [[ -n ${DEBUG} ]]; then
  set -"${DEBUG_OPTS:-xv}"
fi



## Sets up the environment
init_env() {

  ## Make options local to function
  local -

  ## Expand braces and exit on error
  set -o braceexpand -o errexit


  ## -- Work Directory

  ## Directory for temporary files
  declare -g workdir=''

  ## Set a trap to clean up on exit
  trap '[[ -d ${workdir} ]] && rm -rf "${workdir}"' EXIT

  ## Create directory for temporary files
  workdir="$(mktemp -d --tmpdir "${0##*/}-$$-XXXXXX")"

  
  ## -- Tiles

  ## List of tiles
  declare -ag  tiles=( {A..Z} _ )
  declare -Aig tile_map=( )
  for (( i = 0; i < "${#tiles[@]}"; ++i )); do
    tile_map[${tiles[i]}]=${i}
  done


  ## Letters mapped to tile count
  declare -Aig tile_counts=(
    [A]=9 [B]=2 [C]=2 [D]=4 [E]=12 [F]=2 [G]=3 [H]=2 [I]=9
    [J]=1 [K]=1 [L]=4 [M]=2 [N]=6  [O]=8 [P]=2 [Q]=1 [R]=6
    [S]=4 [T]=6 [U]=4 [V]=2 [W]=2  [X]=1 [Y]=2 [Z]=1 [_]=2
  )

  ## Letters mapped to points
  declare -Aig tile_points=(
    [A]=1 [B]=3 [C]=3 [D]=2 [E]=1 [F]=4 [G]=2 [H]=4  [I]=1
    [J]=8 [K]=5 [L]=1 [M]=3 [N]=1 [O]=1 [P]=3 [Q]=10 [R]=1
    [S]=1 [T]=1 [U]=1 [V]=4 [W]=4 [X]=8 [Y]=4 [Z]=10 [_]=0
  )


  ## -- Board

  ## Square board dimensions {board_dim}x{board_dim}
  declare -ig board_dim=${board_dim}

  ## Default to 9x9
  (( board_dim <= 1 )) && board_dim=9

  ## Board represented as array of arrays
  eval "declare -ag board=( board_row{0..$((board_dim - 1))}\[@] )"
  eval "declare -ag board_row{0..$((board_dim - 1))}='( )'"

  ## Fill board with spaces
  eval "declare -g board_row{0..$((board_dim - 1))}\[{0..$((board_dim - 1))}]='.'"


  ## -- Players

  ## Number of players
  declare -ig player_count=${player_count}

  ## Default to 1 player
  (( player_count <= 0 )) && player_count=1

  ## Player hands
  eval "declare -ag  player{0..$((player_count - 1))}_hand='( )'"
  eval "declare -Ag  player{0..$((player_count - 1))}_hand_map='( )'"
  eval "declare -Aig player{0..$((player_count - 1))}_tile_counts='( )'"

  ## Player points
  eval "declare -ig player{0..$((player_count - 1))}_score=0"

}




## Prints the board
print_board() {

  local i=0
  local coord_fmt="%${#board_dim}d"

  ## Print horizontal coordinates
  if tput rep 1> /dev/null 2>&1; then
    tput rep 32 "$((${#board_dim} + 1))"
  else
    for ((i = 0; i <= ${#board_dim}; ++i)); do
      printf ' '
    done
  fi
  eval "echo {1..$((board_dim))}"

  ## Print board and vertical coordinates
  for ((i = 0; i < board_dim; ++i)); do
    printf "${coord_fmt} " "$((i + 1))" 
    echo "${!board[i]}"
  done

}




## Prints a players hand
print_hand() {

  local hand="player${1:-0}_hand[@]"
  local -a hand_points=( )

  echo "${!hand}"

  for tile in "${!hand}"; do
    hand_points+=( "${tile_points[${tile}]}" )
  done

  echo "${hand_points[@]}"

}




## Draws a tile into player's hand
draw_tile() {

  local tile=''
  local -n hand="player${1:-0}_hand"
  local -n hand_map="player${1:-0}_hand_map"

  ## Try random tile until pulled tile exists
  while tile="${tiles[RANDOM % ${#tiles[@]}]}"
    ! ((tile_counts[${tile}]))
  do
    :
  done

  ## Add tile to player's hand
  hand+=( "${tile}" )

  ## Add tile to player's hand map
  hand_map[${tile}]+=":$((${#hand[@]} - 1))"

  ## Decrement the tile counter
  (( --tile_counts[${tile}] ))

  ## Increment player's tile counter
  (( ++player${1:-0}_tile_counts[${tile}] ))
}




## Gets letter to play from player
query_tile() {

  local -n player_tile_counts="player${1:-0}_tile_counts"

  while read -r -p '>> Tile: ' tile && tile="${tile^}"
    (( ${#tile} != 1  || player_tile_counts[${tile}] == 0 ))
  do
    if (( ${#tile} != 1 )); then
      printf "*> Please enter a single letter\n"
    else
      printf "*> '%s' not in hand\n" "${tile}"
    fi
  done

}




## Gets the position to play from player
query_position() {

  while IFS=$', \t\n' read -rp '>> Position (x,y): ' position[0] position[1]
    [[ ${position[0]} = *[![:digit:]]* || ${position[1]} = *[![:digit:]]* ]] \
      || (( position[0] < 1 || position[0] > board_dim ||
            position[1] < 1 || position[1] > board_dim ))
  do
    if (( position[0] < 1 || position[0] > board_dim ||
          position[1] < 1 || position[1] > board_dim ))
    then
      printf "*> Enter a position within the bounds of board\n"
    else
      printf "*> Enter position formatted as 'x, y'\n"
    fi
  done

}




## Plays a tile
play_tile() {

  local -i i
  local -n hand="player${1:-0}_hand"
  local -n hand_map="player${1:-0}_hand_map"

  ## Place the tile
  declare -g "board_row$((position[1] - 1))[position[0] - 1]=${tile}"

  ## Update the player's score
  declare -g player"${1:-0}"_score+=${tile_points[${tile}]}

  ## Update the player's hand
  unset -v hand[${hand_map[${tile}]##*:}]
  hand=( "${hand[@]}" )

  ## Decrement player's tile counter
  (( --player${1:-0}_tile_counts[${tile}] ))

  ## Refresh player's hand map
  hand_map=( )
  for (( i = 0; i < ${#hand[@]}; ++i )); do
    hand_map[${hand[i]}]+=":${i}"
  done

}




## Executes a player's turn
player_turn() {

  local tile=''
  local -ai position=( )
  local -n hand="player${1:-0}_hand"
  local -n score="player${1:-0}_score"

  ## Print player's name
  printf "*> Player %s, Score %d\n" "${1:-0}" "${score}"

  ## Draw a tile
  while (( ${#hand[@]} < 7 )); do
    draw_tile "${1:-0}"
  done

  ## Print player's hand
  print_hand "${1:-0}"

  ## Get tile and position
  query_tile "${1:-0}"
  query_position "${1:-0}"

  ## Play the tile
  play_tile "${1:-0}"
  
}




## Runs the game
main() {

  ## Initialize the environment
  init_env

  ## Main game loop
  while true; do

    ## Loop for each player
    for (( player = 0; player < player_count; ++player )); do
      ## Print the board
      print_board
      ## Get the player's move
      player_turn "${player}"
    done

  done

}


## Start the game
main
