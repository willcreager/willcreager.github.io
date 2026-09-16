WITH BatterChallengablePitches AS (
    SELECT 
        batterId,
        CASE WHEN inningHalf = 0 THEN 'Away' ELSE 'Home' END AS homeAwaySplit,
        -- Create inning grouping
		CASE 
            WHEN inning BETWEEN 1 AND 3 THEN 'Inn_1_3'
            WHEN inning BETWEEN 4 AND 6 THEN 'Inn_4_6'
            WHEN inning BETWEEN 7 AND 9 THEN 'Inn_7_9'
            ELSE 'Inn_10Plus' 
        END AS inningSplit,
        CASE 
            WHEN inningHalf = 0 THEN awayChallengesLeft 
            ELSE homeChallengesLeft 
        END AS teamChallengesLeft,
		-- Create pitch type grouping
		CASE 
            WHEN pitchTypeId in (5,6,7,12) THEN 1 -- Fastballs
            WHEN pitchTypeId in (2,3,10,13,14,15) THEN 2 -- Breaking Balls
            ELSE 3 -- Other 
        END AS PitchTypeGroup,
        hasABSChallenge,
        isOverturned
    FROM MLBData..pitch_by_pitch_20260901
    WHERE (challengePlayerPosition = 'Batter'
       OR (
            pitchDescription = 'Called Strike' 
            AND hasABSChallenge = 0
            AND (
                (inningHalf = 0 AND awayChallengesLeft > 0) 
                OR (inningHalf = 1 AND homeChallengesLeft > 0)
            )
       )) AND
	   -- These are games where ABS replays were not available
	   GamePK not in (
		 825093, -- 4/25/26 DBacks Padres Mexico game
		 825094, -- 4/26/26 DBacks Padres Mexico game
		 823669, -- 8/13/26 Phillies Twins Field of Dreams
		 823745 -- 8/23/26 Brewers Braves Williamsport
	   )
)
SELECT 
    b.batterId, 
    p.lastName, 
    p.firstName,
    
    -- =========================================================================
    -- OVERALL METRICS
    -- =========================================================================
    COUNT(*) AS Total_Opp_Ovr, 
    SUM(b.hasABSChallenge) AS Total_ChallengesMade,
    1.0 * SUM(b.hasABSChallenge) / COUNT(*) AS Total_ChallengeRate, 
    SUM(CASE WHEN b.isOverturned = 1 THEN 1 ELSE 0 END) AS Total_ChallengesOverturned,
    1.0 * SUM(CASE WHEN b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(b.hasABSChallenge), 0) AS Total_OverturnedRate,

     -- =========================================================================
    -- 2. HOME SPLIT METRICS
    -- =========================================================================
    SUM(CASE WHEN b.homeAwaySplit = 'Home' THEN 1 ELSE 0 END) AS Home_Opp,
    SUM(CASE WHEN b.homeAwaySplit = 'Home' THEN b.hasABSChallenge ELSE 0 END) AS Home_Made,
    1.0 * SUM(CASE WHEN b.homeAwaySplit = 'Home' THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.homeAwaySplit = 'Home' THEN 1 ELSE 0 END), 0) AS Home_Rate,
    SUM(CASE WHEN b.homeAwaySplit = 'Home' AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Home_Over,
    1.0 * SUM(CASE WHEN b.homeAwaySplit = 'Home' AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.homeAwaySplit = 'Home' THEN b.hasABSChallenge ELSE 0 END), 0) AS Home_OvrRate,

    -- =========================================================================
    -- 3. AWAY SPLIT METRICS
    -- =========================================================================
    SUM(CASE WHEN b.homeAwaySplit = 'Away' THEN 1 ELSE 0 END) AS Away_Opp,
    SUM(CASE WHEN b.homeAwaySplit = 'Away' THEN b.hasABSChallenge ELSE 0 END) AS Away_Made,
    1.0 * SUM(CASE WHEN b.homeAwaySplit = 'Away' THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.homeAwaySplit = 'Away' THEN 1 ELSE 0 END), 0) AS Away_Rate,
    SUM(CASE WHEN b.homeAwaySplit = 'Away' AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Away_Over,
    1.0 * SUM(CASE WHEN b.homeAwaySplit = 'Away' AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.homeAwaySplit = 'Away' THEN b.hasABSChallenge ELSE 0 END), 0) AS Away_OvrRate,

    -- =========================================================================
    -- 4. TEAM HAS 2 CHALLENGES LEFT METRICS
    -- =========================================================================
    SUM(CASE WHEN b.teamChallengesLeft = 2 THEN 1 ELSE 0 END) AS Team2Left_Opp,
    SUM(CASE WHEN b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) AS Team2Left_Made,
    1.0 * SUM(CASE WHEN b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.teamChallengesLeft = 2 THEN 1 ELSE 0 END), 0) AS Team2Left_Rate,
    SUM(CASE WHEN b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Team2Left_Over,
    1.0 * SUM(CASE WHEN b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END), 0) AS Team2Left_OvrRate,

    -- =========================================================================
    -- 5. TEAM HAS 1 CHALLENGE LEFT METRICS
    -- =========================================================================
    SUM(CASE WHEN b.teamChallengesLeft = 1 THEN 1 ELSE 0 END) AS Team1Left_Opp,
    SUM(CASE WHEN b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) AS Team1Left_Made,
    1.0 * SUM(CASE WHEN b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.teamChallengesLeft = 1 THEN 1 ELSE 0 END), 0) AS Team1Left_Rate,
    SUM(CASE WHEN b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Team1Left_Over,
    1.0 * SUM(CASE WHEN b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END), 0) AS Team1Left_OvrRate,

    -- =========================================================================
    -- 6. INNING 1-3 DEEP DIVE (Overall, 2 Left, 1 Left)
    -- =========================================================================
    -- Inn 1-3 Overall
    SUM(CASE WHEN b.inningSplit = 'Inn_1_3' THEN 1 ELSE 0 END) AS Inn1_3_Ovr_Opp,
    SUM(CASE WHEN b.inningSplit = 'Inn_1_3' THEN b.hasABSChallenge ELSE 0 END) AS Inn1_3_Ovr_Made,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_1_3' THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_1_3' THEN 1 ELSE 0 END), 0) AS Inn1_3_Ovr_Rate,
    SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn1_3_Ovr_Over,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_1_3' THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn1_3_Ovr_OvrRate,
    
    -- Inn 1-3 with 2 Challenges Remaining
    SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 2 THEN 1 ELSE 0 END) AS Inn1_3_Chg2_Opp,
    SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) AS Inn1_3_Chg2_Made,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 2 THEN 1 ELSE 0 END), 0) AS Inn1_3_Chg2_Rate,
    SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn1_3_Chg2_Over,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn1_3_Chg2_OvrRate,

    -- Inn 1-3 with 1 Challenge Remaining
    SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 1 THEN 1 ELSE 0 END) AS Inn1_3_Chg1_Opp,
    SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) AS Inn1_3_Chg1_Made,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 1 THEN 1 ELSE 0 END), 0) AS Inn1_3_Chg1_Rate,
    SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn1_3_Chg1_Over,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_1_3' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn1_3_Chg1_OvrRate,

    -- =========================================================================
    -- 7. INNING 4-6 DEEP DIVE (Overall, 2 Left, 1 Left)
    -- =========================================================================
    -- Inn 4-6 Overall
    SUM(CASE WHEN b.inningSplit = 'Inn_4_6' THEN 1 ELSE 0 END) AS Inn4_6_Ovr_Opp,
    SUM(CASE WHEN b.inningSplit = 'Inn_4_6' THEN b.hasABSChallenge ELSE 0 END) AS Inn4_6_Ovr_Made,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_4_6' THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_4_6' THEN 1 ELSE 0 END), 0) AS Inn4_6_Ovr_Rate,
    SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn4_6_Ovr_Over,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_4_6' THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn4_6_Ovr_OvrRate,
    
    -- Inn 4-6 with 2 Challenges Remaining
    SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 2 THEN 1 ELSE 0 END) AS Inn4_6_Chg2_Opp,
    SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) AS Inn4_6_Chg2_Made,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 2 THEN 1 ELSE 0 END), 0) AS Inn4_6_Chg2_Rate,
    SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn4_6_Chg2_Over,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn4_6_Chg2_OvrRate,

    -- Inn 4-6 with 1 Challenge Remaining
    SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 1 THEN 1 ELSE 0 END) AS Inn4_6_Chg1_Opp,
    SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) AS Inn4_6_Chg1_Made,
    1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 1 THEN 1 ELSE 0 END), 0) AS Inn4_6_Chg1_Rate,
	SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn4_6_Chg1_Over,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_4_6' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn4_6_Chg1_OvrRate,
	
	-- =========================================================================-- 8. INNING 7-9 DEEP DIVE (Overall, 2 Left, 1 Left)-- =========================================================================
	-- Inn 7-9 Overall
	SUM(CASE WHEN b.inningSplit = 'Inn_7_9' THEN 1 ELSE 0 END) AS Inn7_9_Ovr_Opp,
	SUM(CASE WHEN b.inningSplit = 'Inn_7_9' THEN b.hasABSChallenge ELSE 0 END) AS Inn7_9_Ovr_Made,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_7_9' THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_7_9' THEN 1 ELSE 0 END), 0) AS Inn7_9_Ovr_Rate,
	SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn7_9_Ovr_Over,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_7_9' THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn7_9_Ovr_OvrRate,
	
	-- Inn 7-9 with 2 Challenges Remaining
	SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 2 THEN 1 ELSE 0 END) AS Inn7_9_Chg2_Opp,
	SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) AS Inn7_9_Chg2_Made,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 2 THEN 1 ELSE 0 END), 0) AS Inn7_9_Chg2_Rate,
	SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn7_9_Chg2_Over,1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn7_9_Chg2_OvrRate,
	
	-- Inn 7-9 with 1 Challenge Remaining
	SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 1 THEN 1 ELSE 0 END) AS Inn7_9_Chg1_Opp,
	SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) AS Inn7_9_Chg1_Made,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 1 THEN 1 ELSE 0 END), 0) AS Inn7_9_Chg1_Rate,
	SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn7_9_Chg1_Over,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_7_9' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn7_9_Chg1_OvrRate,
	
	-- =========================================================================-- 9. EXTRA INNINGS (10+) DEEP DIVE (Overall, 2 Left, 1 Left)-- =========================================================================
	-- Inn 10+ Overall
	SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' THEN 1 ELSE 0 END) AS Inn10_Ovr_Opp,
	SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' THEN b.hasABSChallenge ELSE 0 END) AS Inn10_Ovr_Made,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' THEN 1 ELSE 0 END), 0) AS Inn10_Ovr_Rate,
	SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn10_Ovr_Over,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn10_Ovr_OvrRate,
	
	-- Inn 10+ with 2 Challenges Remaining
	SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 2 THEN 1 ELSE 0 END) AS Inn10_Chg2_Opp,
	SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) AS Inn10_Chg2_Made,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 2 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 2 THEN 1 ELSE 0 END), 0) AS Inn10_Chg2_Rate,
	SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn10_Chg2_Over,1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn10_Chg2_OvrRate,
	
	-- Inn 10+ with 1 Challenge Remaining
	SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 1 THEN 1 ELSE 0 END) AS Inn10_Chg1_Opp,
	SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) AS Inn10_Chg1_Made,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 1 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 1 THEN 1 ELSE 0 END), 0) AS Inn10_Chg1_Rate,
	SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS Inn10_Chg1_Over,
	1.0 * SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' AND b.teamChallengesLeft = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.inningSplit = 'Inn_10Plus' THEN b.hasABSChallenge ELSE 0 END), 0) AS Inn10_Chg1_OvrRate,

	 -- =========================================================================
    -- FASTBALL METRICS
    -- =========================================================================
    SUM(CASE WHEN b.PitchTypeGroup = 1 THEN 1 ELSE 0 END) AS FastBall_Opp,
    SUM(CASE WHEN b.PitchTypeGroup = 1 THEN b.hasABSChallenge ELSE 0 END) AS FastBall_Made,
    1.0 * SUM(CASE WHEN b.PitchTypeGroup = 1 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.PitchTypeGroup = 1 THEN 1 ELSE 0 END), 0) AS FastBall_Rate,
    SUM(CASE WHEN b.PitchTypeGroup = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS FastBall_Over,
    1.0 * SUM(CASE WHEN b.PitchTypeGroup = 1 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.PitchTypeGroup = 1 THEN b.hasABSChallenge ELSE 0 END), 0) AS FastBall_OvrRate,

     -- =========================================================================
    -- BREAKING BALL METRICS
    -- =========================================================================
    SUM(CASE WHEN b.PitchTypeGroup = 2 THEN 1 ELSE 0 END) AS BreakBall_Opp,
    SUM(CASE WHEN b.PitchTypeGroup = 2 THEN b.hasABSChallenge ELSE 0 END) AS BreakBall_Made,
    1.0 * SUM(CASE WHEN b.PitchTypeGroup = 2 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.PitchTypeGroup = 2 THEN 1 ELSE 0 END), 0) AS BreakBall_Rate,
    SUM(CASE WHEN b.PitchTypeGroup = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS BreakBall_Over,
    1.0 * SUM(CASE WHEN b.PitchTypeGroup = 2 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.PitchTypeGroup = 2 THEN b.hasABSChallenge ELSE 0 END), 0) AS BreakBall_OvrRate,

	 -- =========================================================================
    -- OTHER PITCH TYPE METRICS
    -- =========================================================================
    SUM(CASE WHEN b.PitchTypeGroup = 3 THEN 1 ELSE 0 END) AS OtherPitch_Opp,
    SUM(CASE WHEN b.PitchTypeGroup = 3 THEN b.hasABSChallenge ELSE 0 END) AS OtherPitch_Made,
    1.0 * SUM(CASE WHEN b.PitchTypeGroup = 3 THEN b.hasABSChallenge ELSE 0 END) / NULLIF(SUM(CASE WHEN b.PitchTypeGroup = 3 THEN 1 ELSE 0 END), 0) AS OtherPitch_Rate,
    SUM(CASE WHEN b.PitchTypeGroup = 3 AND b.isOverturned = 1 THEN 1 ELSE 0 END) AS OtherPitch_Over,
    1.0 * SUM(CASE WHEN b.PitchTypeGroup = 3 AND b.isOverturned = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN b.PitchTypeGroup = 3 THEN b.hasABSChallenge ELSE 0 END), 0) AS OtherPitch_OvrRate

FROM BatterChallengablePitches b
INNER JOIN MLBData..players p
    ON p.id = b.batterId
GROUP BY 
    b.batterId, 
    p.lastName, 
    p.firstName
HAVING SUM(b.hasABSChallenge) > 1;
