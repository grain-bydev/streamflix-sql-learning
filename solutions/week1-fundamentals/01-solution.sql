-- ============================================================================
-- EXERCICE #1 - Métriques d'engagement de base
-- ============================================================================
-- Contexte: Calculer les 4 KPI clés pour les 30 derniers jours
-- Concepts: Agrégations simples, COUNT DISTINCT, ROUND()
-- ============================================================================

SELECT
  -- KPI 1: Nombre total de sessions (ne pas utiliser DISTINCT ici)
  -- On compte chaque session une fois
  COUNT(DISTINCT session_id) AS total_sessions,
  
  -- KPI 2: Durée moyenne de visionnage par session
  -- AVG() va automatialement ignorer les NULL
  -- Arrondir à 2 décimales pour lisibilité
  ROUND(AVG(watch_duration_minutes), 2) AS average_duration,
  
  -- KPI 3: Taux de complétion moyen en pourcentage
  -- completion_rate est entre 0 et 1, multiplier par 100 pour avoir %
  -- Arrondir à 2 décimales
  ROUND(AVG(completion_rate) * 100, 2) AS avg_pct_completion,
  
  -- KPI 4: Nombre d'utilisateurs actifs uniques
  -- DISTINCT sur user_id pour éviter les doublons
  -- (un user peut avoir plusieurs sessions)
  COUNT(DISTINCT user_id) AS active_users

FROM 
  -- Table des sessions de visionnage
  `ultra-airway-475009-m6.streamflix.viewing_sessions`

WHERE 
  -- Filtrer sur les 30 derniers jours
  -- DATE('2025-12-31') = date de référence
  -- DATE_SUB(..., INTERVAL 30 DAY) = 30 jours avant
  -- >= pour inclure le jour de début
  watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 30 DAY)
  
-- Pas de GROUP BY: on agrège sur tout le dataset
-- Pas de ORDER BY: un seul résultat
;
