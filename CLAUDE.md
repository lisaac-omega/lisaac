# CLAUDE.md — Développement en Lisaac

## Présentation

Ce projet est écrit en **Lisaac**, un langage orienté prototype (pas de classes),
compilé vers du C ANSI puis vers un binaire natif via `gcc`.

## Chemins importants

- **Projet** : répertoire courant (fichiers `.li` à la racine)
- **Librairie Lisaac** : `~/lisaac/lib/`
- **Compilation normale** (avec assertions/contrats) : `lisaac <fichier>`
- **Compilation boost** (sans assertions, x20 plus rapide) : `lisaac <fichier> -boost`
- **C lisible** (option cachée) : `lisaac <fichier> --r` garde des identifiants lisibles dans le C. Par défaut, le C est volontairement illisible (`li__QXC`…) : ne pas changer ce choix, utiliser `--r` pour lire ou profiler le C.
- **Gestion de version** : SVN ou GIT `svn add` / `svn rm` sont permis pour que les fichiers créés ou supprimés apparaissent dans le diff.
- **Ne jamais commiter**, quel que soit l'outil : l'utilisateur relit le diff et commite toujours lui-même.

---

## Lisaac — Guide de syntaxe essentiel

### Prototypes, slots et héritage

Lisaac est un langage **orienté prototype**. Tout est prototype, il n'y a pas de classes.

Les noms de prototypes sont en `Snake_case` avec majuscule initiale : `Nom_du_prototype`, `String_buffer`, `File_utils`, etc.

Un nom d'**une seule lettre majuscule** (`T`, `V`, `E`...) désigne toujours un paramètre de type générique, comme `V` dans `Array V`. Ne jamais l'utiliser comme nom de prototype : même un programme de test nommé `T` fait planter le compilateur (erreur de segmentation).

Le fichier d'un prototype porte son nom en minuscules : `Nom_du_prototype` est dans `nom_du_prototype.li`. Renommer un prototype, c'est donc aussi renommer son fichier (`svn mv`) et mettre à jour toutes ses références, `@Nom` dans les commentaires compris. Le qualificatif `Flat` de `+ name := Flat ...` ne compte pas dans le nom du fichier ; `ℤ`, `ℚ`, `ℝ` et `ℂ` sont des exceptions, dans `z.li`, `q.li`, `r.li` et `c.li` (table `utf8_dico` de `src/lisaac_common.li` : un nouveau type de ce genre demande de recompiler le compilateur).

```
Header
  + name := Nom_du_prototype
Insert
  - parent_utils:Utils := Utils
Private
  ...
Public
  ...
```

Il n'y a **pas de racine commune** dans Lisaac Ω : pas de `Any` ni d'`Object` dans la lib. Les parents communs d'un programme portent son nom et s'insèrent (`Lisaac_common` dans `src/lisaac_common.li` pour le compilateur, `Elit_common` pour elit, `Elito_common` pour elito). Un prototype sans parent est permis. Les slots d'usage général (`crash_with_message`, `is_debug_mode`…) sont dans `Utils`, à insérer quand on en a besoin, comme le fait `Numeric`. Un nom de prototype est visible partout : c'est la façon d'avoir une constante globale.

**`Inherit` vs `Insert` :**
- `Inherit` → le prototype est un **sous-type** de son parent : il est conforme à son type (affectation à une variable du type parent, liaison dynamique). Exemple : `+ parent_div:Flat Div` dans un widget qui doit prendre place dans un arbre de `Div`.
- `Insert` → le prototype **reprend les slots** du parent sans en être un sous-type : boîte à outils (`Utils`, `Clone`), état ou commandes partagés.
- Pas de polymorphisme par `Insert` : pour qu'une affectation `a := b` soit possible, il faut un chemin d'`Inherit` du type de `b` vers celui de `a`. Choisir `Insert` par défaut, et `Inherit` seulement quand ce chemin est voulu.
- La recherche d'un slot parcourt les parents **en profondeur, dans l'ordre de lecture du fichier** : l'ordre des parents compte. Les sections `Inherit` et `Insert` peuvent se répéter et s'alterner : pour changer un parent de section, l'encadrer d'une nouvelle section à sa place, sans changer l'ordre.

**Slots `+` vs `-` :**
- `+` → slot **dupliqué** au clonage : chaque clone possède sa propre copie (équivalent champ d'instance)
- `-` → slot **partagé** entre tous les clones : équivalent variable globale du prototype

**Redéfinition et appel au parent (le `super` de Java) :** un slot redéfini appelle la version de son parent par le nom du slot parent : `parent_recyclable.free`, `parent_signed_integer.append_in b`. Le compilateur reconnaît ce renvoi (`is_resend` dans `Itm_read`) : le slot du parent s'exécute avec le `self` courant, pas avec l'objet parent.

```lisaac
- free <-
( (expr != NULL).if { expr.free; expr := NULL; }
  parent_recyclable.free   // super.free
)
```

**Variables locales dans le corps d'une méthode :**
- `+ x:Int` → locale standard (pile)
- `- x:Int` → locale **persistante** : conserve sa valeur entre les appels (globale à portée locale)

**`self` vs `Self` :**
- `self` (minuscule) → l'objet courant (comme `this` en C++)
- `Self` (majuscule) → LE prototype de `self` (le "type" au sens prototype), utilisé pour les constructeurs

**`Flat` et `Exact` :**
- `Flat Foo` → le slot est **expansé inline** dans la structure parente (comme un `struct` dans un `struct` en C, pas un pointeur). Ne peut jamais être `NULL` par construction, sauf si sa valeur par défaut est `NULL`, comme `Pointer` (voir la section NULL).
- `Exact Foo` → accepte **uniquement** ce type précis, pas ses sous-types. Permet des optimisations compilateur.
- **Les champs `+` d'un parent `-` sont partagés** : avec `- parent_r_node:R_node := R_node`, tous les héritiers lisent et écrivent les champs de l'objet `R_node` lui-même. Pour qu'un héritier ait ses propres champs (un prototype utilisé comme objet, comme `Pi`), écrire `+ parent_r_node:Flat R_node` dans `Inherit`, comme `+ parent_window:Flat Window`.
- Un `Flat` qui contient un autre `Flat` à plusieurs champs (un `ℚ` dans un `ℝ`) peut produire un C faux (« invalid type argument of unary `*` ») : ranger plutôt les champs eux-mêmes (deux `ℤ`), comme dans `r.li`.

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

Tant qu'une instruction n'est pas terminée, on va donc à la ligne avec `\r\n` ; seul le `\n` de sa dernière ligne la termine. Exception : une ligne qui commence par `.` (`.elseif`, `.when`) continue l'instruction précédente même après un `\n` seul. Les lignes de continuation sont indentées de 2 espaces de plus que la première ligne de l'instruction (sauf celles qui commencent par `)` ou `}`, alignées sur leur ouverture), et l'indentation revient au niveau de départ après le `\n` final :

```lisaac
    p := Paint.create_box (32,32) size (w-64,h-64)\r
      radius 64 feather 64\r
      color (color.focus_off)\r
      to (Color.rgba(0FFh,0FFh,0FFh,0))
    pen.fill_paint p
```

Le `\r` est écrit ici pour le montrer, mais il est invisible dans un fichier (`cat -A` l'affiche en `^M`) : c'est l'indentation qui montre ce qui appartient à l'instruction. Le vieux code (écrit avant cette règle) contient souvent des instructions sur plusieurs lignes terminées par de simples `\n` : en le reprenant, ajouter les `\r` et réindenter.

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
- Mais **pas de surcharge par le nombre d'arguments** : `init` et `init p:Win` sont le même slot (« Incorrect number argument »). Un nom générique ajouté à un parent commun (`init`, `free`, `new`...) peut donc entrer en conflit avec un slot d'un héritier ou d'un autre parent.
- Les parenthèses autour d'un argument simple sont **optionnelles** : `avance(80)` ≡ `avance 80`. Elles sont nécessaires pour un calcul (`avance (i * p)`), un nombre négatif (`tourne(-45)`) ou le résultat d'un appel (`(random.min 1 max 10).times`).
- Une signature à couple `- rectangle (longueur, largeur:Int)` s'appelle toujours avec parenthèses : `rectangle(300, 200)`.
- **Style des signatures** : dans le nouveau code, pas de parenthèses autour d'un argument seul : `- init sp:String base base:Int :Self`, pas `- init (sp:String) base (base:Int) :Self`. C'est seulement une question de look : la signature est la même et les appels ne changent pas. Les parenthèses restent pour les couples (`(a,b:Int)`). Ne pas retoucher l'ancien code pour cela.
- Les variables locales entières sont initialisées à 0.
- **`<>` sur un opérateur ne permute pas les arguments** : il autorise la *promotion du receveur*. Dans `3 - 4 i`, le `-` de `Int` ne prend pas de `ℂ` ; comme `Int` exporte vers `ℂ` (`- export := ..., ℂ`, conversion par `to_c`), le compilateur convertit `3` en `ℂ` et appelle le `-` de `ℂ`. Il faut `<>` sur les deux slots (voir `commutativity` dans `src/dispatcher/node.li`). Les opérateurs non commutatifs (`-`, `/`) peuvent donc porter `<>`.
- **Appel d'un slot sans argument : plusieurs écritures.** La forme d'origine est `x.print`, mais le point est optionnel et, selon le contexte, `x print`, `print(x)` et `print x` passent aussi. Après une constante, `2 i` et `2.5 i` marchent ; après une variable, `y i` échoue (« Slot `i' not found » : `i` est cherché dans `self`). Il faut alors `y.i`, `(y) i`, `i(y)` ou `i y`. Pour ℂ, on écrit `x + i y`, comme en maths : dans du code qui manipule des ℂ, ne pas nommer de variable locale `i` (elle masquerait le slot).

`.elseif` se chaîne après `if`, jamais après `if_false` : `False.if_false { ... }` rend `False`, donc le `.elseif` qui suit s'exécute **aussi**. Écrire `(! c).if { ... }.elseif ...`.

**Évaluation paresseuse par dispatch :**
```lisaac
(a) && {b}   // b évalué seulement si a est True (méthode sur True/False)
(a) || {b}   // b évalué seulement si a est False
```

### Opérateurs de sortie

```lisaac
Out # valeur              // affiche valeur (stdout, sans retour ligne)
Out #| valeur             // valeur PUIS retour ligne
Out |# valeur             // retour ligne PUIS valeur
Out # valeur1 # valeur2   // chaînable
err # valeur #| autre     // même sémantique sur le Log d'erreur (avec flush disque sur #| et |#)
```

`Out # x` est un raccourci de `x.print`, plus compact, et évite les allocations des `+` entre chaînes : `Out # "a" # b #| c` plutôt que `("a" + b + c).println`. Quand le dernier morceau est une chaîne constante, y laisser le `\n` (`Out # "Done.\n"`) ; sinon finir par `#|` (`Out #| msg`) ; une ligne vide seule s'écrit `Out # '\n'` (un `Char` est plus léger qu'une chaîne). La référence reste le code : `lib/io/out.li`, `lib/io/log.li`.

`#|` et `|#` déclenchent un **flush disque** sur les logs — à éviter dans les boucles critiques.

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
- **Sections C d'un prototype** : `- include := `...`` va dans l'en-tête, vu par tout le C ; `- external := `...`` va dans le fichier des données (`_data.c` avec `-split`). Une fonction C appelée depuis le code d'un slot (un backtick) se met donc dans `- include`, en `static inline` (comme `li_is_zero` de `C_array`) ; sinon, avec `-split`, le lien échoue (« référence indéfinie »). `- external` est pour les définitions de données globales (un tableau initialisé), qui ne doivent exister qu'une fois.

### `lip` : évalué à la compilation par lisaac

`lip "x" str`, `lip "x" int` et `lip "x" bool` (primitive `` `26` `` de `String_alias`) lisent une variable de `make.lip` **pendant la compilation par `lisaac`** : le C généré ne contient que le résultat, figé. Ce n'est donc pas une information sur la machine qui exécute.

`build_lisaac.c` est livré tout généré dans le zip et compilé par `gcc` sur la machine de l'utilisateur : il a été produit sur la machine de release, avec sa cible et ses chemins. **Rien de ce qu'atteint `build_lisaac.li` ne doit dépendre de `lip`.** Le même raisonnement vaut pour `bin/lisaac.c`. Plus généralement, préférer une information obtenue à l'exécution :

- système : `System.name` (`#if defined(...)` en C, résolu par `gcc` sur la bonne machine) ;
- chemins : `Command_args.executable_directory`, `Environment.read_variable`.

Pour vérifier, le C généré doit être identique d'une cible à l'autre et ne contenir aucun chemin de la machine :

```bash
lisaac build_lisaac -boost -q && cp build_lisaac.c /tmp/unix.c
lisaac build_lisaac -boost -q -target windows
diff /tmp/unix.c build_lisaac.c
```

### Tuples et affectations multiples

```lisaac
(a, b) := (x, y)
(i, result) := Json.parse_int "key" in (buf, i)
```

### NULL

`NULL` est la valeur nulle (équivalent `nil`/`null`). Tester avec `!= NULL` ou `= NULL`.
Les slots `Flat` ne peuvent jamais être `NULL`, sauf ceux d'un type dont la valeur par défaut (`- default` du `Header`) est `NULL`, comme `Pointer` (`void *`) : ceux-là se testent avec `= NULL` ou `!= NULL`. Il n'y a pas de `is_null` : ce serait un message envoyé à `NULL`.

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

### COP : objets actifs (multithread)

Modèle en cours de refonte : voir le journal `doc/cop_modele.md` (choix datés, pour un article).

Avec l'option `-cop`, un prototype nommé avec `-` (`- name := Worker`) est un **objet actif** : chaque clone ouvre un **univers**, avec sa file de messages (FIFO) et son **socle** (`struct universe_base`) qui contient sa propre copie de tous les slots `-` du programme, initialisée dans le nouvel univers (`li_init_base`). Les univers tournent sur une **réserve de fils** (un par cœur, variable d'environnement `LI_THREADS`) : un univers n'est qu'une file et un état, un message s'exécute jusqu'au bout. Sémantique formelle et preuves : `doc/cop_semantique.md`, `doc/tla/`, `doc/lean/`.

- Un slot **sans résultat** (`- run <-`) est **asynchrone** : l'appel dépose un message (arguments copiés dans une `struct msg_<slot>`) et rend la main tout de suite.
- Un slot **avec résultat** ou la lecture d'un slot de donnée sont **synchrones** : l'appelant attend son tour dans la file, puis exécute le message dans l'univers du receveur. Lire `w.done` après `w.run` attend donc la fin de `run`.
- Vers son propre univers (`self` implicite, ou une variable qui désigne l'univers courant), un message s'exécute **immédiatement**, comme un appel ordinaire.
- **Envoi terminal** : un envoi asynchrone en dernière instruction d'un slot appelé seulement par des messages (comme une récursivité terminale) devient `li_send_tail` : à la fin du message, si le receveur est au repos, le même fil le prend et l'exécute aussitôt, sans passer par sa file ni par l'ordonnanceur (`Profil.mark_cop_tail`, `li_run`).
- Ce qui passe d'un univers à l'autre (arguments d'un message asynchrone, résultat d'un message synchrone ou lecture d'un slot) doit être une **valeur** (type C, `Flat` sans pointeur), un objet **immuable** ou un **objet actif** ; sinon, erreur à la compilation. Un message synchrone peut aussi **emprunter** un objet modifiable de l'appelant, si sa fonction ne le garde pas. L'analyse (`src/cop/escape.li`) affiche à la compilation les types immuables (`Immutable types:`) : un objet est immuable si toutes ses écritures ont lieu avant qu'il échappe (création, initialisation).
- Un bloc n'est jamais une valeur (fermeture sur l'univers de l'appelant) : `Parallel` et `Cop_job` sont refusés avec `-cop`.
- **Transfert** : un message asynchrone peut aussi emporter un objet modifiable frais que l'appelant n'utilise plus après l'envoi ; un message synchrone peut renvoyer un objet neuf. Pour partager des données en lecture : `Immutable_array V` (comme `String_alias`). L'option `-cop_report` (dans `make.lip`) affiche le rapport de l'analyse (types immuables, raisons).
- Le clone d'un objet actif repart des **valeurs initiales** de ses champs, calculées dans le nouvel univers (pas une copie de l'objet cloné) : lui transmettre ce qu'il faut par message.
- **`One`** (devant `Flat`/`Exact`, `+ a:One Array Int`) : un objet à référence unique, qui peut passer d'un univers à l'autre (déplacé) sans copie ni verrou. `a := b` entre `One` déplace l'objet : une variable `b` ne peut plus être lue (contrôle statique ; `NULL` en debug, rien en `-boost`), un champ `b` devient `NULL` dans les deux modes (un autre message peut le relire et le comparer à `NULL`) ; un `One` ne se range que dans un `One` ; il ne doit plus être utilisé après son envoi. Un `One` possède son contenu : `o.raw` ne peut pas rendre un pointeur de tableau C (`C_array`) de `o`, sauf un champ `One` (`+ data:One C_array Int`), qui se déplace alors dans une variable `One`.
- Un prototype ordinaire **modifié** par le programme (détecté par le compilateur) a une copie dans le socle de chaque univers ; les autres prototypes sont partagés.
- Un univers neuf démarre à son premier message (son initialisation passe en tête de sa file) ; la fin du programme lance ceux qui n'en ont reçu aucun (`li_lazy_start`). Le programme se termine quand tous les univers sont au repos.
- Un cycle de messages synchrones (`a` attend `b` qui attend `a`) est un interblocage : en debug, il arrête le programme (`COP Error: deadlock: cycle of synchronous messages!`) ; en `-boost`, le programme se bloque.
- Sans `-cop`, le C produit est exactement celui d'avant.

`Parallel` (`lib/cop`) et les benchmarks `-cop` de `example/shootout/` ne marchent plus avec ce modèle : leurs blocs utilisent les slots `-` de `Main`, propres à chaque univers. Ils seront repris quand la communication entre univers existera.

**Bloc et variables locales** : un bloc qui n'est pas inliné dans la fonction C de son appelant (passé à `Parallel`, ou au comparateur de `quick_sort_with`, qui est récursif) ne doit pas utiliser les variables locales de l'appelant : le C produit ne compile pas (« undeclared »). Passer ces valeurs par des slots du prototype.

**Coordination** (`lib/cop`) : un univers ne peut pas attendre « jusqu'à ce que » (un message synchrone attend seulement son tour) ; on passe par un univers à états qui répond par un message (style acteur). Briques génériques sur le type `W` de ceux qui attendent ; chaque demande porte un numéro `tag k` (choisi par le demandeur), rendu dans la réponse :

- `Semaphore W` : `acquire self tag k` puis le message `acquired k` (à une place, c'est un verrou) ; `release`.
- `Latch W` : `count_down` ; `await self tag k` puis `opened k` quand le compte est nul.
- `Barrier W` : `arrive self tag k` puis `passed k` quand les `n` sont là (cyclique).
- `Channel V From P To C` : canal borné ; `put v from self tag k` puis `ready k` (contre-pression), `take self tag k` puis `receive v tag k` ou `closed k` après les `finish` des producteurs.
- `Timer W` : `after ms for self tag k` puis `timeout k` (un univers qui dort par délai).

`Shared E` (`lib/kernel/shared.li`) : n'importe quel prototype partagé par plusieurs univers, sans verrou (`m := Shared (Array Int) .new`, puis `m.add_last 1` asynchrone, `m.count` synchrone). Un objet actif qui tient son `E` en ligne (`Insert + parent_e:Flat E`) ; chaque appel est un message, atomique (pas une suite d'appels : une opération composée s'écrit dans un héritier). Un bloc (`m.foreach { }`) est refusé.

L'option `-cop_report` (dans `make.lip`) affiche aussi la liste des messages COP.

Exemples : `example/cop/` (sieve, producer_consumer, philosophers, parallel_sum, ring, bank, channel, thread_ring, pairs, primes, inference, contention, heat), compilés avec `lisaac main -cop`. Comparaison avec Go, Erlang, Pony et Java : `doc/bench_langages/run.sh`.

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
9. **Les `Flat` ne sont jamais `NULL`** : inutile de les tester, sauf si leur type a `NULL` pour valeur par défaut (`Pointer`).
10. **Dans les commentaires, préfixer par `@` les variables et les noms de prototypes** (par exemple `@i`, `@nb`, `@True`, `@False`, `@Array`, `@ℤ`) : elit les affiche alors correctement. Ne pas en mettre dans un extrait de code cité tel quel (`Out # ...`, `i:Int`).
11. **Pas de code ni de pseudo-code dans les commentaires d'en-tête** : il n'existe pas encore de moyen de bien formater du code Lisaac Ω dans un commentaire, et un pseudo-code à la Python (`for j from m down to 1:`) n'a pas le look Lisaac Ω. Décrire l'algorithme par une phrase ou une formule mathématique (`s(k+1) = s(k)^2 - 2`) ; le code est juste en dessous.
12. **Pas de commentaire redondant** : le code Lisaac Ω se lit de lui-même (mots-clés dans les noms des slots, `if c then`, `from a to b do`, contrats). Un commentaire dit ce que le code ne dit pas : le pourquoi, une précaution, un renvoi vers un autre prototype. Jamais de paraphrase d'une ligne de code (`// Remove the .c file.` au-dessus de `file_remove path`).

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
