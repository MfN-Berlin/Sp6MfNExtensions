DELIMITER GO

GO


ALTER TABLE `mfn_collection`
  ADD `separator` VARCHAR(1) NOT NULL DEFAULT '_' AFTER `prefix`;

GO

UPDATE `mfn_collection`
   SET `separator` = `so_separator`

GO

ALTER TABLE `mfn_collection`
  ADD `autoNumberYear` INT NULL;

GO

ALTER TABLE `mfn_collection`
  ADD `autoNumberMax` INT NULL;

GO

DROP TRIGGER IF EXISTS `tr_mfn_collectionobject_inscatno`

GO

DROP TRIGGER IF EXISTS `tr_mfn_collectionobject_updcatno`

GO

CREATE TRIGGER `tr_mfn_collectionobject_inscatno` BEFORE INSERT ON `collectionobject`
  FOR EACH ROW 
BEGIN
  DECLARE $cn_separator        VARCHAR(1);
  DECLARE $gin_allwayswithyear BIT;
  DECLARE $gin_maxnumberlength INT;
  DECLARE $gin_separator       VARCHAR(1);
  DECLARE $prefix              VARCHAR(25);
  DECLARE $so_allwayswithyear  BIT;
  DECLARE $so_maxnumberlength  INT;
  DECLARE $so_separator        VARCHAR(1);
  DECLARE $yearseparator       VARCHAR(1);
  DECLARE $autoNumberMax       INT;

  SET $prefix = (SELECT `collectioncode`
                   FROM `mfn_collection`
                  WHERE (`collectioncode` = `f_mfn_getCollectionCode`(NEW.`CollectionID`)));

  IF (NEW.`CatalogNumber` = 'auto') THEN
    SET $cn_separator = (SELECT `separator`
                           FROM `mfn_collection`
                          WHERE (`collectioncode` = `f_mfn_getCollectionCode`(NEW.`CollectionID`)));

    SET $autoNumberMax = (SELECT autoNumberMax + 1
                            FROM `mfn_collection`
                           WHERE (`collectioncode` = `f_mfn_getCollectionCode`(NEW.`CollectionID`)));

    UPDATE `mfn_collection`
       SET autoNumberMax = autoNumberMax + 1
     WHERE (`collectioncode` = `f_mfn_getCollectionCode`(NEW.`CollectionID`));

    SET NEW.`CatalogNumber` = CONCAT($prefix, $cn_separator, $autoNumberMax);
  END IF;

  IF ($prefix IS NOT NULL) THEN 
    SET $gin_allwayswithyear = (SELECT `gin_allwayswithyear`
                                  FROM `mfn_collection`
                                 WHERE (`collectioncode` = $prefix));
    SET $so_allwayswithyear = (SELECT `so_allwayswithyear`
                                 FROM `mfn_collection`
                                WHERE (`collectioncode` = $prefix));

    SET $gin_maxnumberlength = (SELECT `gin_maxnumberlength`
                                  FROM `mfn_collection`
                                 WHERE (`collectioncode` = $prefix));
    SET $so_maxnumberlength = (SELECT `so_maxnumberlength`
                                 FROM `mfn_collection`
                                WHERE (`collectioncode` = $prefix));

    SET $gin_separator = (SELECT `gin_separator`
                            FROM `mfn_collection`
                           WHERE (`collectioncode` = $prefix));
    SET $so_separator = (SELECT `so_separator`
                           FROM `mfn_collection`
                          WHERE (`collectioncode` = $prefix));

    SET $yearseparator = (SELECT `yearseparator`
                            FROM `mfn_collection`
                           WHERE (`collectioncode` = $prefix));

    IF (`f_mfn_adjustacronym`(`f_mfn_catno_getacronym`(NEW.`CatalogNumber`), $gin_separator) = $prefix)
    OR (`f_mfn_adjustacronym`(`f_mfn_catno_getacronym`(NEW.`CatalogNumber`), $gin_separator) LIKE CONCAT($prefix, '%')) THEN
      SET $prefix = '';
    END IF;

    SET NEW.`ReservedText` = `f_mfn_catno2gin`(NEW.`CatalogNumber`
                                             , $prefix
                                             , $yearseparator
                                             , $gin_separator
                                             , $gin_maxnumberlength
                                             , $gin_allwayswithyear);

    SET NEW.`AltCatalogNumber` = `f_mfn_catno2sortorderstring`(NEW.`CatalogNumber`
                                                             , $yearseparator
                                                             , $so_separator
                                                             , $so_maxnumberlength
                                                             , $so_allwayswithyear);
  END IF;
END;

GO

CREATE TRIGGER `tr_mfn_collectionobject_updcatno` BEFORE UPDATE ON `collectionobject`
  FOR EACH ROW 
BEGIN
  DECLARE $gin_allwayswithyear BIT;
  DECLARE $gin_maxnumberlength INT;
  DECLARE $gin_separator       VARCHAR(1);
  DECLARE $prefix              VARCHAR(25);
  DECLARE $so_allwayswithyear  BIT;
  DECLARE $so_maxnumberlength  INT;
  DECLARE $so_separator        VARCHAR(1);
  DECLARE $yearseparator       VARCHAR(1);

  IF (NEW.`CatalogNumber` IS NULL) THEN
    SET NEW.`ReservedText` = NULL;
    SET NEW.`AltCatalogNumber` = NULL;
  END IF;

  IF (NEW.`CatalogNumber` <> OLD.`CatalogNumber`) THEN
    SET $prefix = (SELECT `collectioncode`
                     FROM `mfn_collection`
                    WHERE (`collectioncode` = `f_mfn_getCollectionCode`(NEW.`CollectionID`)));

    IF ($prefix IS NOT NULL) THEN 
      SET $gin_allwayswithyear = (SELECT `gin_allwayswithyear`
                                    FROM `mfn_collection`
                                   WHERE (`collectioncode` = $prefix));
      SET $so_allwayswithyear = (SELECT `so_allwayswithyear`
                                   FROM `mfn_collection`
                                  WHERE (`collectioncode` = $prefix));

      SET $gin_maxnumberlength = (SELECT `gin_maxnumberlength`
                                    FROM `mfn_collection`
                                   WHERE (`collectioncode` = $prefix));
      SET $so_maxnumberlength = (SELECT `so_maxnumberlength`
                                   FROM `mfn_collection`
                                  WHERE (`collectioncode` = $prefix));

      SET $gin_separator = (SELECT `gin_separator`
                              FROM `mfn_collection`
                             WHERE (`collectioncode` = $prefix));
      SET $so_separator = (SELECT `so_separator`
                             FROM `mfn_collection`
                            WHERE (`collectioncode` = $prefix));

      SET $yearseparator = (SELECT `yearseparator`
                              FROM `mfn_collection`
                             WHERE (`collectioncode` = $prefix));

      IF (`f_mfn_adjustacronym`(`f_mfn_catno_getacronym`(NEW.`CatalogNumber`), $gin_separator) = $prefix)
      OR (`f_mfn_adjustacronym`(`f_mfn_catno_getacronym`(NEW.`CatalogNumber`), $gin_separator) LIKE CONCAT($prefix, '%')) THEN
        SET $prefix = '';
      END IF;

      SET NEW.`ReservedText` = `f_mfn_catno2gin`(NEW.`CatalogNumber`
                                               , $prefix
                                               , $yearseparator
                                               , $gin_separator
                                               , $gin_maxnumberlength
                                               , $gin_allwayswithyear);

      SET NEW.`AltCatalogNumber` = `f_mfn_catno2sortorderstring`(NEW.`CatalogNumber`
                                                               , $yearseparator
                                                               , $so_separator
                                                               , $so_maxnumberlength
                                                               , $so_allwayswithyear);
    END IF;
  END IF;
END;

GO

DELIMITER ;


