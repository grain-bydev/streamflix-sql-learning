# Exercice #4 - Segmentation utilisateurs multi-dimensionnelle

## 📊 Contexte

StreamFlix veut comprendre ses utilisateurs par profil et niveau d'engagement pour adapter son contenu et sa UX.

## 🎯 Objectif

Pour les **90 derniers jours**, créer un rapport de segmentation selon **2 dimensions** :

**Dimension 1** : Profil utilisateur
- `age_group` (18-24, 25-34, 35-44, 45-54, 55+)
- `device_type` (mobile, smart_tv, desktop, tablet)

**Dimension 2** : Niveau d'engagement
- **"heavy"** : ≥ 10 sessions dans les 90 jours
- **"medium"** : 3-9 sessions
- **"light"** : 1-2 sessions
- **"inactive"** : 0 session (inscrit mais jamais actif sur la période)

## 📋 Spécifications

### Calculs attendus par segment

| Métrique | Formule | Format |
|----------|---------|--------|
| Nombre d'utilisateurs | `COUNT(user_id)` | Entier |
| Durée moy/user | `ROUND(AVG(total_duration), 0)` | Minutes (0 déc) |
| Taux complét moy | `ROUND(AVG(avg_completion) * 100, 2)` | % (2 déc) |
| Sessions moy/user | `ROUND(AVG(total_sessions), 1)` | Nombre (1 déc) |

### Filtres et tris
- **HAVING** : Segments avec ≥ 50 utilisateurs
- **ORDER BY** : Nombre d'utilisateurs décroissant

## 🔍 Difficultés à anticiper

- ✅ Cascade de CTEs (user_metrics → user_engagement → agrégation)
- ✅ CASE WHEN pour segmentation d'engagement
- ✅ Jointure entre viewing_sessions et users
- ✅ Multi-level GROUP BY (3 dimensions)
- ✅ Distinction active vs inactive (qui n'a 0 session)

## 💡 Indications

### Concepts testés
- **CTEs en cascade** : Chaque CTE affine les données
- **CASE WHEN** : Convertir sessions numériques en catégories
- **Window functions** : Non utilisée ici, mais approche scalaire
- **Jointures** : Garder tous les users (INNER vs LEFT JOIN)
- **GROUP BY multi-dimensionnel** : 3 niveaux de groupage

### Structure recommandée

```sql
-- CTE 1: Toutes les métriques user sur la période
WITH user_metrics AS (
  SELECT
    user_id,
    COUNT(session_id) AS total_sessions,
    SUM(watch_duration_minutes) AS total_duration,
    AVG(completion_rate) AS avg_completion
  FROM viewing_sessions
  WHERE watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
  GROUP BY user_id
),

-- CTE 2: Enrichir avec profil user + segmenter engagement
user_engagement AS (
  SELECT
    u.age_group,
    u.device_type,
    m.total_sessions,
    m.total_duration,
    m.avg_completion,
    CASE
      WHEN m.total_sessions >= 10 THEN 'heavy'
      WHEN m.total_sessions >= 3 THEN 'medium'
      WHEN m.total_sessions >= 1 THEN 'light'
      ELSE 'inactive'
    END AS engagement
  FROM user_metrics m
  FULL OUTER JOIN users u USING (user_id)
)

-- SELECT final: Agréger par segment
SELECT
  age_group,
  device_type,
  engagement,
  COUNT(*) AS nb_users,
  ROUND(AVG(total_duration), 0) AS avg_duration_min,
  ROUND(AVG(avg_completion) * 100, 2) AS avg_completion_pct,
  ROUND(AVG(total_sessions), 1) AS avg_sessions_per_user
FROM user_engagement
GROUP BY age_group, device_type, engagement
HAVING nb_users >= 50
ORDER BY nb_users DESC;
```

### Points clés
- La **CTE 1** ne compte que les users ACTIFS (qui ont au moins 1 session)
- La **CTE 2** doit joindre avec `users` pour inclure les INACTIFS
- **CASE WHEN** pour la segmentation d'engagement
- **3 dimensions** dans le GROUP BY final

## 📊 Résultat attendu

```
+----------+-----------+-----------+---------+-----------------+------------------+---------------------+
| age_group| device_type| engagement| nb_users| avg_duration_min| avg_completion_pct| avg_sessions_per_user
+----------+-----------+-----------+---------+-----------------+------------------+---------------------+
| 25-34    | mobile    | heavy     | 280     | 4500            | 78.50            | 15.2                |
| 35-44    | desktop   | medium    | 240     | 2100            | 76.25            | 5.8                 |
| ...      | ...       | ...       | ...     | ...             | ...              | ...                 |
+----------+-----------+-----------+---------+-----------------+------------------+---------------------+
```

## ⚠️ Pièges fréquents

1. **Oublier les inactifs** → utiliser FULL OUTER JOIN au lieu de INNER
2. **Total_duration NULL pour inactifs** → utiliser COALESCE/IFNULL
3. **Mauvais seuil de sessions** → vérifier que 10+3+1 > 0 et < N
4. **Oubli du DISTINCT user_id** en CTE 1

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution** : `solutions/week1-fundamentals/04-solution.sql`
