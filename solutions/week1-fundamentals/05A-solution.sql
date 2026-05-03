-- ============================================================================
-- EXERCICE #5A - Top contenus avec Window Functions (RANK)
-- ============================================================================
-- Contexte: Identifier les 20 contenus les plus populaires avec rankings
-- Concepts: Agrégations, RANK() window function, jointures
-- ============================================================================

-- CTE: Agréger les métriques par contenu
WITH agg AS (
  SELECT
    -- Identifiant du contenu (pour joindre avec la table content)
    vs.content_id,  
    
    -- Métrique 1: Nombre total de visionnages
    -- COUNT(session_id) = compter chaque session
    COUNT(vs.session_id) AS total_views,  
    
    -- Métrique 2: Nombre d'utilisateurs uniques
    -- COUNT(DISTINCT user_id) pour éviter les doublons
    COUNT(DISTINCT vs.user_id) AS nbr_viewers,  
    
    -- Métrique 3: Durée moyenne de visionnage
    -- AVG(watch_duration_minutes) = moyenne sur toutes les sessions
    -- ROUND(..., 2) pour 2 décimales
    ROUND(AVG(vs.watch_duration_minutes), 2) AS avg_duration_min,  
    
    -- Métrique 4: Taux de complétion moyen
    -- AVG(completion_rate) retourne une valeur 0-1
    -- Ne pas multiplier par 100 ici (pas de % dans les métriques brutes)
    ROUND(AVG(vs.completion_rate), 2) AS avg_completion
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions` vs
    
  WHERE 
    -- Filtrer sur 30 derniers jours
    watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 30 DAY)
    
  GROUP BY 
    content_id
    
  -- Filtrer les contenus avec < 20 visionnages
  HAVING 
    COUNT(vs.session_id) >= 20
)

-- SELECT final: Joindre avec content + ajouter les rankings
SELECT
  -- Informations du contenu
  c.title,
  c.content_type,
  c.genre,
  
  -- Métriques agrégées
  agg.total_views,
  agg.nbr_viewers,
  agg.avg_duration_min,
  agg.avg_completion,
  
  -- RANKING 1: Classement par nombre de visionnages
  -- RANK() OVER (ORDER BY colonne DESC) = numéro de classement
  -- ORDER BY total_views DESC = classement décroissant (1 = plus vues)
  -- RANK() gère les ex-aequo (deux contenus avec même nb de vues = même rang)
  RANK() OVER(ORDER BY agg.total_views DESC) AS rank_views,
  
  -- RANKING 2: Classement par taux de complétion
  -- Même logique, mais sur le taux de complétion (plus élevé = mieux)
  RANK() OVER(ORDER BY agg.avg_completion DESC) AS rank_completion

FROM 
  agg

-- Joindre avec la table content pour avoir les infos (title, genre, etc.)
JOIN 
  `ultra-airway-475009-m6.streamflix.content` c
  USING (content_id)

ORDER BY 
  -- Afficher en premier les contenus avec le plus de visionnages
  agg.total_views DESC

LIMIT 
  -- Limiter à 20 résultats
  20
;

-- NOTE SUR RANK() vs ROW_NUMBER():
-- - RANK(): Si deux contenus ont 100 vues, tous deux reçoivent rank=1, le suivant reçoit rank=3
-- - ROW_NUMBER(): Chaque ligne reçoit un numéro unique (1, 2, 3, 4, ...), sans ex-aequo
-- Pour ce use-case, RANK() est plus approprié
