# Exercice #3 - Analyse temporelle et croissance MoM

## 📊 Contexte

StreamFlix veut suivre son évolution mensuelle : inscriptions, activité, et croissance du nombre de sessions.

## 🎯 Objectif

Pour chaque mois des **6 derniers mois**, calculer :

1. **Nombre de nouveaux utilisateurs inscrits** (signup) ce mois-ci
2. **Nombre d'utilisateurs actifs** (ayant au moins 1 session) ce mois-ci
3. **Nombre total de sessions** ce mois-ci
4. **Croissance MoM** du nombre de sessions (en %, par rapport au mois précédent)

## 📋 Spécifications

### Période analysée
- Les **6 derniers mois** à partir de la date de référence (31 décembre 2025)
- Plage: 1 juillet 2025 → 31 décembre 2025

### Calculs attendus

| Métrique | Formule | Format |
|----------|---------|--------|
| Nouveaux users | `COUNT(DISTINCT user_id)` sur `users` filtrée | Entier |
| Utilisateurs actifs | `COUNT(DISTINCT user_id)` sur `viewing_sessions` | Entier |
| Total sessions | `COUNT(DISTINCT session_id)` | Entier |
| Croissance MoM | `(mois_n - mois_n-1) / mois_n-1 * 100` | 2 décimales |

### Groupement temporel
- Format du mois : `YYYY-MM` (ex: `2025-07`, `2025-08`)
- **Tri** : Mois décroissant (plus récent en premier)

## 🔍 Difficultés à anticiper

- ✅ Deux CTEs : une pour signups, une pour activity
- ✅ Jointure des deux CTEs par mois
- ✅ Utiliser `LAG()` window function pour comparer au mois précédent
- ✅ Format de date avec `FORMAT_DATE()` et `DATE_TRUNC()`
- ✅ Gestion des NULL (premier mois n'a pas de mois précédent)

## 💡 Indications

### Concepts testés
- **CTEs (Common Table Expressions)** : Structurer la requête en blocs
- **Formatage de dates** : `FORMAT_DATE('%Y-%m', date)`
- **DATE_TRUNC** : Truncate à mois entier
- **Window functions** : `LAG()` pour l'historique
- **IFNULL / COALESCE** : Gérer les NULL du mois sans signups
- **Jointures CTE** : `FULL OUTER JOIN` ou `LEFT JOIN`

### Structure recommandée
1. **CTE signups** : Compter les nouveaux users par mois
2. **CTE activity** : Compter les actifs et sessions par mois
3. **SELECT final** : Joindre les CTEs et calculer la croissance

### Points clés
```sql
-- Formatter le mois
FORMAT_DATE('%Y-%m', signup_date) AS month

-- Comparer au mois précédent avec LAG
LAG(total_sessions) OVER (ORDER BY month)

-- Calculer la croissance (attention aux NULL)
ROUND((current - previous) / previous * 100, 2)
```

## 📊 Résultat attendu

```
+----------+-----------+--------------+------------------+------------------+
| months   | new_users | active_users | total_sessions   | growth_mom_pct   |
+----------+-----------+--------------+------------------+------------------+
| 2025-12  | ~180      | ~1300        | ~4200            | ~5.25            |
| 2025-11  | ~165      | ~1250        | ~3995            | ~3.75            |
| 2025-10  | ~150      | ~1100        | ~3850            | ~2.50            |
| 2025-09  | ~140      | ~1050        | ~3750            | NULL             |
| ...      | ...       | ...          | ...              | ...              |
+----------+-----------+--------------+------------------+------------------+
```

## ⚠️ Pièges fréquents

1. **Oublier DISTINCT sur user_id** → doublons si un user a plusieurs sessions
2. **Mauvaise jointure des CTEs** → perte de mois sans signups
3. **Croissance du premier mois = NULL** → normal, pas de comparaison possible
4. **Format de date incorrect** → groupage non-uniforme

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution** : `solutions/week1-fundamentals/03-solution.sql`
