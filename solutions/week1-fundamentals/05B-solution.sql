-- ============================================================================
-- EXERCICE #5B - Cohorte de rétention (Cohort Analysis)
-- ============================================================================
-- Contexte: Analyser la rétention des utilisateurs inscrits en novembre 2024
-- Concepts: Cohortes, DATE_DIFF(), CTEs en cascade, rétention
-- ============================================================================

-- CTE 1: Identifier les utilisateurs inscrits en novembre 2024
WITH inscrits_nov AS (
  SELECT
    -- Identifiant de l'utilisateur
    user_id,  
    -- Date d'inscription (pour calculer l'écart)
    signup_date  
    
  FROM 
    `ultra-airway-475009-m6.streamflix.users`  
    
  WHERE 
    -- Filtrer uniquement novembre 2024 (01/11 à 30/11)
    signup_date >= "2024-11-01" 
    AND signup_date <= "2024-11-30"
),

-- CTE 2: Pour chaque utilisateur, calculer les semaines d'activité après inscription
activite_par_semaine AS (
  SELECT
    -- Identifiant de l'utilisateur
    user_id,    
    
    -- Calculer le nombre de semaines écoulées depuis l'inscription
    -- DATE_DIFF(date_plus_recente, date_plus_ancienne, WEEK) = écart en semaines
    -- vs.watch_date = date d'une session
    -- inn.signup_date = date d'inscription
    -- Résultat: 0 (même semaine), 1 (1 semaine après), 2, 3, ...
    DATE_DIFF(vs.watch_date, inn.signup_date, WEEK) AS week_since_signup  
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions` vs  
    
  JOIN 
    inscrits_nov inn
    USING (user_id)
    
  -- Note: Cette CTE ne retourne que les users ACTIFS (qui ont des sessions)
),

-- CTE 3: Compter les utilisateurs actifs par semaine (incluant semaine 0)
agregation AS (
  SELECT
    -- Semaine 0 = semaine d'inscription
    -- Ne pas filtrer sur viewing_sessions, utiliser directement inscrits_nov
    0 AS week_since_signup,  
    
    -- Tous les utilisateurs inscrits en novembre (que ce soit actifs ou non cette semaine)
    COUNT(DISTINCT user_id) AS active_users
    
  FROM 
    inscrits_nov
  
  UNION ALL
  
  -- Semaines 1+: Compter les utilisateurs actifs chaque semaine
  SELECT
    -- Semaine de l'activité
    week_since_signup,  
    
    -- Compter les utilisateurs uniques actifs cette semaine-là
    COUNT(DISTINCT user_id) AS active_users
    
  FROM 
    activite_par_semaine
    
  -- Limiter à 8 semaines max
  WHERE 
    week_since_signup BETWEEN 1 AND 8
    
  GROUP BY 
    week_since_signup
)

-- SELECT final: Calculer le taux de rétention
SELECT
  -- Semaine depuis inscription (0, 1, 2, ..., 8)
  week_since_signup,  
  
  -- Nombre d'utilisateurs actifs cette semaine
  active_users,
  
  -- Taux de rétention = active_users_week_n / active_users_week_0 * 100
  -- MAX(CASE WHEN week = 0 THEN active ELSE 0 END) OVER () = users à la semaine 0
  -- Diviser par ce maximum pour avoir la rétention
  ROUND(
    100 * active_users / 
    MAX(CASE WHEN week_since_signup = 0 THEN active_users ELSE 0 END) OVER (),
    2
  ) AS retention_rate

FROM 
  agregation

ORDER BY 
  week_since_signup ASC
;

-- NOTE SUR LA RÉTENTION:
-- - Semaine 0: 100% (tous les utilisateurs inscrits)
-- - Semaine 1: Par exemple 380/450 = 84.4% (84.4% des users originaux actifs la semaine 1)
-- - Semaine 2: Par exemple 325/450 = 72.2% (72.2% des users originaux actifs la semaine 2)
-- 
-- Cela montre si les utilisateurs restent engagés après leur inscription.
