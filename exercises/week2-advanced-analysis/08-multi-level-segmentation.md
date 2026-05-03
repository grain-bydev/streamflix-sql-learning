# Exercice #8 - Segmentation multi-niveaux (engagement par type de contenu)

## 📊 Contexte

StreamFlix veut identifier ses **profils d'utilisateurs par préférence de contenu** pour personnaliser les recommandations et optimiser le contenu par segment.

## 🎯 Objectif

Pour les **90 derniers jours**, segmenter les utilisateurs selon **3 dimensions** :

**Dimension 1** : Type de contenu préféré
- Identifier pour chaque user le `content_type` qu'il a le plus regardé (movie ou series)
- En cas d'égalité, prendre 'movie' par défaut

**Dimension 2** : Niveau d'engagement
- **"heavy"** : ≥ 15 sessions
- **"medium"** : 5-14 sessions
- **"light"** : 1-4 sessions

**Dimension 3** : Profil utilisateur
- `country`
- `device_type`

## 📋 Spécifications

### Calculs attendus par segment

| Métrique | Formule | Format |
|----------|---------|--------|
| Nombre d'utilisateurs | `COUNT(user_id)` | Entier |
| Nombre total sessions | `SUM(total_sessions)` | Entier |
| Durée moy/session | `AVG(avg_duration_session)` | Minutes (1 déc) |
| Complét moy | `AVG(avg_completion) * 100` | % (2 déc) |

### Filtres & tris
- **HAVING** : Segments avec ≥ 30 utilisateurs
- **ORDER BY** : Nombre d'utilisateurs décroissant
- **LIMIT** : 20 premiers segments

## 🔍 Difficultés à anticiper

- ✅ `ROW_NUMBER()` pour identifier le type de contenu préféré
- ✅ Gérer l'égalité (movie par défaut avec ORDER BY)
- ✅ CTEs en cascade : content_counts → preferred_content → metrics → user_engagement
- ✅ Jointures multiples sur user_id
- ✅ Agrégation multi-dimensionnelle (4 colonnes de groupement)

## 💡 Indications

### Concepts testés
- **ROW_NUMBER()** : Identifier le top 1 par user
- **Window functions avancées** : PARTITION BY user_id
- **CASE WHEN** : Segmentation engagement
- **Jointures en cascade** : Enrichissement progressif
- **GROUP BY multi-dim** : 4 colonnes

### Structure recommandée

```sql
-- CTE 1: Compter content_type par user
WITH content_counts AS (
  SELECT
    vs.user_id,
    c.content_type,
    COUNT(vs.session_id) AS nb_sessions,
    ROW_NUMBER() OVER (
      PARTITION BY vs.user_id
      ORDER BY COUNT(vs.session_id) DESC, c.content_type ASC
    ) AS ct_rank  -- ASC pour movie en premier en cas d'égalité
  FROM viewing_sessions vs
  JOIN content c USING (content_id)
  WHERE vs.watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
  GROUP BY vs.user_id, c.content_type
),

-- CTE 2: Prendre le top 1 (préférence)
preferred_content AS (
  SELECT *
  FROM content_counts
  WHERE ct_rank = 1
),

-- CTE 3: Toutes les métriques user
metrics AS (
  SELECT
    vs.user_id,
    u.country,
    u.device_type,
    COUNT(vs.session_id) AS total_sessions,
    AVG(vs.watch_duration_minutes) AS avg_duration_session,
    AVG(vs.completion_rate) AS avg_completion
  FROM viewing_sessions vs
  JOIN users u USING (user_id)
  WHERE vs.watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
  GROUP BY vs.user_id, u.country, u.device_type
),

-- CTE 4: Ajouter segmentation engagement
user_engagement AS (
  SELECT
    m.user_id,
    m.country,
    m.device_type,
    m.total_sessions,
    m.avg_duration_session,
    m.avg_completion,
    CASE
      WHEN m.total_sessions >= 15 THEN 'heavy'
      WHEN m.total_sessions >= 5 THEN 'medium'
      ELSE 'light'
    END AS engagement
  FROM metrics m
)

-- SELECT final: Agréger par segment
SELECT
  ue.country,
  ue.device_type,
  pc.content_type,
  ue.engagement,
  COUNT(ue.user_id) AS nb_users,
  SUM(ue.total_sessions) AS total_sessions,
  ROUND(AVG(ue.avg_duration_session), 1) AS avg_duration_session,
  ROUND(AVG(ue.avg_completion) * 100, 2) AS avg_completion_pct
FROM user_engagement ue
JOIN preferred_content pc USING (user_id)
GROUP BY ue.country, ue.device_type, pc.content_type, ue.engagement
HAVING nb_users >= 30
ORDER BY nb_users DESC
LIMIT 20;
```

### Points clés
- `ROW_NUMBER()` avec ORDER BY `COUNT DESC, content_type ASC` pour "movie par défaut"
- Jointure `JOIN preferred_content` sur user_id pour retrouver le type
- `GROUP BY` sur 4 dimensions : country, device_type, content_type, engagement

## 📊 Résultat attendu

```
+---------+----------+----------+----------+---------+---------+----------------------+-------------------+
| country | device_t | cont_type| engagement| nb_users| tot_sess| avg_duration_session | avg_completion_pct|
+---------+----------+----------+----------+---------+---------+----------------------+-------------------+
| USA     | mobile   | movie    | heavy    | 85      | 1360    | 72.5                 | 79.25             |
| USA     | mobile   | series   | medium   | 72      | 680     | 38.2                 | 76.50             |
| France  | desktop  | movie    | light    | 65      | 195     | 85.0                 | 81.75             |
| ...     | ...      | ...      | ...      | ...     | ...     | ...                  | ...               |
+---------+----------+----------+----------+---------+---------+----------------------+-------------------+
```

## ⚠️ Pièges fréquents

1. **ROW_NUMBER() mal configuré** → ORDER BY doit avoir COUNT DESC + content_type ASC
2. **Oublier `WHERE ct_rank = 1`** → inclut tous les content_types
3. **Jointure sur user_id manquante** → impossible de retrouver le content_type
4. **GROUP BY incomplet** → oublier une colonne

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution** : `solutions/week2-advanced-analysis/08-solution.sql`
