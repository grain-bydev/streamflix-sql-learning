# StreamFlix SQL Learning Project

Un projet d'apprentissage progressif du SQL pour l'analyse de données, basé sur un dataset synthétique d'une plateforme de streaming.

## 📋 À propos

Ce projet contient :
- **10 exercices SQL** organisés en 2 semaines
- **Solutions annotées** avec commentaires détaillés sur chaque CTE, JOIN et window function
- **Schéma de base de données** complet avec DDL
- **Structure progressive** : du basic (agrégations, jointures) aux concepts avancés (CTEs, window functions, segmentation)

### Objectifs d'apprentissage

- ✅ Fondamentaux (SELECT, agrégations, jointures)
- ✅ Manipulation de dates et périodes
- ✅ Window functions (ranking, navigation, agrégations)
- ✅ CTEs et sous-requêtes
- ✅ Logique conditionnelle (CASE WHEN, COALESCE)
- ✅ Analyses métier (KPI, cohortes, rétention, segmentation)

---

## 📁 Structure du projet

```
streamflix-sql-learning/
├── README.md (ce fichier)
├── database-schema/
│   ├── 01-create-tables.sql         # DDL pour créer les 4 tables
│   └── schema-overview.md           # Description du schéma
├── exercises/
│   ├── week1-fundamentals/
│   │   ├── 01-basic-engagement-metrics.md
│   │   ├── 02-kpi-by-country.md
│   │   ├── 03-temporal-analysis.md
│   │   ├── 04-user-segmentation.md
│   │   └── 05-content-performance-retention.md
│   └── week2-advanced-analysis/
│       ├── 06-user-journey-tracking.md
│       ├── 07-churn-prediction-metrics.md
│       ├── 08-multi-level-segmentation.md
│       ├── 09-engagement-evolution.md
│       └── 10-consumption-patterns.md
├── solutions/
│   ├── week1-fundamentals/
│   │   ├── 01-solution.sql
│   │   ├── 02-solution.sql
│   │   ├── 03-solution.sql
│   │   ├── 04-solution.sql
│   │   └── 05-solution.sql
│   └── week2-advanced-analysis/
│       ├── 06-solution.sql
│       ├── 07-solution.sql
│       ├── 08-solution.sql
│       ├── 09-solution.sql
│       └── 10-solution.sql
└── .gitignore
```

---

## 🗄️ Dataset : StreamFlix

Une plateforme de streaming avec 4 tables principales :

### **users** (5000 utilisateurs)
- `user_id` : UUID unique
- `country` : France, USA, UK, Germany, Spain
- `signup_date` : Date d'inscription
- `device_type` : mobile, smart_tv, desktop, tablet
- `age_group` : 18-24, 25-34, 35-44, 45-54, 55+

### **content** (800 contenus)
- `content_id` : UUID unique
- `title` : Titre du contenu
- `content_type` : movie ou series
- `genre` : Drama, Comedy, Action, Thriller, Documentary, Sci-Fi
- `release_year` : Année de sortie
- `duration_minutes` : Durée en minutes
- `country_production` : Pays de production

### **subscriptions** (5000 abonnements)
- `sub_id` : UUID unique
- `user_id` : FK → users
- `plan_type` : basic, standard, premium
- `start_date` : Début d'abonnement
- `end_date` : Fin (nullable si actif)
- `monthly_price` : Prix mensuel
- `status` : active ou cancelled

### **viewing_sessions** (~80k sessions)
- `session_id` : UUID unique
- `user_id` : FK → users
- `content_id` : FK → content
- `watch_date` : Date de visionnage
- `watch_duration_minutes` : Durée regardée
- `completion_rate` : Taux de complétion (0-1)
- `device_type` : mobile, smart_tv, desktop, tablet

**Caractéristiques** :
- Données sur 2 ans (2024-2025)
- ~23k sessions sur les 30 derniers jours
- Distribution réaliste et synthétique

---

## 🚀 Démarrage rapide

### 1. Créer les tables dans BigQuery

```bash
# Copier le contenu de database-schema/01-create-tables.sql
# Exécuter dans BigQuery Console ou via bq CLI
bq query < database-schema/01-create-tables.sql
```

### 2. Consulter un exercice

Chaque semaine contient 5 exercices :
- **Semaine 1** : Fondamentaux (agrégations, jointures, temporel)
- **Semaine 2** : Avancé (window functions, CTEs, segmentation)

Ouvrir l'énoncé dans `exercises/` et consulter la solution correspondante dans `solutions/`

### 3. Les solutions sont annotées

Chaque fichier `.sql` contient :
- Commentaires explicatifs pour chaque CTE
- Justification des clauses clés (GROUP BY, HAVING, ORDER BY)
- Annotations sur les window functions et jointures

---

## 📚 Concepts clés par exercice

### Semaine 1
| Exercice | Concepts | Difficulté |
|----------|----------|-----------|
| #1 | COUNT DISTINCT, AVG, agrégations | ⭐ |
| #2 | Jointures, GROUP BY, agrégations par dimension | ⭐ |
| #3 | CTE, FORMAT_DATE, DATE_TRUNC, window functions (LAG) | ⭐⭐ |
| #4 | Cascades de CTEs, CASE WHEN, multi-dimensional segmentation | ⭐⭐ |
| #5A | RANK, window functions avec contenu | ⭐⭐ |
| #5B | Cohortes, rétention, calculs complexes avec LAG | ⭐⭐⭐ |

### Semaine 2
| Exercice | Concepts | Difficulté |
|----------|----------|-----------|
| #6 | LAG/LEAD, PARTITION BY avancé, calculs temporels | ⭐⭐⭐ |
| #7 | Churn metrics, cumulative metrics, window functions | ⭐⭐⭐ |
| #8 | Multi-level segmentation, ROW_NUMBER, jointures complexes | ⭐⭐⭐ |
| #9 | LAG avancé, évolution temporelle, filtrage avec HAVING | ⭐⭐⭐ |
| #10 | Intervals, STDDEV, dedoublonnage, patterns | ⭐⭐⭐⭐ |

---

## 💡 Méthodologie

### Approche recommandée

1. **Lire l'énoncé** : `exercises/week-X/NN-*.md`
2. **Essayer d'écrire la requête** avant de regarder la solution
3. **Consulter la solution** : `solutions/week-X/NN-solution.sql`
4. **Analyser les commentaires** pour comprendre chaque section
5. **Reproduire** sur BigQuery et tester les résultats

### Points clés

- Les solutions sont commentées par **section logique** (CTE, SELECT final, etc.)
- Les **window functions** sont expliquées avec leur `PARTITION BY` et `ORDER BY`
- Les **agrégations** incluent la justification du `GROUP BY`
- Les **jointures** indiquent le type et la raison

---

## 🔧 BigQuery Setup

### Projet
```
<ton-projet-id>
```

### Dataset
```
<ton-dataset-name>
```

### Connexion
```sql
-- Référencer les tables avec le chemin complet
SELECT * FROM <ton-projet-id>.<ton-dataset-name>.users` LIMIT 5;
```

---

## 📖 Thèmes couverts

### Fondamentaux (Semaine 1)
- Agrégations : `COUNT DISTINCT`, `SUM`, `AVG`
- Jointures : `INNER JOIN`, `LEFT JOIN`
- Groupage : `GROUP BY`, `HAVING`
- Dates : `DATE_SUB`, `DATE_TRUNC`, `FORMAT_DATE`

### Avancé (Semaine 2)
- **CTEs** : Structure en cascade, optimisation logique
- **Window functions** : `LAG`, `LEAD`, `RANK`, `ROW_NUMBER`
- **Partitioning** : `PARTITION BY` pour analyses temporelles
- **Segmentation** : Multi-niveaux avec CASE WHEN
- **Analyses métier** : Rétention, churn, patterns de consommation

---

## 🤝 Bonnes pratiques appliquées

Chaque solution suit ces principes :

✅ **Clarté** : Commentaires au-dessus de chaque CTE  
✅ **Modularité** : CTEs nommées de façon descriptive  
✅ **Robustesse** : `NULLIF`, `IFNULL`, `COALESCE` pour edge cases  
✅ **Performance** : Filtrage précoce, `DISTINCT` justifié  
✅ **Documentation** : Explications des choix techniques  

---

## 📝 Notes d'apprentissage

Pendant que tu avances, je te recommande de maintenir tes propres notes :

- **Blocages** : Les concepts difficiles
- **Patterns** : Ce qui revient souvent (CASE WHEN, LAG, etc.)
- **Variations** : Comment adapter une requête pour un contexte différent
- **Optimisations** : Ce que tu découvres sur BigQuery

---

## 🎯 Progression estimée

- **Semaine 1** : 1 exercice/jour (5 jours) → Fondamentaux solides
- **Semaine 2** : 1 exercice/jour (5 jours) → Concepts avancés maîtrisés
- **Total** : 2 semaines pour automatiser les patterns clés

---

## 📞 Questions fréquentes

### Comment exécuter une solution ?
1. Copier le contenu du fichier `.sql`
2. Ouvrir BigQuery Console
3. Coller et exécuter

### Comment adapter une solution ?
- Modifier les dates (`DATE('2025-12-31')`)
- Changer les seuils (HAVING, WHERE)
- Ajouter/retirer des dimensions (GROUP BY)

### BigQuery vs autre DB ?
Les solutions sont **spécifiques à BigQuery** :
- Syntaxe : `DATE('2025-12-31')` au lieu de `'2025-12-31'::DATE`
- Fonctions : `DATE_TRUNC`, `FORMAT_DATE`, `GENERATE_DATE_ARRAY`
- Format : Backticks pour les noms qualifiés

---

## 📄 Licence

Ce projet est à usage personnel pour l'apprentissage du SQL.

---

**Bon apprentissage ! 🚀**
