# Exercice #1 - Métriques d'engagement de base

## 📊 Contexte

Nous analysons les performances générales de la plateforme StreamFlix pour le dernier mois.

## 🎯 Objectif

Calculer **4 KPI clés** pour les 30 derniers jours :

1. **Nombre total de sessions** de visionnage
2. **Durée moyenne** de visionnage par session (en minutes)
3. **Taux de complétion moyen** (pourcentage du contenu regardé)
4. **Nombre d'utilisateurs actifs uniques**

## 📋 Spécifications

### Période analysée
- Les **30 derniers jours** à partir de la date de référence (31 décembre 2025)
- Plage: 2 décembre 2025 → 31 décembre 2025

### Calculs attendus

| Métrique | Formule | Format |
|----------|---------|--------|
| Total sessions | `COUNT(DISTINCT session_id)` | Nombre entier |
| Durée moyenne | `AVG(watch_duration_minutes)` | 2 décimales |
| Taux complétion | `AVG(completion_rate) * 100` | Pourcentage (2 décimales) |
| Utilisateurs actifs | `COUNT(DISTINCT user_id)` | Nombre entier |

### Date de référence
```sql
DATE('2025-12-31')
```

## 🔍 Difficultés à anticiper

- ✅ Comprendre la différence entre `COUNT()`, `COUNT(DISTINCT)` et `SUM()`
- ✅ Savoir quand utiliser `DISTINCT`
- ✅ Conversion du completion_rate en pourcentage
- ✅ Arrondis avec `ROUND()`

## 💡 Indications

### Concepts testés
- Agrégations de base : `COUNT`, `AVG`
- Déduplication : `DISTINCT`
- Filtrage temporel : `DATE_SUB`, `INTERVAL`
- Arrondis : `ROUND(valeur, décimales)`

### Approche recommandée
1. Commencer par une requête simple : `SELECT * FROM viewing_sessions LIMIT 10`
2. Ajouter le filtre de dates
3. Appliquer les agrégations une par une

## 📊 Résultat attendu

```
+----------------+------------------+--------------------+---------------+
| total_sessions | average_duration | avg_pct_completion | active_users  |
+----------------+------------------+--------------------+---------------+
| ~2300          | ~65.50           | ~78.25             | ~1200         |
+----------------+------------------+--------------------+---------------+
```

(Les valeurs exactes dépendront de ta distribution de données)

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution** : `solutions/week1-fundamentals/01-solution.sql`
