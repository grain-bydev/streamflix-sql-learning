-- ============================================================================
-- EXERCICE #4 - Segmentation multi-dimensionnelle (2D)
-- ============================================================================
-- Contexte: Segmenter les utilisateurs par profil ET engagement
-- Concepts: CTEs en cascade, CASE WHEN, multi-dimensional GROUP BY
-- ============================================================================

-- CTE 1: Calculer toutes les métriques des utilisateurs actifs
-- Cette CTE ne regroupe que les users qui ont au moins 1 session
WITH user_metrics AS (
  SELECT
    -- Identifiant de l'utilisateur
    user_id,
    
    -- Nombre de sessions pour cet utilisateur
    -- COUNT(DISTINCT session_id) pour éviter les doublons
    COUNT(DISTINCT session_id) AS total_sessions,
    
    -- Durée totale regardée par cet utilisateur
    -- SUM() agrège toutes les sessions de l'user
    SUM(watch_duration_minutes) AS total_duration,
    
    -- Taux de complétion moyen pour cet utilisateur
    -- Moyenne de tous ses taux de complétion
    AVG(completion_rate) AS avg_completion
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions`
    
  WHERE 
    -- Filtrer sur 90 derniers jours
    watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
    
  GROUP BY 
    user_id
),

-- CTE 2: Enrichir avec profil utilisateur + segmenter par engagement
user_engagement AS (
  SELECT
    -- Profil utilisateur (dimensions)
    u.age_group,
    u.device_type,
    
    -- Métriques de l'utilisateur
    m.total_sessions,
    m.total_duration,
    m.avg_completion,
    
    -- Segmentation d'engagement basée sur le nombre de sessions
    -- CASE WHEN: convertir un nombre en catégorie
    CASE
      -- Plus de 10 sessions = utilisateur actif
      WHEN m.total_sessions >= 10 THEN 'heavy'
      -- Entre 3 et 9 sessions = moyennement actif
      WHEN m.total_sessions >= 3 THEN 'medium'
      -- Sinon (1-2 sessions) = peu actif
      ELSE 'light'
    END AS engagement
    
  FROM 
    -- Joindre les métriques avec la table users
    user_metrics m
    
  -- INNER JOIN: garder seulement les users avec des sessions
  INNER JOIN 
    `ultra-airway-475009-m6.streamflix.users` u 
    USING (user_id)
)

-- SELECT final: Agréger par segment (age_group, device_type, engagement)
SELECT
  age_group,
  device_type,
  engagement,
  
  -- Nombre d'utilisateurs dans ce segment
  COUNT(*) AS nb_users,
  
  -- Durée moyenne de visionnage par utilisateur du segment
  -- AVG() fait la moyenne des total_duration sur tous les users du segment
  -- ROUND(..., 0) pour arrondir à 0 décimales (entier)
  ROUND(AVG(total_duration), 0) AS avg_duration_min,
  
  -- Taux de complétion moyen du segment
  -- AVG(avg_completion) = moyenne des moyennes (est-ce bon statistiquement?)
  -- * 100 pour convertir en pourcentage
  ROUND(AVG(avg_completion) * 100, 2) AS avg_completion_pct,
  
  -- Nombre moyen de sessions par utilisateur du segment
  -- AVG(total_sessions) = moyenne du nombre de sessions
  ROUND(AVG(total_sessions), 1) AS avg_sessions_per_user

FROM 
  user_engagement

GROUP BY 
  -- Grouper par les 3 dimensions: profil (2) + engagement (1)
  age_group, 
  device_type, 
  engagement

HAVING 
  -- Ne garder que les segments avec au moins 50 utilisateurs
  -- HAVING s'applique après GROUP BY, donc nb_users est disponible
  COUNT(*) >= 50

ORDER BY 
  -- Afficher les segments avec le plus d'utilisateurs en premier
  nb_users DESC
;

-- NOTE IMPORTANTE:
-- Cette requête inclut UNIQUEMENT les users ACTIFS (qui ont au least 1 session)
-- Si tu veux aussi les users INACTIFS (inscrits mais 0 session),
-- il faudrait faire un FULL OUTER JOIN users dans CTE 2 au lieu de INNER JOIN
