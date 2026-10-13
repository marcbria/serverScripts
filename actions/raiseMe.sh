cd /home/marc/serverMigration &&
rm /home/docker/sites/$JOURNAL/volumes/db/* -Rf && 
chown 999:999 /srv/backups/migration/$JOURNAL/ -Rf && 
chmod 755 /srv/backups/migration/$JOURNAL && 
cd /home/docker/sites/$JOURNAL/ && 
docker compose down && 
docker compose up -d &&
echo "Letting the DB some time to raise..." &&
sleep 200
