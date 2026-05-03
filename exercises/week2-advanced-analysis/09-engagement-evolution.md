# Exercice #9 - Analyse de fidélisation : évolution du temps de visionnage

## 📊 Contexte

StreamFlix veut comprendre **l'évolution de l'engagement** au fil du temps. Qui regarde de plus en plus ? Qui abandonne ? Qui sont les utilisateurs "à risque" ?

## 🎯 Objectif

Pour chaque utilisateur et chaque mois des **6 derniers mois**, afficher :

**Informations utilisateur :**
- `user_id`, `country`, `age_group`

**Métriques mensuelles :**
- `mois` (format YYYY-MM)
- `nb_sessions` : nombre de sessions ce mois-ci
- `temps_total_minutes` : durée regardée ce mois-ci

**Comparaison avec le mois précédent (LAG) :**
- `temps_mois_precedent` : durée du mois précédent
- `evolution_minutes` : différence (mois actuel - mois précédent)
- `evolution_pourcent` : variation en % (arrondi 1 décimale)

## 📋 Spécifications

### Calculs attendus

| Métrique | Formule | Format |
|----------|---------|--------|
| Nb sessions | `COUNT(session_id)` | Entier |
| Temps total | `SUM(watch_duration_minutes)` | Minutes |
| Temps mois-1 | `LAG(temps_total) OVER (...)` | Minutes |
| Évolution min | Temps_n - Temps_n-1 | Entier |
| Évolution % | `(Temps_n - Temps_n-1) / Temps_n-1 * 100` | % (1 déc) |

### Filtres & tris
- **Garder uniquement** les users avec ≥ 2 mois d'activité
- **Garder uniquement** les 6 derniers mois
- **ORDER BY** : user_id, mois (du plus ancien au plus récent)

## 🔍 Difficultés à anticiper

- ✅ `LAG()` pour accéder au mois précédent
- ✅ `PARTITION BY user_id` pour rester dans chaque user
- ✅ `ORDER BY mois` pour l'ordre chronologique
- ✅ `FORMAT_DATE()` pour grouper par mois
- ✅ Filtrer après agrégation (HAVING avec COUNT DISTINCT)
- ✅ Gérer les NULL (premier mois n'a pas de précédent)
- ✅ Division par zéro `NULLIF()`

## 💡 Indications

### Concepts testés
- **LAG() avancé** : Partition et Order By corrects
- **FORMAT_DATE()** : Groupement par mois
- **Window functions** : Navigation dans l'historique
- **Calculs avec NULL** : NULLIF pour éviter division par zéro
- **Filtrage post-agrégation** : HAVING COUNT(DISTINCT month) >= 2

### Structure recommandée

```sql
-- CTE 1: Visionnage total par mois par user
WITH monthly_view AS (
  SELECT
    user_id,
    FORMAT_DATE('%Y-%m', watch_date) AS view_month,
    COUNT(session_id) AS nb_sessions,
    SUM(watch_duration_minutes) AS total_view_n
  FROM viewing_sessions
  WHERE watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 6 MONTH)
  GROUP BY user_id, view_month
),

-- CTE 2: Ajouter le mois précédent (LAG)
mois_n_1 AS (
  SELECT
    *,
    LAG(total_view_n) OVER (
      PARTITION BY user_id
      ORDER BY view_month
    ) AS total_view_n_1
  FROM monthly_view
),

-- CTE 3: Calculer l'évolution
evolution AS (
  SELECT
    *,
    total_view_n - total_view_n_1 AS duration_diff,
    ROUND(100 * (total_view_n - total_view_n_1) / NULLIF(total_view_n_1, 0), 1) AS duration_pct
  FROM mois_n_1
),

-- CTE 4: Identifier les users avec 2+ mois
users_2_months AS (
  SELECT user_id
  FROM monthly_view
  GROUP BY user_id
  HAVING COUNT(DISTINCT view_month) >= 2
)

-- SELECT final
SELECT
  ev.user_id,
  us.country,
  us.age_group,
  ev.view_month AS mois,
  ev.nb_sessions,
  ev.total_view_n AS temps_total_minutes,
  ev.total_view_n_1 AS temps_mois_precedent,
  ev.duration_diff AS evolution_minutes,
  ev.duration_pct AS evolution_pourcent
FROM evolution ev
JOIN users_2_months u2m ON ev.user_id = u2m.user_id
JOIN users us ON ev.user_id = us.user_id
ORDER BY ev.user_id, ev.view_month;
```

### Points clés
- `LAG()` dans CTE séparée (plus lisible)
- `NULLIF(total_view_n_1, 0)` pour éviter division par zéro
- `HAVING COUNT(DISTINCT view_month) >= 2` pour filtrer les users avec peu de mois
- `ORDER BY user_id, view_month` pour tri chronologique par user

## 📊 Résultat attendu

```
+----------+---------+----------+----------+------------+---------------------+--------------------+------------------+------------------+
| user_id  | country | age_group| mois     | nb_sessions| temps_total_minutes | temps_mois_prec    | evolution_minutes| evolution_pourcent|
+----------+---------+----------+----------+------------+---------------------+--------------------+------------------+------------------+
| user_001 | France  | 25-34    | 2025-07  | 8          | 480                 | NULL               | NULL             | NULL             |
| user_001 | France  | 25-34    | 2025-08  | 10         | 620                 | 480                | 140              | 29.2             |
| user_001 | France  | 25-34    | 2025-09  | 6          | 380                 | 620                | -240             | -38.7            |
| user_002 | USA     | 35-44    | 2025-07  | 15         | 950                 | NULL               | NULL             | NULL             |
| user_002 | USA     | 35-44    | 2025-08  | 14         | 880                 | 950                | -70              | -7.4             |
| ...      | ...     | ...      | ...      | ...        | ...                | ...                | ...              | ...              |
+----------+---------+----------+----------+------------+---------------------+--------------------+------------------+------------------+
```

## ⚠️ Pièges fréquents

1. **LAG() sans PARTITION BY user_id** → mélange les users
2. **ORDER BY mois sans ORDER BY view_month dans LAG** → mauvais ordre
3. **Oublier NULLIF** → division par zéro en évolution %
4. **Evolution_pourcent pour premier mois = NULL** → OK, c'est normal
5. **Filtre sur users_2_months** → peut perdre des users légitimes avec 1 mois

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution** : `solutions/week2-advanced-analysis/09-solution.sql`
