# Exercice #10 - Analyse des schémas de consommation et régularité des utilisateurs

## 📊 Contexte

StreamFlix veut analyser **les patterns de visionnage** : qui regarde régulièrement ? Qui a des pauses longues ? Ces métriques aident à prédire le churn.

## 🎯 Objectif

Pour chaque utilisateur actif sur les **90 derniers jours**, calculer :

1. **Nombre total de sessions** sur la période
2. **Intervalle moyen** entre deux sessions (en jours)
3. **Intervalle minimum** entre deux sessions
4. **Intervalle maximum** entre deux sessions
5. **Écart-type des intervalles** (variabilité)
6. **Nombre de périodes d'inactivité** de plus de 14 jours

## 📋 Spécifications

### Calculs attendus

| Métrique | Formule | Format |
|----------|---------|--------|
| Nb sessions | `COUNT(DISTINCT watch_date)` | Entier |
| Intervalle moy | `AVG(intervalle)` | Jours (2 déc) |
| Intervalle min | `MIN(intervalle)` | Jours |
| Intervalle max | `MAX(intervalle)` | Jours |
| Écart-type | `STDDEV(intervalle)` | Jours (2 déc) |
| Longues pauses | `COUNTIF(intervalle >= 14)` | Entier |

### Contraintes importantes
1. Considérer uniquement les **users ayant ≥ 3 sessions** sur la période
2. **Compter une seule session par jour** (même si plusieurs sessions le même jour)
3. Calculer l'intervalle comme `DATE_DIFF(current_date, previous_date, DAY)`
4. **ORDER BY** : nb_sessions DESC, puis avg_interval_days ASC
5. **LIMIT** : 50 premiers utilisateurs

## 🔍 Difficultés à anticiper

- ✅ **Dedoublonnage** : DISTINCT sur watch_date pour ne compter qu'un jour = une session
- ✅ **LAG()** : Accéder à la date précédente
- ✅ **DATE_DIFF()** : Calculer l'écart en jours
- ✅ **STDDEV()** : Écart-type (peut être NULL avec peu de données)
- ✅ **COUNTIF()** : Compter les intervalles > 14
- ✅ **HAVING COUNT(*)** : Filtrer après les calculs d'intervalle
- ✅ **NULL sur la première session** : LAG retourne NULL, à gérer

## 💡 Indications

### Concepts testés
- **Dedoublonnage** : `DISTINCT` avant window functions
- **LAG() avancé** : Navigation dans dates distinctes
- **DATE_DIFF()** : Calcul d'intervalles
- **Statistiques** : `STDDEV()`, `AVG()`, `MIN()`, `MAX()`
- **Filtrage complexe** : HAVING sur count après agrégation d'intervalles

### Structure recommandée

```sql
-- CTE 1: Dedoublonner les sessions par jour
WITH dedoublon AS (
  SELECT DISTINCT
    user_id,
    watch_date
  FROM viewing_sessions
  WHERE watch_date >= DATE_SUB(DATE('2025-12-31'), INTERVAL 90 DAY)
),

-- CTE 2: Calculer les intervalles entre sessions
intervalle AS (
  SELECT
    user_id,
    watch_date,
    DATE_DIFF(
      watch_date,
      LAG(watch_date) OVER (
        PARTITION BY user_id
        ORDER BY watch_date
      ),
      DAY
    ) AS intervalle_prec
  FROM dedoublon
)

-- SELECT final
SELECT
  user_id,
  COUNT(DISTINCT watch_date) AS nb_sessions,
  ROUND(AVG(intervalle_prec), 2) AS avg_interval_days,
  MIN(intervalle_prec) AS min_interval,
  MAX(intervalle_prec) AS max_interval,
  ROUND(STDDEV(intervalle_prec), 2) AS stddev_interval,
  COUNTIF(intervalle_prec >= 14) AS nb_longues_pauses
FROM intervalle
GROUP BY user_id
HAVING COUNT(*) >= 3  -- Au moins 3 sessions (donc 2 intervalles mesurables)
ORDER BY nb_sessions DESC, avg_interval_days ASC
LIMIT 50;
```

### Points clés
- `DISTINCT user_id, watch_date` pour dedoublonner
- `LAG(watch_date)` (pas sur session_id) pour accéder à la date précédente
- `DATE_DIFF(..., DAY)` pour l'écart en jours
- `COUNTIF(intervalle_prec >= 14)` pour longues pauses
- `HAVING COUNT(*) >= 3` : au moins 3 sessions = 2 intervalles mesurables
- NULL du premier intervalle : inclus mais AVG/STDDEV l'ignorent (comportement BigQuery)

## 📊 Résultat attendu

```
+----------+------------------+------------------+------------------+------------------+-------------------+-------------------+
| user_id  | nb_sessions      | avg_interval_days| min_interval     | max_interval     | stddev_interval   | nb_longues_pauses |
+----------+------------------+------------------+------------------+------------------+-------------------+-------------------+
| user_abc | 25               | 3.45             | 1                | 15               | 4.25              | 3                 |
| user_def | 18               | 4.80             | 1                | 28               | 7.50              | 5                 |
| user_ghi | 12               | 2.15             | 1                | 7                | 1.85              | 0                 |
| ...      | ...              | ...              | ...              | ...              | ...               | ...               |
+----------+------------------+------------------+------------------+------------------+-------------------+-------------------+
```

## ⚠️ Pièges fréquents

1. **Oublier DISTINCT** → plusieurs sessions le même jour = faux intervalles
2. **LAG() sans PARTITION BY user_id** → mélange les users
3. **DATE_DIFF(watch_date, previous_date)** → attention à l'ordre des paramètres
4. **COUNTIF vs COUNT** → COUNTIF pour condition, COUNT pour nombre total
5. **NULL du premier intervalle** → normal, ne pas le compter dans HAVING
6. **Résultat NULL pour STDDEV** → peut arriver avec peu de variance
7. **HAVING COUNT(*) >= 3** → compte les intervalles (donc sessions doit être > 2)

## 🚀 À toi de jouer !

Écris ta requête SQL et consulte la solution quand tu es bloqué.

**Fichier solution** : `solutions/week2-advanced-analysis/10-solution.sql`
