# Exercice #7 - Métriques de churn et engagement cumulatif

## 📊 Contexte

StreamFlix veut identifier les **utilisateurs à risque de churn** (qui s'éloignent) et suivre leur **engagement cumulatif** pour mieux cibler les relances marketing.

## 🎯 Objectif

Pour les **180 derniers jours**, analyser pour chaque utilisateur :

1. **Nombre total de sessions**
2. **Durée totale cumulée** (en heures)
3. **Taux de complétion moyen**
4. **Dernière date active**
5. **Jours écoulés** depuis la dernière activité
6. **Tendance d'engagement** : hausse, baisse ou stable (comparaison premier/dernier mois)
7. **Score de risque churn** : utilisateurs inactifs depuis > 30 jours

## 📋 Spécifications

### Calculs attendus

| Métrique | Formule | Format |
|----------|---------|--------|
| Total sessions | `COUNT(session_id)` | Entier |
| Durée cumul (h) | `SUM(watch_duration) / 60` | Float (1 déc) |
| Complét moy | `AVG(completion_rate) * 100` | % (2 déc) |
| Dernière activité | `MAX(watch_date)` | DATE |
| Jours sans activité | `DATE_DIFF(DATE('2025-12-31'), last_date, DAY)` | Entier |
| Tendance | CASE WHEN mois_1 < mois_final THEN 'hausse' ... | String |
| Risque churn | CASE WHEN jours_inactif > 30 THEN 'HIGH' ... | String |

### Regroupement
- Par `user_id`
- Enrichir avec country, age_group, device_type

### Filtres & tris
- Période : 180 derniers jours
- ORDER BY : jours_inactif DESC (plus inactifs en premier)
- LIMIT : 100 utilisateurs

## 🔍 Difficultés à anticiper

- ✅ CTEs en cascade pour split premier/dernier mois
- ✅ Jointures user_id avec users table
- ✅ Conditions complexes pour tendance et risque
- ✅ Window functions pour comparaison périodes
- ✅ Gestion des NULL (user jamais actif)

## 💡 Indications

### Concepts testés
- **CTEs complexes** : Structurer premiers/derniers mois
- **Window functions** : `MAX() OVER (...)`, `MIN() OVER (...)`
- **CASE WHEN imbriqué** : Tendance et risque
- **DATE_DIFF()** : Calculs temporels
- **Jointures multiples** : Enrichissement données

### Structure recommandée

```sql
-- CTE 1: Toutes métriques globales
WITH global_metrics AS (
  SELECT
    user_id,
    COUNT(session_id) AS total_sessions,
    ROUND(SUM(watch_duration_minutes) / 60, 1) AS total_hours,
    ROUND(AVG(completion_rate) * 100, 2) AS avg_completion_pct,
    MAX(watch_date) AS last_active_date
  FROM viewing_sessions
  WHERE watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 180 DAY)
  GROUP BY user_id
),

-- CTE 2: Engagement premier mois
first_month AS (
  SELECT
    user_id,
    SUM(watch_duration_minutes) AS first_month_duration
  FROM viewing_sessions
  WHERE watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 180 DAY)
    AND watch_date <= DATE_ADD(DATE_SUB(DATE('2025-12-31'), INTERVAL 180 DAY), INTERVAL 30 DAY)
  GROUP BY user_id
),

-- CTE 3: Engagement dernier mois
last_month AS (
  SELECT
    user_id,
    SUM(watch_duration_minutes) AS last_month_duration
  FROM viewing_sessions
  WHERE watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 30 DAY)
  GROUP BY user_id
)

-- SELECT final
SELECT
  gm.user_id,
  u.country,
  u.age_group,
  gm.total_sessions,
  gm.total_hours,
  gm.avg_completion_pct,
  gm.last_active_date,
  DATE_DIFF(DATE('2025-12-31'), gm.last_active_date, DAY) AS days_since_last_activity,
  CASE
    WHEN fm.first_month_duration < lm.last_month_duration THEN 'increasing'
    WHEN fm.first_month_duration > lm.last_month_duration THEN 'decreasing'
    ELSE 'stable'
  END AS engagement_trend,
  CASE
    WHEN DATE_DIFF(DATE('2025-12-31'), gm.last_active_date, DAY) > 30 THEN 'HIGH'
    WHEN DATE_DIFF(DATE('2025-12-31'), gm.last_active_date, DAY) > 14 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS churn_risk
FROM global_metrics gm
LEFT JOIN first_month fm USING (user_id)
LEFT JOIN last_month lm USING (user_id)
JOIN users u USING (user_id)
ORDER BY days_since_last_activity DESC
LIMIT 100;
```

### Points clés
- Comparaison premier/dernier mois via CTEs séparées
- NULL sur first_month/last_month si user inactif sur la période
- `DATE_DIFF()` pour jours inactifs
- `CASE WHEN imbriqué` pour churn_risk

## 📊 Résultat attendu

```
+-----------+---------+----------+------------------+------------------+------------------+--------------------+------------------------+--------------------+-----------+
| user_id   | country | age_group| total_sessions   | total_hours      | avg_completion%  | last_active_date   | days_since_activity | engagement_trend   | churn_risk|
+-----------+---------+----------+------------------+------------------+------------------+--------------------+------------------------+--------------------+-----------+
| user_456  | USA     | 35-44    | 25               | 65.5             | 77.25            | 2025-11-15         | 46                 | decreasing         | HIGH      |
| user_789  | France  | 25-34    | 18               | 42.3             | 75.80            | 2025-11-28         | 33                 | stable             | MEDIUM    |
| user_012  | UK      | 45-54    | 42               | 112.0            | 82.50            | 2025-12-25         | 6                  | increasing        | LOW       |
| ...       | ...     | ...      | ...              | ...              | ...              | ...                | ...                | ...                | ...       |
+-----------+---------+----------+------------------+------------------+------------------+--------------------+------------------------+--------------------+-----------+
```

## ⚠️ Pièges fréquents

1. **CTEs pour premier/dernier mois mal dimensionnées** → vérifier les dates
2. **NULL sur first_month/last_month** → utiliser LEFT JOIN et COALESCE
3. **Churn_risk ne tient pas compte de NULL** → ajouter gestion IFNULL
4. **Tendance inversée** → vérifier le sens de la comparaison

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution** : `solutions/week2-advanced-analysis/07-solution.sql`
