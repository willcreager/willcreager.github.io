-- Returns subset containing only pitches batter could have challenged
-- Called strike, their team has a challenge left
SELECT *
FROM MLBData..pitch_by_pitch_20260901
WHERE (challengePlayerPosition = 'Batter'
		OR (pitchDescription = 'Called Strike' AND hasABSChallenge = 0
			AND ((inningHalf = 0 AND awayChallengesLeft > 0) 
				OR (inningHalf = 1 AND homeChallengesLeft > 0))))  AND
	   -- These are games where ABS replays were not available
	   GamePK not in (
		 825093, -- 4/25/26 DBacks Padres Mexico game
		 825094, -- 4/26/26 DBacks Padres Mexico game
		 823669, -- 8/13/26 Phillies Twins Field of Dreams
		 823745 -- 8/23/26 Brewers Braves Williamsport
	   )

-- Returns subset containing only pitches pitcher or catcher could have challenged
-- Called ball, their team has a challenge left
SELECT *
FROM MLBData..pitch_by_pitch_20260901
WHERE (challengePlayerPosition in ('Pitcher','Catcher')
		OR (pitchDescription like '%Ball%' AND hasABSChallenge = 0
			AND ((inningHalf = 1 AND awayChallengesLeft > 0) 
				OR (inningHalf = 0 AND homeChallengesLeft > 0))))  AND
	   -- These are games where ABS replays were not available
	   GamePK not in (
		 825093, -- 4/25/26 DBacks Padres Mexico game
		 825094, -- 4/26/26 DBacks Padres Mexico game
		 823669, -- 8/13/26 Phillies Twins Field of Dreams
		 823745 -- 8/23/26 Brewers Braves Williamsport
	   )