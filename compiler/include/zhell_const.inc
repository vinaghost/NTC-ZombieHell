
#if defined _ZHELL_CONST_
  #endinput
#endif

#define _ZHELL_CONST_


#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

stock getHuman(players[32], &num) {
    get_players(players, num, "ae", "CT");
}
stock getZombie(players[32], &num) {
    get_players(players, num, "ae", "TERRORIST");
}
