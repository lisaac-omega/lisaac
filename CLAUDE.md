# CLAUDE.md — Développement en Lisaac

## Présentation

Ce projet est écrit en **Lisaac**, un langage orienté prototype (pas de classes),
compilé vers du C ANSI puis vers un binaire natif via `gcc`.

## Chemins importants

- **Projet** : répertoire courant (fichiers `.li` à la racine)
- **Librairie Lisaac** : `~/lisaac/lib/`
- **Compilation normale** (avec assertions/contrats) : `lisaac <fichier>`
- **Compilation boost** (sans assertions, x20 plus rapide) : `lisaac <fichier> -boost`
- **Gestion de version** : SVN ou GIT `svn add` / `svn rm` sont permis pour que les fichiers créés ou supprimés apparaissent dans le diff.
- **Ne jamais commiter**, quel que soit l'outil : l'utilisateur relit le diff et commite toujours lui-même.

---

## Lisaac — Guide de syntaxe essentiel

### Prototypes, slots et héritage

Lisaac est un langage **orienté prototype**. Tout est prototype, il n'y a pas de classes.

Les noms de prototypes sont en `Snake_case` avec majuscule initiale : `Nom_du_prototype`, `String_buffer`, `File_utils`, etc.

Le fichier d'un prototype porte son nom en minuscules : `Nom_du_prototype` est dans `nom_du_prototype.li`. Renommer un prototype, c'est donc aussi renommer son fichier (`svn mv`) et mettre à jour toutes ses références, `@Nom` dans les commentaires compris. Le qualificatif `Flat` de `+ name := Flat ...` ne compte pas dans le nom du fichier ; `ℤ` est une exception, dans `z.li`.

```
Header
  + name := Nom_du_prototype
Inherit
  - parent_any:Any := Any
Private
  ...
Public
  ...
```

**Slots `+` vs `-` :**
- `+` → slot **dupliqué** au clonage : chaque clone possède sa propre copie (équivalent champ d'instance)
- `-` → slot **partagé** entre tous les clones : équivalent variable globale du prototype

**Variables locales dans le corps d'une méthode :**
- `+ x:Int` → locale standard (pile)
- `- x:Int` → locale **persistante** : conserve sa valeur entre les appels (globale à portée locale)

**`self` vs `Self` :**
- `self` (minuscule) → l'objet courant (comme `this` en C++)
- `Self` (majuscule) → LE prototype de `self` (le "type" au sens prototype), utilisé pour les constructeurs

**`Flat` et `Exact` :**
- `Flat Foo` → le slot est **expansé inline** dans la structure parente (comme un `struct` dans un `struct` en C, pas un pointeur). Ne peut jamais être `NULL` par construction.
- `Exact Foo` → accepte **uniquement** ce type précis, pas ses sous-types. Permet des optimisations compilateur.

### Définition de méthodes

```lisaac
- nom_methode param1:Type1 param2:Type2 :TypeRetour <-
[ ? {précondition1}
  ? {précondition2}
]
( + locale:Int
  ...corps...
  résultat
)
[ ? {postcondition sur Result}
  ? {postcondition2 sur Result2}
]
```

- `<-` introduit la définition d'une méthode
- `[ ? {...} ]` avant le corps : **préconditions** (programmation par contrat)
- `[ ? {...} ]` après le corps : **postconditions** ; `Result` désigne la valeur de retour, `Result1`, `Result2`... pour les retours multiples
- La forme standard est `? {condition}` ; une simple expression booléenne `[ (condition) ]` est aussi vérifiée.
- Les contrats sont désactivés avec `-boost`. Doser avec soin : trop de contrats ralentit l'exécution, pas assez ouvre aux bugs.

### Fins de ligne — règle critique

- **`\n` seul** (LF) → fin de l'instruction courante, coupe la dernière instruction
- **`\r\n`** (CR+LF) → l'instruction **continue** sur la ligne suivante (continuation)

Autrement dit : un fichier avec des fins de ligne Windows (`\r\n`) produit des continuations là où un fichier Unix (`\n`) couperait. Cette distinction est sémantique, pas seulement stylistique.

Un `\n` termine l'instruction **même à l'intérieur de parenthèses** : un appel écrit sur plusieurs lignes sans `\r\n` est coupé, et l'erreur est trompeuse (par exemple « Slot `at' not found »). Dans le doute, garder l'appel sur une seule ligne, quitte à passer par des variables locales.

**Toute édition par script doit préserver les `\r\n`.** En Python, ouvrir le fichier avec `newline=''` : par défaut, `open()` convertit silencieusement les `\r\n` en `\n` et casse les continuations (erreurs du type `__postfix_or_or` non trouvé). Après l'édition, comparer le nombre de `\r` avec la version SVN (`svn cat f | tr -cd '\r' | wc -c`) et recompiler.

### Blocs et dispatch polymorphique

Les blocs `{...}` sont des objets de première classe. **Il n'y a pas de mots-clés de contrôle de flux** : tout est méthode définie en lib sur les prototypes `True`, `False`, `Block`.

```lisaac
(condition).if { ... }                      // if
(condition).if { ... } else { ... }         // if/else
if (condition) then { ... } else { ... }    // même chose, forme « phrase »
.elseif {condition2} then { ... }           // elseif (chaînable)
{condition}.while_do { ...corps... }        // while
{ ...corps... }.do_while { condition }      // do/while (récursif terminal dérécursivé)
n.times { ... }                             // répéter n fois (aussi : repeat n times { ... })
0.to (n-1) do { i:Int ... }                 // for loop (aussi : from 0 to (n-1) do { i:Int ... })
n.downto 0 do { i:Int ... }                 // for à rebours
collection.foreach { e:Type ... }           // foreach
collection.foreach_backward { e:Type ... }  // foreach à rebours (pour suppressions en cours d'itération)
```

Les formes `if c then`, `repeat n times` ou `from a to b do` existent parce qu'un slot peut prendre `self` comme argument (`- from self:Self to limit_up:Self do ...`) : le receveur s'écrit alors comme un argument.

**« French corner »** (pour les débutants, `lib/teaching/`, `lib/boolean/boolean.li`, `lib/number/integer/int.li`) : `répéter n fois { }`, `de a à b répéter { i:Int }`, `si (c) alors { } sinon { }`. À réserver aux tout premiers exemples : la lib est en anglais et le code des élèves doit y revenir vite.

### Appels de méthodes et parenthèses

- Les mots-clés font partie du nom de la méthode : `hilbert n:Int gauche l:Int` et `hilbert n:Int droite l:Int` sont **deux méthodes différentes**.
- Les parenthèses autour d'un argument simple sont **optionnelles** : `avance(80)` ≡ `avance 80`. Elles sont nécessaires pour un calcul (`avance (i * p)`), un nombre négatif (`tourne(-45)`) ou le résultat d'un appel (`(random.min 1 max 10).times`).
- Une signature à couple `- rectangle (longueur, largeur:Int)` s'appelle toujours avec parenthèses : `rectangle(300, 200)`.
- Les variables locales entières sont initialisées à 0.

**Évaluation paresseuse par dispatch :**
```lisaac
(a) && {b}   // b évalué seulement si a est True (méthode sur True/False)
(a) || {b}   // b évalué seulement si a est False
```

### Opérateurs de sortie

```lisaac
Out # valeur              // affiche valeur (stdout, sans retour ligne)
Out #| valeur             // retour ligne PUIS valeur
Out # valeur1 # valeur2   // chaînable
err # valeur #| autre     // même sémantique sur le Log d'erreur (avec flush disque sur #|)
```

`#|` déclenche un **flush disque** sur les logs — à éviter dans les boucles critiques.

### Chaînes de caractères

- `String_alias` : immuable, **internée** (unicité garantie dans tout le programme). Comparer avec `=` (comparaison de pointeur) suffit. Jamais mutable.
- `String_buffer` : mutable, non internée.
- `String.tmp { tmp:String_buffer ... }` : alloue un `String_buffer` temporaire depuis un pool, automatiquement libéré à la fin du bloc.

```lisaac
String.tmp { tmp:String_buffer
  tmp # "hello " # name # " !"
  k := tmp.to_string_alias   // interning
}
```

### Externals C

```lisaac
`expression_c`:TypeRetour           // external sans effet de bord
`expression_c`:(TypeRetour)         // external AVEC effet de bord
```

- Sans `()` : si le résultat n'est **pas utilisé**, le compilateur **supprime** l'external (dead code elimination).
- Avec `()` : l'external est **toujours conservé** même si le résultat n'est pas utilisé.
- `@variable` dans un backtick → référence à une variable Lisaac depuis le C.
- **Restriction importante** : dans un external, on ne peut accéder qu'aux **variables locales** et **arguments** de la méthode courante via `@`. Les slots du prototype ne sont **pas** directement accessibles — il faut les affecter au préalable à une variable locale.

### Tuples et affectations multiples

```lisaac
(a, b) := (x, y)
(i, result) := Json.parse_int "key" in (buf, i)
```

### NULL

`NULL` est la valeur nulle (équivalent `nil`/`null`). Tester avec `!= NULL` ou `= NULL`.
Les slots `Flat` ne peuvent jamais être `NULL`.

### Constructeurs idiomatiques

```lisaac
- new:Self <- clone                         // constructeur simple
- init param:Type :Self <- ( ...; self )   // initialisation chaînable, retourne self
```

Pour pouvoir appeler `clone`, un prototype qui n'hérite d'aucun prototype en disposant (`Window`, etc.) doit insérer `Clone` :

```lisaac
Insert
  - parent_clone:Clone := Clone
```

---

## Collections courantes de la lib

| Type | Description |
|---|---|
| `Array V` | Tableau redimensionnable, borne basse 0 |
| `Flat Array (Exact Foo)` | Tableau inline expansé, type strict |
| `Linked_list V` | Liste doublement chaînée |
| `Hset` / `Hmap` | Hash set / hash map |
| `fast_reference_at_key k` | Recherche par égalité de pointeur (pour `String_alias`) |

---

## Règles générales pour les suggestions de code

1. **Respecter la sémantique `+`/`-`** sur les slots : ne jamais confondre slot partagé et slot dupliqué.
2. **Ne jamais créer de mots-clés** : `if`, `while`, `foreach` sont des **méthodes**, pas des mots-clés.
3. **Préserver les contrats** `[ ? {...} ]` existants. En ajouter avec parcimonie sur les méthodes publiques critiques. Ne pas en mettre dans les boucles internes chaudes.
4. **`String_alias` pour les clés et constantes**, `String_buffer` pour la construction de chaînes.
5. **Utiliser `String.tmp { tmp:String_buffer ... }`** pour toute construction de chaîne temporaire.
6. **`foreach_backward`** pour les suppressions en cours d'itération sur les collections.
7. **Externals C avec `()`** si effet de bord, sans si résultat seul nécessaire.
8. **Ne pas utiliser `Self` à la place de `self`** : ce sont deux choses fondamentalement différentes.
9. **Les `Flat` ne sont jamais `NULL`** : inutile de les tester.
10. **Dans les commentaires, préfixer par `@` les variables et les noms de prototypes** (par exemple `@i`, `@nb`, `@True`, `@False`, `@Array`, `@ℤ`) : elit les affiche alors correctement. Ne pas en mettre dans un extrait de code cité tel quel (`Out # ...`, `i:Int`).

---

## Compilation et validation

```bash
# Compilation avec assertions (développement)
lisaac mon_fichier

# Compilation sans assertions (production/bench)
lisaac mon_fichier -boost

# La compilation produit du C, puis gcc est invoqué automatiquement
```

En cas d'erreur de compilation, analyser le message Lisaac avant le message gcc.

Pour vérifier qu'un fichier compile sans rien laisser derrière soi : `lisaac <fichier> -q`, puis supprimer le binaire, le `.c` et le dossier `assets/` générés dans le répertoire courant.

Un prototype qui hérite de `Tortue` sans définir `dessin` (parent abstrait, comme `Curseur_tortue` ou `Rosace`) ne compile pas seul : c'est normal. Pour les exemples Tortue, `./auto_test.sh tortue_show.li` compile tous les exemples qui contiennent ` dessin `.
