# ********************************************************************************* #
# * This program was created with the intention of looking at how champions scale * #
# * over the course of a match. Therefore, it uses matches from high ranked       * #
# * players and takes the following:                                              * #
# * (1) Match Duration (2) Champion ID (3) Outcome as 1/0 (4) Match ID            * #
# *                                                                               * #
# * For easily accessing information from Riot API's, please check Cassiopeia:    * #
# * https://github.com/robrua/cassiopeia                                          * #
# ********************************************************************************* #


# Get your tools ready

import cassiopeia
import random
import re
from cassiopeia import riotapi
from cassiopeia import baseriotapi
from cassiopeia.type.core.common import LoadPolicy
import sys
import itertools
import csv
import numpy as np

# Set the range of players you wish to extract data from!
# Low indicates the lowest value rank (0 is the highest rated player)
# High indicates the highest value rank (199 in challenger as of Path 5.18)

Low = 0
High = 100

# 10 calls per 10 seconds AND 500 calls per 10 minutes, this is the current limit

riotapi.set_rate_limits((10, 10), (500, 600));

# Change loading to lazy (eager is the default)

riotapi.set_load_policy(LoadPolicy.lazy);

# Set your region and API Key found here: (https://developer.riotgames.com/)

riotapi.set_region("NA")
riotapi.set_api_key("YOUR KEY HERE")

# Develop a list of some challenger solo q players' ID (for master, simply replace 'challenger' with 'master')
# Weed out players who have irrelevant game types in their match history
# See IDLE to examine who's match history was used

game_type_list=['"gameMode": "ARAM"', '"gameMode": "ARAM"','"subType": "RANKED_SOLO_3x3"','"subType": "RANKED_PREMADE_3x3"',
                '"subType": "RANKED_TEAM_3x3"','"subType": "NORMAL"','CUSTOM','a']

player_list = []

challenger_league = cassiopeia.baseriotapi.get_challenger('RANKED_SOLO_5x5')
arg = 0
for arg in range (Low,High): 
    summoner_id = challenger_league.entries[arg].playerOrTeamId
    test = challenger_league.entries[arg].playerOrTeamName
    print(test)
    text = str(cassiopeia.baseriotapi.get_recent_games(summoner_id))
    arg = arg + 1

    if '"gameMode": "ARAM"' in text:
        print("Bad")
        continue

    if '"subType": "RANKED_SOLO_3x3"' in text:
        print("Bad")
        continue

    if '"subType": "RANKED_PREMADE_3x3"' in text:
        print("Bad")
        continue

    if '"gameMode": "ODIN"' in text:
        print("Bad")
        continue

    if '"subType": "RANKED_TEAM_3x3"' in text:
        print("Bad")
        continue

    if 'NORMAL' in text:
        print("Bad")
        continue

    if 'CUSTOM' in text:
        print("Bad")
        continue

    player_list.append(summoner_id)
    print("OK!")


# Use player IDs to get match IDs from their match history

Match_ID_List=[]
i = 0
g = 0
for s in player_list:
    matches = str(cassiopeia.baseriotapi.get_recent_games(player_list[i]))
    z = re.findall('"gameId": (.+?),',matches)
    Match_ID_List.append(z)    
    i = i + 1

# Using the match IDs, extract all relevant information and place them into lists

j=0
h=0
Duration_List = []
Champ_ID_List = []
Win_Lose_List = []
Match_ID = []

j = 0
h = 0

for s in Match_ID_List:
    
    for s in Match_ID_List[j]:

        # Identify the game based on values from the Match_ID_List
        game = str(cassiopeia.baseriotapi.get_match(Match_ID_List[j][h]))
        
        # Find duration, list each 10 times to match up with champs and win/loss
        duration = re.findall('"matchDuration": (.+?),', game)
        for _ in itertools.repeat(None,10):
            Duration_List.append(duration)

        # Include the match ID to weed out duplicate observations in the future
        Match = Match_ID_List[j]
        Match_ID.append(Match)

        # Get champion IDs and append them to their own list
        champ_id = re.findall('"championId": (.+?),', game)
        champ_id = champ_id[:10]
        Champ_ID_List.append(champ_id)

        # Get win/loss and append them to their own list 
        winner = re.findall('"winner": (.+?)', game)
        del winner[-2:]
        Win_Lose_List.append(winner)
        
        
        h = h+1

    j = j+1
    h = 0


# In case of the Champion_ID list being a strange value for whatever reason, fill it in with 0 to keep
# lists the same length.

y=0
Champ_ID_New = []
for s in Champ_ID_List:
    if len(Champ_ID_List[y]) is not 10:
        Champ_ID_List[y].append(0)
    Champ_ID_New = Champ_ID_New + Champ_ID_List[y]
    y = y+1

# Errors often occur due to lists of different lengths. You'll be able to see where the problem is
# coming from.

print(len(Champ_ID_New))
print(len(Win_Lose_List))
print(len(Match_ID))
print(len(Duration_List))

# Currently lists contain smaller lists, smush them together

Duration_List = list(itertools.chain.from_iterable(Duration_List))
Win_Lose_List = list(itertools.chain.from_iterable(Win_Lose_List))
Match_ID_List = list(itertools.chain.from_iterable(Match_ID))

# Ensure lengths are still equivelent

print(len(Champ_ID_New))
print(len(Win_Lose_List))
print(len(Match_ID_List))
print(len(Duration_List))

# Convert w/l into values 1 (win) and 0 (lose)

tq = 0
for s in Win_Lose_List:
    if Win_Lose_List[tq] == 't':
        Win_Lose_List[tq] = 1
        tq = tq + 1
    else:
        Win_Lose_List[tq] = 0
        tq = tq +1

# Turn all values into floats, this enables us to use vstack

Duration_List = list(map(float,Duration_List))
Champ_ID_List = list(map(float,Champ_ID_New))
Win_Lose_List = list(map(float,Win_Lose_List))
Match_ID_List = list(map(float,Match_ID_List))

# Turn lists into arrays, this enables us to use vstack

d_list = np.array(Duration_List)
c_list = np.array(Champ_ID_List)
w_list = np.array(Win_Lose_List)
m_list = np.array(Match_ID_List)

# Put arrays together, and transpose to get into column form

final = np.vstack((d_list,c_list,w_list,m_list))
final = np.transpose(final)

# Save file as a comma delimited CSV file
# NOTE Values are in float form and should be rounded

np.savetxt('final.csv',final,delimiter=',',newline='\n')

sys.exit("Error Message")

