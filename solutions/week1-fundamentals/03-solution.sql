-- ============================================================================
-- EXERCICE #3 - Analyse temporelle et croissance MoM
-- ============================================================================
-- Contexte: Suivre l'évolution mensuelle des signups, activité et sessions
-- Concepts: CTEs, FORMAT_DATE(), DATE_TRUNC(), LAG() window function
-- ============================================================================

-- CTE 1: Calculer les nouveaux utilisateurs inscrits chaque mois
WITH signups AS (
  SELECT
    -- Formater la date en YYYY-MM pour grouper par mois
    -- FORMAT_DATE('%Y-%m', date) retourne une string du type "2025-07"
    FORMAT_DATE("%Y-%m", signup_date) AS month,
    
    -- Compter les utilisateurs uniques inscrits ce mois-ci
    COUNT(DISTINCT user_id) AS new_users
    
  FROM 
    `ultra-airway-475009-m6.streamflix.users`
    
  WHERE 
    -- DATE_TRUNC() arrondit la date au mois entier
    -- DATE_SUB(..., INTERVAL 6 MONTH) = 6 mois avant la date de référence
    -- Plage: 2025-07-01 à 2025-12-31
    signup_date >= DATE_TRUNC(
      DATE_SUB(DATE('2025-12-31'), INTERVAL 6 MONTH), MONTH)  
    AND signup_date < DATE_TRUNC(DATE('2025-12-31'), MONTH)
    
  GROUP BY 
    month
),

-- CTE 2: Calculer l'activité (utilisateurs actifs et sessions) chaque mois
activity AS (
  SELECT
    -- Formater le mois
    FORMAT_DATE("%Y-%m", watch_date) AS month,
    
    -- Compter les utilisateurs uniques actifs ce mois-ci
    COUNT(DISTINCT user_id) AS active_users,
    
    -- Compter les sessions ce mois-ci
    COUNT(DISTINCT session_id) AS total_sessions  
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions`
    
  WHERE      
    -- Même plage temporelle que CTE 1
    watch_date >= DATE_TRUNC(        
      DATE_SUB(DATE('2025-12-31'), INTERVAL 6 MONTH), MONTH)      
    AND watch_date < DATE_TRUNC(DATE('2025-12-31'), MONTH)
    
  GROUP BY 
    month
)

-- SELECT final: Joindre les CTEs et calculer la croissance
SELECT 
  a.month AS months,  
  
  -- Utiliser IFNULL pour remplacer les NULL (mois sans signups)
  -- Si s.new_users est NULL, afficher 0
  IFNULL(s.new_users, 0) AS new_users,  
  
  -- Utilisateurs actifs ce mois-ci (toujours dans activity)
  a.active_users,  
  
  -- Nombre total de sessions ce mois-ci
  a.total_sessions,  
  
  -- Calculer la croissance MoM (Month-over-Month)
  -- LAG(colonne) OVER (ORDER BY ...) = valeur de la ligne précédente
  -- En l'occurrence: sessions du mois précédent
  -- Formule: (sessions_mois_n - sessions_mois_n-1) / sessions_mois_n-1 * 100
  ROUND(
    (a.total_sessions - LAG(a.total_sessions) OVER (ORDER BY a.month)) / 
    LAG(a.total_sessions) OVER (ORDER BY a.month) * 100,    
    2
  ) AS growth_mom_pct

FROM 
  -- OUTER JOIN pour garder tous les mois (même sans signups)
  activity a

LEFT JOIN 
  signups s
  USING (month)

ORDER BY 
  -- Afficher le plus récent en premier
  months DESC
;

-- NOTE: LAG(a.total_sessions) OVER (ORDER BY a.month)
-- - Premier mois: LAG = NULL, donc growth_mom_pct = NULL (normal, pas de comparaison)
-- - Autres mois: LAG = sessions du mois précédent
-- - ORDER BY month assure le classement chronologique pour LAG
