-- ============================================================================
-- EXERCICE #7 - Métriques de churn et engagement cumulatif
-- ============================================================================
-- Contexte: Identifier les utilisateurs à risque (inactifs depuis longtemps)
-- Concepts: CTEs pour comparaison périodes, CASE WHEN imbriqué, DATE_DIFF
-- ============================================================================

-- CTE 1: Calculer les métriques globales sur 180 jours
WITH global_metrics AS (
  SELECT
    -- Identifiant utilisateur
    user_id,
    
    -- Métrique 1: Nombre total de sessions
    COUNT(DISTINCT session_id) AS total_sessions,
    
    -- Métrique 2: Durée totale en heures
    ROUND(SUM(watch_duration_minutes) / 60, 1) AS total_hours,
    
    -- Métrique 3: Taux de complétion moyen en %
    ROUND(AVG(completion_rate) * 100, 2) AS avg_completion_pct,
    
    -- Métrique 4: Dernière date active (plus récente session)
    MAX(watch_date) AS last_active_date
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions`
    
  WHERE 
    -- Filtrer sur 180 derniers jours
    watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 180 DAY)
    
  GROUP BY 
    user_id
),

-- CTE 2: Calculer l'engagement du premier mois
first_month AS (
  SELECT
    -- Identifiant utilisateur
    user_id,
    
    -- Durée du premier mois (pour comparer tendance)
    SUM(watch_duration_minutes) AS first_month_duration
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions`
    
  WHERE 
    -- Premier mois = 30 jours après le début de la période 180j
    watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 180 DAY)
    AND watch_date <= DATE_ADD(
      DATE_SUB(DATE('2025-12-31'), INTERVAL 180 DAY), 
      INTERVAL 30 DAY
    )
    
  GROUP BY 
    user_id
),

-- CTE 3: Calculer l'engagement du dernier mois
last_month AS (
  SELECT
    -- Identifiant utilisateur
    user_id,
    
    -- Durée du dernier mois (pour comparer tendance)
    SUM(watch_duration_minutes) AS last_month_duration
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions`
    
  WHERE 
    -- Dernier mois = les 30 derniers jours
    watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 30 DAY)
    
  GROUP BY 
    user_id
)

-- SELECT final: Agréger et calculer risque churn
SELECT
  -- Identifiants et profil utilisateur
  gm.user_id,
  u.country,
  u.age_group,
  
  -- Métriques globales
  gm.total_sessions,
  gm.total_hours,
  gm.avg_completion_pct,
  gm.last_active_date,
  
  -- Métrique 5: Jours écoulés sans activité
  -- DATE_DIFF(date_fin, date_début, DAY) = écart en jours
  -- Plus la valeur est grande, plus l'utilisateur est inactif
  DATE_DIFF(DATE('2025-12-31'), gm.last_active_date, DAY) AS days_since_last_activity,
  
  -- Métrique 6: Tendance d'engagement
  -- Comparer premier mois vs dernier mois
  -- CASE WHEN imbriqué pour gérer les NULL
  CASE
    -- Si dernier mois > premier mois: engagement augmente
    WHEN fm.first_month_duration IS NOT NULL 
      AND lm.last_month_duration IS NOT NULL 
      AND fm.first_month_duration < lm.last_month_duration THEN 'increasing'
    -- Si dernier mois < premier mois: engagement diminue
    WHEN fm.first_month_duration IS NOT NULL 
      AND lm.last_month_duration IS NOT NULL 
      AND fm.first_month_duration > lm.last_month_duration THEN 'decreasing'
    -- Sinon: engagement stable
    ELSE 'stable'
  END AS engagement_trend,
  
  -- Métrique 7: Score de risque churn
  -- Basé sur l'inactivité
  CASE
    -- Inactif depuis > 30 jours = risque ÉLEVÉ
    WHEN DATE_DIFF(DATE('2025-12-31'), gm.last_active_date, DAY) > 30 THEN 'HIGH'
    -- Inactif depuis > 14 jours = risque MOYEN
    WHEN DATE_DIFF(DATE('2025-12-31'), gm.last_active_date, DAY) > 14 THEN 'MEDIUM'
    -- Inactif depuis <= 14 jours = risque FAIBLE
    ELSE 'LOW'
  END AS churn_risk

FROM 
  global_metrics gm

-- Joindre avec les CTEs pour comparer périodes
LEFT JOIN 
  first_month fm 
  USING (user_id)

LEFT JOIN 
  last_month lm 
  USING (user_id)

-- Joindre avec users pour avoir le profil (country, age_group)
JOIN 
  `ultra-airway-475009-m6.streamflix.users` u 
  USING (user_id)

-- Trier par inactivité décroissante (utilisateurs à risque en premier)
ORDER BY 
  days_since_last_activity DESC

LIMIT 
  100
;

-- NOTES:
-- 1. Les CTEs first_month et last_month peuvent avoir des NULL si l'user
--    n'a pas d'activité sur la période (rare, puisque global_metrics les filtre)
--
-- 2. LEFT JOIN car un user peut ne pas avoir d'activité en première ou dernière période
--
-- 3. Tendance 'stable' capture aussi les cas NULL ou égalité
