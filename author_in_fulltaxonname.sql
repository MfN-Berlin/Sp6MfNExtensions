/******************************************************************************/
/* MfN extensions for Specify 6                                               */
/* Author in fulltaxonname                                                    */
/******************************************************************************/

USE specify;

DROP TRIGGER IF EXISTS `tr_mfn_taxon_insfulltaxonname`;
DROP TRIGGER IF EXISTS `tr_mfn_taxon_updfulltaxonname`;

DELIMITER GO

CREATE TRIGGER `tr_mfn_taxon_insfulltaxonname` BEFORE INSERT ON `taxon`
  FOR EACH ROW 
BEGIN
  IF  (COALESCE(NEW.`Author`, '') <> '')
  AND (LOCATE(NEW.`Author`, NEW.`FullName`) = 0) THEN
    SET NEW.`FullName` = CONCAT(NEW.`FullName`, ' ', NEW.`Author`);
  END IF;
END

GO

CREATE TRIGGER `tr_mfn_taxon_updfulltaxonname` BEFORE UPDATE ON `taxon`
  FOR EACH ROW 
BEGIN
  IF  (COALESCE(NEW.`Author`, '') <> '')
  AND (LOCATE(NEW.`Author`, NEW.`FullName`) = 0) THEN
    SET NEW.`FullName` = CONCAT(NEW.`FullName`, ' ', NEW.`Author`);
  END IF;
END

GO

DELIMITER ;
