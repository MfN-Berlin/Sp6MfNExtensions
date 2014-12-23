/******************************************************************************/
/* MfN extensions for Specify 6                                               */
/* additional indices                                                         */
/******************************************************************************/

USE specify;

DROP PROCEDURE IF EXISTS `p_mfn_createIndices`;
DROP PROCEDURE IF EXISTS `p_mfn_dropIndices`;

DELIMITER GO

CREATE PROCEDURE `p_mfn_createIndices`()
BEGIN
  IF (NOT EXISTS(SELECT *
                   FROM INFORMATION_SCHEMA.STATISTICS
                  WHERE (table_schema = DATABASE())
                    AND (table_name = 'collectionobject')
                    AND (index_name = 'ix_mfn_collectionobject_reservedtext'))) THEN
    CREATE INDEX ix_mfn_collectionobject_reservedtext ON `collectionobject` (`ReservedText`);
  END IF;

  IF (NOT EXISTS(SELECT *
                   FROM INFORMATION_SCHEMA.STATISTICS
                  WHERE (table_schema = DATABASE())
                    AND (table_name = 'collectionobject')
                    AND (index_name = 'ix_mfn_collectionobject_altcatalognumber'))) THEN
    CREATE INDEX ix_mfn_collectionobject_altcatalognumber ON `collectionobject` (`AltCatalogNumber`);
  END IF;
END;

GO

CREATE PROCEDURE `p_mfn_dropIndices`()
BEGIN
  IF (EXISTS(SELECT *
               FROM INFORMATION_SCHEMA.STATISTICS
              WHERE (table_schema = DATABASE())
                AND (table_name = 'collectionobject')
                AND (index_name = 'ix_mfn_collectionobject_reservedtext'))) THEN
    DROP INDEX ix_mfn_collectionobject_reservedtext ON `collectionobject`;
  END IF;

  IF (EXISTS(SELECT *
               FROM INFORMATION_SCHEMA.STATISTICS
              WHERE (table_schema = DATABASE())
                AND (table_name = 'collectionobject')
                AND (index_name = 'ix_mfn_collectionobject_altcatalognumber'))) THEN
    DROP INDEX ix_mfn_collectionobject_altcatalognumber ON `collectionobject`;
  END IF;
END;

GO

DELIMITER ;

CALL `p_mfn_createIndices`();
