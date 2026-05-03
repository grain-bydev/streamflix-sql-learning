-- ============================================================================
-- EXERCICE #10 - Analyse des schémas de consommation et régularité
-- ============================================================================
-- Contexte: Analyser les patterns de visionnage (régularité, pauses)
-- Concepts: DISTINCT avant window fn, LAG() sur dates, STDDEV(), COUNTIF()
-- ============================================================================

-- CTE 1: Dedoublonner les sessions par jour
-- Important: Traiter plusieurs sessions le même jour comme UNE seule session
WITH dedoublon AS (
  SELECT
    -- Identifiant unique: user_id + watch_date
    DISTINCT
    user_id,
    watch_date
    
  FROM 
    `ultra-airway-475009-m6.streamflix.viewing_sessions`
    
  WHERE
    -- Filtrer sur 90 derniers jours
    watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
    AND watch_date <= DATE('2025-12-31')
),

-- CTE 2: Calculer les intervalles entre sessions consécutives
intervalle AS (
  SELECT
    -- Identifiant utilisateur
    user_id,
    
    -- Date de visionnage (unique par jour)
    watch_date,
    
    -- Intervalle en jours depuis la session précédente
    -- DATE_DIFF(date_actuelle, date_précédente, DAY) = écart en jours
    -- LAG(watch_date) retourne la date de la session précédente (ordre chronologique)
    -- NULL si c'est la première session
    DATE_DIFF(
      watch_date, 
      LAG(watch_date) 
        OVER (
          PARTITION BY user_id
          ORDER BY watch_date
        ), 
      DAY
    ) AS intervalle_prec
    
  FROM 
    dedoublon
)

-- SELECT final: Agréger les intervalles par utilisateur
SELECT 
  -- Identifiant utilisateur
  user_id,
  
  -- Métrique 1: Nombre total de sessions (jours actifs)
  COUNT(DISTINCT watch_date) AS nb_sessions,
  
  -- Métrique 2: Intervalle moyen en jours
  -- AVG() ignore automatiquement les NULL (première session)
  -- Représente la régularité globale
  ROUND(AVG(intervalle_prec), 2) AS avg_interval_days,
  
  -- Métrique 3: Intervalle minimum en jours
  -- MIN() ignore aussi les NULL
  -- Représente la plus courte pause entre deux sessions
  MIN(intervalle_prec) AS min_interval,
  
  -- Métrique 4: Intervalle maximum en jours
  -- MAX() ignore aussi les NULL
  -- Représente la plus longue pause entre deux sessions
  MAX(intervalle_prec) AS max_interval,
  
  -- Métrique 5: Écart-type des intervalles
  -- STDDEV() mesure la variabilité des intervalles
  -- Bas = régularité (sessions espacées uniformément)
  -- Haut = irrégularité (mélange de sessions rapides et pauses longues)
  ROUND(STDDEV(intervalle_prec), 2) AS stddev_interval,
  
  -- Métrique 6: Nombre de longues pauses (> 14 jours)
  -- COUNTIF(condition) = compter les lignes satisfaisant la condition
  -- Représente les pauses d'au moins 2 semaines
  COUNTIF(intervalle_prec >= 14) AS nb_longues_pauses

FROM 
  intervalle

GROUP BY 
  user_id

HAVING 
  -- Filtrer: garder uniquement les users avec >= 3 sessions
  -- COUNT(*) compte les lignes de intervalle (= nb de sessions - 1 car LAG crée un NULL)
  -- Donc COUNT(*) >= 3 signifie >= 3 sessions
  -- Plus précisément: >= 3 intervalles mesurables
  COUNT(*) >= 3

ORDER BY 
  -- Trier par:
  -- 1. Nombre de sessions (décroissant) = users les plus actifs en premier
  -- 2. Intervalle moyen (croissant) = among same nb sessions, most regular in first
  nb_sessions DESC,
  avg_interval_days ASC

LIMIT 
  50
;

-- NOTES IMPORTANTES:
--
-- 1. DISTINCT sur (user_id, watch_date):
--    - Dedoublonne les sessions du même jour
--    - Plusieurs sessions le même jour = 1 seule ligne
--    - Date = repère temporel, pas session_id
--
-- 2. LAG(watch_date) retourne la date précédente:
--    - DATE_DIFF(current, previous, DAY) = écart en jours
--    - Première session: LAG = NULL, DATE_DIFF = NULL
--    - Deuxième session: LAG = date de première, DATE_DIFF = nombre de jours
--
-- 3. PARTITION BY user_id:
--    - Assure que chaque user est isolé
--    - Les intervalles ne se mélangent pas entre users
--
-- 4. ORDER BY watch_date:
--    - Assure l'ordre chronologique pour LAG
--    - "Précédent" = date chronologiquement avant
--
-- 5. AVG(), MIN(), MAX(), STDDEV() ignorent les NULL:
--    - Même si LAG crée un NULL pour la première session
--    - Les agrégats ne l'incluent pas dans les calculs
--
-- 6. COUNTIF(intervalle_prec >= 14):
--    - Compte les intervalles de 14 jours ou plus
--    - Ignore les NULL (première session)
--    - Représente les pauses longues (abandon temporal)
--
-- 7. HAVING COUNT(*) >= 3:
--    - COUNT(*) = nombre de lignes dans intervalle
--    - = nombre de sessions - 1 (car première session crée NULL)
--    - >= 3 signifie >= 4 sessions au minimum
--    - Note: Le filtre du énoncé est "au moins 3 sessions"
--    - Donc on devrait peut-être utiliser COUNT(DISTINCT watch_date) >= 3
--    - Mais HAVING s'applique sur les agrégats de GROUP BY, donc on utilise COUNT(*)
