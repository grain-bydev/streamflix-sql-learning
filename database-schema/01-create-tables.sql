-- ============================================================================
-- StreamFlix Dataset - DDL Scripts
-- Project: ultra-airway-475009-m6
-- Dataset: streamflix
-- ============================================================================
-- Description: Scripts pour créer les 4 tables principales du dataset
-- Exécuter dans BigQuery Console ou via bq CLI
-- ============================================================================

-- PREREQUISITE: Créer le dataset si inexistant
-- CREATE SCHEMA IF NOT EXISTS `ultra-airway-475009-m6.streamflix`;

-- ============================================================================
-- TABLE 1: users (5000 utilisateurs)
-- ============================================================================
-- Description: Profils utilisateurs avec informations démographiques et techniques
-- Clé primaire: user_id (UUID)
-- Cardinalité: 5000 lignes

CREATE OR REPLACE TABLE `ultra-airway-475009-m6.streamflix.users` (
  -- Identifiant unique
  user_id STRING NOT NULL,
  
  -- Informations démographiques
  country STRING NOT NULL,           -- France, USA, UK, Germany, Spain
  age_group STRING NOT NULL,         -- 18-24, 25-34, 35-44, 45-54, 55+
  
  -- Informations techniques et comportementales
  device_type STRING NOT NULL,       -- mobile, smart_tv, desktop, tablet
  signup_date DATE NOT NULL,         -- Date d'inscription (2024-01-01 à 2025-12-31)
  
  -- Contraintes
  PRIMARY KEY (user_id) NOT ENFORCED
)
PARTITION BY signup_date
CLUSTER BY country, device_type;

-- Index hints pour performance
-- Note: BigQuery utilise le clustering pour optimisation


-- ============================================================================
-- TABLE 2: content (800 contenus)
-- ============================================================================
-- Description: Catalogue de contenus disponibles sur la plateforme
-- Clé primaire: content_id (UUID)
-- Cardinalité: 800 lignes

CREATE OR REPLACE TABLE `ultra-airway-475009-m6.streamflix.content` (
  -- Identifiant unique
  content_id STRING NOT NULL,
  
  -- Métadonnées du contenu
  title STRING NOT NULL,             -- Titre du contenu
  content_type STRING NOT NULL,      -- 'movie' ou 'series'
  genre STRING NOT NULL,             -- Drama, Comedy, Action, Thriller, Documentary, Sci-Fi
  
  -- Informations de production
  release_year INT64 NOT NULL,       -- Année de sortie (2000-2025)
  duration_minutes INT64 NOT NULL,   -- Durée totale en minutes (15-300 pour films)
  country_production STRING,         -- Pays de production
  
  -- Contraintes
  PRIMARY KEY (content_id) NOT ENFORCED
)
CLUSTER BY genre, content_type;


-- ============================================================================
-- TABLE 3: subscriptions (5000 abonnements)
-- ============================================================================
-- Description: Abonnements des utilisateurs avec informations de facturation
-- Clé primaire: sub_id (UUID)
-- Clé étrangère: user_id → users.user_id
-- Cardinalité: 5000 lignes (1:1 avec users)

CREATE OR REPLACE TABLE `ultra-airway-475009-m6.streamflix.subscriptions` (
  -- Identifiant unique
  sub_id STRING NOT NULL,
  
  -- Références
  user_id STRING NOT NULL,           -- FK → users.user_id
  
  -- Informations d'abonnement
  plan_type STRING NOT NULL,         -- 'basic', 'standard', 'premium'
  status STRING NOT NULL,            -- 'active' ou 'cancelled'
  
  -- Dates
  start_date DATE NOT NULL,          -- Début d'abonnement
  end_date DATE,                     -- Fin (NULL si status='active')
  
  -- Facturation
  monthly_price FLOAT64 NOT NULL,    -- Prix mensuel en euros
  
  -- Contraintes
  PRIMARY KEY (sub_id) NOT ENFORCED
)
PARTITION BY start_date
CLUSTER BY user_id, plan_type;

-- Note: end_date doit être NULL si status='active'
-- Invariant: end_date >= start_date quand end_date IS NOT NULL


-- ============================================================================
-- TABLE 4: viewing_sessions (~80,000 sessions)
-- ============================================================================
-- Description: Sessions de visionnage avec métriques d'engagement
-- Clé primaire: session_id (UUID)
-- Clés étrangères: user_id → users.user_id, content_id → content.content_id
-- Cardinalité: ~80,000 lignes

CREATE OR REPLACE TABLE `ultra-airway-475009-m6.streamflix.viewing_sessions` (
  -- Identifiant unique
  session_id STRING NOT NULL,
  
  -- Références
  user_id STRING NOT NULL,           -- FK → users.user_id
  content_id STRING NOT NULL,        -- FK → content.content_id
  
  -- Informations de visionnage
  watch_date DATE NOT NULL,          -- Date de visionnage (2024-01-01 à 2025-12-31)
  watch_duration_minutes INT64 NOT NULL,  -- Durée regardée en minutes
  completion_rate FLOAT64 NOT NULL,  -- Taux de complétion (0.0 à 1.0)
  
  -- Contexte technique
  device_type STRING NOT NULL,       -- mobile, smart_tv, desktop, tablet
  
  -- Contraintes
  PRIMARY KEY (session_id) NOT ENFORCED,
  FOREIGN KEY (user_id) REFERENCES users(user_id) NOT ENFORCED,
  FOREIGN KEY (content_id) REFERENCES content(content_id) NOT ENFORCED
)
PARTITION BY watch_date
CLUSTER BY user_id, content_id;

-- Note importante: watch_date peut être identique pour plusieurs sessions
-- (un utilisateur peut regarder plusieurs contenus le même jour)
-- Utiliser DISTINCT sur watch_date pour compter les "jours actifs"


-- ============================================================================
-- VÉRIFICATIONS POST-CRÉATION
-- ============================================================================

-- Vérifier que les tables existent et contiennent des données
SELECT 
  'users' AS table_name, 
  COUNT(*) AS row_count,
  MIN(signup_date) AS date_min,
  MAX(signup_date) AS date_max
FROM `ultra-airway-475009-m6.streamflix.users`
UNION ALL
SELECT 'content', COUNT(*), NULL, NULL
FROM `ultra-airway-475009-m6.streamflix.content`
UNION ALL
SELECT 'subscriptions', COUNT(*), MIN(start_date), MAX(start_date)
FROM `ultra-airway-475009-m6.streamflix.subscriptions`
UNION ALL
SELECT 'viewing_sessions', COUNT(*), MIN(watch_date), MAX(watch_date)
FROM `ultra-airway-475009-m6.streamflix.viewing_sessions`;

-- Résultat attendu:
-- +-------------------+-----------+-----------+-----------+
-- | table_name        | row_count | date_min  | date_max  |
-- +-------------------+-----------+-----------+-----------+
-- | users             | 5000      | 2024-01-01| 2025-12-31|
-- | content           | 800       | NULL      | NULL      |
-- | subscriptions     | 5000      | 2024-01-01| 2025-12-31|
-- | viewing_sessions  | ~80000    | 2024-01-01| 2025-12-31|
-- +-------------------+-----------+-----------+-----------+


-- ============================================================================
-- CONSTRAINTS DE DONNÉES (à respecter lors du peuplement)
-- ============================================================================

-- users:
--   - user_id: UUID unique (non-null)
--   - country: enum(France, USA, UK, Germany, Spain)
--   - age_group: enum(18-24, 25-34, 35-44, 45-54, 55+)
--   - device_type: enum(mobile, smart_tv, desktop, tablet)
--   - signup_date: 2024-01-01 ≤ signup_date ≤ 2025-12-31

-- content:
--   - content_id: UUID unique (non-null)
--   - title: chaîne non-vide
--   - content_type: enum(movie, series)
--   - genre: enum(Drama, Comedy, Action, Thriller, Documentary, Sci-Fi)
--   - release_year: 2000 ≤ release_year ≤ 2025
--   - duration_minutes: 15 ≤ duration_minutes ≤ 300

-- subscriptions:
--   - sub_id: UUID unique (non-null)
--   - user_id: FK valide vers users
--   - plan_type: enum(basic, standard, premium)
--   - status: enum(active, cancelled)
--   - start_date: date valide
--   - end_date: NULL si status='active', sinon end_date ≥ start_date
--   - monthly_price: > 0 (0.01 à 99.99)

-- viewing_sessions:
--   - session_id: UUID unique (non-null)
--   - user_id: FK valide vers users
--   - content_id: FK valide vers content
--   - watch_date: 2024-01-01 ≤ watch_date ≤ 2025-12-31
--   - watch_duration_minutes: 1 ≤ watch_duration ≤ duration_minutes du content
--   - completion_rate: 0.0 ≤ completion_rate ≤ 1.0
--   - device_type: enum(mobile, smart_tv, desktop, tablet)
