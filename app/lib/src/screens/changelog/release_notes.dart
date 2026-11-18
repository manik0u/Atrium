import 'package:flutter/foundation.dart';

/// A category of change within a release, rendered as a colored label.
enum ChangeCategory { added, improved, fixed }

/// One category's bullets within a release.
@immutable
class ChangeGroup {
  const ChangeGroup(this.category, this.items);
  final ChangeCategory category;
  final List<String> items;
}

/// One version and what changed in it.
@immutable
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.date,
    required this.groups,
  });
  final String version;
  final String date;
  final List<ChangeGroup> groups;
}

/// Newest first. Update alongside appVersion and the pubspec at each release.
const List<ReleaseNote> releaseNotes = <ReleaseNote>[
  ReleaseNote(
    version: '1.11.0',
    date: '2026-11-18',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Partagez un film ou une série vers Atrium depuis une autre app pour l'ajouter à Radarr ou Sonarr. Les liens IMDb, TMDB, Letterboxd et Trakt fonctionnent, et un simple titre aussi. S'il est déjà dans votre bibliothèque, son écran s'ouvre, sinon la feuille d'ajout habituelle.",
        "Les liens atrium:// ouvrent Atrium sur un service, un film ou une série, donc une notification ntfy, une tâche Tasker ou une commande shell peuvent vous y emmener directement. Par exemple atrium://sonarr/series?tvdb=81189. Un lien ne fait qu'ouvrir un écran ; l'ajout demande toujours votre geste.",
        "Les feuilles d'ajout de Radarr, Sonarr et Lidarr reprennent les choix faits lors du dernier ajout sur la même instance : dossier racine, profil de qualité, surveillance, recherche à l'ajout et le reste. Les balises ne sont pas reportées.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "Les écrans de recherche de Radarr et Sonarr se ferment d'eux-mêmes après un ajout, et ouvrir un titre déjà dans votre bibliothèque n'attend plus la fin du prochain partage ou lien.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.10.2',
    date: '2026-11-09',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Seerr peut se connecter avec le compte propre d'une personne au lieu de la clé API : un compte Seerr, ou un compte Jellyfin ou Emby. Les écrans suivent alors les permissions Seerr de ce compte, donc vos proches peuvent demander sans recevoir la clé admin.",
        "qBittorrent permet de modifier les trackers d'un torrent. Modifier les trackers les ouvre en texte, une URL par ligne avec une ligne vide entre les niveaux, et montre ce que Enregistrer ajoutera et retirera. Le menu de chaque tracker permet de copier, modifier ou supprimer, et les lignes indiquent leur niveau.",
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Les pochettes Lidarr se chargent quand Lidarr tourne sous une base d'URL ou derrière un portail de connexion qui ne sert que l'interface web.",
        "Le test de connexion et le contrôle de statut de Seerr vérifient que la clé API fonctionne réellement. Auparavant, n'importe quelle clé passait.",
        "Les états Erreur de tracker et Injoignable de qBittorrent ne s'affichent plus comme Inconnu.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.10.1',
    date: '2026-11-02',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.improved, <String>[
        "Deluge est repensé pour ressembler à qBittorrent et Transmission. Téléchargement, envoi et espace libre tiennent sur trois tuiles, avec la pause de session et les limites de vitesse dessous, et l'ajout d'un torrent passe par un bouton flottant. Les filtres d'état passent dans un tiroir latéral, avec une bande « Filtré » et un point sur le bouton de filtre tant qu'un filtre est actif. Les torrents s'affichent en cartes avec leurs vitesses, ratio et ETA, les actions au appui long, et l'écran de détail est composé de panneaux, avec les drapeaux de pays des pairs et un menu regroupant toutes les actions.",
        'Le marqueur « téléchargé » du calendrier suit les couleurs de votre thème.',
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        'Sur les onglets Transferts et Recherche de slskd, le tirage pour actualiser apparaît sous la barre de recherche et non plus par-dessus.',
        "La version de slskd s'affiche 0.26.2 au lieu de 0.26.2.0.",
        "L'onglet Journaux de slskd explique que la clé API doit avoir le rôle Administrateur au lieu d'afficher une erreur brute.",
        "Le filtre Actif de Deluge liste les torrents qui avancent, et un torrent en pause ou terminé n'affiche plus une vitesse estompée et un ETA.",
        "Fermer la feuille d'ajout de Transmission pendant qu'un torrent est encore ajouté ne signale plus l'ajout comme échoué.",
        "Les messages d'erreur de Cleanuparr sont lisibles sur leur fond rouge.",
        'Le formulaire de service rejette une seconde URL mal formée même si la première est valide.',
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.10.0',
    date: '2026-11-02',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "slskd, le client Soulseek, est un service pris en charge, en bêta. Transferts liste les téléchargements et envois par pair et dossier ou en une seule liste. La recherche affiche les résultats en albums ou pistes, avec des filtres de format, débit et emplacement libre, et le téléchargement d'un album en un toucher. Parcourir ouvre les partages d'un pair en arbre de dossiers, Communauté regroupe les messages privés et les salons de discussion, et Système couvre la connexion au serveur, les partages, les journaux et les statistiques de transferts.",
        "aria2 est un service pris en charge, en bêta. Les téléchargements peuvent être filtrés par état, recherchés, triés, et mis en pause, repris ou supprimés en masse, et un téléchargement s'ouvre avec ses fichiers, pairs, miroirs et ses propres limites de vitesse. Ajoutez par lien, magnet, .torrent ou .metalink, et modifiez les paramètres du démon. aria2 apparaît aussi dans Téléchargements actifs et Activité, et accepte les torrents partagés.",
        "Cleanuparr est un service pris en charge, en bêta, listé sous un nouveau groupe Divers dans la barre latérale et lors de l'ajout d'un service. Vue d'ensemble montre les malwares bloqués, les strikes actifs, les torrents nettoyés et les tâches en arrière-plan, Strikes liste les téléchargements porteurs de strikes, et Événements est le journal d'audit. Un widget du tableau de bord indique si les files sont propres.",
        "AdGuard Home a un onglet Filtres, avec listes de blocage et d'autorisation, règles personnalisées, services bloqués avec leur planning, réécritures DNS et Vérifier un hôte, et un onglet Paramètres, avec les serveurs DNS, le cache, l'accès, le journal des requêtes et la conservation des statistiques, le chiffrement, DHCP et la vérification des mises à jour.",
        'Les demandes Seerr peuvent être filtrées par statut : En attente, Approuvée, Terminée, Refusée et Échouée.',
        'qBittorrent affiche son adresse IPv4 et IPv6 externe dans Paramètres > Système, sur qBittorrent 5.0 et ultérieur.',
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "L'ajout d'un service part d'une grille interrogeable de tous les services, groupés par catégorie, et le formulaire s'ouvre prérempli pour celui que vous choisissez.",
        "Transmission est reconstruit autour d'un tiroir de filtres avec les filtres d'état de l'interface web plus les trackers et labels.",
        'Le calendrier se souvient si vous utilisiez la liste ou la vue mois la dernière fois.',
        'AdGuard Home sort de bêta.',
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "L'action Supprimer de qBittorrent utilise la couleur d'erreur du thème en mode clair comme sombre.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.9.1',
    date: '2026-10-19',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.improved, <String>[
        "La liste des torrents de qBittorrent ne demande que ce qui a changé depuis la dernière actualisation, comme le fait l'interface web de qBittorrent, donc une grande bibliothèque se charge plus vite et consomme beaucoup moins de données. La fréquence d'actualisation se règle maintenant par instance dans son formulaire, 5 secondes par défaut (c'était 3).",
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        'La liste des demandes Seerr ne se recharge plus indéfiniment sur les serveurs qui en ont beaucoup.',
        'Les affiches et autres illustrations se chargent depuis une instance avec « Autoriser les certificats auto-signés » activé.',
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.9.0',
    date: '2026-10-08',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "AdGuard Home est un service pris en charge, en bêta. Accueil active ou désactive la protection, ou la met en pause pour un temps, et affiche les statistiques DNS avec les principaux clients, domaines et serveurs amont, où un domaine peut être bloqué ou débloqué depuis sa ligne. Le journal des requêtes est recherché et filtré comme dans l'interface web, et une requête s'ouvre en entier, pour bloquer ou débloquer son nom pour tout le monde ou pour un seul client, ou pour interdire le client. Clients liste les clients persistants et ceux en cours d'exécution, et un client persistant peut être ajouté, modifié ou supprimé, avec ses propres paramètres de protection, services bloqués et serveurs amont. Un widget du tableau de bord montre l'état, avec Pause et Reprendre. Les listes de filtres et les paramètres du serveur restent à venir.",
        "AdGuard Home verrouille une adresse après quelques connexions échouées, donc un mauvais mot de passe n'est essayé qu'une fois et rien d'autre n'est envoyé jusqu'à ce que vous touchiez Réessayer.",
        'Sonarr et Radarr proposent les filtres personnalisés enregistrés sur votre serveur dans la feuille de tri et filtrage.',
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        'Ombi sort de bêta.',
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.8.0',
    date: '2026-10-03',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Radarr surveille les collections. L'ajout d'un film appartenant à une collection propose de surveiller toute la collection, et l'écran du film montre la collection avec un bouton pour la surveiller ou non.",
        "qBittorrent marque les torrents comme privés ou publics. Le badge est dans la liste sur qBittorrent 5.0 et ultérieur, et sur l'écran du torrent depuis la 4.5.1.",
        'Un profil peut être renommé depuis sa carte.',
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "Ombi a un nouveau look : Demandes et Découvrir comme deux onglets, un compteur sur chaque puce de filtre, des cartes de demande avec l'affiche, le statut et qui a demandé, des cartes Découvrir et recherche plus riches, et une feuille pour un titre avec ses détails et le bouton de demande.",
        "Navidrome sort de bêta. Les playlists sont une grille de pochettes comme les albums, et un album s'ouvre avec l'artiste en bannière et la pochette à côté du titre.",
        'Lidarr et Unraid sortent de bêta.',
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        'Les heures des demandes Ombi ne sont plus décalées par votre fuseau horaire.',
        "Une demande Ombi n'affiche son motif de refus que tant qu'elle est refusée, pas après une nouvelle approbation.",
        "Les en-têtes de section d'artistes de Navidrome accueillent les noms de groupe plus longs utilisés par un serveur, comme X-Z et [Inconnu].",
        "Les grilles d'albums et de playlists de Navidrome ne débordent plus avec les grandes tailles de texte.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.7.0',
    date: '2026-09-21',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "MySpeed est un service pris en charge. Son onglet Statut indique si un test est en cours et permet d'en lancer un, avec les résultats du dernier jour en dessous ; Historique liste chaque test avec les moyennes et une recherche par id ; Config montre le planning, le fournisseur et les chiffres de stockage. Les instances protégées par mot de passe fonctionnent, et un widget du tableau de bord montre les derniers chiffres et lance un test depuis le tableau.",
        "Ombi est un service pris en charge, en bêta. Les demandes de films, séries et musique sont listées comme la page Demandes d'Ombi, avec approuver, refuser avec un motif, et supprimer. La recherche et un onglet Découvrir de titres populaires et à venir permettent de demander depuis l'app, et les demandes apparaissent sur le widget Demandes du tableau de bord.",
        'Navidrome est un service pris en charge, en bêta. Parcourez les artistes et albums avec bannières et biographies, notez-les et marquez vos favoris, gardez des playlists, recherchez dans la bibliothèque et lancez une analyse rapide.',
        "Gluetun est un service pris en charge. Voyez l'adresse publique, la localisation et le port ouvert du VPN, reconnectez-le en un toucher, et arrêtez le VPN ou le DNS derrière une confirmation. Un widget du tableau de bord montre son état, et un serveur de contrôle sans clé API peut être ajouté sans.",
        'Un widget de tableau de bord dashdot : anneaux CPU, mémoire et disque avec réseau montant et descendant, température et disponibilité, un bloc par instance.',
        "Transmission fait tout ce que fait son interface web et sort de bêta : les neuf filtres, les puces de tracker et label, la recherche, dix ordres de tri, les lignes compactes, la sélection avec actions groupées, chaque action de torrent dont définir l'emplacement, renommer, labels et déplacements dans la file, un écran de détail avec tout ce que montre l'inspecteur plus un arbre de dossiers, les drapeaux de pairs et les niveaux de trackers, et un onglet Paramètres pour les préférences Torrents, Vitesse, Pairs et Réseau avec statistiques, un test de port et une mise à jour de la liste de blocage. L'ajout d'un torrent préremplit le dossier utilisé par le serveur et montre son espace libre.",
        "qBittorrent a un onglet de journal d'exécution, lu à l'ouverture, avec copie.",
        'Le formulaire Plex peut se connecter sur plex.tv et remplir un serveur qui répond, au lieu de demander un jeton.',
        "La recherche tapée dans la liste Sonarr ou Radarr est reprise sur l'écran d'ajout.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "Les écrans de Transmission suivent le même look que qBittorrent, et retour défait d'abord une sélection, puis l'onglet, puis le tiroir avant de quitter l'écran.",
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        'Enregistrer une instance ne supprime plus les en-têtes personnalisés définis pour elle.',
        'Les paramètres de qBittorrent listent les interfaces réseau que le serveur possède réellement.',
        "Navidrome signe ses requêtes comme Subsonic l'attend et signale un mot de passe refusé au lieu de le cacher.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.6.1',
    date: '2026-09-11',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Un widget Wake-on-LAN pour le tableau de bord. Les machines que vous avez configurées peuvent être réveillées en un toucher depuis le tableau, sans aller les chercher dans les paramètres. Il vous dit que le paquet magique a été envoyé plutôt que la machine réveillée, puisque rien ne répond à un tel paquet et qu'une machine met un moment à démarrer.",
        "L'ajout d'un torrent dans qBittorrent préremplit le chemin d'enregistrement depuis le serveur, en utilisant son emplacement par défaut ou le chemin défini par la catégorie choisie, donc plus besoin de le retaper pour chaque torrent.",
        "La barre latérale peut être tirée vers le bas pour actualiser la santé de chaque service. Elle vérifie aussi à l'ouverture si la dernière vérification date de plus d'une minute, et les maintient à jour toutes les 30 secondes tant qu'elle reste ouverte.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "Les en-têtes personnalisés avertissent quand un en-tête ne survivra pas au trajet. Plusieurs services utilisent Authorization pour leur propre connexion et écrasent le vôtre, et qBittorrent refuse celui qu'il n'a pas émis, donc l'avertissement nomme les services concernés et suggère Proxy-Authorization, qui fonctionne partout où votre proxy l'accepte.",
        "Le contrôle de santé ne prend plus la page de connexion d'un proxy inverse pour un serveur fonctionnel. Il suivait auparavant la redirection vers une page de connexion, recevait une réponse normale, et déclarait le service en ligne. Il reconnaît maintenant une page de connexion et affiche un avertissement à la place.",
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Les affiches et fonds se chargent derrière un proxy inverse. Les illustrations n'emportaient jamais vos en-têtes personnalisés, donc derrière Authelia, Cloudflare Access ou similaire, chaque image était refusée et apparaissait vide pendant que le reste de l'app fonctionnait.",
        "Les en-têtes définis pour tout le profil atteignent maintenant chaque requête. Le test de connexion, le point de santé de chaque service et les clients Beszel, dashdot et Glances les perdaient, c'est pourquoi le test de connexion pouvait échouer pendant que l'app elle-même fonctionnait.",
        'Le widget Téléchargements actifs montre ce qui est réellement en téléchargement. Il triait uniquement par progression, donc une file de torrents presque terminés pouvait pousser le seul téléchargement en cours hors de la carte.',
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.6.0',
    date: '2026-08-30',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Unraid est désormais un service pris en charge. L'onglet du tableau montre les disques de parité et de données avec l'utilisation, la température et la santé de chacun, ainsi que l'état de la dernière vérification de parité. L'onglet système couvre la charge CPU par cœur, la mémoire, le réseau, et une carte À propos nommant le processeur, la disponibilité, le noyau, les emplacements mémoire et le nom d'hôte. Les conteneurs Docker sont listés avec leurs ports et leur disponibilité, ouvrent une feuille de détail, et peuvent être démarrés, arrêtés, mis en pause et repris. Les machines virtuelles peuvent être démarrées, arrêtées, mises en pause, reprises, redémarrées, arrêtées de force et réinitialisées. Il est marqué bêta le temps de se stabiliser.",
        "La recherche interactive de Radarr et Sonarr peut ouvrir une release sur sa page torrent ou indexeur, pour l'examiner avant de la grabber, et copier son URL de téléchargement ou son lien magnet.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "qBittorrent se souvient de la façon dont vous avez trié la liste. Ce que vous avez choisi en dernier est ce que vous retrouvez à la prochaine ouverture de l'app, conservé séparément pour chaque serveur, au lieu de revenir au plus récent à chaque lancement.",
        "Le tableau de bord n'offre que des widgets que quelque chose de configuré peut réellement remplir, et indique quel service un widget attend plutôt que d'ajouter une carte vide.",
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Le bouton de filtre de l'écran qBittorrent rouvre le tiroir de filtres. Il interrogeait la mauvaise partie de l'écran, qui répondait en ne faisant rien, donc le bouton semblait mort alors que le balayage depuis le bord fonctionnait toujours.",
        "Quand un serveur refuse une requête avec 401 ou 403, Atrium affiche maintenant la raison donnée par le serveur au lieu de la remplacer par un message d'authentification générique. Un refus qui s'avère être une vérification intersite plutôt qu'une mauvaise clé le dit aussi.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.5.1',
    date: '2026-08-26',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        "L'ajout de choses dans Lidarr fonctionne à nouveau. L'ajout d'un artiste, indexeur, client de téléchargement, liste d'import, notification, balise, dossier racine, format personnalisé ou de l'un des profils était refusé par le serveur, tout comme le grab d'une release depuis une recherche interactive. Atrium envoyait des champs vides que Lidarr n'accepte pas, et il rejetait la requête entière sans dire quelle partie lui déplaisait.",
        'La recherche interactive ne plante plus sur les versions nightly de Lidarr et sur les builds avec des plugins installés. Ces versions nomment leurs protocoles de téléchargement différemment, et un seul nom non reconnu par Atrium écartait toute la liste de résultats au lieu de ce seul champ.',
        "Les écrans de Lidarr ne débordent plus du bord avec les grandes tailles de texte système, dans l'éditeur de fichiers de pistes, la liste des fichiers non mappés et l'historique de l'artiste.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "L'historique d'activité de Lidarr continue de se charger au défilement au lieu de s'arrêter à la première page.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.5.0',
    date: '2026-08-23',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Lidarr est désormais un service pris en charge : artistes et discographie, détail d'album et de piste, recherchés, file d'attente et historique, l'arbre complet des paramètres, un lecteur de journal intégré, et les sorties d'albums dans le calendrier. Il est marqué bêta le temps de se stabiliser.",
        "qBittorrent a gagné une page de paramètres couvrant ce qu'offre sa propre interface web, sur système, comportement, téléchargements, connexion, vitesse, BitTorrent, RSS, interface web et avancé.",
        'Les torrents de qBittorrent peuvent être déplacés dans la file, en haut, vers le haut, vers le bas ou en bas, un par un ou plusieurs à la fois, et la liste peut être triée par position dans la file.',
        "L'icône de l'app suit maintenant la palette de votre système quand les icônes thématiques Android sont activées.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "L'écran de qBittorrent mène avec vos totaux, les téléchargements actifs et ce qui est en seed, avec la recherche et démarrer/arrêter tout à portée, et répartit la liste des torrents et les paramètres sur deux onglets.",
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Modifier un paramètre qBittorrent qui couperait Atrium du serveur demande maintenant d'abord. Déplacer l'adresse ou le port de l'interface web rend l'app incapable de le joindre, et désactiver la protection CSRF ou anti-clickjacking affaiblit le serveur, donc chacun explique ce qu'il va faire avant de continuer.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.4.2',
    date: '2026-08-21',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        'qBittorrent peut ignorer la vérification du hash quand vous ajoutez un torrent dont les fichiers sont déjà sur le disque, au lieu de tout revérifier.',
        'Les torrents de qBittorrent peuvent être filtrés par tracker, avec un compte à côté de chacun.',
        'Le calendrier peut afficher les sorties non surveillées aussi bien que surveillées, et se souvient de votre choix.',
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        'Toucher un transfert dans Activité ouvre directement ce torrent, film ou série au lieu de vous déposer sur le service pour le chercher. Fonctionne pour qBittorrent, Deluge, Transmission, rTorrent, Sonarr et Radarr.',
        "Un message de tracker dans qBittorrent passe maintenant à la ligne au lieu d'être coupé, pour que vous puissiez lire pourquoi un tracker ne fonctionne pas.",
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Les pochettes ne sont plus vides quand Sonarr ou Radarr est servi depuis un sous-chemin avec une base d'URL configurée.",
        "Le calendrier n'étiquette plus un épisode comme surveillé quand la série à laquelle il appartient ne l'est pas.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.4.1',
    date: '2026-08-15',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "La recherche interactive dans Sonarr et Radarr affiche maintenant le score de format personnalisé et les formats correspondus par chaque release, triés de la meilleure correspondance d'abord.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "Tracearr a été reconstruit : une vue d'ensemble de toute votre flotte, les flux en direct avec les diagnostics de lecture, un catalogue de médias avec la disponibilité par serveur, les profils utilisateurs, et un registre de sécurité.",
        "Tracearr n'est plus marqué bêta.",
        "Quand un serveur demande de ralentir, Atrium attend maintenant le temps demandé et réessaie au lieu d'afficher une erreur.",
        'Les listes qui se chargent au défilement indiquent maintenant quand vous avez atteint la fin.',
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Tracearr n'interroge plus un écran que vous avez quitté, et son cache d'illustrations ne grossit plus sans limite.",
        "Marquer un incident de sécurité Tracearr comme examiné dit maintenant clairement que c'est stocké uniquement sur cet appareil.",
        "Un seul élément illisible n'efface plus toute une liste Tracearr.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.4.0',
    date: '2026-08-13',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        'Beszel est désormais un service pris en charge : voyez vos systèmes, leurs métriques en direct, et un écran détaillé pour chacun.',
        "dashdot est désormais un service pris en charge aussi, avec des anneaux en direct pour CPU, mémoire, disque et GPU et un onglet d'informations système.",
        "qBittorrent a gagné la gestion des balises : filtrez vos torrents par balise, et copiez l'URL d'un tracker directement depuis la liste des trackers.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "L'onglet Fichiers affiche maintenant le nom de fichier complet au lieu de le tronquer.",
        'rTorrent, Deluge, Transmission, SABnzbd et Speedtest Tracker utilisent désormais leurs propres icônes.',
        'Tracearr, Transmission, Deluge et rTorrent sont marqués comme bêta pour que vous sachiez ce qui est encore en rodage.',
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        'Le test de connexion vérifie maintenant vos identifiants pour Beszel et pour les clés API de qBittorrent, au lieu de seulement vérifier que le serveur répond.',
        "L'écran de détail d'un torrent Deluge ne plante plus sur certains torrents.",
        'Le défilement est plus fluide dans Emby, Jellyfin et Beszel.',
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.3.3',
    date: '2026-08-07',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "La recherche de films ou d'épisodes sur le disque en les gardant dans votre bibliothèque, pour libérer de l'espace sans perdre la fiche. Cochez « ne plus surveiller » en même temps et il ne se retéléchargera pas tout seul.",
        'La même chose en masse : sélectionnez plusieurs films ou séries, choisissez « Supprimer uniquement les fichiers », et les fiches restent.',
        'Radarr peut être trié par ordre croissant ou décroissant.',
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Les listes ne passent plus sous les boutons de navigation système en bas de l'écran.",
        "Les boutons d'un écran de détail de film ou de série ne passent plus sur une seconde ligne sur les téléphones plus étroits.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.3.2',
    date: '2026-08-07',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Partagez tout un lot de fichiers .torrent d'un coup et Atrium les ajoute ensemble, plutôt qu'un seul partage à la fois.",
        "Tracearr a gagné des écrans de détail : touchez un titre pour voir ses statistiques et qui l'a regardé, ou touchez un compte pour voir ce qu'il a joué.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "Tracearr parle maintenant à son API publique et demande une clé API au lieu d'un nom d'utilisateur et d'un mot de passe. Ouvrez Tracearr, allez dans Paramètres, Clé API, Générer une clé, et collez-la dans l'instance. Si vous aviez déjà Tracearr configuré, vous devrez le refaire une fois.",
        "Cette API publique couvre moins que celle qu'utilisait Atrium auparavant, donc si quelque chose de Tracearr vous manque ici, ouvrez une demande de fonctionnalité sur GitHub et nous verrons ce que nous pouvons atteindre.",
        'Sonarr et Radarr se souviennent si vous les laissiez en vue grille ou liste.',
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "La barre de navigation du bas n'a plus ses icônes rognées sur les téléphones en navigation à trois boutons.",
        "Téléchargés récemment ne répète plus plusieurs fois le même épisode ou film, et une saison arrivée d'un coup se lit comme une seule entrée.",
        'Les instances Tracearr qui répondaient parfaitement ne signalent plus que le serveur est injoignable lors du test de connexion.',
        "La barre de recherche d'Emby est alignée avec le reste de l'écran.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.3.1',
    date: '2026-08-06',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "L'app Atrium apparaît maintenant dans la liste quand vous touchez un fichier .torrent ou ouvrez un lien magnet, et dans la feuille de partage quand vous partagez l'un ou l'autre depuis une autre app.",
        'Si vous avez plusieurs clients torrent configurés, elle demande lequel utiliser, sinon le torrent y part directement.',
        "Dans les deux cas, la feuille d'ajout habituelle s'ouvre avec le lien ou le fichier déjà rempli, donc le chemin d'enregistrement, la catégorie et le choix « démarrer en pause » restent à vous.",
        "Partagez-en plusieurs à la suite et ils s'enchaînent un par un plutôt que seul le premier n'arrive.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.3.0',
    date: '2026-08-04',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        'Deluge, Transmission et rTorrent sont désormais des services que vous pouvez ajouter, donc chaque client torrent courant est couvert aux côtés de qBittorrent.',
        'Chacun offre une liste de torrents en direct avec démarrer, arrêter, retirer, revérifier et ré-annoncer, des puces de filtre, le tri, les limites de vitesse globales, et un écran de détail avec fichiers, pairs et trackers.',
        'Ajoutez un torrent par lien magnet, URL de .torrent ou fichier, et choisissez où il atterrit.',
        "Tracearr est désormais un service que vous pouvez ajouter : qui regarde en ce moment, statistiques de visionnage et de bibliothèque, historique, et une carte d'où les comptes sont utilisés.",
        "Atrium se compile pour iOS. Il n'y a pas de téléchargement, la licence excluant l'App Store, donc vous le compilez et l'installez vous-même. Il n'a pas encore tourné sur du vrai matériel, donc attendez-vous à des angles rugueux.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "Les écrans de torrents mènent avec les deux vitesses en direct, et un transfert qui avance réellement a une barre de progression ondulée pour distinguer d'un coup d'œil ceux qui tournent.",
        'Un torrent terminé affiche son ratio de partage dans la barre de progression au lieu de rester à 100 pourcent sans rien dire.',
        "Les écrans de détail s'ouvrent maintenant sur tout l'écran plutôt qu'à l'intérieur de l'onglet.",
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Les écrans qui mettaient plus longtemps à se charger que leur intervalle d'actualisation pouvaient redémarrer en boucle sans jamais finir. Ils attendent maintenant qu'une actualisation se termine avant d'en programmer une autre, et ralentissent quand un serveur ne répond pas.",
        "Un serveur qui reste injoignable n'affiche plus un spinner par-dessus l'erreur toutes les quelques secondes.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.2.0',
    date: '2026-07-29',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        'NZBGet est désormais un service que vous pouvez ajouter, avec une file en direct que vous pouvez réordonner par glisser-déposer, mettre en pause et reprendre élément par élément, et supprimer.',
        "Ajoutez un NZB depuis l'app en collant une URL ou en choisissant un fichier .nzb, et changez la priorité ou la catégorie d'un élément une fois en file.",
        'Définissez une limite de vitesse de téléchargement, ou levez-la, sans quitter la file.',
        "L'historique de NZBGet liste les téléchargements terminés et échoués, avec une nouvelle tentative sur ceux qui ont échoué.",
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "Les téléchargements NZBGet apparaissent dans le widget Téléchargements actifs et l'onglet Activité aux côtés de vos autres clients de téléchargement.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.1.1',
    date: '2026-07-24',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Recherchez des mises à jour depuis Paramètres, À propos. Voyez si une version plus récente existe et ouvrez sa page de version. Atrium n'installe jamais les mises à jour lui-même.",
        'Quand une mise à jour est disponible, le Journal des modifications la montre en haut avec les notes de version lues en ligne.',
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        "Le Journal des modifications est maintenant des cartes par version avec les libellés Nouveau, Amélioré et Corrigé dans vos couleurs d'accent, les dates, et un marqueur Installée.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.1.0',
    date: '2026-07-23',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Service Speedtest Tracker, suivez vos vitesses de téléchargement, d'envoi et de ping depuis le tableau de bord.",
        "Bouton Tester la connexion sur chaque service, vérifiez l'URL et la connexion avant d'enregistrer.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.7',
    date: '2026-07-19',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        'Les paramètres de Radarr correspondent maintenant à ceux de Sonarr, configurables à la même profondeur.',
      ]),
      ChangeGroup(ChangeCategory.improved, <String>[
        'Nouveau moteur de thèmes avec un look plus épuré et plat et un aperçu des paramètres qui se met à jour en direct.',
        'Les jauges Glances suivent votre thème au lieu de couleurs fixes.',
        'Les jauges Glances suivent votre thème au lieu de couleurs fixes.',
        "Les journaux continuent de se charger au défilement au lieu de s'arrêter après la première page.",
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Le défilement ne s'étire plus exagérément aux bords.",
        'Les widgets du tableau de bord conservent leur état quand vous naviguez.',
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.6',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.improved, <String>[
        'Les écrans de détail de séries et films défilent nettement plus fluidement.',
        'Le tirage pour actualiser est unifié sur tous les écrans, plus fluide et réactif.',
        'Les affiches, fonds et distributions de Seerr se chargent maintenant depuis votre propre serveur Seerr plutôt que TMDB.',
      ]),
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Le tirage pour actualiser ne se déclenche plus quand vous balayez une rangée d'affiches sur le côté.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.5',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Les numéros de build suivent maintenant le schéma de F-Droid. Si vous venez d'une build GitHub antérieure, Android demande une réinstallation unique, donc exportez d'abord vos profils depuis les Paramètres. Rien après cela n'est affecté.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.4',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        'Les builds reproductibles correspondent maintenant octet par octet à ceux de F-Droid, une bibliothèque embarquait une empreinte de chemin de build.',
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.3',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.improved, <String>[
        "Les versions sont maintenant construites par un serveur pour que F-Droid puisse les reconstruire et vérifier, ce qui permet aux deux de partager une même signature pour passer de l'une à l'autre sans réinstaller.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.2',
    date: '2026-07-17',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Suppression d'une liste de dépendances chiffrée que les outils Android intégraient dans chaque APK, elle était propre à Play et n'était jamais envoyée nulle part.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.1',
    date: '2026-07-16',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.fixed, <String>[
        "Sécurité, la 1.0.0 joignait votre clé API Sonarr ou Radarr aux requêtes d'affiches envoyées à TheTVDB, TMDB et Fanart.tv. Si vous avez fait tourner la 1.0.0, envisagez de renouveler ces clés.",
        "Les affiches et fonds se chargent maintenant depuis vos propres instances Sonarr et Radarr, donc les sites d'illustrations ne voient plus votre adresse ni ce que vous consultez.",
      ]),
    ],
  ),
  ReleaseNote(
    version: '1.0.0',
    date: '2026-07-16',
    groups: <ChangeGroup>[
      ChangeGroup(ChangeCategory.added, <String>[
        "Tableau de bord de widgets d'un coup d'œil (téléchargements, en cours de lecture, à venir, ajouts et téléchargements récents, demandes, infos serveur), réorganisables.",
        "Gestion de Sonarr et Radarr sur bibliothèque, file d'attente, recherchés, historique, liste de blocage, système et paramètres.",
        'Modules qBittorrent, SABnzbd, Prowlarr, Bazarr, Seerr, Tautulli et Glances.',
        'Navigation dans Jellyfin, Emby et Plex avec les reprises, le détail des éléments et les sessions en cours de lecture.',
        'Plusieurs profils, chaque instance avec une URL locale et une URL externe, plus import et export.',
        'Thème Material 3 Expressive avec couleur dynamique, palettes personnalisées et verrou biométrique facultatif.',
      ]),
    ],
  ),
];
