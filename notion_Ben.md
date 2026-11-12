# <u>Introduction</u>

Ce projet a pour but de nous faire explorer le concept de “docker” et tout ce qui tourne autour du concept de container. 

On peut parfois dire que c’est un sujet a la *Born to Be Root* (B2BR) en plus avance. Car au dela des notions de Docker, on va devoir aussi mettre en place differents services, qu’on a plus ou moins deja rencontre et aussi de nouvelle chose.

En plus de docker on va voir ; NGINX, wordpress, mariadb et les conceptes autour de TLS. 

Cette documentation va essayer d’expliquer les conceptes et aussi un peu ce que j’ai mis en place, en sachant qu’il y plusieurs manieres de faire et que je ne compte pas faire les bonus.

Precision importante ; on doit rendre un readme, mais aussi 2 autres documents en .md avec des instructions pour un utilisateur lambda et un dev. Ce qui fait partie de la nouveaute du projet depuis fin 2025 / debut 2026.

# <u>VM</u>

Les VM, virtual machines, on a pu les voir dans le projet B2BR. On va en reparler ici un moment pour faire un rappel entre autre et aussi expliquer pourquoi on va utiliser une VM dans notre projet a l’ecole 42.

### <u>C’est quoi un VM ?</u>

Une machine virtuel existe grace a ce qu’on appelle un *hypervisor*. 

L’hypervisor va permettre de simuler une autre machine. Mais pour ca, pour faire ce genre d’operation, l’hypervisor va avoir besoin de reserver des ressources de la machine qui l’heberge, qu’on appelle l’*host*.

Donc l’hypervisor, lui il va prendre du CPU, de la memoire etc….Parce qu’une fois qu’il va se lancer, l’OS qui est lancer pour lui, rien n’existe d’autres. Il n’est pas au courant que vous avez une machine qui le fait tourner. Pour lui tout est natif de chez lui.

Ce point est tres important pour la suite des explications avec Docker.

On a l’habitude voir des schemas dans ce genre pour resumer tout ca ; 

!image.png

### <u>Les avantages et defauts des VM</u>

*avantages*;
-permet d’avoir un autre OS sur votre machine qui fonctionne avec un autre OS. Vous pouvez comme ca lancer des tests sur différents OS, ou apprendre de nouvelles choses sur un OS. 
-permet de bien separer, d’isoler tout ce qui se passe sur cette machine. Les malwares sont souvent lance dans des environnements virtuels pour essayer de les reverse.
-on peut faire des snapshot et revenir en arriere facilement.

*desavantages*;
-demande des ressources
-plus lent car on passe par differentes couches de l’OS installe sur la VM a l’hypervisor jusqu’a l’OS de notre host et l’hardware finalement.

### <u>Pourquoi on va utiliser une VM ?</u>

On devait pas utiliser docker ?

On va l’utiliser, rassurez-vous (*start a panick attack right now*), mais comme on doit avec docker installez differentes choses (et docker lui meme) nous n’avons pas les droits root sur nos machines a 42.

Donc on va lancer une machine virtuel, sur laquelle on va installer ce qu’il faut pour lancer docker et tout mettre en marche. 

# <u>**DOCKER**</u>

### <u>Qu’est ce que docker ?</u>

Docker est un outil qui permet de gerer des containers, un programme qui permet de faire de la containerisation.

<u>qu’est ce qu’un container ?</u>

*On peut ecrire “container” ou “conteneur”, l’un etant le terme anglophone, l’autre francophone, dans le reste de cette explication je risque d’utiliser les deux.*

Un container est un ***environnement isole***, qui permet d’executer une application avec toutes ces dependances, ***en partageant le kernel de l’host***.

Ainsi une personne qui “prend” votre “docker” va pouvoir lancer votre programme sur ca machine sans avoir de soucis d’environnement. Il aura les meme reglages, les meme parametres que sur votre machine a vous.

Ce qui vient resoudre une problematique connu de “ca marche sur ma machine”, alors que ca marche pas sur la votre. 

### <u>VM vs docker</u>

On peut se poser la question suivante ; “du coup quelle est la difference avec une VM ? La aussi je peux avoir tout ce qu’il faut pour lancer comme il faut”

Dans la définition de container, j’ai pu preciser que le container partage le kernel de l’host, ce qui est different de la VM qui va avoir son propre OS.
Ce qui veut dire que si vous etes sur linux, vous ne pouvez pas lancer un docker qui fonctionne avec windows. Il faut passer par une VM
*L’inverse est possible grace a WSL que Microsoft a mis en place.*

Meme si j’ai precise plus tot que le container est “isole”, il s’agit surtout d’un point important a developper plus tard. Mais les VM eux sont plus fortement isole, ce qui se passe dans votre VM reste dans votre VM.

Docker est plus rapide qu’un VM car il ne passe pas par differentes couches avant de lancer ces services (voir image plus haut sur VM pour comparaison), pour Docker il s’agit juste d’un lancement de process.

### <u>**Isolement**</u>

Dans la definition de container, on a parle de “***environnement isole***”. Pour autant on a aussi dit que c’etait pas tout a fait comme dans une VM. Donc de quoi je voulais parler exactement ?

Un ordinateur classique, lorsque vous lancez un programme, cela lance un process. Ce process en realite peut communiquer avec les autres, l’OS manipule ce process etc….

Mais avec docker on a une premiere notion importante de l’isolement ;  **les namespaces**

Les **namespaces**, c’est ce qui permet de faire l’isolation ;
*des processus
*reseau
*systeme de fichier
*les utilisateurs

Donc au yeux du container, il est le seul processus existant. Pour l’ordinateur ce docker a un PID XXX alors que pour le container lui il pense avoir juste le PID 1. 

La seconde notion importante pour l’isolement ; **le cgroups**

Le **cgroups**, lui permet de faire l’isolation de l’utilisation de;
*la memoire
*le CPU
*l’entree / sortie du disque

La aussi concept important car cela permet de limiter l’utilisation des ressources (on pourrait dire que c’est une genre de protection).

### <u>**Docker Engine**</u>

*On va rester sur des idees simple ici, car il s’agit du coeur de Docker et va me servir plus de tremplin pour les prochaines explications.*

On vient d’expliquer l’objectif de docker, la difference avec une VM et l’isolement. Mais tout ca est possible grace au docker engine.

Le daemon (=programme qui s’execute en arriere plan) docker ; ***dockerd*** 
va gerer ce dont on va parler par la suite dans cette documentation; 

*les images
*les containers (= ce qui est lance)
*le reseau
*les volumes

c’est le process principal de docker.

Pour pouvoir l’utiliser, nous on utilisera ***docker cli***.

C’est simplement ce qui va permettre de rentre des commandes pour manipuler docker et les containers qu’on va lancer.

Les commandes commencent toujours par le mot “docker” suivit de ce qu’on veut faire; 
docker ps
docker run
docker build 
etc…..

### <u>**Docker Images & containers**</u>

On a pu voir que dockerd gere les images et les containers.

<u>Mais qu’est ce que c’est que docker image ?</u>

Une image docker, c’est un modele en read-only qui permet de lancer un container.
Pour creer une image docker on va passer par un ***dockerfile***, c’est ce qui permet de creer des images.

Donc on a ce chemin; 
dockerfile → docker image → container

Ce qui est interessant c’est que la rapidite de Docker vient entre autre de ce mecanisme.

<u>Qu’est ce qui se cache derriere une image ?</u>

Une image est compose de plusieurs layers. Ces layers proviennent des instructions qu’il y a dans les docker files.

Mais les differentes couches sont partages entre les images. Donc si on cree plusieurs images mais quelles utilisent par exemple toutes le meme OS (directive FROM qu’on verra plus loin), il va garder cette information et va partager cette couche avec les autres images. 

L’autre avantage a ce partage, c’est que docker va pouvoir garder en cache les informations des differentes couches. Donc si une modification est apporte mais qui ne touche pas a certaines couches, il ne va rien modifier.

Ensuite les conteneurs, ne vont faire qu’ajouter au couches des images leurs propre layer qui permet ici de faire des operations, des modifications.

### <u>**Volumes**</u>

Lorsqu’on lance un container, on va le manipuler, faire surement des operations sur l’application qu’on va lancer, bref utiliser l’outil.

Les donnees ajouter / modifier lors de cette etape vont etre enregistre, si on eteind simplement le container. 

Par contre si on supprime container, on vient de supprimer le layer que le lancement du container ajoute (precedent point) et la on perd les donnees.

Cependant, il y a un concept important qu’on peut mettre en place; **les volumes**

Les volumes c’est simplement un endroit ou on va pouvoir enregistre les informations et faire en sorte que les informations ne soient plus lie au cycle e vie du container.

Comme ca on ne doit pas tout recommancer de 0.

Pour nous aider a gerer les volumes, on va utiliser un outil docker en particulier ;

### <u>Docker compose</u>

On a pu voir que chaque container est isole par defaut, ils vivent leurs vie indépendamment des autres. Mais nous on va vouloir utiliser plusieurs services ensemble, chaque service etant dans un container.

Donc on doit faire communiquer et fonctionner les containers ensemble. Pour ca on va utiliser **docker compose**

Docker compose, c’est l’outil de gestion multi container qui permet de tout faire a partir d’un seul endroit (= un seul fichier).

Dans l’idee pour notre projet, on va ecrire des dockerfiles pour nos services et ils vont etre lancer par le docker compose comme il faut avec les indications sur les volumes et autres.

maintenant on peut enfin parler de notre projet plus concretement; 

# <u>**Architecture du projet**</u>

L’enonce nous donne une image qui represente l’architecture du projet qu’on va expliquer ici en detail; 

!image.png

On va avoir 3 services a lancer ; 
*NGINX
*Wordpress + php
*MariaDB

On va avoir 2 volumes; 
*pour wordpress
*pour la base de donnes

Chaque service va avoir son propre container. 

On va devoir mettre en place un reseau docker qui fait que les communications arrivent toujours dans un sens precis. 

NGINX va recevoir tout ce qui est de l’exterieur (on en reparle plus en detail par la suite) et va repondre. 
NGINX ne peut communiquer qu’avec wordpress qui lui a acces a la base de donnee. 
Tout ce chemin de communication doit etre respecter avec les bons ports mis en place.

*je ne donne pas de precision ici sur ce qu’est un port (allez voir netpractice ou la documentation sur Webserv).*

### <u>**Le port 443**</u>

C’est le port qui devrait attirer votre attention ! 

Le port 443 c’est le port HTTPS ! C’est celui ci qui doit etre utilise pour acceder a NGINX.

Dans B2BR, on utilisait simplement le port HTTP (80), mais la on va devoir comprendre et mettre en place tout ce qu’il faut pour etre bien sur le S de HTTPS. 

Dans l’enonce on nous demande de bien utilise  TLSv1.2 ou TLSv1.3 (plus de details a ce sujet plus tard) mais c’est ce qui permet de mettre en place le HTTPS.

### <u>**NGINX**</u>

Engine X (oui ca se prononce se dit comme ca)

C’est un outil qu’on va explorer dans webserv, ca permet de faire des server mais aussi d’autres choses comme ici ou on va l’utiliser en tant que reverse proxy.

un reverse proxy est un serveur qui est en face d’autres server / services / etc… 

Ce qui permet de gerer le traffic ainsi que la securite

### <u>**Wordpress & MariaDB**</u>

on a deja rencontre ces services dans B2BR. 

Wordpress, l’outil favoris d’Eric dans son precedent job.

MariaDB, la base de donnee SQL 

bref tout est connecte et ca fait des chocapic I guess.

# <u>Mises en place VM</u>

Sur mon ordinateur perso; j’ai DL Virtual Box avec la version de l’ecole (ou moment ou j’ecris ces lignes, d’ici la il y a peut etre eu des mises a jour sur les nouveau dump).

*Ici le choix est pas tres important, mais il faut faire attention pour les docker files, il faut utiliser la version penultimate ⇒ ce qui va etre bookworm car penultimate ca veut dire avant dernier. Pour la VM techniquement ca n’a pas d’importance la version mais avec Trixie (last version) ca va etre plus chiant de mettre docker etc…*

!image.png

Ensuite une fois cette version installe ;

!image.png

!image.png

!image.png

!image.png

et apres globalement j’ai tout mis par defaut en suivant ce guide ; https://goopensource.fr/debian-installation-sans-interface-graphique/

*Le choix de ne pas mettre d’interface graphique est un probleme pour plus tard sur certains points mais ca peut se changer et c’est suffisant pour commencer*

j’ai du installer a un moment donne sudo en me mettant en root 

!image.png

### <u>**SSH installation, vim & make**</u>

Pour simplifier le travail j’ai installer SSH pour pouvoir copy paste plus facilement

Pour ca j’ai suivis le meme guide que dans born2beroot pour installation de ssh ; j’ai pas mis le port 4242 mais j’ai mis aussi le no pour root.
https://noreply.gitbook.io/born2beroot/virtual-machine-setup/installing-and-configuring-ssh

j’ai aussi installer vim parce que j’aime pas trop nano (*alors qu’un temps j’utilisais que nano au debut quand j’apprenais linux de mon cote avant 42 *petit lore drop**).

Il faut aussi installer make pour avoir plus tard le makefile.

### <u>Installation de docker et docker file</u>

Les commandes; 
**sudo apt install -y ca-certificates curl gnupg lsb-release** ⇒ installer les dependances

**curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg** ⇒ ajoute la cle de docker

**echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null** =>ajouter le depot docker

**apt install -y docker-ce docker-ce-cli containerd.io** ⇒ pour la derniere chose pour docker engine

****(moi j’ai eu directement docker compose mais potentiellement; **sudo apt install -y docker-compose-plugin**) 

On peut verifier que tout est bon avec les commandes suivantes ;

!image.png

### <u>Votre user</u>

Comme dans le guide qu’on avait suivi a l’epoque dans B2BR, il faut bien ajouter votre user a sudo. Mais il faut aussi l’ajouter a un group docker. Ce qui va etre utile pour la suite et particulierement quand on va faire des make et autre 

!image.png

attention si vous faites comme ca, vous allez peut etre rencontre un probleme que j’ai eu et ca va pas marche tout de suite. Il faut enfait rafraichir en faisant ; **newgrp docker**

### <u>Taille de votre goinfre et autre (Alpine vs Debian)</u>

**du -sh /sgoinfre/goinfre/Perso/bsuger**

cette commande permet de regarder la taille de votre sgoinfre comme on est limite sur la taille a 30 Go, il vaut mieux surveiller au fur et a mesure.

Normalement on est safe meme en installant debian. 

L’avantage de Alpine sur Debian est ca taille, c’est une distribution qui est legere par defaut. Elle est faite expres pour etre legere mais ca vient avec quelques defauts; 
moins d’information en ligne que Debian
des choses en plus a configurer et installer

<u>est ce que c’est bcp plus difficile ?</u>
je pense pas perso mais je prefere rester sur quelque chose de facile pour le moment car le sujet est pas assez interessant pour que je fasse autre chose. Mon avis sur le sujet; voir docker c’est bien mais tu passes plus de temps a faire autre chose que du docker. Tu passes plus de temps a gere les scripts et installation de mariadb, wordpress nginx. A moins de travailler dans un job ou tu met en place les docker dans la vrai vie on va utiiliser des choses deja faites pour nous et voir meme docker hub qui est interdit pour ce sujet. 

*Detail; je suis pas sur que les version light de bookworm sont autorisees*

# <u>Organisation des fichiers et structure du rendu</u>

On nous demande une arborescence tres precise pour le rendu du projet.

!image.png

On nous demande une structure suivante ou dans le fichier “secrets” on aurat tout ce qui concerne les identifiants et mot de passe. 

Dans srcs, c’est la ou on va avoir le docker compose. et nos dockerfiles.

!image.png

Maintenant qu’on a vu tout ca, on va pouvoir passer a l’ecriture des fichiers.

Ici je vais decrire simplement les fichiers.

Ici il y a que le produit finit de mon travail mais voila comment j’ai fais ; 

J’ai installe Mariadb avec un dockerfile. 
Puis j’ai fais un Docker compose simple et un docker file pour wordpress. 
je suis passe a  NGINX et TLS comme il faut

les 4 sections suivantes vont decrire les docker files + les scripts utilise avec des explications sur chaque utilisation

# <u>MARIADB</u>

### <u>Dockerfile</u>

!image.png

FROM est le premier layer de notre docker file pour la creation de notre image (pour rappel, un docker file cree une image).

Ici avec FROM on va cree notre base, on nous demande dans le sujet d’utiliser la penultimate version de debian (actuellement bookworm). C’est donc comme si on allait avoir un linux debian dans le container. Mais attention c’est pas un OS qu’on a mais un systeme de fichier racine.

Ensuite on va faire RUN pour executer une commande dans notre container. Apt update ca sert a mettre a jour, l’information des paquets disponible. Puis il va installer mariadb.
On precise le -y pour dire yes a tout et —no-install-recommends pour installer le minimum requis de mariadb.
Le apt clean et la suppression de /var/lib/apt/lists/* c’est pour tout clean et liberer aussi de l’espace disque.
On utilise bien && parce que chaque etape a fonctionne avant de faire une autre

Ensuite avec COPY on va prendre notre script sh qu’on a fait, pour le mettre au bon endroit dans le container, on lui donne aussi des permissions pour etre capable de l’executer.

EXPOSE nous permet d’ouvrir le port en interne qui nous interesse. 

Entrypoint c’est le lancement de notre script. On prefere ENTRYPOINT a CMD, parce que ca transforme notre docker en executable. 

### <u>Script</u>

!image.png

On commence par un shebang pour preciser le lancement du script en sh

FLAG et DB_DIR vont me servir en securite s’il y a des problemes d’interruption d’installation. Qu’on va voir juste apres.

Dans le bloc suivant je supprime mysqld.pid et mysqld.sock. Ce sont 2 fichiers qui sont present quand mariadb run. Mais si mariadb crash ou s’interromp de maniere brutale, si mariadb voit ca, il ne va pas vouloir se relancer. Car il va croire qu’une instance est deja ouverte.
je m’assure ensuite que /var/run/mysqld est cree si ce n’etait pas le cas et je donne les permissins a mysql pour qu’il puisse le manipuler.

Ensuite avec le bloc if je fais une verification. Soit il y a bien un fichier flag qui existe et le directory. S’il manque un des deux. Je dois installer, sinon c’est que c’etait deja installer et que je n’ai plus que a lancer.

A l’interieur de bloc IF;

je demarre mariadb avec la commande service. Cela n’est pas instantane et du coup, j’attend avec une boucle que ca soit lance.

La je suis sur que ca a demarre et je vais donc cree la base de donne necessaire avec le user. Toutes ces informations viennent de mon .env (attention a pas le rendre dans le repo). 
On va cree le user et lui donne des permissions sur le base de donne wordpress (le flush c’est pour faire l’update tout de suite)

Ensuitem on eteind mysqladmin. Pourquoi ? Docker ne surveille que le PID 1, si celui ci se termine, il considere que c’est termine. Au lancement du docker notre PID 1 c’est notre entrypoint, notre script sh qui va installer tout ce qu’il faut. Mais service mariadb start c’est un service en arriere plan, qui du coup utilise le port expose dans le dockerfile, donc impossible de lancer comme il faut apres avec le PID 1. Du coup on va l’eteindre et lancer mysqld_safe qui a l’avantage de le mettre en premier plan. A comprendre que le exec c’est comme execve() qu’on a pu utiliser dans pipex, minishell et webserv.

On le bind a l’adresse 0.0.0.0 pour qu’il ecoute bien sur toutes les interfaces reseaux et pas que 127.0.0.1 qui est le truc par defaut.

### <u>Verification / manipulation</u>

C’est un des seul bloc qu’on peut verifier solo. C’est a dire que c’est ok si les autres sont pas lance. Pour wordpress c’est plus dur car il va attendre des choses et pareil pour NGINX.

Mais ici je pars du resultat final, c’est a dire que j’ai deja mon docker compose qui lance tout. 

C’est plus ce qu’on va faire en correction

Donc vous avez fait Make en premier lieu.

**docker exec -it mariadb sh
exec -it** ⇒ permet de rentrer dans le docker et d’avoir un terminal interactif

!image.png

**mariadb -u root -p**

permet de rentrer dans mariadb avec l’utilisateur root 

!image.png

Ici on peut alors faire differentes commandes

!image.png

!image.png

# <u>Wordpress</u>

### <u>Dockerfile</u>

!image.png

Le FROM est aussi comme pour le dockerfile de mariadb il est la pour donne la base. En sachant que Docker est intelligent et qu’il a donc mis en cache tout ca, il va utiliser qu’une fois le FROM.

Dans le RUN, je vais installer tout ce qu’il faut pour avoir wordpress mais aussi ce qu’il me faut pour utiliser les autres container comme mariadb avec mariadb-client.

Techniquement je pourrais mettre le second RUN avec le premier. Ca ferait un layer en moins pour l’image. Mais plus difficile a debuger. Le premier RUN obtient tout ce qu’il faut pour la suite et le second s’occupe d’obtenir wp-cli, de mettre les bonnes permissions et de le deplacer a un autre endroit.

Pareil pour le bloc avec COPY RUN que dans mariadb, on prend notre script pour qu’il deviennt l’entrypoint plus tard.

Juste avant on prepare le fichier ou on va mettre tout pour la suite et avec WORKDIR on fait un equivalent de cd.

Precision n’oubliez pas que les dossiers sont dans vos volumes mais aussi mount sur le docker. 

### <u>Script</u>

!image.png

Le script commence par attendre que mariadb soit setup. Car on va en avoir besoin pour lier wordpress a tout ca. 

J’ai encore des flags qui servent a la meme chose que dans le precedent script, des securite s’il y a un soucis lors de la creation. 

Dans notre IF on va avoir 2 gros blocs;

wp core c’est ce qui est essentiel a wordpress et on va cree dans le premier bloc ce qu’il faut pour le lier a base de donne.

Dans le second bloc on va cree le wordpress par defaut.

La securite fait qu’on doit donner les permissions a www-data, on doit meme cree un dir specifique pour php

La partie des sed et grep est la partie qui ma fait le plus chier. C’est pour lui expliquer qu’on veut le port 9000 et de tout

Ensuite on va exec comme les autres pour lancer le service et garder le PID 1

### <u>Pour mettre l’interface visuel</u>

*pour XCFE;
sudo apt update
sudo apt install -y xfce4 xfce4-goodies lightdm
sudo apt install -y firefox-esr

### <u>**verification / manipulation**</u>

# <u>NGINX et TLS/SSL</u>

### <u>Dockerfile</u>

!image.png

Ici peu d’explication a donne c’est la meme chose que les autres ; 

on get ⇒ on installe

Petit detail en plus ici pour le TLS avec une commande un peu plus complex

Comme on a pas de script mais juste une commande a execute on utilise CMD

Le -g daemon off est important. Si on ne fait pas ca probleme a cause du PID 1. De base NGINX va tourner en arriere plan (daemon) et le probleme c’est que sans PID 1 notre docker s’arrete. Donc on lui dit d’etre en premier plan

### <u>Config</u>

!image.png

Ici pas de script sh mais juste une config NGINX 

Proche du sujet webserv sur l’idee. On expose bien le port 443 qui va nous servir de reverse proxy

### <u>**Verification**</u>

# <u>**Docker Compose**</u>

!image.png

!image.png

# <u>Makefile</u>

!image.png

# <u>**GRILLE DE CORRECTION**</u>

*Explication prepare pour la correction sur les questions pose en correction*

### <u>**How Docker and docker compose work**</u>

Docker permet de faire de la containerisation. Un conteneur c’est un environnement isole, i permet d’executer une application avec toutes ces dependances, en partageant le kernel de l’host.  C’est la ou reside la difference avec une machine virtuel qui ne partage pas le kernel de l’host. La machine virtuel elle va avoir un hypervisor et reserve des ressources pour tourner. Ce qui fait qu’on appelle souvent docker, une lightweight VM car plus rapide.

Les containers sont isoles, quand on parle d’isolation c’est le namespaces (process, user, etc…) et cgroups (les ressources). Un container a un PID, et pour lui il a juste un PID 1 du service qu’on lance.

Du coup pour faire, travailler des dockers ensemble, on va utiliser docker compose. Docker compose c’est une genre d’orchestrateur de container. On va decrire dans un fichier yaml comment les containers doivent se connecter entre eux. 

### <u>The difference between a Docker image used with docker compose and without docker compose</u>

Un docker image c’est un fichier read only qu’on obtient grace a un dockerfile. Ca va permettre ensuite de lancer un container. 

Seul comme ca, il fait rien, et sans docker compose je vais devoir lancer plein de choses differentes de maniere complexe.

Alors qu’avec docker compose je vais pouvoir construire tout un site, tout un reseau de chose de maniere plus simple. 

Exemple; je dois faire docker build puis docker run ⇒ alors qu’avec docker compose j’ai qu’une commande

Si on fait une modification sur un docker file, en faisant docker compose up de nouveau, on va reconstrure que cette image la

### <u>The benefit of Docker compared to VMs</u>

*lightweight pour tout ce qu’on a dit
*plus facile a partage qu’une VM
*facile a modifier et a reconstruire
*l’opti derriere avec les layers

### <u>The pertinence of the directory structure required for this project (an example is provided in the subject's PDF file).</u>

L’interet c’est d’avoir un docker un service.

On a une architecture en micro service, chaque service a sa responsabilite.

On a tout encapsule comme il faut, tout est bien mis au bon endroit pour etre independant

Il y a une separation des volumes du reste

Le makefile permet de tout lancer comme il faut

### <u>simple explanation of docker-network</u>

Le docker network c’est ce qui permet au dockers de communique ensemble.

Docker a un genre de DNS interne pour communiquer entre container. Avec Docker Network c’est comme si ca gerait un projet netpractice tout seul.

Nous on utilise donc bridge pour bien isoler, le fait que chaque docker peut communiquer que entre eux, a part NGINX qui est expose en dehors comme reverse proxy. 

### <u>Changer de port des services</u>

(techniquement c’est a nous de choisir mais dans le doute on va se preparer a changer ceux de tous les ports)

# <u>README et rendu</u>

N’oubliez pas que c’est le premier sujet avec un README a faire depuis le nouveau sujet. 

Il y a 3 fichiers en markdown a faire ; README.md, USER_DOC.md et DEV_DOC.md 

On doit rendre les .md a la racine de notre repo, avec le Makefile necessaire qui appel tous les fichiers qui sont dans un dossier srcs.

Attention si vous avez utilise un .env il ne faut pas le rendre sur le git, sinon c’est 0

# <u>DOCKER COMMANDS BASIQUE</u>

**docker build** ; permet de construire l’image
**docker run** ; permet de lancer un docker depuis une image
**docker ps -a** ; liste les containers lance
**docker stop <le container>** ; pour stopper
**docker rm <le container>** ; supprime le container
**docker images -a** ; montre les images

# <u>**RESSOURCES**</u>

https://www.reddit.com/r/virtualization/comments/1lak0rw/explain_like_im_5_how_do_virtual_machines_work/
Très bonne explication pour un rappel sur les machines virtuelles. Ce que j’aime bien dans cette explication c’est la precison sur les 2 types d’hypervisor, meme si nous on rencontre qu’un seul type.

https://www.youtube.com/watch?v=mQP0wqNT_DI
Video que j’avais regarde a l’epoqe de B2BR et que j’ai revu pour reviser, qui reprend bien tout les concepts des machines virtuelles.

https://www.youtube.com/watch?v=a1M_thDTqmU
Une explication pour bien differencier VM et Docker. On a aussi une precision importante sur quand on doit utiliser l’un ou l’autre.

https://www.youtube.com/watch?v=cjXI-yxqGTI
Une autre video de IBM qui parle de difference entre VM et Containers (sans parler precisement de docker). Video qui m’a aider a bien comprendre l’isolation sur les containers.

https://www.youtube.com/watch?v=rIrNIzy6U_g
Exageration dans le titre car il s’agit d’une video de 8 minutes et les 100 notions sont pas forcement de docker mais de sujet connexes.  Cependant tres interessante sur un court brief de docker.

https://www.youtube.com/watch?v=DQdB7wFEygo
Video ok mais sans plus, petite explication sympa sur les images et containers meme s’il doit revenir presque  2 fois dessus parce qu’il a trop simplifie. Utilise docker desktop ce qui est pas possible pour notre projet. Mais il montre un exemple de docker file ce qui est pas mal et docker compose 

https://youtu.be/t779DVjCKCs?si=dkmxVBEjwlTnR2lS
c’est cette video qui m’a fait comprendre l’interet d’alpine (meme si je ne suis pas sur de l’utiliser) mais aussi l’importance du caching quand on rebuild pour rester rapide.

https://youtu.be/DUgzXX2_aDQ?si=HAdTiMWFE_Ko2I9q
Des details interessant sur comment les containers fonctionnent.  Dans la video on revoit des informations au sujet de VM vs docker. 

https://youtu.be/aN4PCILrbBg?si=jcLgPSO5dY-a9ogS
Une video en francais qui est bien faites pour expliquer les differences en VM (type 1 et type 2) et containers. 

### <u>Impact d’ajouter rm -rf /var/lib/apt/lists/*</u>

avant

!image.png

apres

!image.png

petite amelioration comme il faut