-- ============================================================================
-- EXERCICE #9 - Analyse de fidélisation : évolution du temps de visionnage
-- ============================================================================
-- Contexte: Suivre comment l'engagement évolue mois après mois pour chaque user
-- Concepts: LAG() pour comparaison temporelle, FORMAT_DATE(), NULLIF()
-- ============================================================================

-- CTE 1: Calculer le visionnage total par mois par utilisateur
WITH monthly_view AS (
  SELECT
    -- Identifiant utilisateur
    user_id,
    
    -- Mois au format YYYY-MM (ex: '2025-10')
    FORMAT_DATE('%Y-%m', watch_date) AS view_month,
    
    -- Nombre de sessions ce mois-ci
    COUNT(session_id) AS nb_sessions,
    
    -- Durée totale regardée ce mois-ci
    SUM(watch_duration_minutes) AS total_view_n  -- "n" = mois courant
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions`
    
  WHERE
    -- Filtrer sur 6 derniers mois
    watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 6 MONTH)
    
  GROUP BY 
    user_id, 
    view_month
),

-- CTE 2: Ajouter le mois précédent via LAG()
mois_n_1 AS (
  SELECT 
    *,
    
    -- LAG(colonne) OVER (PARTITION BY ... ORDER BY ...) = valeur de la ligne précédente
    -- Récupère la durée du mois précédent pour le même utilisateur
    LAG(total_view_n) OVER (
      PARTITION BY user_id
      ORDER BY view_month
    ) AS total_view_n_1  -- "n_1" = mois précédent
    
  FROM 
    monthly_view
),

-- CTE 3: Calculer l'évolution entre le mois courant et le précédent
evolution AS (
  SELECT
    *,
    
    -- Différence en minutes: mois_courant - mois_précédent
    -- Peut être positif (augmentation) ou négatif (diminution)
    -- NULL si c'est le premier mois (pas de précédent)
    total_view_n - total_view_n_1 AS duration_diff,
    
    -- Pourcentage d'évolution: (courant - précédent) / précédent * 100
    -- NULLIF(total_view_n_1, 0) = éviter division par zéro
    -- Si total_view_n_1 = 0, retourner NULL au lieu de l'infini
    ROUND(
      100 * (total_view_n - total_view_n_1) / 
      NULLIF(total_view_n_1, 0), 
      1
    ) AS duration_pct
    
  FROM 
    mois_n_1
),

-- CTE 4: Identifier les utilisateurs avec au moins 2 mois d'activité
users_2_months AS (
  SELECT 
    user_id
  FROM 
    monthly_view
  GROUP BY 
    user_id
  HAVING 
    -- Compter le nombre de mois distincts avec activité
    COUNT(DISTINCT view_month) >= 2
)

-- SELECT final
SELECT
  -- Identifiant utilisateur
  u2m.user_id,
  
  -- Profil utilisateur (enrichir de la table users)
  us.country, 
  us.age_group,
  
  -- Temporalité
  ev.view_month AS mois,
  
  -- Métriques du mois courant
  ev.nb_sessions,
  ev.total_view_n AS temps_total_minutes,
  
  -- Métrique du mois précédent (pour référence)
  ev.total_view_n_1 AS temps_mois_precedent,
  
  -- Évolution (comparaison)
  ev.duration_diff AS evolution_minutes,
  ev.duration_pct AS evolution_pourcent

FROM
  -- Joindre avec la CTE des users_2_months
  `ultra-airway-475009-m6.streamflix.users` us

INNER JOIN 
  users_2_months u2m 
  USING (user_id)

-- Joindre avec les évolutions
INNER JOIN
  evolution ev
  USING (user_id)

ORDER BY 
  -- Trier par user, puis chronologiquement
  ev.user_id,
  ev.view_month
;

-- NOTES IMPORTANTES:
--
-- 1. LAG() retourne NULL pour la première ligne (pas de précédent)
--    -> evolution_minutes et evolution_pourcent seront NULL pour le premier mois
--    -> C'est normal et prévu
--
-- 2. NULLIF(total_view_n_1, 0):
--    - Si total_view_n_1 = 0 (pas regardé le mois précédent), retourner NULL
--    - Sinon, utiliser la vraie valeur
--    - Évite une division par zéro qui causerait une erreur
--
-- 3. PARTITION BY user_id dans LAG():
--    - Assure que chaque utilisateur est comparé à lui-même seulement
--    - Sans ça, les données de users différents se mélangent
--
-- 4. ORDER BY view_month dans LAG():
--    - Assure l'ordre chronologique pour la comparaison
--    - "Précédent" = mois chronologiquement avant
--
-- 5. Exemple de résultat:
--    user_001, 2025-07: 480 min, NULL prev, NULL diff, NULL %  (premier mois)
--    user_001, 2025-08: 620 min, 480 prev, +140 diff, +29.2 %
--    user_001, 2025-09: 380 min, 620 prev, -240 diff, -38.7 %
