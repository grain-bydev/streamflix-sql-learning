-- ============================================================================
-- EXERCICE #6 - Suivi du parcours utilisateur temporel
-- ============================================================================
-- Contexte: Analyser le parcours jour après jour de chaque utilisateur
-- Concepts: LAG() avancé, SUM() OVER, PARTITION BY, jointures multiples
-- ============================================================================

WITH sessions_with_content AS (
  SELECT
    -- Identifiants
    vs.user_id,
    vs.watch_date,
    vs.session_id,
    
    -- Titre du contenu regardé dans cette session
    c.title AS current_title,
    
    -- Taux de complétion de cette session
    vs.completion_rate,
    
    -- Nombre de sessions le même jour (peut être > 1)
    -- COUNT() OVER (PARTITION BY user_id, watch_date) = compter les sessions du jour
    COUNT(vs.session_id) OVER (
      PARTITION BY vs.user_id, vs.watch_date
    ) AS sessions_today,
    
    -- Contenu de la session précédente (jour ou heure?)
    -- LAG(c.title) OVER (... ORDER BY watch_date, session_id)
    -- = titre du contenu regardé juste avant
    -- NULL si c'est la première session
    LAG(c.title) OVER (
      PARTITION BY vs.user_id 
      ORDER BY vs.watch_date, vs.session_id
    ) AS prev_title,
    
    -- Date de la session précédente
    LAG(vs.watch_date) OVER (
      PARTITION BY vs.user_id 
      ORDER BY vs.watch_date, vs.session_id
    ) AS prev_date,
    
    -- Cumul du nombre de sessions depuis le début
    -- SUM(1) OVER (... ORDER BY ...) crée un compteur cumulatif
    -- Chaque ligne ajoute 1 au total précédent
    SUM(1) OVER (
      PARTITION BY vs.user_id 
      ORDER BY vs.watch_date, vs.session_id
    ) AS cumulative_sessions
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions` vs
    
  JOIN 
    `ultra-airway-475009-m6.streamflix.content` c 
    USING (content_id)
    
  WHERE 
    -- Filtrer sur 90 derniers jours
    vs.watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
),

-- CTE 2: Identifier les 100 utilisateurs avec le plus de sessions
user_session_count AS (
  SELECT 
    user_id, 
    COUNT(*) AS total_sessions
    
  FROM 
    sessions_with_content
    
  GROUP BY 
    user_id
    
  ORDER BY 
    total_sessions DESC
    
  LIMIT 
    100
)

-- SELECT final
SELECT
  -- Identifiant et profil de l'utilisateur
  u.user_id,
  u.country,
  
  -- Dimension temporelle
  swc.watch_date,
  swc.sessions_today,
  
  -- Contenu regardé
  swc.current_title,
  
  -- Contenu précédent (navigation)
  swc.prev_title,
  
  -- Intervalle depuis la dernière session
  -- DATE_DIFF(date_actuelle, date_précédente, DAY) = écart en jours
  -- NULL si c'est la première session (prev_date = NULL)
  DATE_DIFF(swc.watch_date, swc.prev_date, DAY) AS days_since_last_session,
  
  -- Engagement de la session actuelle
  swc.completion_rate,
  
  -- Cumul des sessions
  swc.cumulative_sessions
  
FROM 
  sessions_with_content swc
  
-- Joindre avec la CTE des top 100 utilisateurs
JOIN 
  user_session_count usc 
  USING (user_id)
  
-- Joindre avec la table users pour avoir le pays
JOIN 
  `ultra-airway-475009-m6.streamflix.users` u 
  USING (user_id)

ORDER BY 
  swc.user_id, 
  swc.watch_date
;

-- NOTES IMPORTANTES:
-- 
-- 1. LAG() nécessite:
--    - PARTITION BY: pour isoler chaque utilisateur
--    - ORDER BY: pour définir l'ordre chronologique
--    - ORDER BY doit être sur watch_date ET session_id pour les sessions du même jour
--
-- 2. SUM(1) OVER (... ORDER BY ...) crée un cumul:
--    Session 1: 1
--    Session 2: 1+1 = 2
--    Session 3: 2+1 = 3
--    ...
--
-- 3. COUNT() OVER (PARTITION BY user_id, watch_date) compte les sessions du même jour
--    Utile pour voir si l'utilisateur a regardé plusieurs contenus ce jour-là
--
-- 4. Première session:
--    - prev_title = NULL
--    - prev_date = NULL
--    - days_since_last_session = NULL
