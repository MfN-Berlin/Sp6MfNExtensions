/******************************************************************************/
/* MfN extensions for Specify 6                                               */
/* Extracts the parts of a catalog number string and create a sortable        */
/* and a global catalog number                                                */
/******************************************************************************/

USE specify_test;

-- Configuration table
-- field collectioncode contains the identifier from collection.code

CREATE TABLE IF NOT EXISTS `mfn_collection`
(
  `collectioncode`      VARCHAR(128) NOT NULL,
  `prefix`              VARCHAR(128) NOT NULL DEFAULT '',
  `yearseparator`       VARCHAR(1)   NOT NULL DEFAULT '/',
  `so_separator`        VARCHAR(1)   NOT NULL DEFAULT '_',
  `so_allwayswithyear`  BIT          NOT NULL DEFAULT 0,
  `so_maxnumberlength`  INT          NOT NULL DEFAULT 6,
  `gin_separator`       VARCHAR(1)   NOT NULL DEFAULT '_',
  `gin_allwayswithyear` BIT          NOT NULL DEFAULT 0,
  `gin_maxnumberlength` INT          NOT NULL DEFAULT 0,

  CONSTRAINT pk_mfn_collection_01 PRIMARY KEY (`collectioncode`)
) DEFAULT CHARSET=utf8;

INSERT 
  INTO `mfn_collection` (`collectioncode`, `prefix`)
       SELECT `code`, 
              `code`
         FROM `collection`
        WHERE (`code` NOT IN (SELECT `collectioncode`
                                FROM `mfn_collection`));

DROP FUNCTION IF EXISTS `f_mfn_getCollectionCode`;
DROP FUNCTION IF EXISTS `f_mfn_catno_getacronym`;
DROP FUNCTION IF EXISTS `f_mfn_catno_getyear`;
DROP FUNCTION IF EXISTS `f_mfn_catno_getnumber`;
DROP FUNCTION IF EXISTS `f_mfn_catno_getsubno`;
DROP FUNCTION IF EXISTS `f_mfn_adjustseparator`;
DROP FUNCTION IF EXISTS `f_mfn_adjustacronym`;
DROP FUNCTION IF EXISTS `f_mfn_catno2sortorderstring`;
DROP FUNCTION IF EXISTS `f_mfn_catno2gin`;

DROP TRIGGER IF EXISTS `tr_mfn_collectionobject_inscatno`;
DROP TRIGGER IF EXISTS `tr_mfn_collectionobject_updcatno`;

DELIMITER GO

GO

CREATE FUNCTION `f_mfn_getCollectionCode`($collid INT) 
  RETURNS VARCHAR(128)
  READS SQL DATA
  RETURN (SELECT `Code`
            FROM `collection`
           WHERE (`CollectionID` = $collid));

GO

CREATE FUNCTION `f_mfn_catno_getacronym`($value VARCHAR(255))
  RETURNS VARCHAR(255)
  DETERMINISTIC
BEGIN
  DECLARE $index  INT;
  DECLARE $strlen INT;

  SET $index  = 0;
  SET $strlen = LENGTH($value);

  WHILE ($index < $strlen) 
    AND (SUBSTRING($value,$index + 1,1) NOT IN (N'1',N'2',N'3',N'4',N'5',N'6',N'7',N'8',N'9',N'0')) DO

    SET $index  = $index + 1;
  END WHILE;

  RETURN TRIM(SUBSTRING($value,1,$index));
END

GO

CREATE FUNCTION `f_mfn_catno_getyear`($value         VARCHAR(255)
                                    , $yearseparator VARCHAR(1))
  RETURNS INT
  DETERMINISTIC
BEGIN
  DECLARE $index  INT;
  DECLARE $result INT;
  DECLARE $strlen INT;

  IF (COALESCE($yearseparator,'') = N'') THEN
    SET $yearseparator = N'/';
  END IF;

  SET $index  = 0;
  SET $strlen = LENGTH($value);

  WHILE ($index < $strlen) 
    AND (SUBSTRING($value, $index + 1, 1) NOT IN (N'1',N'2',N'3',N'4',N'5',N'6',N'7',N'8',N'9',N'0')) DO

    SET $index  = $index + 1;
  END WHILE;

  SET $value = SUBSTRING($value,$index + 1, 255); -- cut acronym 
  SET $index = LOCATE($yearseparator, $value);    -- year separator (slash or dot) 

  IF ($index > 0) THEN
    SET $value  = TRIM(SUBSTRING($value, 1, $index - 1));
    SET $index  = 0;
    SET $strlen = LENGTH($value);

    WHILE ($index < $strlen)
      AND (SUBSTRING($value, $index + 1, 1) IN (N'1',N'2',N'3',N'4',N'5',N'6',N'7',N'8',N'9',N'0')) DO

      SET $index = $index + 1;
    END WHILE;

    SET $result = $value;
  END IF;

  RETURN $result;
END

GO

CREATE FUNCTION `f_mfn_catno_getnumber`($value         VARCHAR(255)
                                      , $yearseparator VARCHAR(1))
  RETURNS INT
  DETERMINISTIC
BEGIN
  DECLARE $index  INT;
  DECLARE $result INT;
  DECLARE $strlen INT;

  IF (COALESCE(@yearseparator,'') = N'') THEN
    SET $yearseparator = N'/';
  END IF;

  SET $index  = 0;
  SET $strlen = LENGTH($value);

  WHILE ($index < $strlen) 
    AND (SUBSTRING($value, $index + 1, 1) NOT IN (N'1',N'2',N'3',N'4',N'5',N'6',N'7',N'8',N'9',N'0')) DO

    SET $index  = $index + 1;
  END WHILE;
    
  SET $value = SUBSTRING($value,$index + 1, 255); -- cut acronym 
  SET $index = LOCATE($yearseparator, $value);    -- year separator (slash or dot) 


  IF ($index > 0) THEN
    SET $value = LTRIM(SUBSTRING($value,$index + 1, 255)); -- cut year and separator
  END IF;

  SET $index  = 0;
  SET $strlen = LENGTH($value);

  WHILE ($index < $strlen) 
    AND (SUBSTRING($value, $index + 1, 1) IN (N'1',N'2',N'3',N'4',N'5',N'6',N'7',N'8',N'9',N'0')) DO

    SET $index  = $index + 1;
  END WHILE;

  SET $result = SUBSTRING($value, 1, $index);

  RETURN $result;
END

GO

CREATE FUNCTION `f_mfn_catno_getsubno`($value         VARCHAR(255)
                                     , $yearseparator VARCHAR(1))
  RETURNS VARCHAR(255)
  DETERMINISTIC
BEGIN
  DECLARE $index  INT;
  DECLARE $strlen INT;

  IF (COALESCE(@yearseparator,'') = N'') THEN
    SET $yearseparator = N'/';
  END IF;

  SET $index  = 0;
  SET $strlen = LENGTH($value);

  WHILE ($index < $strlen) 
    AND (SUBSTRING($value, $index + 1, 1) NOT IN (N'1',N'2',N'3',N'4',N'5',N'6',N'7',N'8',N'9',N'0')) DO

    SET $index  = $index + 1;
  END WHILE;
    
  SET $value = SUBSTRING($value,$index + 1, 255); -- cut acronym 
  SET $index = LOCATE($yearseparator, $value);    -- year separator (slash or dot) 

  IF ($index > 0) THEN
    SET $value = LTRIM(SUBSTRING($value,$index + 1, 255)); -- en: cut year and separator
  END IF;

  SET $index  = 0;
  SET $strlen = LENGTH($value);

  WHILE ($index < $strlen) 
    AND (SUBSTRING($value, $index + 1, 1) IN (N'1',N'2',N'3',N'4',N'5',N'6',N'7',N'8',N'9',N'0')) DO

    SET $index  = $index + 1;
  END WHILE;

  RETURN NULLIF(TRIM(SUBSTRING($value, $index + 1, 255)), '');
END

GO

CREATE FUNCTION `f_mfn_adjustseparator`($value     VARCHAR(255)
                                      , $separator VARCHAR(1))
  RETURNS VARCHAR(255)
  DETERMINISTIC
BEGIN
  SET $separator = COALESCE($separator, '_');

  RETURN REPLACE(REPLACE(REPLACE(REPLACE($value, '/', $separator), '.', $separator), ' ', $separator), CONCAT($separator, $separator), $separator);
END

GO

CREATE FUNCTION `f_mfn_adjustacronym`($value     VARCHAR(255)
                                    , $separator VARCHAR(1))
  RETURNS VARCHAR(255)
  DETERMINISTIC
BEGIN
  DECLARE $result VARCHAR(255);

  SET $separator = COALESCE($separator, '_');
  SET $result    = `f_mfn_adjustseparator`($value, $separator);

  IF  (LENGTH($result) > 0) 
  AND (SUBSTRING($result, LENGTH($result), 1) = $separator) THEN
    SET $result = SUBSTRING($result, 1, LENGTH($result) - 1);
  END IF;

  RETURN $result;
END

GO

CREATE FUNCTION `f_mfn_catno2sortorderstring`($value           VARCHAR(255)
                                            , $yearseparator   VARCHAR(1)
                                            , $separator       VARCHAR(1)
                                            , $maxnumberlength INT
                                            , $allwayswithyear BIT)
  RETURNS VARCHAR(255)
  DETERMINISTIC
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION RETURN NULL;
  DECLARE CONTINUE HANDLER FOR SQLWARNING BEGIN END;

  SET $separator       = COALESCE($separator, '_');
  SET $maxnumberlength = COALESCE($maxnumberlength, 6);

  IF (COALESCE($yearseparator, '') = '') THEN
    SET $yearseparator = '/';
  END IF;

  IF ($allwayswithyear <> 0) THEN
    RETURN CONCAT(COALESCE(CONCAT(NULLIF(`f_mfn_adjustacronym`(`f_mfn_catno_getacronym`($value), $separator), ''), $separator), '')
         , CONCAT(LPAD(COALESCE(`f_mfn_catno_getyear`($value, $yearseparator), ''), 4, '0'), $separator)
         , LPAD(COALESCE(`f_mfn_catno_getnumber`($value, $yearseparator), ''), $maxnumberlength, '0')
         , COALESCE(CONCAT($separator, `f_mfn_catno_getsubno`($value, $yearseparator)), ''));
  ELSE
    RETURN CONCAT(COALESCE(CONCAT(NULLIF(`f_mfn_adjustacronym`(`f_mfn_catno_getacronym`($value), $separator), ''), $separator), '')
         , COALESCE(CONCAT(LPAD(`f_mfn_catno_getyear`($value, $yearseparator), 4, '0'), $separator), '')
         , LPAD(COALESCE(`f_mfn_catno_getnumber`($value, $yearseparator), ''), $maxnumberlength, '0')
         , COALESCE(CONCAT($separator, `f_mfn_catno_getsubno`($value, $yearseparator)), ''));
  END IF;
END

GO

CREATE FUNCTION `f_mfn_catno2gin`($value           VARCHAR(255)
                                , $prefix          VARCHAR(25)
                                , $yearseparator   VARCHAR(1)
                                , $separator       VARCHAR(1)
                                , $maxnumberlength INT
                                , $allwayswithyear BIT)
  RETURNS VARCHAR(255)
  DETERMINISTIC
BEGIN
  DECLARE $result VARCHAR(255);
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION RETURN NULL;
  DECLARE CONTINUE HANDLER FOR SQLWARNING BEGIN END;

  SET $separator       = COALESCE($separator, '_');
  SET $maxnumberlength = COALESCE($maxnumberlength, 6);

  IF (COALESCE($yearseparator, '') = '') THEN
    SET $yearseparator = '/';
  END IF;

  IF ($allwayswithyear <> 0) THEN
    IF ($maxnumberlength > 0) AND ($maxnumberlength <= 32) THEN
      SET $result = CONCAT(COALESCE(CONCAT(NULLIF($prefix,''), $separator), '')
                  , COALESCE(CONCAT(NULLIF(`f_mfn_catno_getacronym`($value), ''), $separator), '')
                  , CONCAT(LPAD(COALESCE(`f_mfn_catno_getyear`($value, $yearseparator), ''), 4, '0'), $separator)
                  , LPAD(COALESCE(`f_mfn_catno_getnumber`($value, $yearseparator), ''), $maxnumberlength, '0')
                  , COALESCE(CONCAT($separator, `f_mfn_catno_getsubno`($value, $yearseparator)), ''));
    ELSE
      SET $result = CONCAT(COALESCE(CONCAT(NULLIF($prefix,''), $separator), '')
                  , COALESCE(CONCAT(NULLIF(`f_mfn_catno_getacronym`($value), ''), $separator), '')
                  , CONCAT(LPAD(COALESCE(`f_mfn_catno_getyear`($value, $yearseparator), ''), 4, '0'), $separator)
                  , COALESCE(`f_mfn_catno_getnumber`($value, $yearseparator), '')
                  , COALESCE(CONCAT($separator, `f_mfn_catno_getsubno`($value, $yearseparator)), ''));
    END IF;
  ELSE
    IF ($maxnumberlength > 0) AND ($maxnumberlength <= 32) THEN
      SET $result = CONCAT(COALESCE(CONCAT(NULLIF($prefix,''), $separator), '')
                  , COALESCE(CONCAT(NULLIF(`f_mfn_catno_getacronym`($value), ''), $separator), '')
                  , COALESCE(CONCAT(LPAD(`f_mfn_catno_getyear`($value, $yearseparator), 4, '0'), $separator), '')
                  , LPAD(COALESCE(`f_mfn_catno_getnumber`($value, $yearseparator), ''), $maxnumberlength, '0')
                  , COALESCE(CONCAT($separator, `f_mfn_catno_getsubno`($value, $yearseparator)), ''));
    ELSE
      SET $result = CONCAT(COALESCE(CONCAT(NULLIF($prefix,''), $separator), '')
                  , COALESCE(CONCAT(NULLIF(`f_mfn_catno_getacronym`($value), ''), $separator), '')
                  , COALESCE(CONCAT(`f_mfn_catno_getyear`($value, $yearseparator), $separator), '')
                  , COALESCE(`f_mfn_catno_getnumber`($value, $yearseparator), '')
                  , COALESCE(CONCAT($separator, `f_mfn_catno_getsubno`($value, $yearseparator)), ''));
    END IF;
  END IF;

  RETURN `f_mfn_adjustseparator`($result, $separator);
END

GO

CREATE TRIGGER `tr_mfn_collectionobject_inscatno` BEFORE INSERT ON `collectionobject`
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

  SET $prefix = (SELECT `collectioncode`
                   FROM `mfn_collection`
                  WHERE (`collectioncode` = `f_mfn_getCollectionCode`(NEW.`CollectionID`)));

  IF (NEW.`CatalogNumber` = 'auto') THEN
    SET NEW.`CatalogNumber` = NULL;
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

    IF (`f_mfn_adjustacronym`(`f_mfn_catno_getacronym`(NEW.`CatalogNumber`), $gin_separator) = $prefix) THEN
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

      IF (`f_mfn_adjustacronym`(`f_mfn_catno_getacronym`(NEW.`CatalogNumber`), $gin_separator) = $prefix) THEN
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
