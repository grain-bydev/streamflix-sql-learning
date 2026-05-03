# Schema Overview - StreamFlix

## Description générale

StreamFlix est une plateforme de streaming synthétique avec 4 tables principales :
- `users` : Profils utilisateurs
- `content` : Catalogue de contenus
- `subscriptions` : Abonnements des utilisateurs
- `viewing_sessions` : Sessions de visionnage

### Relations

```
users (1) ───────────────── (N) subscriptions
  │
  │
  └─ (1) ───────────────── (N) viewing_sessions ───────── (N) content
```

---

## Tables détaillées

### 1. **users** (5000 lignes)

| Colonne | Type | Description |
|---------|------|-------------|
| `user_id` | STRING (UUID) | Identifiant unique de l'utilisateur (PK) |
| `country` | STRING | France, USA, UK, Germany, Spain |
| `signup_date` | DATE | Date d'inscription (2024-01-01 à 2025-12-31) |
| `device_type` | STRING | mobile, smart_tv, desktop, tablet |
| `age_group` | STRING | 18-24, 25-34, 35-44, 45-54, 55+ |

**Caractéristiques** :
- Distribution équilibrée par pays
- Distribution réaliste par groupe d'âge
- Types d'appareils variant selon le pays et l'âge

**Exemple de requête** :
```sql
SELECT country, age_group, COUNT(*) AS nb_users
FROM users
GROUP BY country, age_group
ORDER BY nb_users DESC;
```

---

### 2. **content** (800 lignes)

| Colonne | Type | Description |
|---------|------|-------------|
| `content_id` | STRING (UUID) | Identifiant unique du contenu (PK) |
| `title` | STRING | Titre du contenu |
| `content_type` | STRING | 'movie' ou 'series' |
| `genre` | STRING | Drama, Comedy, Action, Thriller, Documentary, Sci-Fi |
| `release_year` | INT64 | Année de sortie (2000-2025) |
| `duration_minutes` | INT64 | Durée en minutes (15-300 pour films, 30-80/ep pour séries) |
| `country_production` | STRING | Pays de production |

**Caractéristiques** :
- Ratio ~60% films / 40% séries
- Distribution par genre varie entre contenus
- Durée corrélée au type (films plus longs que séries)

**Exemple de requête** :
```sql
SELECT genre, COUNT(*) AS nb_content, AVG(duration_minutes) AS avg_duration
FROM content
GROUP BY genre
ORDER BY nb_content DESC;
```

---

### 3. **subscriptions** (5000 lignes)

| Colonne | Type | Description |
|---------|------|-------------|
| `sub_id` | STRING (UUID) | Identifiant unique de l'abonnement (PK) |
| `user_id` | STRING (UUID) | FK → users |
| `plan_type` | STRING | 'basic', 'standard', 'premium' |
| `start_date` | DATE | Date de début d'abonnement |
| `end_date` | DATE | Date de fin (NULL si actif) |
| `monthly_price` | FLOAT64 | Prix mensuel (varies by plan) |
| `status` | STRING | 'active' ou 'cancelled' |

**Caractéristiques** :
- 1 utilisateur = 1 abonnement (1:1 avec users)
- Mix de subscriptions actives et annulées
- `end_date` NULL si `status = 'active'`
- Prix : basic < standard < premium

**Distribution des plans** :
```
basic    : ~40% (€4.99/mois)
standard : ~35% (€9.99/mois)
premium  : ~25% (€14.99/mois)
```

**Exemple de requête** :
```sql
SELECT plan_type, status, COUNT(*) AS nb_subs, ROUND(AVG(monthly_price), 2) AS avg_price
FROM subscriptions
GROUP BY plan_type, status
ORDER BY nb_subs DESC;
```

---

### 4. **viewing_sessions** (~80,000 lignes)

| Colonne | Type | Description |
|---------|------|-------------|
| `session_id` | STRING (UUID) | Identifiant unique de la session (PK) |
| `user_id` | STRING (UUID) | FK → users |
| `content_id` | STRING (UUID) | FK → content |
| `watch_date` | DATE | Date de visionnage (2024-01-01 à 2025-12-31) |
| `watch_duration_minutes` | INT64 | Durée regardée en minutes |
| `completion_rate` | FLOAT64 | Taux de complétion (0.0 à 1.0) |
| `device_type` | STRING | mobile, smart_tv, desktop, tablet |

**Caractéristiques** :
- ~80k sessions réparties sur 2 ans
- ~23k sessions sur les 30 derniers jours
- Plusieurs sessions peuvent avoir la même `watch_date` (plusieurs sessions/jour)
- `completion_rate` = durée regardée / durée totale du contenu
- `device_type` peut différer du device_type stocké dans users

**Distribution temporelle** :
- Sessions plus concentrées en fin d'année
- Pics de visionnage le soir/weekend
- Variation saisonnière réaliste

**Exemple de requête** :
```sql
SELECT 
  FORMAT_DATE('%Y-%m', watch_date) AS month,
  COUNT(DISTINCT session_id) AS nb_sessions,
  COUNT(DISTINCT user_id) AS active_users,
  ROUND(AVG(completion_rate) * 100, 2) AS avg_completion_pct
FROM viewing_sessions
GROUP BY month
ORDER BY month DESC;
```

---

## Patterns de données importants

### 1. **Dates de référence**
La date de fin des données est **31 décembre 2025** (`DATE('2025-12-31')`).

Toutes les requêtes d'exercice utilisent cette date de référence pour :
- Calculer "les 30 derniers jours"
- Calculer "les 6 derniers mois"
- Créer des fenêtres temporelles cohérentes

### 2. **Utilisateurs actifs vs. inactifs**
- **Actif** : Au moins 1 session dans la période analysée
- **Inactif** : Inscrit mais 0 session

Les exercices distinguent souvent ces deux groupes pour les analyses de rétention/churn.

### 3. **Completion rate**
- `completion_rate = watch_duration_minutes / duration_minutes` (du contenu)
- Valeurs typiques : 0.0 (pas regardé) à 1.0 (regardé en entier)
- Utile pour mesurer l'engagement et la satisfaction

### 4. **Multiple sessions par jour**
Un utilisateur peut avoir plusieurs sessions le même jour (ex: regarder 2 films différents).

Les exercices distinguent :
- **Nombre de sessions** : COUNT(DISTINCT session_id)
- **Nombre de jours actifs** : COUNT(DISTINCT watch_date)

---

## Requêtes de vérification utiles

### Vérifier la taille des tables
```sql
SELECT 
  'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL
SELECT 'content', COUNT(*) FROM content
UNION ALL
SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL
SELECT 'viewing_sessions', COUNT(*) FROM viewing_sessions;
```

### Vérifier la couverture temporelle
```sql
SELECT 
  'users' AS table_name, MIN(signup_date) AS date_min, MAX(signup_date) AS date_max
FROM users
UNION ALL
SELECT 'subscriptions', MIN(start_date), MAX(start_date) FROM subscriptions
UNION ALL
SELECT 'viewing_sessions', MIN(watch_date), MAX(watch_date) FROM viewing_sessions;
```

### Vérifier les NULL
```sql
SELECT 
  'subscriptions.end_date' AS column_check,
  COUNTIF(end_date IS NULL) AS null_count,
  COUNTIF(end_date IS NOT NULL) AS not_null_count
FROM subscriptions;
```

---

## Notes d'implémentation

### Types de données BigQuery
- **UUID** : Stocké comme STRING (ex: `"f47ac10b-58cc-4372-a567-0e02b2c3d479"`)
- **Dates** : Type DATE natif
- **Pourcentages** : FLOAT64 (0.0 à 1.0)

### Backticks dans BigQuery
Pour les noms qualifiés, utiliser des backticks :
```sql
SELECT * FROM `ultra-airway-475009-m6.streamflix.users`;
```

### Date de référence
Pour reproductibilité, **toutes les requêtes utilisent** :
```sql
DATE('2025-12-31')
```
Modifier uniquement si tu veux analyser une période différente.

---

## Cas d'usage des exercices

| Exercice | Tables utilisées | Pattern clé |
|----------|------------------|-----------|
| #1 | viewing_sessions | Agrégations simples |
| #2 | viewing_sessions, users | Jointure + GROUP BY dimension |
| #3 | users, viewing_sessions | CTE + temporal analysis |
| #4 | viewing_sessions, users, content | Multi-CTE + CASE WHEN |
| #5A | viewing_sessions, content | Window functions (RANK) |
| #5B | users, viewing_sessions | Cohorte + date calculations |
| #6 | viewing_sessions, users | LAG/LEAD complex |
| #7 | subscriptions, viewing_sessions | Churn metrics |
| #8 | viewing_sessions, content, users | Multi-level segmentation |
| #9 | viewing_sessions, users | Temporal evolution + LAG |
| #10 | viewing_sessions | Intervals + STDDEV |

---

**Pour plus de détails, consulte les énoncés des exercices dans `/exercises/`**
