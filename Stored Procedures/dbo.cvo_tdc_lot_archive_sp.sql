SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [dbo].[cvo_tdc_lot_archive_sp] @m int = NULL
AS 

-- execute cvo_tdc_lot_archive_sp @m=2

BEGIN


SET NOCOUNT ON;

DECLARE @asofdate DATETIME;
SELECT @asofdate  = '1/1/1900';

IF @m IS NULL SELECT @m = 1;

SELECT @asofdate = DATEADD(m, @m, MIN(tran_date))
FROM   tdc_log WHERE tran_date < DATEADD(y,-2,GETDATE());  -- keep 2 years in the live file

IF OBJECT_ID('dbo.cvo_tdc_log_archive') IS NULL
    BEGIN
        CREATE TABLE dbo.cvo_tdc_log_archive
            (
                tran_date DATETIME NOT NULL ,
                UserID VARCHAR(50) NOT NULL ,
                trans_source VARCHAR(2) NULL ,
                module VARCHAR(50) NULL ,
                trans VARCHAR(50) NULL ,
                tran_no VARCHAR(16) NULL ,
                tran_ext VARCHAR(5) NULL ,
                part_no VARCHAR(30) NULL ,
                lot_ser VARCHAR(25) NULL ,
                bin_no VARCHAR(12) NULL ,
                location VARCHAR(10) NULL ,
                quantity VARCHAR(20) NULL ,
                data VARCHAR(7500) NULL
            ) ON [PRIMARY];
        /****** Object:  Index [tdc_log_idx1]    Script Date: 9/13/2017 12:42:10 PM ******/
        CREATE NONCLUSTERED INDEX tdc_log_idx_arch_1
            ON dbo.cvo_tdc_log_archive
        (
            tran_date ASC ,
            location ASC ,
            part_no ASC )
            WITH ( PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF ,
                   SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF ,
                   ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY];
        GRANT ALL
            ON dbo.cvo_tdc_log_archive
            TO PUBLIC;
    END;

IF (@asofdate IS NOT NULL AND  @asofdate <> '1/1/1900')
begin
INSERT INTO dbo.cvo_tdc_log_archive ( tran_date ,
                                      UserID ,
                                      trans_source ,
                                      module ,
                                      trans ,
                                      tran_no ,
                                      tran_ext ,
                                      part_no ,
                                      lot_ser ,
                                      bin_no ,
                                      location ,
                                      quantity ,
                                      data )
            SELECT *
            FROM   tdc_log (nolock)
            WHERE  tran_date < @asofdate;

DELETE FROM tdc_log WITH (tablock)
WHERE tran_date < @asofdate;
END

SELECT MIN(tran_date), COUNT(*)
FROM   tdc_log;
SELECT max(tran_date), COUNT(*)
FROM   dbo.cvo_tdc_log_archive AS tla;

END;

GRANT EXECUTE ON cvo_tdc_lot_archive_sp TO PUBLIC;
GO
