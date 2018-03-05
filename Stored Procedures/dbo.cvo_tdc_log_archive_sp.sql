SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [dbo].[cvo_tdc_log_archive_sp] @m int = NULL
AS 

-- execute cvo_tdc_log_archive_sp @m=6

BEGIN

SET NOCOUNT ON;

DECLARE @asofdate DATETIME;
SELECT @asofdate  = '1/1/1900';

IF @m IS NULL SELECT @m = 1;

SELECT @asofdate = DATEADD(m, @m, MIN(tran_date))
FROM   dbo.tdc_log WHERE tran_date < DATEADD(y,-2,GETDATE());  -- keep 2 years in the live file

IF OBJECT_ID('dbo.cvo_tdc_log_archive_tbl') IS NULL
    BEGIN
        CREATE TABLE dbo.cvo_tdc_log_archive_tbl
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
            ON dbo.cvo_tdc_log_archive_tbl
        (
            tran_date ASC ,
            location ASC ,
            part_no ASC )
            WITH ( PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF ,
                   SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF ,
                   ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY];
        GRANT ALL
            ON dbo.cvo_tdc_log_archive_tbl
            TO PUBLIC;
    END;

IF (@asofdate IS NOT NULL AND  @asofdate <> '1/1/1900')
BEGIN

; WITH i AS 
( SELECT TOP (100) PERCENT t.* FROM dbo.tdc_log t WHERE tran_date < @asofdate ORDER BY t.tran_date)

INSERT INTO dbo.cvo_tdc_log_archive_tbl ( tran_date ,
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
            SELECT tran_date,
                   UserID,
                   trans_source,
                   module,
                   trans,
                   tran_no,
                   tran_ext,
                   part_no,
                   lot_ser,
                   bin_no,
                   location,
                   quantity,
                   data
            FROM   i;

DECLARE @recs BIGINT;

SELECT @recs = COUNT(*) FROM dbo.tdc_log t  WHERE t.tran_date < @asofdate;

WHILE @recs > 0
BEGIN

; WITH d AS 
( SELECT TOP (100000) t.tran_date FROM dbo.tdc_log t WHERE tran_date < @asofdate ORDER BY t.tran_date )
delete from d

SELECT @recs = COUNT(*) FROM dbo.tdc_log t  WHERE t.tran_date < @asofdate;

END;

END;


SELECT MIN(tran_date), COUNT(*)
FROM   dbo.tdc_log;
SELECT max(tran_date), COUNT(*)
FROM   dbo.cvo_tdc_log_archive_tbl AS tla;

END;

GO
GRANT EXECUTE ON  [dbo].[cvo_tdc_log_archive_sp] TO [public]
GO
