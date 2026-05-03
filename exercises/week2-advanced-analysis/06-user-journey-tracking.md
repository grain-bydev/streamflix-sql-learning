# Exercice #6 - Suivi du parcours utilisateur avec navigation temporelle

## 📊 Contexte

StreamFlix veut analyser le **parcours temporel** de ses utilisateurs : quelle est leur activité jour après jour ? Quel contenu regardent-ils en succession ?

## 🎯 Objectif

Pour les **90 derniers jours**, analyser pour chaque utilisateur **par date** :

1. **Nombre de sessions** du jour
2. **Contenu regardé** (titre du dernier contenu)
3. **Contenu précédent** (titre de la session d'avant)
4. **Intervalle en jours** depuis la dernière session
5. **Taux de complétion** de la session actuelle
6. **Total cumulatif** de sessions depuis le début

## 📋 Spécifications

### Calculs attendus

| Métrique | Formule | Format |
|----------|---------|--------|
| Sessions du jour | `COUNT(session_id)` par user/date | Entier |
| Contenu actuel | Titre du contenu de la session | String |
| Contenu précédent | `LAG(title) OVER (...)` | String/NULL |
| Intervalle jours | `DATE_DIFF(current_date, prev_date, DAY)` | Entier/NULL |
| Complét actuelle | Taux de complétion moyen | Float (0-1) |
| Cumul sessions | `SUM(...) OVER (ORDER BY date)` | Entier |

### Regroupement
- Par `user_id`, `watch_date`
- Lister une ligne par contenu regardé le même jour (pas une agrégation par jour)

### Filtres & tris
- Période : 90 derniers jours
- ORDER BY : user_id, watch_date (du plus ancien au plus récent)
- Limiter aux **100 premiers utilisateurs** (par nombre de sessions total)

## 🔍 Difficultés à anticiper

- ✅ `LAG()` pour accéder à la ligne précédente
- ✅ `PARTITION BY user_id` pour rester dans l'historique de l'user
- ✅ `ORDER BY watch_date` pour l'ordre chronologique
- ✅ `SUM(...) OVER (...)` pour le cumul
- ✅ Gestion des NULL (première session n'a pas de précédent)
- ✅ Jointures : viewing_sessions + content + users

## 💡 Indications

### Concepts testés
- **Window functions avancées** :
  - `LAG()` pour la session précédente
  - `SUM() OVER (...)` pour cumul
  - Partitioning et ordering
- **Jointures multiples** : sessions + content + users
- **Date arithmetic** : `DATE_DIFF()`

### Structure recommandée

```sql
WITH sessions_with_content AS (
  SELECT
    vs.user_id,
    vs.watch_date,
    vs.session_id,
    c.title AS current_title,
    vs.completion_rate,
    COUNT(vs.session_id) OVER (PARTITION BY vs.user_id, vs.watch_date) AS sessions_today,
    LAG(c.title) OVER (PARTITION BY vs.user_id ORDER BY vs.watch_date, vs.session_id) AS prev_title,
    LAG(vs.watch_date) OVER (PARTITION BY vs.user_id ORDER BY vs.watch_date) AS prev_date,
    SUM(1) OVER (PARTITION BY vs.user_id ORDER BY vs.watch_date, vs.session_id) AS cumulative_sessions
  FROM viewing_sessions vs
  JOIN content c USING (content_id)
  WHERE vs.watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
),

user_session_count AS (
  SELECT user_id, COUNT(*) AS total_sessions
  FROM sessions_with_content
  GROUP BY user_id
  ORDER BY total_sessions DESC
  LIMIT 100
)

SELECT
  u.user_id,
  u.country,
  swc.watch_date,
  swc.sessions_today,
  swc.current_title,
  swc.prev_title,
  DATE_DIFF(swc.watch_date, swc.prev_date, DAY) AS days_since_last_session,
  swc.completion_rate,
  swc.cumulative_sessions
FROM sessions_with_content swc
JOIN user_session_count usc USING (user_id)
JOIN users u USING (user_id)
ORDER BY swc.user_id, swc.watch_date;
```

### Points clés
- `LAG()` nécessite une `ORDER BY` compatible
- La `PARTITION BY` doit isoler chaque user
- `SUM(...) OVER (ORDER BY)` crée un cumul
- `DATE_DIFF()` peut retourner NULL si prev_date est NULL

## 📊 Résultat attendu

```
+-----------+---------+------------+-----------+------------------+------------------+----------------------+------------------+---------------------+
| user_id   | country | watch_date | sessions_t| current_title    | prev_title       | days_since_last    | completion_rate  | cumulative_sessions |
+-----------+---------+------------+-----------+------------------+------------------+----------------------+------------------+---------------------+
| user_123  | France  | 2025-10-05 | 1         | Inception        | NULL             | NULL               | 0.95             | 1                   |
| user_123  | France  | 2025-10-07 | 2         | The Crown S1     | Inception        | 2                  | 0.85             | 3                   |
| user_123  | France  | 2025-10-10 | 1         | Dune              | The Crown S1     | 3                  | 0.92             | 4                   |
| ...       | ...     | ...        | ...       | ...              | ...              | ...                | ...              | ...                 |
+-----------+---------+------------+-----------+------------------+------------------+----------------------+------------------+---------------------+
```

## ⚠️ Pièges fréquents

1. **Confondre PARTITION BY et ORDER BY** → PARTITION isole, ORDER BY ordonne
2. **NULL sur la première session** → normal pour LAG
3. **Cumul incorrect** → vérifier la PARTITION BY et l'ORDER BY du SUM
4. **Oublier la jointure avec users** → pour avoir le country

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution** : `solutions/week2-advanced-analysis/06-solution.sql`
