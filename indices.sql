/******************************************************************************/
/* MfN extensions for Specify 6                                               */
/* additional indices                                                    */
/******************************************************************************/

DELIMITER GO

USE specify;

GO

DROP PROCEDURE IF EXISTS `p_mfn_createIndices`;

GO

CREATE PROCEDURE `p_mfn_createIndices`()
BEGIN
  IF (NOT EXISTS(SELECT *
                   FROM INFORMATION_SCHEMA.STATISTICS
                  WHERE (table_schema = 'specify')
                    AND (table_name = 'collectionobject')
                    AND (index_name = 'ix_mfn_collectionobject_reservedtext'))) THEN
    CREATE INDEX ix_mfn_collectionobject_reservedtext ON `specify`.`collectionobject` (`ReservedText`);
  END IF;

  IF (NOT EXISTS(SELECT *
                   FROM INFORMATION_SCHEMA.STATISTICS
                  WHERE (table_schema = 'specify')
                    AND (table_name = 'collectionobject')
                    AND (index_name = 'ix_mfn_collectionobject_altcatalognumber'))) THEN
    CREATE INDEX ix_mfn_collectionobject_altcatalognumber ON `specify`.`collectionobject` (`AltCatalogNumber`);
  END IF;
END;

GO

DROP PROCEDURE IF EXISTS `p_mfn_dropIndices`;

GO

CREATE PROCEDURE `p_mfn_dropIndices`()
BEGIN
  IF (EXISTS(SELECT *
               FROM INFORMATION_SCHEMA.STATISTICS
              WHERE (table_schema = 'specify')
                AND (table_name = 'collectionobject')
                AND (index_name = 'ix_mfn_collectionobject_reservedtext'))) THEN
    DROP INDEX ix_mfn_collectionobject_reservedtext ON `specify`.`collectionobject`;
  END IF;

  IF (EXISTS(SELECT *
               FROM INFORMATION_SCHEMA.STATISTICS
              WHERE (table_schema = 'specify')
                AND (table_name = 'collectionobject')
                AND (index_name = 'ix_mfn_collectionobject_altcatalognumber'))) THEN
    DROP INDEX ix_mfn_collectionobject_altcatalognumber ON `specify`.`collectionobject`;
  END IF;
END;

GO

CALL `p_mfn_createIndices`();

GO

DELIMITER ;
