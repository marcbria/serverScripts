ALTER DATABASE `ojs` COLLATE utf8mb4_general_ci;

UPDATE review_assignments
SET review_round_id = 0
WHERE review_round_id IS NULL;

-- DELETE FROM `plugin_settings`
-- WHERE `plugin_name` = 'editor';

CREATE TABLE IF NOT EXISTS deleted_plugin_settings AS
    SELECT * FROM plugin_settings 
    WHERE plugin_name = "customblockmanagerplugin" 
          and setting_name = "blocks";

DELETE FROM plugin_settings
WHERE plugin_name = "customblockmanagerplugin"
      and setting_name = "blocks";

-- DROP TABLE deleted_plugin_settings;


-- Remove orphan log entries
CREATE TABLE IF NOT EXISTS deleted_email_log AS
	SELECT * FROM email_log
	WHERE assoc_id IS NULL;

DELETE FROM email_log
WHERE assoc_id IS NULL;

-- DROP deleted_email_log;


-- Remove "unproductive" authors
CREATE TABLE IF NOT EXISTS deleted_authors AS
    SELECT * FROM authors
    WHERE publication_id IS NULL;

DELETE FROM author_settings          WHERE author_id IN ( SELECT author_id FROM deleted_authors );
-- DELETE FROM books_for_review_authors WHERE author_id IN ( SELECT author_id FROM deleted_authors );
DELETE FROM submission_comments      WHERE author_id IN ( SELECT author_id FROM deleted_authors );
DELETE FROM authors                  WHERE author_id IN ( SELECT author_id FROM deleted_authors );

-- DROP TABLE authors2delete;

TRUNCATE TABLE notification_settings;
TRUNCATE TABLE comments;
