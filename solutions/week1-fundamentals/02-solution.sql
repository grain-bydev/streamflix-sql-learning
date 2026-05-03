-- ============================================================================
-- EXERCICE #2 - KPI de performance par pays
-- ============================================================================
-- Contexte: Analyser les performances par géographie
-- Concepts: Jointures, GROUP BY, HAVING, conversions d'unités
-- ============================================================================

SELECT
  -- Dimension: Pays
  u.country,
  
  -- Métrique 1: Utilisateurs actifs uniques par pays
  -- Compter DISTINCT user_id pour éviter les doublons
  -- (un user peut avoir plusieurs sessions)
  COUNT(DISTINCT user_id) AS active_users,
  
  -- Métrique 2: Durée totale en heures
  -- SUM(watch_duration_minutes) = total en minutes
  -- / 60 = conversion en heures
  -- ROUND(..., 1) = arrondir à 1 décimale
  ROUND(SUM(vs.watch_duration_minutes) / 60, 1) AS total_duration_hours,
  
  -- Métrique 3: Durée moyenne par utilisateur (en minutes)
  -- SUM(watch_duration_minutes) / COUNT(DISTINCT user_id)
  -- = total minutes / nombre d'utilisateurs
  -- Ne pas faire SUM()/COUNT() car SUM compte toutes les lignes, pas les users
  ROUND(SUM(vs.watch_duration_minutes) / COUNT(DISTINCT user_id), 0) AS avg_duration_user,
  
  -- Métrique 4: Taux de complétion moyen en pourcentage
  -- AVG(completion_rate) = moyenne entre 0 et 1
  -- * 100 = conversion en pourcentage
  -- ROUND(..., 2) = 2 décimales
  ROUND(AVG(vs.completion_rate) * 100, 2) AS avg_pct_completion

FROM 
  -- Table des sessions
  `ultra-airway-475009-m6.streamflix.viewing_sessions` vs

-- Jointure avec la table users pour récupérer le country
-- USING (user_id) = condition de jointure implicite sur user_id
JOIN 
  `ultra-airway-475009-m6.streamflix.users` u
  USING (user_id)

WHERE
  -- Filtrer sur 90 derniers jours
  -- La date de référence est 2025-12-31
  -- 90 jours avant = 2025-10-02
  vs.watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)

-- Grouper par dimension (pays)
-- Chaque ligne du résultat représente un pays
GROUP BY 
  u.country

-- Filtrer après agrégation: garder uniquement pays avec >= 500 users
-- HAVING s'applique aux agrégats (COUNT, SUM, AVG, etc.)
-- WHERE s'applique avant agrégation
HAVING 
  COUNT(DISTINCT user_id) >= 500

-- Ordonner par durée totale décroissante
-- Voir d'abord les pays avec le plus de visionnage
ORDER BY 
  total_duration_hours DESC
;
