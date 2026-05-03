-- ============================================================================
-- EXERCICE #8 - Segmentation multi-niveaux par contenu
-- ============================================================================
-- Contexte: Identifier les profils d'users par préférence de contenu
-- Concepts: ROW_NUMBER() window function, jointures en cascade, multi-dim GROUP BY
-- ============================================================================

-- CTE 1: Compter les visionnages par content_type pour chaque utilisateur
WITH content_counts AS (
  SELECT
    -- Identifiant utilisateur
    vw.user_id,
    
    -- Type de contenu (movie ou series)
    c.content_type,
    
    -- Compter le nombre de sessions pour ce type de contenu
    COUNT(vw.session_id) AS nb_sessions,
    
    -- ROW_NUMBER() pour classer les content_types par user
    -- ORDER BY nb_sessions DESC = classement par popularité (DESC)
    -- ORDER BY c.content_type ASC = en cas d'égalité, 'movie' avant 'series' (ASC)
    -- Résultat: ct_rank=1 pour le top 1 (préféré), 2 pour le deuxième, etc.
    ROW_NUMBER() OVER (
      PARTITION BY vw.user_id
      ORDER BY COUNT(vw.session_id) DESC, c.content_type ASC
    ) AS ct_rank
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions` AS vw
    
  JOIN 
    `ultra-airway-475009-m6.streamflix.content` AS c
    USING (content_id)
    
  WHERE
    -- Filtrer sur 90 derniers jours
    vw.watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
    
  GROUP BY 
    vw.user_id, 
    c.content_type
),

-- CTE 2: Extraire seulement le type de contenu préféré (ct_rank = 1)
preferred_content AS (
  SELECT 
    *
  FROM 
    content_counts
  WHERE 
    -- Garder uniquement la première ligne par user (le type préféré)
    ct_rank = 1
),

-- CTE 3: Calculer toutes les métriques pour chaque utilisateur
metrics AS (
  SELECT
    -- Identifiants
    vw.user_id,
    u.country,
    u.device_type,
    
    -- Métrique 1: Nombre total de sessions
    COUNT(vw.session_id) AS total_sessions,
    
    -- Métrique 2: Durée moyenne par session
    AVG(vw.watch_duration_minutes) AS avg_duration_session,
    
    -- Métrique 3: Taux de complétion moyen
    AVG(completion_rate) AS avg_completion
    
  FROM
    `ultra-airway-475009-m6.streamflix.viewing_sessions` vw
    
  JOIN 
    `ultra-airway-475009-m6.streamflix.users` u
    USING (user_id)
    
  WHERE
    -- Filtrer sur 90 derniers jours
    vw.watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
    
  GROUP BY 
    vw.user_id,
    u.country,
    u.device_type 
),

-- CTE 4: Ajouter la segmentation d'engagement
user_engagement AS (
  SELECT
    -- Toutes les colonnes de metrics
    *,
    
    -- Segmenter par nombre de sessions
    -- CASE WHEN pour convertir nombre en catégorie
    CASE
      -- >= 15 sessions = utilisateur très actif
      WHEN total_sessions >= 15 THEN 'heavy'
      -- 5-14 sessions = moyennement actif
      WHEN total_sessions >= 5 THEN 'medium'
      -- 1-4 sessions = peu actif
      ELSE 'light'
    END AS engagement
    
  FROM 
    metrics
)

-- SELECT final: Agréger par segment (3 dimensions: country, device_type, content_type + 1: engagement)
SELECT
  -- Dimensions du segment
  ue.country,
  ue.device_type,
  pc.content_type,  -- Type de contenu préféré (ajouté par la jointure)
  ue.engagement,
  
  -- Métrique 1: Nombre d'utilisateurs dans ce segment
  COUNT(ue.user_id) AS nb_users,
  
  -- Métrique 2: Nombre total de sessions du segment
  -- SUM(total_sessions) = somme des sessions de tous les users du segment
  SUM(ue.total_sessions) AS total_sessions,
  
  -- Métrique 3: Durée moyenne par session (moyenne des moyennes)
  -- AVG(avg_duration_session) = moyenne des durées moyennes des users
  ROUND(AVG(ue.avg_duration_session), 1) AS avg_duration_session,
  
  -- Métrique 4: Taux de complétion moyen en %
  -- AVG(avg_completion) * 100 = convertir en pourcentage
  ROUND(AVG(ue.avg_completion) * 100, 2) AS avg_completion

FROM 
  -- Joindre user_engagement avec preferred_content pour avoir le content_type
  user_engagement ue
  
JOIN
  preferred_content pc
  USING (user_id)

-- Grouper par toutes les dimensions
GROUP BY 
  ue.country,
  ue.device_type,
  pc.content_type,  -- Doit être dans le GROUP BY
  ue.engagement

-- Filtrer après agrégation: segments avec >= 30 utilisateurs
HAVING 
  COUNT(ue.user_id) >= 30

-- Trier par nombre d'utilisateurs décroissant
ORDER BY 
  nb_users DESC

-- Limiter aux 20 premiers segments
LIMIT 20
;

-- NOTES IMPORTANTES:
--
-- 1. ROW_NUMBER() vs RANK():
--    - ROW_NUMBER(): Chaque ligne reçoit un numéro unique (1, 2, 3, ...)
--    - RANK(): Les ex-aequo reçoivent le même rang
--    Pour ce use-case, ROW_NUMBER() est correct
--
-- 2. ORDER BY dans ROW_NUMBER():
--    - COUNT DESC = classer par popularité (plus de sessions = mieux)
--    - content_type ASC = en cas d'égalité, 'movie' avant 'series'
--
-- 3. JOIN preferred_content USING (user_id):
--    - Retrouve le content_type préféré de chaque user
--    - Chaque user a exactement 1 ligne dans preferred_content
