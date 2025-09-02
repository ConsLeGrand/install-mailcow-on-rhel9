**Rapport : Mise en place du Backup et Restore de Mailcow**

**1. Contexte**
Dans le cadre de la migration du serveur Mailcow local vers une VM de test, il a été nécessaire de tester et valider un processus de backup et restauration complet, afin d’assurer la continuité du service mail et la sécurité des données (mails, utilisateurs, configurations).

**2. Objectifs**
- Assurer un backup complet des mails, utilisateurs et configurations.
- Restaurer le serveur Mailcow sur une VM sans perte de données.
- Vérifier la cohérence des boîtes mail après restauration.
- Préparer le serveur cible pour une bascule en production.

**3. Pré-requis**
- Serveur source : Mailcow opérationnel.
- Serveur cible : VM avec Docker et Docker Compose installés.
- Accès root sur les deux serveurs.
- Espace disque suffisant.
- Connexion réseau pour transfert des backups.

**4. Processus de Backup**

*Commande de backup complet*:
```
cd /opt/mailcow-dockerized
./helper-scripts/backup_and_restore.sh backup all /opt/mailcow-dockerized/bckp/
```

*Contenu du backup*:
- `mailcow.conf` (configuration Mailcow)
- Bases de données MySQL
- Volumes Docker : `vmail/`, `redis/`, `rspamd/`, `postfix/`

*Vérification*:
```
ls -l /opt/mailcow-dockerized/bckp/
```

**5. Transfert vers le serveur cible**
```
scp -r /opt/mailcow-dockerized/bckp/ root@vm:/opt/mailcow-dockerized/bckp/
```

**6. Processus de restauration**

*Préparation sur le serveur cible*:
```
git clone https://github.com/mailcow/mailcow-dockerized /opt/mailcow-dockerized
cd /opt/mailcow-dockerized
docker-compose pull
cp /opt/mailcow-dockerized/bckp/mailcow.conf /opt/mailcow-dockerized/
```

*Lancer la restauration*:
```
./helper-scripts/backup_and_restore.sh restore all /opt/mailcow-dockerized/bckp/
```

*Resynchronisation Dovecot (optionnelle mais recommandée)*:
```
docker exec mailcow-dovecot doveadm force-resync -A '*'
```

**7. Gestion du serveur source pendant la migration**
- Maintien du serveur source actif pendant les tests.
- Pour bascule DNS sans perte :
  1. Arrêter le serveur source ou juste les services mail.
  2. Mettre à jour les enregistrements MX vers le serveur cible.
  3. Dernier resync si nécessaire.

**8. Points critiques et solutions appliquées**
| Problème | Solution |
|----------|---------|
| Environment file not found | Vérification et copie de `mailcow.conf` dans `/opt/mailcow-dockerized` avant restore |
| Resynchronisation des boîtes | Utilisation de `doveadm force-resync -A '*'` |
| Migration sans perte de mails | Maintien du serveur source actif, arrêt uniquement pour bascule DNS |


**9. Conclusion**
Le processus de backup et restauration a été testé avec succès. Le serveur Mailcow peut être migré vers une VM sans perte de données, en assurant continuité et cohérence des boîtes mail. Ce protocole est réutilisable pour migrations futures ou restaurations d’urgence.

**10. Schéma de flux**
1. Backup complet sur serveur source → 2. Transfert vers serveur cible → 3. Restore sur serveur cible → 4. Resync Dovecot → 5. Test et vérification → 6. Bascule DNS → 7. Arrêt serveur source

