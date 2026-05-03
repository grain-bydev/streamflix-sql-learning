# Exercice #2 - KPI de performance par pays

## 📊 Contexte

StreamFlix veut analyser ses performances par géographie pour adapter sa stratégie marketing et son contenu par région.

## 🎯 Objectif

Pour les **90 derniers jours**, calculer les KPI **par pays** :

1. **Nombre d'utilisateurs actifs** (ayant au moins 1 session)
2. **Durée totale de visionnage** (en heures, arrondi à 1 décimale)
3. **Durée moyenne par utilisateur** (en minutes, arrondi à 0 décimales)
4. **Taux de complétion moyen** (en %, arrondi à 2 décimales)

## 📋 Spécifications

### Période analysée
- Les **90 derniers jours** à partir de la date de référence (31 décembre 2025)
- Plage: 2 octobre 2025 → 31 décembre 2025

### Calculs attendus

| Métrique | Formule | Format |
|----------|---------|--------|
| Utilisateurs actifs | `COUNT(DISTINCT user_id)` | Entier |
| Durée totale (h) | `SUM(watch_duration_minutes) / 60` | 1 décimale |
| Durée moyenne/user | `SUM(...) / COUNT(DISTINCT user_id)` | 0 décimales |
| Taux complét. moyen | `AVG(completion_rate) * 100` | 2 décimales |

### Filtres
- **HAVING** : Segments avec ≥ 500 utilisateurs actifs
- **ORDER BY** : Durée totale décroissante

## 🔍 Difficultés à anticiper

- ✅ Jonction entre `viewing_sessions` et `users`
- ✅ Regroupement par dimension (country)
- ✅ Calculs d'agrégation imbriqués (durée moyenne par user)
- ✅ Conversion d'unités (minutes → heures)
- ✅ Clause HAVING vs WHERE (filtrer après agrégation)

## 💡 Indications

### Concepts testés
- **Jointures** : `INNER JOIN` ou `LEFT JOIN` ?
- **GROUP BY** : Dimensionner par pays
- **HAVING** : Filtrer les agrégats
- **Conversions d'unités** : `/60` pour heures
- **Orden de calcul** : Quelle agrégation en premier ?

### Points clés
- La jointure doit se faire sur `user_id`
- Ne pas oublier `DISTINCT` sur `user_id` pour éviter les doublons
- `AVG(completion_rate)` doit être multiplié par 100

## 📊 Résultat attendu

```
+----------+--------------+------------------+-----------------------+---------------------+
| country  | active_users | total_duration_h | avg_duration_per_user | avg_pct_completion  |
+----------+--------------+------------------+-----------------------+---------------------+
| USA      | ~1500        | ~4850.5          | ~194                  | ~78.50              |
| France   | ~1200        | ~3900.2          | ~162                  | ~77.25              |
| Germany  | ~800         | ~2600.1          | ~174                  | ~78.75              |
| ...      | ...          | ...              | ...                   | ...                 |
+----------+--------------+------------------+-----------------------+---------------------+
```

(Les valeurs exactes dépendent de ta distribution)

## ⚠️ Attention

**Erreur fréquente** : Oublier le `COUNT(DISTINCT user_id)` au dénominateur
```sql
-- ❌ Faux : va donner des valeurs énormes
AVG(watch_duration_minutes) / COUNT(user_id)

-- ✅ Correct : divise par le nombre d'utilisateurs UNIQUES
SUM(watch_duration_minutes) / COUNT(DISTINCT user_id)
```

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution** : `solutions/week1-fundamentals/02-solution.sql`
