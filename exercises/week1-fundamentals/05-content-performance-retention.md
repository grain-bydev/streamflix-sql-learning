# Exercice #5 - KPI complexes & Window Functions

## 📊 Contexte

StreamFlix lance un dashboard pour optimiser son catalogue : quels contenus marchent le mieux ? Quelle est la rétention des utilisateurs par cohorte d'inscription ?

## 🎯 Objectif

**PARTIE A : Top contenus avec ranking**

Identifier les 20 contenus les plus populaires des 30 derniers jours avec :
1. Nombre total de visionnages
2. Nombre d'utilisateurs uniques
3. Durée moyenne de visionnage
4. Taux de complétion moyen
5. **Ranking par nombre de visionnages** (1 = le plus regardé)
6. **Ranking par taux de complétion** (1 = le mieux complété)

**PARTIE B : Cohorte de rétention**

Analyser la **rétention des utilisateurs** inscrits en novembre 2024 :
1. Nombre d'utilisateurs actifs par semaine
2. Taux de rétention par rapport à la semaine 0 (inscription)
3. Comparaison jusqu'à 8 semaines après inscription

## 📋 Spécifications - PARTIE A

### Calculs attendus

| Métrique | Formule | Format |
|----------|---------|--------|
| Visionnages | `COUNT(session_id)` | Entier |
| Utilisateurs | `COUNT(DISTINCT user_id)` | Entier |
| Durée moy | `ROUND(AVG(watch_duration_minutes), 2)` | 2 déc |
| Complét moy | `ROUND(AVG(completion_rate), 2)` | 2 déc (pas %) |
| Rank vues | `RANK() OVER (ORDER BY views DESC)` | Window fn |
| Rank complét | `RANK() OVER (ORDER BY completion DESC)` | Window fn |

### Filtres
- Période : 30 derniers jours
- HAVING : ≥ 20 visionnages
- LIMIT : 20 premiers résultats

## 📋 Spécifications - PARTIE B

### Calculs attendus

| Métrique | Formule |
|----------|---------|
| Semaines écoulées | `DATE_DIFF(watch_date, signup_date, WEEK)` |
| Users actifs/semaine | `COUNT(DISTINCT user_id)` par semaine |
| Taux rétention | `active_users_week_n / active_users_week_0 * 100` |

### Filtres
- Utilisateurs : Inscrits en novembre 2024 uniquement
- Semaines : 0 à 8 après inscription
- Format : week_since_signup, active_users, retention_rate

## 🔍 Difficultés à anticiper

**PARTIE A :**
- ✅ Window functions `RANK()` au lieu de `ROW_NUMBER()`
- ✅ Plusieurs `RANK()` dans le même SELECT
- ✅ Jointure viewing_sessions + content

**PARTIE B :**
- ✅ `DATE_DIFF()` pour calculer les semaines
- ✅ CTEs en cascade
- ✅ Calcul de rétention (division avec la semaine 0)
- ✅ Traiter la semaine 0 spécialement (lecture directe de `users`)

## 💡 Indications PARTIE A

### Concepts testés
- **Window functions** : `RANK()` pour le classement
- **Agrégations** : Avant les rankings
- **Jointures** : viewing_sessions + content
- **LIMIT** : Limiter les résultats

### Structure

```sql
-- CTE: Agrégation par contenu
WITH agg AS (
  SELECT
    content_id,
    COUNT(session_id) AS total_views,
    COUNT(DISTINCT user_id) AS nbr_viewers,
    ROUND(AVG(watch_duration_minutes), 2) AS avg_duration_min,
    ROUND(AVG(completion_rate), 2) AS avg_completion
  FROM viewing_sessions
  WHERE watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 30 DAY)
  GROUP BY content_id
  HAVING total_views >= 20
)

-- SELECT final: Joindre content + window functions
SELECT
  c.title,
  c.content_type,
  c.genre,
  agg.total_views,
  agg.nbr_viewers,
  agg.avg_duration_min,
  agg.avg_completion,
  RANK() OVER (ORDER BY agg.total_views DESC) AS rank_views,
  RANK() OVER (ORDER BY agg.avg_completion DESC) AS rank_completion
FROM agg
JOIN content c USING (content_id)
ORDER BY agg.total_views DESC
LIMIT 20;
```

## 💡 Indications PARTIE B

### Concepts testés
- **DATE_DIFF()** : Calculer écart en semaines
- **CTEs complexes** : 3-4 niveaux d'imbrication
- **Divisions** : Calcul de rétention
- **Traitement spécial** : Semaine 0 depuis `users`

### Structure

```sql
-- CTE 1: Users inscrits en novembre 2024
WITH inscrits_nov AS (
  SELECT user_id, signup_date
  FROM users
  WHERE signup_date >= '2024-11-01' AND signup_date <= '2024-11-30'
),

-- CTE 2: Pour chaque user, les semaines d'activité
activite_par_semaine AS (
  SELECT
    user_id,
    DATE_DIFF(vs.watch_date, inn.signup_date, WEEK) AS week_since_signup
  FROM viewing_sessions vs
  JOIN inscrits_nov inn USING (user_id)
),

-- CTE 3: Compter actifs par semaine (y compris semaine 0)
agregation AS (
  -- Semaine 0 = tous les users inscrits
  SELECT 0 AS week_since_signup, COUNT(DISTINCT user_id) AS active_users
  FROM inscrits_nov
  
  UNION ALL
  
  -- Semaines 1-8 = users avec activité
  SELECT
    week_since_signup,
    COUNT(DISTINCT user_id) AS active_users
  FROM activite_par_semaine
  WHERE week_since_signup BETWEEN 1 AND 8
  GROUP BY week_since_signup
)

-- SELECT final: Calculer rétention
SELECT
  week_since_signup,
  active_users,
  ROUND(100 * active_users / MAX(active_users) OVER () AS retention_rate
FROM agregation
ORDER BY week_since_signup;
```

## 📊 Résultats attendus

### PARTIE A
```
+------------------+-----------+------------------+------------------+----------+-----------+
| title            | total_views| avg_duration_min | avg_completion   | rank_views| rank_compl|
+------------------+-----------+------------------+------------------+----------+-----------+
| Inception        | 145       | 75.50            | 0.92             | 1        | 2        |
| The Crown S1     | 138       | 42.30            | 0.88             | 2        | 5        |
| ...              | ...       | ...              | ...              | ...      | ...      |
+------------------+-----------+------------------+------------------+----------+-----------+
```

### PARTIE B
```
+------------------+-----------+------------------+
| week_since_signup| active_users| retention_rate   |
+------------------+-----------+------------------+
| 0               | 450       | 100.00           |
| 1               | 380       | 84.44            |
| 2               | 325       | 72.22            |
| ...             | ...       | ...              |
+------------------+-----------+------------------+
```

## ⚠️ Pièges fréquents

**PARTIE A :**
1. Confondre `RANK()` et `ROW_NUMBER()` → utiliser RANK() pour les ex-aequo
2. Oublier le HAVING avant le RANK() → agrégations d'abord

**PARTIE B :**
1. Semaine 0 requiert un traitement spécial (pas de viewing_sessions)
2. Rétention = users_n / users_0, pas users_n / users_1
3. DATE_DIFF en WEEK vs DAY → WEEK donne un nombre entier

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution PARTIE A** : `solutions/week1-fundamentals/05A-solution.sql`
**Fichier solution PARTIE B** : `solutions/week1-fundamentals/05B-solution.sql`
